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

local obsolete_top_gui_names = {
  "fes_shop_button",
  "fes_screenshot_button",
  "fes_dev_expand_button",
  "the_square_shop_button"
}

local obsolete_left_gui_names = {
  "fes_shop_frame",
  "fes_debug_frame",
  "the_square_shop_frame"
}

local function destroy_gui_element(parent, name)
  local element = parent and parent[name]

  if element and element.valid then
    element.destroy()
  end
end

for _, player in pairs(game.players) do
  if player.valid and player.gui then
    for _, name in ipairs(obsolete_top_gui_names) do
      destroy_gui_element(player.gui.top, name)
    end

    for _, name in ipairs(obsolete_left_gui_names) do
      destroy_gui_element(player.gui.left, name)
    end
  end
end
