local defs = require("lib.runtime_defs")

if storage.bootstrap and (not storage.bootstrap.surface_name or storage.bootstrap.surface_name == defs.LEGACY_SURFACE_NAME) then
  storage.bootstrap.surface_name = defs.SURFACE_NAME

  if storage.starter_anchors and storage.starter_anchors.anchors then
    for _, anchor in ipairs(storage.starter_anchors.anchors) do
      anchor.entity = nil
    end
  end
end
