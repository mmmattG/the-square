package.path = "./?.lua;./?/init.lua;" .. package.path

defines = {direction = {south = 1, west = 2, north = 3, east = 4}, inventory = {chest = 1}}
settings = {global = {}, startup = {}}
storage = {bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1}}
game = {forces = {player = {valid = true, mining_drill_productivity_bonus = 0}}}

local anchor_runtime = require("lib.anchor_runtime")
local ingress_runtime = require("lib.ingress_runtime")
local defs = require("lib.runtime_defs")

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

run_test("non-Nauvis planets receive configured starter anchors in isolated storage", function()
  local vulcanus = anchor_runtime.ensure_planet_starter_anchor_state("vulcanus")
  local gleba = anchor_runtime.ensure_planet_starter_anchor_state("gleba")

  assert_equal(#vulcanus.anchors, 5, "Vulcanus should get five free starter lines")
  assert_equal(#gleba.anchors, 6, "Gleba should get four ingresses and two egresses")
  assert_equal(storage.starter_anchors, nil, "planet starter creation should not mutate Nauvis anchors")
  assert_equal(storage.planets.vulcanus.starter_anchors, vulcanus, "Vulcanus anchors should live under Vulcanus state")
  assert_equal(storage.planets.gleba.starter_anchors, gleba, "Gleba anchors should live under Gleba state")
end)

run_test("planet starter pumping only uses planet-local anchors", function()
  storage.planets = {
    fulgora = {
      square_size = 17,
      surface_name = "fulgora",
      starter_anchors = {
        anchors = {
          {
            resource = "scrap",
            kind = "item",
            flow = "ingress",
            position = {x = 0, y = -9},
            entity = {
              valid = true,
              get_transport_line = function()
                return {
                  can_insert_at_back = function() return true end,
                  insert_at_back = function(stack)
                    storage.inserted = stack.name
                  end
                }
              end
            },
            item_progress = {0.875, 0}
          }
        }
      }
    },
    gleba = {
      square_size = 17,
      surface_name = "gleba",
      starter_anchors = {
        anchors = {
          {
            resource = "yumako-seed",
            kind = "item",
            flow = "egress",
            position = {x = 0, y = 9},
            entity = {
              valid = true,
              get_transport_line = function()
                return {
                  remove_item = function(stack)
                    storage.removed = stack.name
                    return stack.count
                  end
                }
              end
            },
            item_progress = {0.875, 0}
          }
        }
      }
    }
  }

  ingress_runtime.pump_planet_starter_anchors()
  assert_equal(storage.inserted, "scrap", "Fulgora ingress should emit scrap")
  assert_equal(storage.removed, "yumako-seed", "Gleba egress should drain seed items")
end)

run_test("Gleba fruit ingresses require matching seed egress", function()
  local counts = {inserted = {}, removed = {}}

  local function belt_entity(has_items)
    return {
      valid = true,
      get_transport_line = function()
        return {
          can_insert_at_back = function() return true end,
          insert_at_back = function(stack)
            counts.inserted[stack.name] = (counts.inserted[stack.name] or 0) + stack.count
          end,
          remove_item = function(stack)
            if not has_items[stack.name] then
              return 0
            end

            counts.removed[stack.name] = (counts.removed[stack.name] or 0) + stack.count
            return stack.count
          end
        }
      end
    }
  end

  local function run_case(has_items)
    counts = {inserted = {}, removed = {}}
    storage = {
      bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1},
      planets = {gleba = {square_size = 17, surface_name = "gleba", starter_anchors = {anchors = {
        {resource = "yumako", kind = "item", flow = "ingress", position = {x = 0, y = 9}, entity = belt_entity(has_items), item_progress = {0, 0}},
        {resource = "jellynut", kind = "item", flow = "ingress", position = {x = 9, y = 0}, entity = belt_entity(has_items), item_progress = {0, 0}},
        {resource = "yumako-seed", kind = "item", flow = "egress", position = {x = 0, y = 9}, entity = belt_entity(has_items), item_progress = {0, 0}},
        {resource = "jellynut-seed", kind = "item", flow = "egress", position = {x = 9, y = 0}, entity = belt_entity(has_items), item_progress = {0, 0}}
      }}}}
    }

    for _ = 1, defs.ITEM_ANCHOR_INTERVAL_TICKS do
      ingress_runtime.pump_planet_starter_anchors()
    end

    return counts
  end

  local no_seeds = run_case({})
  assert_equal(no_seeds.inserted.yumako, nil, "no yumako seeds should mean no yumako fruit")
  assert_equal(no_seeds.inserted.jellynut, nil, "no jellynut seeds should mean no jellynut fruit")

  local yumako_only = run_case({["yumako-seed"] = true})
  assert_equal(yumako_only.inserted.yumako, 1, "yumako seeds should feed yumako fruit")
  assert_equal(yumako_only.inserted.jellynut, nil, "yumako seeds should not feed jellynut fruit")

  local jellynut_only = run_case({["jellynut-seed"] = true})
  assert_equal(jellynut_only.inserted.yumako, nil, "jellynut seeds should not feed yumako fruit")
  assert_equal(jellynut_only.inserted.jellynut, 1, "jellynut seeds should feed jellynut fruit")

  local both = run_case({["yumako-seed"] = true, ["jellynut-seed"] = true})
  assert_equal(both.inserted.yumako, 1, "yumako fruit should emit when yumako seeds are drained")
  assert_equal(both.inserted.jellynut, 1, "jellynut fruit should emit when jellynut seeds are drained")
end)

run_test("one Gleba seed budgets fifty matching fruit", function()
  local counts = {inserted = {}, removed = {}}
  local seed_available = true

  local function belt_entity()
    return {
      valid = true,
      get_transport_line = function()
        return {
          can_insert_at_back = function() return true end,
          insert_at_back = function(stack)
            counts.inserted[stack.name] = (counts.inserted[stack.name] or 0) + stack.count
          end,
          remove_item = function(stack)
            if stack.name ~= "yumako-seed" or not seed_available then
              return 0
            end

            seed_available = false
            counts.removed[stack.name] = (counts.removed[stack.name] or 0) + stack.count
            return stack.count
          end
        }
      end
    }
  end

  storage = {
    bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1},
    planets = {gleba = {square_size = 17, surface_name = "gleba", starter_anchors = {anchors = {
      {resource = "yumako", kind = "item", flow = "ingress", position = {x = 0, y = 9}, entity = belt_entity(), item_progress = {0, 0}},
      {resource = "yumako-seed", kind = "item", flow = "egress", position = {x = 0, y = 9}, entity = belt_entity(), item_progress = {0, 0}}
    }}}}
  }

  for _ = 1, defs.ITEM_ANCHOR_INTERVAL_TICKS * 50 do
    ingress_runtime.pump_planet_starter_anchors()
  end

  assert_equal(counts.removed["yumako-seed"], 1, "only one yumako seed should be drained")
  assert_equal(counts.inserted.yumako, 50, "one yumako seed should budget fifty yumako fruit")
end)

run_test("Gleba fruit ingresses and seed egresses use normal anchor rates", function()
  local counts = {inserted = {}, removed = {}}

  local function belt_entity(kind)
    return {
      valid = true,
      get_transport_line = function()
        return {
          can_insert_at_back = function() return true end,
          insert_at_back = function(stack)
            counts.inserted[stack.name] = (counts.inserted[stack.name] or 0) + stack.count
          end,
          remove_item = function(stack)
            counts.removed[stack.name] = (counts.removed[stack.name] or 0) + stack.count
            return stack.count
          end
        }
      end
    }
  end

  storage = {
    bootstrap = {square_size = 7, surface_name = "nauvis", ingress_tier = 1},
    planets = {
      gleba = {
        square_size = 17,
        surface_name = "gleba",
        starter_anchors = {
          anchors = {
            {resource = "yumako", kind = "item", flow = "ingress", position = {x = 0, y = 9}, entity = belt_entity("ingress"), item_progress = {0, 0}},
            {resource = "jellynut", kind = "item", flow = "ingress", position = {x = 9, y = 0}, entity = belt_entity("ingress"), item_progress = {0, 0}},
            {resource = "yumako-seed", kind = "item", flow = "egress", position = {x = 0, y = 9}, entity = belt_entity("egress"), item_progress = {0, 0}},
            {resource = "jellynut-seed", kind = "item", flow = "egress", position = {x = 9, y = 0}, entity = belt_entity("egress"), item_progress = {0, 0}}
          }
        }
      },
      nauvis = {
        square_size = 7,
        surface_name = "nauvis",
        starter_anchors = {
          anchors = {
            {resource = "yumako-seed", kind = "item", flow = "egress", position = {x = 0, y = 9}, entity = belt_entity("egress"), item_progress = {0, 0}}
          }
        }
      }
    }
  }

  for _ = 1, defs.ITEM_ANCHOR_INTERVAL_TICKS do
    ingress_runtime.pump_planet_starter_anchors()
  end

  assert_equal(counts.removed["yumako-seed"], 1, "Yumako seed egress should drain at the normal yellow single-lane rate")
  assert_equal(counts.inserted.yumako, 1, "Yumako ingress should emit at the normal yellow single-lane rate")
  assert_equal(counts.removed["jellynut-seed"], 1, "Jellynut seed egress should drain at the normal yellow single-lane rate")
  assert_equal(counts.inserted.jellynut, 1, "Jellynut ingress should emit at the normal yellow single-lane rate")
end)

run_test("planet bootstrap research unlocks are planet-specific", function()
  local techs = {}
  for _, name in ipairs({"recycling", "heating-tower", "agriculture", "jellynut", "yumako", "calcite-processing", "tungsten-carbide", "lithium-processing"}) do
    techs[name] = {researched = false}
  end

  local force = {technologies = techs}
  anchor_runtime.unlock_planet_bootstrap_research("fulgora", force)
  assert_equal(techs.recycling.researched, true, "Fulgora should unlock recycling")
  assert_equal(techs.agriculture.researched, false, "Fulgora should not unlock Gleba research")

  anchor_runtime.unlock_planet_bootstrap_research("gleba", force)
  assert_equal(techs["heating-tower"].researched, true, "Gleba should unlock heating tower")
  assert_equal(techs.agriculture.researched, true, "Gleba should unlock agriculture")
  assert_equal(techs.jellynut.researched, true, "Gleba should unlock jellynut")
  assert_equal(techs.yumako.researched, true, "Gleba should unlock yumako")

  anchor_runtime.unlock_planet_bootstrap_research("vulcanus", force)
  assert_equal(techs["calcite-processing"].researched, true, "Vulcanus should unlock calcite processing")
  assert_equal(techs["tungsten-carbide"].researched, true, "Vulcanus should unlock tungsten carbide")

  anchor_runtime.unlock_planet_bootstrap_research("aquilo", force)
  assert_equal(techs["lithium-processing"].researched, true, "Aquilo should unlock lithium processing")
end)

run_test("entity presentation maps flow and kind to PRD visuals", function()
  assert_equal(defs.get_anchor_presentation("ingress", "item"), "underground-belt-inward")
  assert_equal(defs.get_anchor_presentation("egress", "item"), "underground-belt-outward")
  assert_equal(defs.get_anchor_presentation("ingress", "fluid"), "offshore-pump")
  assert_equal(defs.get_anchor_presentation("egress", "fluid"), "underground-pipe")
  assert_equal(defs.get_anchor_direction_for_side("egress", "item", "north"), defines.direction.north)
end)
