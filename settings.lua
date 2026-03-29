data:extend({
  {
    type = "int-setting",
    name = "fes-starting-square-size",
    setting_type = "runtime-global",
    default_value = 7,
    minimum_value = 4,
    maximum_value = 255,
    order = "a"
  },
  {
    type = "int-setting",
    name = "fes-expansion-tiles-per-research",
    setting_type = "startup",
    default_value = 7,
    minimum_value = 1,
    maximum_value = 1000,
    order = "b"
  },
  {
    type = "int-setting",
    name = "fes-line-purchase-cost",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 1,
    maximum_value = 1000000,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "fes-enable-logistic-network-automation",
    setting_type = "runtime-global",
    default_value = false,
    order = "d"
  },
  {
    type = "string-setting",
    name = "fes-background-tile",
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
    type = "bool-setting",
    name = "fes-dev-mode",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "f"
  },
  {
    type = "bool-setting",
    name = "fes-ingress-placement-debug",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "g"
  }
})
