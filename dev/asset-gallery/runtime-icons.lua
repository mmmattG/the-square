-- Read the same resource catalogue used by the Anchor configuration menu.
-- A data-only module: no Factorio process, save, or runtime mocks are needed.
local catalog = require("lib.planet_catalog")
for _, planet_name in ipairs(catalog.SUPPORTED_PLANETS) do
  local planet = catalog.get(planet_name)
  for _, resources in ipairs({planet.native_free_resources, planet.opt_in_egress_resources}) do
    for _, resource in ipairs(resources) do
      print(planet_name .. "\t" .. resource.kind .. "\t" .. resource.resource)
    end
  end
end
