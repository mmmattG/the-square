-- Tips and tricks pages that explain the rules of The Square.
local CATEGORY = "the-square-rules"

local pages = {
  {name = "the-square-mod", icon = "__base__/graphics/icons/landfill.png", is_title = true},
  {name = "the-square-overview", icon = "__base__/graphics/icons/info.png"},
  {name = "the-square-expansion-research", icon = "__base__/graphics/icons/landfill.png"},
  {name = "the-square-ingress-lines", icon = "__base__/graphics/icons/transport-belt.png"},
  {name = "the-square-uranium-egress", icon = "__base__/graphics/icons/fluid/sulfuric-acid.png"},
  {name = "the-square-research-and-rewards", icon = "__base__/graphics/icons/utility-science-pack.png"},
  {name = "the-square-anchor-upgrades", icon = "__base__/graphics/icons/fast-transport-belt.png"}
}

local prototypes = {
  {
    type = "tips-and-tricks-item-category",
    name = CATEGORY,
    order = "o[the-square]"
  }
}

for index, page in ipairs(pages) do
  prototypes[#prototypes + 1] = {
    type = "tips-and-tricks-item",
    name = page.name,
    -- Keep the pages in list order, with the title first.
    order = string.char(string.byte("a") + index - 1),
    category = CATEGORY,
    starting_status = "unlocked",
    indent = not page.is_title and 1 or nil,
    is_title = page.is_title,
    localised_name = {"tips-and-tricks-item-name." .. page.name},
    localised_description = {"tips-and-tricks-item-description." .. page.name},
    icon = page.icon,
    icon_size = 64
  }
end

data:extend(prototypes)
