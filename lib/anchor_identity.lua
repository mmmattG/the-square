local defs = require("lib.runtime_defs")
local planet_config = require("lib.planet_config")

local anchor_identity = {}

function anchor_identity.get_generic_kind_flow(entity_name)
  for key, generic_entity_name in pairs(defs.GENERIC_ANCHOR_ENTITIES) do
    if entity_name == generic_entity_name then
      local kind, flow = string.match(key, "^(%w+)_(%w+)$")
      return kind, flow
    end
  end

  return nil, nil
end

function anchor_identity.get_config_proxy_entity_name(kind, flow)
  return "the-square-anchor-config-proxy-" .. (kind or "item") .. "-" .. (flow or "ingress")
end

function anchor_identity.get_config_proxy_kind_flow(entity_name)
  if type(entity_name) ~= "string" then
    return nil, nil
  end

  return string.match(entity_name, "^the%-square%-anchor%-config%-proxy%-(%w+)%-(%w+)$")
end

function anchor_identity.is_config_proxy_entity_name(entity_name)
  return anchor_identity.get_config_proxy_kind_flow(entity_name) ~= nil
end

function anchor_identity.is_generic_entity_name(entity_name)
  return anchor_identity.get_generic_kind_flow(entity_name) ~= nil
end

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
    or anchor_identity.is_config_proxy_entity_name(entity_name)
    or anchor_identity.is_generic_entity_name(entity_name)
    or anchor_identity.is_ingress_entity_name(entity_name)
    or anchor_identity.is_egress_entity_name(entity_name)
end

function anchor_identity.does_anchor_match_entity_name(anchor, entity_name)
  if not anchor then
    return false
  end

  local proxy_kind, proxy_flow = anchor_identity.get_config_proxy_kind_flow(entity_name)
  if proxy_kind and proxy_flow then
    return proxy_kind == anchor.kind and proxy_flow == anchor.flow
  end

  if entity_name == defs.get_generic_anchor_entity_name(anchor.kind, anchor.flow) then
    return true
  end

  if anchor.flow == "egress" then
    return defs.is_egress_entity_name_for_resource(anchor.resource, entity_name)
  end

  return defs.is_ingress_entity_name_for_resource(anchor.resource, entity_name)
end

return anchor_identity
