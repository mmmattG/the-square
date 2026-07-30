#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
mod_name=$(python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["name"])' < /dev/null)

find_factorio() {
  if [ "${FACTORIO:-}" ]; then printf '%s\n' "$FACTORIO"; return 0; fi
  if command -v factorio >/dev/null 2>&1; then command -v factorio; return 0; fi
  for candidate in \
    "/Applications/Factorio.app/Contents/MacOS/factorio" \
    "$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"; do
    if [ -x "$candidate" ]; then printf '%s\n' "$candidate"; return 0; fi
  done
  return 1
}

factorio_bin=$(find_factorio) || {
  echo "error: Factorio binary not found. Set FACTORIO=/path/to/factorio." >&2
  exit 127
}

artifact_path=$("$repo_root/scripts/build-mod.sh")
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/the-square-content-move-e2e.XXXXXX")

cleanup() {
  if [ "${KEEP_E2E_ARTIFACTS:-}" ]; then
    echo "Kept e2e artifacts in $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT INT TERM

mod_dir="$work_dir/mods"
save_path="$work_dir/content-move.zip"
log_path="$work_dir/factorio-create.log"
benchmark_log_path="$work_dir/factorio-benchmark.log"
validator_dir="$mod_dir/the-square-content-move-validator_0.1.0"
mkdir -p "$validator_dir"
cp "$artifact_path" "$mod_dir/"
cp -R "$repo_root/lib" "$validator_dir/"

cat > "$validator_dir/info.json" <<EOF
{"name":"the-square-content-move-validator","version":"0.1.0","title":"The Square Content Move Validator","author":"The Square tests","factorio_version":"2.0","dependencies":["base","$mod_name"]}
EOF

cat > "$validator_dir/control.lua" <<'EOF'
local defs = require("lib.runtime_defs")
local square_move_runtime = require("lib.square_move_runtime")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(
      string.format(
        "[the-square-content-move-validator] %s: expected=%s actual=%s",
        message,
        tostring(expected),
        tostring(actual)
      )
    )
  end
end

script.on_init(function()
  assert(
    helpers.is_valid_sprite_path(defs.SQUARE_MOVE_MODE_INFO_SPRITE),
    "[the-square-content-move-validator] movement mode info sprite is invalid"
  )

  local surface = game.surfaces.nauvis
  local west_anchor = {
    resource = "iron-ore",
    kind = "item",
    flow = "ingress",
    side = "west",
    position = {x = -4, y = -1},
    direction = defines.direction.east,
    entity_name = "the-square-item-ingress-managed-anchor"
  }
  local north_anchor = {
    resource = "water",
    kind = "fluid",
    flow = "ingress",
    side = "north",
    position = {x = 0, y = -4},
    direction = defines.direction.north,
    entity_name = "the-square-fluid-ingress-managed-anchor"
  }
  local east_anchor = {
    resource = "copper-ore",
    kind = "item",
    flow = "ingress",
    side = "east",
    position = {x = 4, y = 1},
    direction = defines.direction.west,
    entity_name = "the-square-item-ingress-managed-anchor"
  }
  local west_egress_anchor = {
    resource = "sulfuric-acid",
    kind = "fluid",
    flow = "egress",
    side = "west",
    position = {x = -4, y = 2},
    direction = defines.direction.east,
    entity_name = "the-square-fluid-egress-managed-anchor"
  }

  storage.planets = {
    nauvis = {
      square_size = 7,
      surface_size = 9,
      surface_name = "nauvis",
      square_position = {x = 0, y = 0},
      starter_anchors = {anchors = {west_anchor, north_anchor, east_anchor, west_egress_anchor}}
    }
  }

  surface.set_tiles({
    {name = "refined-concrete", position = {x = 0, y = 1}}
  }, false, false, false, false)

  local chest = surface.create_entity({
    name = "steel-chest",
    position = {x = 0.5, y = 0.5},
    force = game.forces.player
  })
  assert(chest, "[the-square-content-move-validator] failed to create source chest")
  chest.insert({name = "iron-plate", count = 42})
  local character = surface.create_entity({
    name = "character",
    position = {x = -1, y = 1},
    force = game.forces.player
  })
  assert(character, "[the-square-content-move-validator] failed to create source character")
  local connected_belt = surface.create_entity({
    name = "transport-belt",
    position = {x = -3, y = -1},
    direction = defines.direction.east,
    force = game.forces.player
  })
  assert(connected_belt, "[the-square-content-move-validator] failed to create edge belt")
  local belt_start = {x = connected_belt.position.x, y = connected_belt.position.y}
  local connected_pipe = surface.create_entity({
    name = "pipe",
    position = {x = 0, y = -3},
    force = game.forces.player
  })
  assert(connected_pipe, "[the-square-content-move-validator] failed to create edge pipe")
  local pipe_start = {x = connected_pipe.position.x, y = connected_pipe.position.y}
  local leading_belt = surface.create_entity({
    name = "transport-belt",
    position = {x = 3, y = 1},
    direction = defines.direction.west,
    force = game.forces.player
  })
  assert(leading_belt, "[the-square-content-move-validator] failed to create leading ingress belt")
  local leading_belt_start = {x = leading_belt.position.x, y = leading_belt.position.y}
  west_anchor.entity = surface.create_entity({
    name = west_anchor.entity_name,
    position = west_anchor.position,
    direction = west_anchor.direction,
    force = game.forces.player,
    type = "input"
  })
  assert(west_anchor.entity, "[the-square-content-move-validator] failed to create west Managed Line")
  north_anchor.entity = surface.create_entity({
    name = north_anchor.entity_name,
    position = north_anchor.position,
    direction = north_anchor.direction,
    force = game.forces.player
  })
  assert(north_anchor.entity, "[the-square-content-move-validator] failed to create north Managed Line")
  east_anchor.entity = surface.create_entity({
    name = east_anchor.entity_name,
    position = east_anchor.position,
    direction = east_anchor.direction,
    force = game.forces.player,
    type = "input"
  })
  assert(east_anchor.entity, "[the-square-content-move-validator] failed to create east Managed Line")
  west_egress_anchor.entity = surface.create_entity({
    name = west_egress_anchor.entity_name,
    position = west_egress_anchor.position,
    direction = west_egress_anchor.direction,
    force = game.forces.player
  })
  assert(
    west_egress_anchor.entity,
    "[the-square-content-move-validator] failed to create disconnected west egress"
  )
  local west_anchor_start = {x = west_anchor.entity.position.x, y = west_anchor.entity.position.y}

  local result = square_move_runtime.move("nauvis", "east", {
    mode = square_move_runtime.MODE_CONTENTS,
    managed_line_runtime = {
      reconcile = function()
        if not (north_anchor.entity and north_anchor.entity.valid) then
          north_anchor.entity = surface.create_entity({
            name = north_anchor.entity_name,
            position = north_anchor.position,
            direction = north_anchor.direction,
            force = game.forces.player
          })
        end
      end
    }
  })
  assert(result.ok, "[the-square-content-move-validator] contents movement failed: " .. tostring(result.reason))
  assert_equal(storage.planets.nauvis.square_position.x, 0, "Square x position changed")
  assert_equal(storage.planets.nauvis.square_position.y, 0, "Square y position changed")

  local moved_chest = surface.find_entities_filtered({
    name = "steel-chest",
    position = {x = 1.5, y = 0.5}
  })[1]
  assert(moved_chest, "[the-square-content-move-validator] moved chest was not found")
  assert_equal(moved_chest.get_item_count("iron-plate"), 42, "chest inventory was not preserved")
  assert_equal(character.position.x, -1, "character x position changed")
  assert_equal(character.position.y, 1, "character y position changed")
  assert(
    surface.find_entities_filtered({
      name = "transport-belt",
      position = {x = belt_start.x + 1, y = belt_start.y}
    })[1],
    "[the-square-content-move-validator] edge belt did not move east"
  )
  assert(
    surface.find_entities_filtered({
      name = "pipe",
      position = {x = pipe_start.x + 1, y = pipe_start.y}
    })[1],
    "[the-square-content-move-validator] edge pipe did not move east"
  )
  assert_equal(west_anchor.position.x, -4, "trailing Managed Line state moved")
  assert_equal(west_anchor.entity.position.x, west_anchor_start.x, "trailing Managed Line entity moved")
  assert(
    surface.find_entities_filtered({
      name = "transport-belt",
      position = belt_start
    })[1],
    "[the-square-content-move-validator] trailing ingress belt stub was not restored"
  )
  assert(
    surface.find_entities_filtered({
      name = "transport-belt",
      position = leading_belt_start
    })[1],
    "[the-square-content-move-validator] leading ingress belt connection was not retained"
  )
  assert(east_anchor.entity and east_anchor.entity.valid, "leading Managed Line entity was replaced")
  assert(
    surface.find_entities_filtered({
      name = "pipe",
      position = {x = -2.5, y = 2.5}
    })[1],
    "[the-square-content-move-validator] disconnected egress did not gain a pipe connection"
  )
  assert_equal(north_anchor.position.x, 1, "north Managed Line state did not move east")
  assert(north_anchor.entity and north_anchor.entity.valid, "north Managed Line entity was not reconciled")
  assert_equal(
    math.floor(north_anchor.entity.position.x),
    1,
    "north Managed Line entity did not follow its pipe east"
  )
  assert_equal(surface.get_tile(1, 1).name, "refined-concrete", "placed tile did not move east")
  assert_equal(surface.get_tile(-3, 1).name, "grass-1", "vacated edge was not restored")
  storage.awaiting_buffer_cleanup = true
  log("[the-square-content-move-validator] entity state and placed tile moved east")
end)

script.on_nth_tick(1, function()
  if not storage.awaiting_buffer_cleanup or game.tick == 0 then
    return
  end

  for surface_name in pairs(game.surfaces) do
    if string.match(surface_name, "^the%-square%-content%-move%-buffer") then
      error("[the-square-content-move-validator] move buffer surface was not deleted: " .. surface_name)
    end
  end
  storage.awaiting_buffer_cleanup = nil
  log("[the-square-content-move-validator] PASS deferred move buffer cleanup completed")
end)
EOF

cat > "$mod_dir/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"$mod_name","enabled":true},{"name":"the-square-content-move-validator","enabled":true}]}
EOF

"$factorio_bin" --create "$save_path" --mod-directory "$mod_dir" --disable-audio > "$log_path" 2>&1 || {
  echo "FAIL Factorio contents movement validation failed" >&2
  tail -200 "$log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
}

"$factorio_bin" \
  --benchmark "$save_path" \
  --benchmark-ticks 3 \
  --mod-directory "$mod_dir" \
  --disable-audio > "$benchmark_log_path" 2>&1 || {
  echo "FAIL Factorio contents movement cleanup validation failed" >&2
  tail -200 "$benchmark_log_path" >&2 || true
  KEEP_E2E_ARTIFACTS=1
  exit 1
}

grep "\[the-square-content-move-validator\]" "$log_path" "$benchmark_log_path"
