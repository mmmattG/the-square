local gui_runtime = require("lib.gui_runtime")

for _, player in pairs(game.players) do
  gui_runtime.sync_screenshot_gui(player)
end
