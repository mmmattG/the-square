local planet_catalog = require("lib.planet_catalog")

-- One starting size per Planet, in catalog order.
for index, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
	data:extend({
		{
			type = "int-setting",
			name = "the-square-" .. planet_name .. "-starting-square-size",
			setting_type = "startup",
			default_value = planet_catalog.get(planet_name).default_square_size,
			minimum_value = 4,
			maximum_value = 255,
			order = "a-" .. string.char(string.byte("a") + index - 1),
		},
	})
end

data:extend({
	{
		type = "int-setting",
		name = "the-square-expansion-tiles-per-research",
		setting_type = "startup",
		default_value = 7,
		minimum_value = 1,
		maximum_value = 1000,
		order = "b",
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
			"checkerboard",
		},
		order = "e",
	},
	{
		type = "int-setting",
		name = "the-square-screenshot-pixels-per-tile",
		setting_type = "runtime-global",
		default_value = 32,
		minimum_value = 8,
		maximum_value = 256,
		order = "f",
	},
	{
		type = "bool-setting",
		name = "the-square-screenshot-alt-mode",
		setting_type = "runtime-global",
		default_value = true,
		order = "g",
	},
	{
		type = "bool-setting",
		name = "the-square-dev-mode",
		setting_type = "runtime-per-user",
		default_value = false,
		order = "h",
	},
	{
		type = "bool-setting",
		name = "the-square-cliff-explosive-button",
		setting_type = "runtime-per-user",
		default_value = false,
		order = "j",
	},
})
