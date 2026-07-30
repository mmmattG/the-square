package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {
  direction = {
    south = 1,
    west = 2,
    north = 3,
    east = 4
  }
}

settings = {
  global = {
    ["the-square-background-tile"] = {value = "grass-1"}
  },
  startup = {
    ["the-square-nauvis-starting-square-size"] = {value = 7}
  }
}

local square_move_runtime = require("lib.square_move_runtime")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function run_test(name, fn)
  local ok, err = pcall(fn)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

local function make_entity(entity_type, position, direction)
  local entity
  entity = {
    valid = true,
    type = entity_type,
    position = {x = position.x, y = position.y},
    direction = direction,
    bounding_box = {
      left_top = {x = position.x, y = position.y},
      right_bottom = {x = position.x + 1, y = position.y + 1}
    },
    destroy = function()
      entity.valid = false
    end,
    teleport = function(target_position)
      local width = entity.bounding_box.right_bottom.x - entity.bounding_box.left_top.x
      local height = entity.bounding_box.right_bottom.y - entity.bounding_box.left_top.y
      entity.position = {x = target_position.x, y = target_position.y}
      entity.bounding_box = {
        left_top = {x = target_position.x, y = target_position.y},
        right_bottom = {x = target_position.x + width, y = target_position.y + height}
      }
      return true
    end
  }

  return entity
end

local function make_surface(area_entities, tile_names)
  local surface
  surface = {
    name = "nauvis",
    area_entities = area_entities or {},
    map_gen_settings = {width = 9, height = 9},
    tiles_set = nil,
    created_entities = {},
    requested_position = nil,
    request_to_generate_chunks = function(position)
      surface.requested_position = position
    end,
    force_generate_chunk_requests = function() end,
    find_entities = function()
      return surface.area_entities
    end,
    find_entities_filtered = function(filter)
      if filter.area then
        return surface.area_entities
      end

      return {}
    end,
    set_tiles = function(tiles)
      surface.tiles_set = tiles
    end,
    get_tile = function(x, y)
      return {name = (tile_names and tile_names[x .. ":" .. y]) or "grass-1"}
    end,
    get_hidden_tile = function()
      return nil
    end,
    set_hidden_tile = function() end,
    clone_area = function() end,
    clone_entities = function(spec)
      for _, source in ipairs(spec.entities) do
        if source.valid then
          local clone = make_entity(source.type, {
            x = source.position.x + spec.destination_offset.x,
            y = source.position.y + spec.destination_offset.y
          }, source.direction)
          spec.destination_surface.area_entities[#spec.destination_surface.area_entities + 1] = clone
        end
      end
    end,
    create_entity = function(spec)
      surface.created_entities[#surface.created_entities + 1] = spec
      return {valid = true, name = spec.name, destroy = function(self) self.valid = false end}
    end
  }

  return surface
end

local function install_world(surface, anchors)
  storage = {
    planets = {
      nauvis = {
        square_size = 7,
        surface_size = 9,
        surface_name = "nauvis",
        square_position = {x = 0, y = 0},
        starter_anchors = {anchors = anchors or {}}
      }
    }
  }

  game = {
    tick = 0,
    surfaces = {nauvis = surface},
    create_surface = function(name)
      local buffer = make_surface()
      buffer.name = name
      game.surfaces[name] = buffer
      return buffer
    end,
    delete_surface = function(surface_to_delete)
      game.surfaces[surface_to_delete.name] = nil
      return true
    end,
    forces = {
      player = {
        set_spawn_position = function(position)
          game.spawn_position = position
        end,
        chart = function() end
      }
    }
  }
end

run_test("Square movement is obstructed by an entity on the departing edge", function()
  local assembler = make_entity("assembling-machine", {x = -3, y = 0})
  local surface = make_surface({assembler})
  install_world(surface)

  local result = square_move_runtime.check("nauvis", "east")

  assert_equal(result.ok, false, "an assembler left behind in the Void should block the move")
  assert_equal(result.reason, "obstructed", "blocked moves should report an obstruction")
  assert_equal(result.departing_side, "west", "moving east should validate the west edge")
  assert_equal(#result.obstructions, 1, "the obstruction should be returned for UI/runtime diagnostics")
end)

run_test("Only a correctly aligned belt connected to a departing Managed Line is permitted", function()
  local west_anchor = {
    resource = "iron-ore",
    kind = "item",
    flow = "ingress",
    side = "west",
    position = {x = -4, y = 0},
    direction = defines.direction.east
  }
  local belt = make_entity("transport-belt", {x = -3, y = 0}, defines.direction.east)
  local surface = make_surface({belt})
  install_world(surface, {west_anchor})

  assert_equal(
    square_move_runtime.check("nauvis", "east").ok,
    true,
    "the connected inward-flowing ingress belt should be allowed"
  )

  belt.direction = defines.direction.west
  assert_equal(
    square_move_runtime.check("nauvis", "east").ok,
    false,
    "a belt flowing away from its Managed Line should block the move"
  )
end)

run_test("A pipe connected to a departing fluid ingress or egress Managed Line is permitted", function()
  local west_anchor = {
    resource = "water",
    kind = "fluid",
    flow = "ingress",
    side = "west",
    position = {x = -4, y = 0},
    direction = defines.direction.west
  }
  local pipe = make_entity("pipe", {x = -3, y = 0})
  local surface = make_surface({pipe})
  install_world(surface, {west_anchor})

  assert_equal(
    square_move_runtime.check("nauvis", "east").ok,
    true,
    "the pipe directly connected to a fluid Managed Line should be allowed"
  )

  west_anchor.flow = "egress"
  west_anchor.direction = defines.direction.east
  assert_equal(
    square_move_runtime.check("nauvis", "east").ok,
    true,
    "the connected pipe exception should apply to fluid egress as well"
  )

  pipe.type = "storage-tank"
  assert_equal(
    square_move_runtime.check("nauvis", "east").ok,
    false,
    "another fluid entity in the same position should still obstruct the move"
  )
end)

run_test("Moving the Square updates tiles and Boundary state without moving factory entities", function()
  local west_anchor_entity = make_entity("underground-belt", {x = -4, y = 0}, defines.direction.east)
  local east_anchor_entity = make_entity("underground-belt", {x = 4, y = 0}, defines.direction.west)
  local west_anchor = {
    resource = "iron-ore",
    kind = "item",
    flow = "ingress",
    side = "west",
    position = {x = -4, y = 0},
    direction = defines.direction.east,
    entity_name = "the-square-iron-ore-ingress-anchor",
    entity = west_anchor_entity
  }
  local east_anchor = {
    resource = "copper-ore",
    kind = "item",
    flow = "ingress",
    side = "east",
    position = {x = 4, y = 0},
    direction = defines.direction.west,
    entity_name = "the-square-copper-ore-ingress-anchor",
    entity = east_anchor_entity
  }
  local north_anchor = {
    resource = "coal",
    kind = "item",
    flow = "ingress",
    side = "north",
    position = {x = 0, y = -4},
    direction = defines.direction.south
  }
  local departing_belt = make_entity("transport-belt", {x = -3, y = 0}, defines.direction.east)
  local assembler = make_entity("assembling-machine", {x = 0, y = 0})
  local surface = make_surface({departing_belt, assembler})
  install_world(surface, {west_anchor, east_anchor, north_anchor})
  local reconciled_planet = nil

  local result = square_move_runtime.move("nauvis", "east", {
    managed_line_runtime = {
      reconcile = function(planet_name)
        reconciled_planet = planet_name
      end
    }
  })

  assert_equal(result.ok, true, "an unobstructed move should succeed")
  assert_equal(storage.planets.nauvis.square_position.x, 1, "the Planet-local Square position should move east")
  assert_equal(storage.planets.nauvis.square_position.y, 0, "moving east should retain the Square y position")
  assert_equal(assembler.position.x, 0, "factory entities should retain their world x coordinate")
  assert_equal(assembler.position.y, 0, "factory entities should retain their world y coordinate")
  assert_equal(west_anchor.position.x, -3, "the departing Managed Line should move onto its connected belt")
  assert_equal(east_anchor.position.x, 5, "the arriving Managed Line should move outward with the Boundary")
  assert_equal(north_anchor.position.x, 0, "a Managed Line in an overlapping Boundary slot should stay connected")
  assert_equal(surface.created_entities[1].name, "transport-belt", "the arriving edge should leave a belt stub")
  assert_equal(surface.map_gen_settings.width, 11, "the finite surface should grow to contain the moved Square")
  assert_equal(surface.map_gen_settings.height, 9, "an east move should not grow the surface vertically")
  assert_equal(type(surface.tiles_set), "table", "playable and Void tiles should be rewritten")
  assert_equal(reconciled_planet, "nauvis", "Managed Lines should be reconciled after the Boundary moves")
  assert_equal(game.spawn_position.x, 1, "the force spawn should follow the moved Square")
end)

run_test("Contents movement is obstructed when an entity would enter the Void", function()
  local east_edge_assembler = make_entity("assembling-machine", {x = 3, y = 0})
  local surface = make_surface({east_edge_assembler})
  install_world(surface)

  local result = square_move_runtime.check("nauvis", "east", square_move_runtime.MODE_CONTENTS)

  assert_equal(result.ok, false, "contents on the destination edge should block the move")
  assert_equal(result.reason, "obstructed", "blocked contents moves should report an obstruction")
  assert_equal(result.obstructed_side, "east", "moving contents east should validate the east edge")
end)

run_test("Moving contents translates entities, characters, and placed tiles without moving the Square", function()
  local assembler = make_entity("assembling-machine", {x = 0, y = 0})
  local character = make_entity("character", {x = -1, y = 1})
  local surface = make_surface(
    {assembler, character},
    {
      ["0:0"] = "refined-concrete"
    }
  )
  install_world(surface)
  local reconciled_planet = nil

  local result = square_move_runtime.move("nauvis", "east", {
    mode = square_move_runtime.MODE_CONTENTS,
    managed_line_runtime = {
      reconcile = function(planet_name)
        reconciled_planet = planet_name
      end
    }
  })

  assert_equal(result.ok, true, "an unobstructed contents move should succeed")
  assert_equal(storage.planets.nauvis.square_position.x, 0, "the Square x position should stay fixed")
  assert_equal(storage.planets.nauvis.square_position.y, 0, "the Square y position should stay fixed")
  assert_equal(character.position.x, 0, "characters should move with the factory")
  assert_equal(character.position.y, 1, "moving east should retain character y position")
  assert_equal(result.moved_entity_count, 1, "the factory entity should be cloned through the move buffer")
  assert_equal(result.moved_character_count, 1, "the character should be teleported with the contents")
  assert_equal(reconciled_planet, "nauvis", "Managed Lines should reconcile after contents move")
  for surface_name in pairs(game.surfaces) do
    assert_equal(
      string.match(surface_name, "^the%-square%-content%-move%-buffer"),
      nil,
      "the temporary surface should be deleted"
    )
  end

  local moved_assembler

  for _, entity in ipairs(surface.area_entities) do
    if entity.valid and entity.type == "assembling-machine" then
      moved_assembler = entity
    end
  end

  assert_equal(moved_assembler.position.x, 1, "factory entities should move east by one tile")

  local moved_concrete = false
  local vacated_floor = false

  for _, tile in ipairs(surface.tiles_set) do
    if tile.position.x == 1 and tile.position.y == 0 and tile.name == "refined-concrete" then
      moved_concrete = true
    elseif tile.position.x == -3 and tile.position.y == 0 and tile.name == "grass-1" then
      vacated_floor = true
    end
  end

  assert_equal(moved_concrete, true, "placed tiles should move with the contents")
  assert_equal(vacated_floor, true, "the vacated edge should be restored to the managed floor")
end)

run_test("Square movement button names only parse supported directions", function()
  assert_equal(
    square_move_runtime.parse_direction_button_name("the_square_move_direction__north"),
    "north",
    "north movement buttons should parse"
  )
  assert_equal(
    square_move_runtime.parse_direction_button_name("the_square_move_direction__diagonal"),
    nil,
    "unknown movement buttons should not be handled"
  )
end)
