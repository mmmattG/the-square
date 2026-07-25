local anchor_placement = require("lib.anchor_placement")
local anchor_identity = require("lib.anchor_identity")
local defs = require("lib.runtime_defs")

local biter_managed_line_migration = {}

biter_managed_line_migration.VERSION = 1

local function is_obsolete_biter_line(anchor)
  return anchor
    and (
      (anchor.flow == "ingress" and anchor.resource == "biter-egg")
      or (anchor.flow == "egress" and anchor.resource == "bioflux")
    )
end

local function destroy_anchor_entity(anchor, surface)
  if anchor.entity and anchor.entity.valid and anchor.entity.destroy then
    anchor.entity.destroy({raise_destroy = false})
    return
  end

  if not (surface and surface.find_entities_filtered and anchor.position) then
    return
  end

  for _, entity in ipairs(surface.find_entities_filtered({position = anchor.position})) do
    if entity.valid and anchor_identity.is_managed_entity_name(entity.name) and entity.destroy then
      entity.destroy({raise_destroy = false})
    end
  end
end

function biter_managed_line_migration.migrate_anchor_set(anchor_set, surface)
  local refund_item_names = {}

  if not (anchor_set and anchor_set.anchors) then
    return refund_item_names
  end

  anchor_set.biter_egg_budget = nil

  for _, anchor in ipairs(anchor_set.anchors) do
    if is_obsolete_biter_line(anchor) then
      local was_placed = anchor.position ~= nil

      destroy_anchor_entity(anchor, surface)
      anchor.kind = anchor.kind or "item"
      anchor.flow = anchor.flow or "ingress"
      anchor.tier_level = anchor.tier_level or 1
      anchor_placement.stash(anchor)

      if was_placed then
        refund_item_names[#refund_item_names + 1] =
          defs.get_generic_anchor_item_name_for_tier(anchor.kind, anchor.flow, anchor.tier_level)
      end
    end
  end

  return refund_item_names
end

local function refund_item(item_name)
  for _, player in pairs(game.players or {}) do
    if player.valid and player.insert and player.insert({name = item_name, count = 1}) == 1 then
      return
    end
  end

  local surface = game.surfaces and game.surfaces[defs.SURFACE_NAME]
  if surface and surface.spill_item_stack then
    surface.spill_item_stack({x = 0, y = 0}, {name = item_name, count = 1}, true, nil, false)
  end
end

function biter_managed_line_migration.migrate_storage()
  if storage.biter_managed_line_migration_version == biter_managed_line_migration.VERSION then
    return 0
  end

  local nauvis = storage.planets and storage.planets.nauvis or storage.bootstrap
  local anchor_set = nauvis and nauvis.starter_anchors or storage.starter_anchors
  local surface = game.surfaces and game.surfaces[defs.SURFACE_NAME]
  local refund_item_names = biter_managed_line_migration.migrate_anchor_set(anchor_set, surface)

  if nauvis then
    nauvis.biter_egg_handling_granted_from_ingress = nil
  end

  for _, item_name in ipairs(refund_item_names) do
    refund_item(item_name)
  end

  storage.biter_managed_line_migration_version = biter_managed_line_migration.VERSION
  return #refund_item_names
end

return biter_managed_line_migration
