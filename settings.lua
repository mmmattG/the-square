data:extend({
  {
    type = "int-setting",
    name = "the-square-starting-square-size",
    setting_type = "runtime-global",
    default_value = 7,
    minimum_value = 4,
    maximum_value = 255,
    order = "a"
  },
  {
    type = "int-setting",
    name = "the-square-nauvis-starting-square-size",
    setting_type = "startup",
    default_value = 7,
    minimum_value = 4,
    maximum_value = 255,
    order = "a-a"
  },
  {
    type = "int-setting",
    name = "the-square-vulcanus-starting-square-size",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 4,
    maximum_value = 255,
    order = "a-b"
  },
  {
    type = "int-setting",
    name = "the-square-fulgora-starting-square-size",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 4,
    maximum_value = 255,
    order = "a-c"
  },
  {
    type = "int-setting",
    name = "the-square-gleba-starting-square-size",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 4,
    maximum_value = 255,
    order = "a-d"
  },
  {
    type = "int-setting",
    name = "the-square-aquilo-starting-square-size",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 4,
    maximum_value = 255,
    order = "a-e"
  },
  {
    type = "int-setting",
    name = "the-square-expansion-tiles-per-research",
    setting_type = "startup",
    default_value = 7,
    minimum_value = 1,
    maximum_value = 1000,
    order = "b"
  },
  {
    type = "int-setting",
    name = "the-square-line-purchase-cost",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 1,
    maximum_value = 1000000,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "the-square-enable-logistic-network-automation",
    setting_type = "runtime-global",
    default_value = false,
    order = "d"
  },
  {
    type = "string-setting",
    name = "the-square-background-tile",
    setting_type = "runtime-global",
    default_value = "grass-1",
    allowed_values = {
      "grass-1",
      "grass-2",
      "grass-3",
      "grass-4",
      "dirt-1",
      "dirt-2",
      "dirt-3",
      "dirt-4",
      "dirt-5",
      "dirt-6",
      "dirt-7",
      "dry-dirt",
      "sand-1",
      "sand-2",
      "sand-3",
      "red-desert-0",
      "red-desert-1",
      "red-desert-2",
      "red-desert-3",
      "landfill",
      "lab-dark-1",
      "lab-dark-2",
      "lab-white",
      "nuclear-ground",
      "checkerboard"
    },
    order = "e"
  },
  {
    type = "int-setting",
    name = "the-square-screenshot-pixels-per-tile",
    setting_type = "runtime-global",
    default_value = 32,
    minimum_value = 8,
    maximum_value = 256,
    order = "f"
  },
  {
    type = "bool-setting",
    name = "the-square-screenshot-alt-mode",
    setting_type = "runtime-global",
    default_value = true,
    order = "g"
  },
  {
    type = "bool-setting",
    name = "the-square-dev-mode",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "h"
  },
  {
    type = "bool-setting",
    name = "the-square-ingress-placement-debug",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "i"
  },
  {
    type = "bool-setting",
    name = "the-square-cliff-explosive-button",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "j"
  }
})
