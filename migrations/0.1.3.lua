local bootstrap_runtime = require("lib.bootstrap_runtime")
local defs = require("lib.runtime_defs")

local function clear_managed_anchor_refs()
  if storage.starter_anchors and storage.starter_anchors.anchors then
    for _, anchor in ipairs(storage.starter_anchors.anchors) do
      anchor.entity = nil
    end
  end
end

local function destroy_surface_entities(surface)
  for _, entity in ipairs(surface.find_entities()) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy({raise_destroy = false})
    end
  end
end

local function ensure_surface_dimensions(surface, surface_size)
  local map_gen_settings = surface.map_gen_settings

  if map_gen_settings.width ~= surface_size or map_gen_settings.height ~= surface_size then
    map_gen_settings.width = surface_size
    map_gen_settings.height = surface_size
    surface.map_gen_settings = map_gen_settings
  end
end

local function migrate_legacy_bootstrap_surface()
  local bootstrap = storage.bootstrap

  if not bootstrap or not (not bootstrap.surface_name or bootstrap.surface_name == defs.LEGACY_SURFACE_NAME) then
    return
  end

  local legacy_surface = game.surfaces[defs.LEGACY_SURFACE_NAME]
  local square_size = bootstrap.square_size or defs.get_square_size()
  local surface_size = bootstrap.surface_size or defs.get_surface_size(square_size)
  local target_surface = game.surfaces[defs.SURFACE_NAME]

  if not target_surface then
    target_surface = game.create_surface(defs.SURFACE_NAME, {
      width = surface_size,
      height = surface_size,
      starting_points = {{x = 0, y = 0}},
      peaceful_mode = true,
      no_enemies_mode = true
    })
  end

  target_surface.peaceful_mode = true
  target_surface.no_enemies_mode = true
  ensure_surface_dimensions(target_surface, surface_size)
  target_surface.destroy_decoratives({})
  target_surface.clear_hidden_tiles()
  destroy_surface_entities(target_surface)

  if legacy_surface then
    local managed_area = defs.get_square_bounds(surface_size)

    legacy_surface.clone_area({
      source_area = managed_area,
      destination_area = managed_area,
      destination_surface = target_surface,
      clone_tiles = true,
      clone_entities = true,
      clone_decoratives = true,
      clear_destination_entities = true,
      clear_destination_decoratives = true,
      expand_map = true
    })
  end

  bootstrap.surface_name = defs.SURFACE_NAME
  bootstrap.surface_size = surface_size
  clear_managed_anchor_refs()
  bootstrap_runtime.refresh_all_generated_chunk_tiles(target_surface, square_size, surface_size)
  bootstrap_runtime.clear_surface_chart(target_surface)

  for _, player in pairs(game.players) do
    if player.valid then
      player.teleport({x = 0, y = 0}, target_surface)
    end
  end

  if legacy_surface then
    game.delete_surface(legacy_surface)
  end
end

local function replace_legacy_prefix(value)
  if type(value) ~= "string" then
    return value
  end

  return (string.gsub(value, "^fes%-", "the-square-"))
end

local function migrate_anchor_namespace(anchor)
  if not anchor then
    return
  end

  anchor.item_name = replace_legacy_prefix(anchor.item_name)
  anchor.entity_name = replace_legacy_prefix(anchor.entity_name)
end

local function get_tier_level_from_anchor_entity_name(anchor)
  if not (anchor and anchor.entity_name and anchor.kind == "item") then
    return nil
  end

  for _, tier in ipairs(defs.MANAGED_LINE_ITEM_TIERS) do
    if tier.key ~= "yellow" and string.match(anchor.entity_name, "%-" .. tier.key .. "$") then
      return tier.tier_level
    end
  end

  return nil
end

local function get_fallback_anchor_tier_level(anchor)
  if not (anchor and anchor.kind == "item") then
    return 1
  end

  local bootstrap = storage.bootstrap or {}

  if anchor.flow == "egress" then
    return bootstrap.egress_tier or bootstrap.ingress_tier or 1
  end

  return bootstrap.ingress_tier or 1
end

local function migrate_anchor_to_generic(anchor)
  if not anchor then
    return
  end

  anchor.flow = anchor.flow or "ingress"
  anchor.kind = anchor.kind or "item"
  anchor.tier_level = anchor.tier_level
    or get_tier_level_from_anchor_entity_name(anchor)
    or get_fallback_anchor_tier_level(anchor)
  anchor.item_name = defs.get_generic_anchor_item_name_for_tier(anchor.kind, anchor.flow, anchor.tier_level)
  anchor.entity_name = anchor.position and anchor.resource
    and defs.get_anchor_entity_name_for_current_tier(anchor)
    or defs.get_generic_anchor_entity_name(anchor.kind, anchor.flow)
  anchor.entity = nil
end

local function migrate_anchor_set_to_generic(anchor_set)
  if not (anchor_set and anchor_set.anchors) then
    return
  end

  for _, anchor in ipairs(anchor_set.anchors) do
    migrate_anchor_to_generic(anchor)
  end
end

local function migrate_managed_anchor_namespace()
  if storage.starter_anchors and storage.starter_anchors.anchors then
    for _, anchor in ipairs(storage.starter_anchors.anchors) do
      migrate_anchor_namespace(anchor)
    end
  end

  if storage.starter_anchors and storage.starter_anchors.inventory then
    for _, anchor in pairs(storage.starter_anchors.inventory) do
      migrate_anchor_namespace(anchor)
    end
  end
end

migrate_legacy_bootstrap_surface()
migrate_managed_anchor_namespace()
migrate_anchor_set_to_generic(storage.starter_anchors)

if storage.planets then
  for _, planet_state in pairs(storage.planets) do
    migrate_anchor_set_to_generic(planet_state.starter_anchors)
  end
end
