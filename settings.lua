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
    setting_type = "runtime-global",
    default_value = 7,
    minimum_value = 1,
    maximum_value = 1000,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "fes-enable-logistic-network-automation",
    setting_type = "runtime-global",
    default_value = false,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "fes-dev-mode",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "d"
  },
  {
    type = "bool-setting",
    name = "fes-ingress-placement-debug",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "e"
  }
})
