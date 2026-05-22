local defs = require("lib.runtime_defs")

local planet_instance = {}
local nauvis_methods = {}
nauvis_methods.__index = nauvis_methods

local function get_target_surface_size(square_size)
  return defs.get_surface_size(square_size)
end

local function clear_managed_line_entity_refs()
  if not (storage and storage.starter_anchors and storage.starter_anchors.anchors) then
    return
  end

  for _, anchor in ipairs(storage.starter_anchors.anchors) do
    anchor.entity = nil
  end
end

local function ensure_bootstrap_defaults(bootstrap)
  bootstrap.square_size = bootstrap.square_size or defs.get_square_size()
  local target_surface_size = get_target_surface_size(bootstrap.square_size)

  if not bootstrap.surface_name or bootstrap.surface_name == defs.LEGACY_SURFACE_NAME then
    bootstrap.surface_name = defs.SURFACE_NAME
    clear_managed_line_entity_refs()
  end
  bootstrap.surface_size = target_surface_size
  bootstrap.expansion_points = bootstrap.expansion_points or 0
  bootstrap.expansions_completed = bootstrap.expansions_completed or 0
  bootstrap.ingress_tier = bootstrap.ingress_tier or 1
  bootstrap.expansion_research_levels = bootstrap.expansion_research_levels or 0
  bootstrap.uranium_ore_progress_carry = bootstrap.uranium_ore_progress_carry or 0
  bootstrap.growth_progress = nil
  bootstrap.expansion_speed_research_levels = nil

  return bootstrap
end

local function wrap_bootstrap(bootstrap)
  return setmetatable({bootstrap = bootstrap}, nauvis_methods)
end

function planet_instance.ensure_nauvis()
  if not storage.bootstrap then
    return nil
  end

  return wrap_bootstrap(ensure_bootstrap_defaults(storage.bootstrap))
end

function planet_instance.from_bootstrap(bootstrap)
  if not bootstrap then
    return nil
  end

  return wrap_bootstrap(ensure_bootstrap_defaults(bootstrap))
end

function nauvis_methods:get_square_size()
  return self.bootstrap.square_size
end

function nauvis_methods:set_square_size(square_size)
  self.bootstrap.square_size = square_size
  self.bootstrap.surface_size = get_target_surface_size(square_size)
end

function nauvis_methods:get_surface_name()
  return self.bootstrap.surface_name
end

function nauvis_methods:set_surface_name(surface_name)
  self.bootstrap.surface_name = surface_name
end

function nauvis_methods:get_surface_size()
  return self.bootstrap.surface_size
end

function nauvis_methods:get_expansion_points()
  return self.bootstrap.expansion_points or 0
end

function nauvis_methods:add_expansion_points(amount)
  self.bootstrap.expansion_points = self:get_expansion_points() + amount
end

function nauvis_methods:get_completed_square_expansion_levels()
  return self.bootstrap.expansion_research_levels or 0
end

function nauvis_methods:set_completed_square_expansion_levels(levels)
  self.bootstrap.expansion_research_levels = levels
end

function nauvis_methods:get_managed_lines()
  return storage.starter_anchors
end

function nauvis_methods:get_bootstrap_storage()
  return self.bootstrap
end

return planet_instance
