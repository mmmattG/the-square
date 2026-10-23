package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local STARTING_SIZES = {nauvis = 7, vulcanus = 17, gleba = 21}

settings = {startup = {}}

for planet_name, size in pairs(STARTING_SIZES) do
  settings.startup["the-square-" .. planet_name .. "-starting-square-size"] = {value = size}
end

local function migrate(planets)
  storage = {planets = planets}
  dofile("migrations/0.2.0-state.lua")
  return storage.planets
end

-- A 0.1.5 Nauvis with a moved, expanded Square, configured and stashed lines,
-- an empty Anchor and part-spent uranium budgets.
local function build_0_1_5_nauvis()
  return {
    name = "nauvis",
    surface_name = "nauvis",
    square_size = 11,
    surface_size = 13,
    square_position = {x = 2, y = -1},
    expansion_research_levels = 2,
    expansions_completed = 2,
    ingress_tier = 3,
    egress_tier = 3,
    uranium_sulfuric_acid_buffer = 123.5,
    uranium_ore_progress_carry = 0.25,
    managed_lines_initialized = true,
    initial_managed_line_inventory_granted = true,
    starter_anchors = {
      layout_version = 12,
      anchors = {
        {kind = "item", flow = "ingress", resource = "iron-ore", tier_level = 4, side = "north", position = {x = 2, y = -8}, item_progress = {0.5, 0.25}},
        {kind = "item", flow = "ingress", resource = "uranium-ore", side = "south", position = {x = 3, y = 6}, item_progress = {0, 0}, input_budget_active = true},
        {kind = "item", flow = "egress", resource = "stone", side = "east", position = {x = 9, y = 0}, item_progress = {0, 0}},
        {kind = "fluid", flow = "ingress", resource = "water", side = "west", position = {x = -5, y = 0}, item_progress = {0, 0}},
        {kind = "item", flow = "ingress", tier_level = 1, item_progress = {0, 0}},
        {side = "north", position = {x = 0, y = -8}, item_progress = {0, 0}}
      }
    }
  }
end

run_test("Nauvis keeps its Square, progression, budgets and every line", function()
  local nauvis = migrate({nauvis = build_0_1_5_nauvis()}).nauvis
  local anchors = nauvis.managed_lines.anchors

  assert_equal(nauvis.square_size, 11, "square size kept")
  assert_equal(nauvis.square_position.x, 2, "square position kept")
  assert_equal(nauvis.expansion_research_levels, 2, "expansion levels kept")
  assert_equal(nauvis.uranium_sulfuric_acid_buffer, 123.5, "acid budget kept")
  assert_equal(nauvis.uranium_ore_progress_carry, 0.25, "ore carry kept")
  assert_equal(nauvis.managed_lines_initialized, true, "setup flags kept")
  assert_equal(#anchors, 6, "every line kept")
  assert_equal(anchors[1].tier_level, 4, "explicit tiers kept")
  assert_equal(anchors[1].item_progress[1], 0.5, "lane progress kept")
  assert_equal(anchors[6].kind, nil, "empty Anchors stay empty")
  assert_equal(anchors[6].tier_level, nil, "empty Anchors get no tier")
  assert_equal(anchors[5].tier_level, 1, "stashed lines keep their tier")
end)

run_test("placed lines without a tier take the tier their Anchor entity showed", function()
  local anchors = migrate({nauvis = build_0_1_5_nauvis()}).nauvis.managed_lines.anchors

  assert_equal(anchors[2].tier_level, 3, "item ingress takes the cached ingress tier")
  assert_equal(anchors[3].tier_level, 3, "item egress takes the cached egress tier")
  assert_equal(anchors[4].tier_level, 1, "fluid lines are always tier 1")
  assert_equal(anchors[2].input_budget_active, nil, "the unused budget flag is dropped")
end)

run_test("derived and unused fields are dropped, and starter_anchors becomes managed_lines", function()
  local nauvis = migrate({nauvis = build_0_1_5_nauvis()}).nauvis

  for _, field in ipairs({"name", "surface_name", "surface_size", "ingress_tier", "egress_tier", "expansions_completed", "starter_anchors"}) do
    assert_equal(nauvis[field], nil, field .. " dropped")
  end

  assert_equal(nauvis.managed_lines.layout_version, nil, "layout version dropped")
end)

run_test("other Planets lose the old Nauvis-sized default but keep real sizes", function()
  local planets = migrate({
    nauvis = build_0_1_5_nauvis(),
    vulcanus = {square_size = 7, expansion_research_levels = 0, expansions_completed = 0},
    gleba = {square_size = 7, expansion_research_levels = 3}
  })

  assert_equal(planets.vulcanus.square_size, 17, "an unexpanded Nauvis-sized Vulcanus gets its own starting size")
  assert_equal(planets.gleba.square_size, 7, "an expanded Planet keeps its size")
  assert_equal(planets.vulcanus.square_position.x, 0, "missing positions default to the centre")
end)

run_test("running the migration twice changes nothing", function()
  local once = migrate({nauvis = build_0_1_5_nauvis()})
  local twice = migrate(once)

  assert_equal(twice.nauvis.square_size, 11, "size unchanged")
  assert_equal(twice.nauvis.managed_lines.anchors[2].tier_level, 3, "tiers unchanged")
  assert_equal(#twice.nauvis.managed_lines.anchors, 6, "lines unchanged")
end)

run_test("a save that never had the mod is left alone", function()
  storage = {}
  dofile("migrations/0.2.0-state.lua")
  assert_equal(storage.planets, nil, "no planets created")
end)
