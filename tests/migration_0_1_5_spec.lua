package.path = "./?.lua;./?/init.lua;" .. package.path

game = {players = {}}

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

local function run_migration()
  dofile("migrations/0.1.5.lua")
end

run_test("0.1.5 migration moves legacy Nauvis state under planets", function()
  local legacy_state = {
    square_size = 9,
    surface_name = "nauvis"
  }
  local legacy_managed_lines = {
    anchors = {
      {resource = "iron-ore"}
    }
  }
  storage = {
    bootstrap = legacy_state,
    starter_anchors = legacy_managed_lines,
    initial_managed_line_inventory_granted = true,
    utilization_metrics = {legacy = true}
  }

  run_migration()

  assert_equal(storage.planets.nauvis, legacy_state, "migration should preserve the existing state table")
  assert_equal(
    storage.planets.nauvis.starter_anchors,
    legacy_managed_lines,
    "migration should move legacy Managed Lines into Nauvis state"
  )
  assert_equal(storage.bootstrap, nil, "migration should remove the legacy state alias")
  assert_equal(storage.starter_anchors, nil, "migration should remove the legacy Managed Line alias")
  assert_equal(
    storage.planets.nauvis.initial_managed_line_inventory_granted,
    true,
    "migration should preserve the initial inventory grant"
  )
  assert_equal(
    storage.initial_managed_line_inventory_granted,
    nil,
    "migration should remove the legacy inventory grant flag"
  )
  assert_equal(storage.utilization_metrics, nil, "migration should remove obsolete utilization state")
end)

run_test("0.1.5 migration merges existing planet state into the legacy Nauvis state", function()
  local legacy_state = {
    square_size = 9,
    surface_name = "nauvis"
  }
  storage = {
    bootstrap = legacy_state,
    planets = {
      nauvis = {
        square_size = 11,
        square_position = {x = 2, y = -1}
      },
      vulcanus = {
        square_size = 17,
        surface_name = "vulcanus"
      }
    }
  }

  run_migration()

  assert_equal(storage.planets.nauvis, legacy_state, "legacy Nauvis state should remain authoritative")
  assert_equal(storage.planets.nauvis.square_size, 9, "existing legacy values should not be overwritten")
  assert_equal(storage.planets.nauvis.square_position.x, 2, "missing values should be merged from planet state")
  assert_equal(storage.planets.vulcanus.surface_name, "vulcanus", "other planet state should be preserved")
end)

run_test("0.1.5 migration preserves already canonical planet storage", function()
  local nauvis_state = {
    square_size = 9,
    surface_name = "nauvis"
  }
  storage = {
    planets = {
      nauvis = nauvis_state
    }
  }

  run_migration()

  assert_equal(storage.planets.nauvis, nauvis_state, "canonical state should be unchanged")
end)

run_test("0.1.5 migration removes obsolete player GUIs", function()
  local function add_gui_element(parent, name)
    local element = {
      valid = true,
      destroyed = false
    }

    element.destroy = function()
      element.valid = false
      element.destroyed = true
      parent[name] = nil
    end
    parent[name] = element

    return element
  end

  local top = {}
  local left = {}
  local obsolete_elements = {
    add_gui_element(top, "fes_shop_button"),
    add_gui_element(top, "fes_screenshot_button"),
    add_gui_element(top, "fes_dev_expand_button"),
    add_gui_element(top, "the_square_shop_button"),
    add_gui_element(left, "fes_shop_frame"),
    add_gui_element(left, "fes_debug_frame"),
    add_gui_element(left, "the_square_shop_frame")
  }
  local current_button = add_gui_element(top, "the_square_screenshot_button")

  storage = {}
  game = {
    players = {
      {
        valid = true,
        gui = {
          top = top,
          left = left
        }
      }
    }
  }

  run_migration()

  for _, element in ipairs(obsolete_elements) do
    assert_equal(element.destroyed, true, "migration should destroy every obsolete GUI element")
  end

  assert_equal(current_button.destroyed, false, "migration should preserve current GUI elements")
end)
