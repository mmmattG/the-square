storage.planets = storage.planets or {}

local legacy_nauvis_state = storage.bootstrap
local nauvis_state = legacy_nauvis_state or storage.planets.nauvis

if legacy_nauvis_state and storage.planets.nauvis and storage.planets.nauvis ~= legacy_nauvis_state then
  for key, value in pairs(storage.planets.nauvis) do
    if legacy_nauvis_state[key] == nil then
      legacy_nauvis_state[key] = value
    end
  end
end

if storage.starter_anchors then
  nauvis_state = nauvis_state or {}
  nauvis_state.starter_anchors = storage.starter_anchors
end

if nauvis_state then
  nauvis_state.initial_managed_line_inventory_granted =
    nauvis_state.initial_managed_line_inventory_granted or storage.initial_managed_line_inventory_granted
  storage.planets.nauvis = nauvis_state
end

storage.bootstrap = nil
storage.starter_anchors = nil
storage.initial_managed_line_inventory_granted = nil
storage.utilization_metrics = nil
