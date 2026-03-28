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
    type = "bool-setting",
    name = "fes-dev-mode",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "b"
  }
})
