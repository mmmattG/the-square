local defs = require("lib.runtime_defs")

local growth_runtime = {}

local function build_empty_category_breakdown()
  local categories = {}

  for _, key in ipairs(defs.COUNTED_CATEGORY_ORDER) do
    categories[key] = {
      key = key,
      label = defs.COUNTED_CATEGORY_LABELS[key],
      entity_count = 0,
      footprint_tiles = 0
    }
  end

  return categories
end

local function get_entity_footprint_tiles(entity)
  return entity.tile_width * entity.tile_height
end

local function is_active_crafting_machine(entity)
  return entity.status == defines.entity_status.working and entity.is_crafting()
end

local function is_active_lab(entity)
  return entity.status == defines.entity_status.working
end

local function is_active_rocket_silo(entity)
  return entity.status == defines.entity_status.working
    or entity.status == defines.entity_status.preparing_rocket_for_launch
    or entity.status == defines.entity_status.launching_rocket
end

local function is_active_power_entity(entity)
  return entity.status == defines.entity_status.working
end

local function evaluate_counted_entity_category(entity)
  if entity.type == "assembling-machine" or entity.type == "furnace" then
    if is_active_crafting_machine(entity) then
      return "crafting"
    end

    return nil
  end

  if entity.type == "lab" then
    if is_active_lab(entity) then
      return "lab"
    end

    return nil
  end

  if entity.type == "rocket-silo" then
    if is_active_rocket_silo(entity) then
      return "rocket-silo"
    end

    return nil
  end

  if entity.type == "generator"
    or entity.type == "boiler"
    or entity.type == "reactor"
    or entity.type == "solar-panel"
    or entity.type == "burner-generator"
    or entity.type == "fusion-generator"
  then
    if is_active_power_entity(entity) then
      return "power"
    end

    return nil
  end

  return nil
end

local function record_breakdown_entry(storage_table, key, label, footprint_tiles)
  local entry = storage_table[key]

  if not entry then
    entry = {
      key = key,
      label = label,
      entity_count = 0,
      footprint_tiles = 0
    }
    storage_table[key] = entry
  end

  entry.entity_count = entry.entity_count + 1
  entry.footprint_tiles = entry.footprint_tiles + footprint_tiles
end

local function add_entity_to_breakdown(metrics, category_key, entity)
  local footprint_tiles = get_entity_footprint_tiles(entity)

  metrics.active_footprint_tiles = metrics.active_footprint_tiles + footprint_tiles
  metrics.active_entity_count = metrics.active_entity_count + 1
  metrics.categories[category_key].entity_count = metrics.categories[category_key].entity_count + 1
  metrics.categories[category_key].footprint_tiles = metrics.categories[category_key].footprint_tiles + footprint_tiles

  record_breakdown_entry(metrics.entity_types, entity.name, entity.name, footprint_tiles)
end

local function collect_active_beacons_from_machine(entity, active_beacons)
  local success, beacons = pcall(entity.get_beacons, entity)

  if not success or not beacons then
    return
  end

  for _, beacon in ipairs(beacons) do
    if beacon.valid and beacon.unit_number then
      active_beacons[beacon.unit_number] = beacon
    end
  end
end

local function compute_growth_rate_per_second(square_size, utilization_ratio)
  return utilization_ratio * (square_size / defs.GROWTH_RATE_SIZE_DIVISOR)
end

function growth_runtime.get_completed_expansion_speed_research_levels()
  if not storage.bootstrap then
    return 0
  end

  return storage.bootstrap.expansion_speed_research_levels or 0
end

function growth_runtime.get_expansion_speed_multiplier()
  local levels = growth_runtime.get_completed_expansion_speed_research_levels()

  return math.pow(1 + defs.EXPANSION_SPEED_RESEARCH_PER_LEVEL_MULTIPLIER, levels), levels
end

local function sort_breakdown_entries(entries_by_key)
  local entries = {}

  for _, entry in pairs(entries_by_key) do
    entries[#entries + 1] = entry
  end

  table.sort(entries, function(left, right)
    if left.footprint_tiles == right.footprint_tiles then
      if left.entity_count == right.entity_count then
        return left.key < right.key
      end

      return left.entity_count > right.entity_count
    end

    return left.footprint_tiles > right.footprint_tiles
  end)

  return entries
end

function growth_runtime.evaluate_utilization(surface, square_size)
  local square_bounds = defs.get_square_bounds(square_size)
  local total_tiles = defs.get_square_area(square_size)
  local expansion_speed_multiplier, expansion_speed_research_levels = growth_runtime.get_expansion_speed_multiplier()
  local metrics = {
    tick = game.tick,
    square_size = square_size,
    total_tiles = total_tiles,
    active_footprint_tiles = 0,
    active_entity_count = 0,
    utilization_ratio = 0,
    base_growth_rate_per_second = 0,
    growth_rate_per_second = 0,
    growth_rate_per_minute = 0,
    expansion_speed_multiplier = expansion_speed_multiplier,
    expansion_speed_research_levels = expansion_speed_research_levels,
    categories = build_empty_category_breakdown(),
    entity_types = {}
  }
  local active_beacons = {}

  for _, entity in ipairs(surface.find_entities_filtered({area = square_bounds})) do
    if entity.valid then
      local category_key = evaluate_counted_entity_category(entity)

      if category_key then
        add_entity_to_breakdown(metrics, category_key, entity)

        if category_key ~= "power" then
          collect_active_beacons_from_machine(entity, active_beacons)
        end
      end
    end
  end

  for _, beacon in pairs(active_beacons) do
    add_entity_to_breakdown(metrics, "beacon", beacon)
  end

  if total_tiles > 0 then
    metrics.utilization_ratio = metrics.active_footprint_tiles / total_tiles
  end

  metrics.base_growth_rate_per_second = compute_growth_rate_per_second(square_size, metrics.utilization_ratio)
  metrics.growth_rate_per_second = metrics.base_growth_rate_per_second * expansion_speed_multiplier
  metrics.growth_rate_per_minute = metrics.growth_rate_per_second * 60
  metrics.sorted_entity_types = sort_breakdown_entries(metrics.entity_types)

  return metrics
end

function growth_runtime.update_utilization_metrics(gui_runtime)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return nil
  end

  local surface = game.surfaces[bootstrap.surface_name]

  if not surface then
    return nil
  end

  local metrics = growth_runtime.evaluate_utilization(surface, bootstrap.square_size)

  storage.utilization_metrics = metrics

  if gui_runtime then
    gui_runtime.refresh_all_status_guis()
  end

  return metrics
end

function growth_runtime.announce_expansion_speed_research(force)
  local multiplier, levels = growth_runtime.get_expansion_speed_multiplier()

  force.print({
    "message.fes-expansion-speed-updated",
    levels,
    defs.format_decimal(multiplier)
  })
end

function growth_runtime.advance_growth_from_utilization(bootstrap_runtime, gui_runtime, anchor_runtime)
  local bootstrap = storage.bootstrap

  if not bootstrap then
    return
  end

  bootstrap_runtime.ensure_bootstrap_state_defaults()

  local metrics = growth_runtime.update_utilization_metrics(gui_runtime)

  if not metrics then
    return
  end

  local interval_seconds = defs.UTILIZATION_UPDATE_INTERVAL_TICKS / 60
  local progress_gain = metrics.growth_rate_per_second * interval_seconds

  if progress_gain > 0 then
    bootstrap_runtime.add_growth_progress(progress_gain)
  end

  local player = game.players[1]

  while (bootstrap.growth_progress or 0) >= defs.get_next_expansion_tile_reward(bootstrap.square_size) do
    bootstrap.growth_progress = bootstrap.growth_progress - defs.get_next_expansion_tile_reward(bootstrap.square_size)
    bootstrap_runtime.expand_square(player, gui_runtime, growth_runtime, anchor_runtime)
    metrics = growth_runtime.update_utilization_metrics(gui_runtime) or metrics
  end

  if gui_runtime then
    gui_runtime.refresh_all_debug_guis()
  end
end

return growth_runtime
