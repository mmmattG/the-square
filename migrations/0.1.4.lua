-- Self-contained on purpose: migrations must not depend on lib/ modules that later
-- versions are free to change.
local function is_managed_anchor_entity_name(entity_name)
  return string.find(entity_name, "^the%-square%-") ~= nil and string.find(entity_name, "%-anchor") ~= nil
end

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
    if entity.valid and is_managed_anchor_entity_name(entity.name) and entity.destroy then
      entity.destroy({raise_destroy = false})
    end
  end
end

local nauvis = storage.planets and storage.planets.nauvis or storage.bootstrap
local anchor_set = nauvis and nauvis.starter_anchors or storage.starter_anchors
local surface = game.surfaces.nauvis

if anchor_set and anchor_set.anchors then
  anchor_set.biter_egg_budget = nil

  for index = #anchor_set.anchors, 1, -1 do
    local anchor = anchor_set.anchors[index]

    if is_obsolete_biter_line(anchor) then
      destroy_anchor_entity(anchor, surface)
      table.remove(anchor_set.anchors, index)
    end
  end
end

if nauvis then
  nauvis.biter_egg_handling_granted_from_ingress = nil
end
