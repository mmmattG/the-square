local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")

local anchor_identity = {}

function anchor_identity.is_ingress_entity_name(entity_name)
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    for _, definition in ipairs(defs.get_input_definitions(planet_name)) do
      if defs.is_ingress_entity_name_for_resource(definition.resource, entity_name) then
        return true
      end
    end
  end

  return false
end

function anchor_identity.is_egress_entity_name(entity_name)
  for _, planet_name in ipairs(planet_config.SUPPORTED_PLANETS) do
    for _, definition in ipairs(defs.get_output_definitions(planet_name)) do
      if defs.is_egress_entity_name_for_resource(definition.resource, entity_name) then
        return true
      end
    end
  end

  return false
end

function anchor_identity.is_managed_entity_name(entity_name)
  return entity_name == defs.ANCHOR_SLOT_PROXY_NAME
    or anchor_identity.is_ingress_entity_name(entity_name)
    or anchor_identity.is_egress_entity_name(entity_name)
end

function anchor_identity.does_anchor_match_entity_name(anchor, entity_name)
  if not anchor then
    return false
  end

  if anchor.flow == "egress" then
    return defs.is_egress_entity_name_for_resource(anchor.resource, entity_name)
  end

  return defs.is_ingress_entity_name_for_resource(anchor.resource, entity_name)
end

return anchor_identity
