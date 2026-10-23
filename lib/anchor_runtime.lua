-- The entities on a Planet's Boundary: Anchor entities for placed Managed Lines,
-- invisible slot markers on empty Anchors, and the belts or pipes left behind when
-- a line moves. Also keeps players from building anything else on the Boundary.
local definitions = require("lib.managed_line_definitions")
local managed_line_state = require("lib.managed_line_state")
local planet_catalog = require("lib.planet_catalog")
local planet_state = require("lib.planet_state")
local square_layout = require("lib.square_layout")

local anchor_runtime = {}

local function find_entity_at(surface, entity_name, position)
  return surface.find_entities_filtered({name = entity_name, position = position})[1]
end

local function get_tile_center(position)
  return {x = position.x + 0.5, y = position.y + 0.5}
end

local function configure_anchor_entity(entity, anchor)
  if anchor.direction and entity.direction ~= anchor.direction then
    entity.direction = anchor.direction
  end

  entity.destructible = false
  entity.operable = true
end

-- Item ingress Anchors are the output end of an underground belt, so items surface
-- inside the Square. Every other Anchor uses the prototype's default.
local function get_underground_belt_type(anchor)
  if anchor.flow == "ingress" and anchor.kind == "item" then
    return "output"
  end

  return nil
end

local function is_correct_anchor_entity(entity, anchor)
  if not (entity and entity.valid and entity.name == anchor.entity_name) then
    return false
  end

  local belt_type = get_underground_belt_type(anchor)

  return belt_type == nil or entity.belt_to_ground_type == belt_type
end

-- Removes anything else of the player's on the Anchor tile.
local function clear_anchor_tile(surface, anchor)
  for _, position in ipairs({anchor.position, get_tile_center(anchor.position)}) do
    for _, entity in ipairs(surface.find_entities_filtered({position = position, force = "player"})) do
      if entity.valid and entity.name ~= anchor.entity_name then
        entity.destroy({raise_destroy = false})
      end
    end
  end
end

-- Makes sure a placed line has exactly the right Anchor entity, reusing what is there.
local function ensure_anchor_entity(surface, anchor)
  anchor.entity_name = managed_line_state.get_entity_name(anchor)

  if not is_correct_anchor_entity(anchor.entity, anchor) then
    if anchor.entity and anchor.entity.valid then
      anchor.entity.destroy({raise_destroy = false})
    end

    anchor.entity = nil
    clear_anchor_tile(surface, anchor)

    local existing = find_entity_at(surface, anchor.entity_name, anchor.position)

    if is_correct_anchor_entity(existing, anchor) then
      anchor.entity = existing
    else
      if existing and existing.valid then
        existing.destroy({raise_destroy = false})
      end

      anchor.entity = surface.create_entity({
        name = anchor.entity_name,
        position = anchor.position,
        direction = anchor.direction,
        force = "player",
        type = get_underground_belt_type(anchor)
      })
    end
  end

  if anchor.entity then
    configure_anchor_entity(anchor.entity, anchor)
    clear_anchor_tile(surface, anchor)
  end
end

-- Puts a slot marker on every empty Anchor and removes markers everywhere else.
local function ensure_slot_markers(surface, square_size, managed_lines, square_position)
  local occupied = {}
  local ring = {}

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position and anchor.resource then
      occupied[square_layout.get_position_key(anchor.position)] = true
    end
  end

  for _, position in ipairs(square_layout.get_anchor_ring_positions(square_size, square_position)) do
    local key = square_layout.get_position_key(position)
    local marker = find_entity_at(surface, definitions.SLOT_PROXY_NAME, get_tile_center(position))

    ring[key] = true

    if occupied[key] then
      if marker then
        marker.destroy({raise_destroy = false})
      end
    elseif not marker then
      surface.create_entity({
        name = definitions.SLOT_PROXY_NAME,
        position = get_tile_center(position),
        force = "player"
      })
    end
  end

  for _, marker in ipairs(surface.find_entities_filtered({name = definitions.SLOT_PROXY_NAME})) do
    local key = square_layout.get_position_key(square_layout.snap_to_tile(marker.position))

    if not ring[key] or occupied[key] then
      marker.destroy({raise_destroy = false})
    end
  end
end

-- Brings every Anchor entity and slot marker on a Planet in line with its stored lines.
function anchor_runtime.reconcile(planet_name)
  local planet = planet_state.get(planet_name)
  local surface = planet:get_surface()
  local managed_lines = managed_line_state.get(planet_name)

  if not (surface and managed_lines) then
    return
  end

  for _, anchor in ipairs(managed_lines.anchors) do
    if anchor.position and anchor.resource then
      ensure_anchor_entity(surface, anchor)
    elseif anchor.entity then
      if anchor.entity.valid then
        anchor.entity.destroy({raise_destroy = false})
      end

      anchor.entity = nil
    end
  end

  ensure_slot_markers(surface, planet:get_square_size(), managed_lines, planet:get_square_position())
end

function anchor_runtime.reconcile_all()
  for _, planet_name in ipairs(planet_catalog.SUPPORTED_PLANETS) do
    anchor_runtime.reconcile(planet_name)
  end
end

function anchor_runtime.destroy_line_entity(surface, anchor)
  local entity = anchor.entity

  if not (entity and entity.valid) and anchor.entity_name and anchor.position then
    entity = find_entity_at(surface, anchor.entity_name, anchor.position)
  end

  if entity and entity.valid then
    entity.destroy({raise_destroy = false})
  end

  anchor.entity = nil
end

-- The plain belt or pipe that continues a line once its Anchor moves on.
local function get_connector_entity_name(anchor)
  if anchor.kind == "fluid" then
    return "pipe"
  end

  return definitions.get_item_tier_for_level(anchor.tier_level or 1).transport_belt
end

-- Managed Line Shift: replaces a line's Anchor entity with a plain belt or pipe, so
-- the line still reaches its Anchor once the Anchor moves one tile further out.
function anchor_runtime.leave_connector(surface, anchor)
  local connector_name = get_connector_entity_name(anchor)

  anchor_runtime.destroy_line_entity(surface, anchor)

  if find_entity_at(surface, connector_name, anchor.position) then
    return
  end

  surface.create_entity({
    name = connector_name,
    position = anchor.position,
    direction = anchor.direction,
    force = "player"
  })
end

-- Makes sure the tile just inside a line's Anchor holds a belt or pipe joining it.
function anchor_runtime.ensure_inner_connector(surface, anchor)
  if not (anchor.position and anchor.resource and anchor.side) then
    return
  end

  local position = square_layout.move_position(anchor.position, anchor.side, -1)
  local connector_name = get_connector_entity_name(anchor)

  if find_entity_at(surface, connector_name, position) then
    return
  end

  surface.create_entity({
    name = connector_name,
    position = position,
    direction = anchor.direction or managed_line_state.get_direction(anchor.flow, anchor.kind, anchor.side),
    force = "player"
  })
end

local function get_refund_item_name(entity)
  local items_to_place = entity.prototype.items_to_place_this

  return items_to_place and items_to_place[1] and items_to_place[1].name or nil
end

-- Destroys a just-built entity and gives its item back to whoever built it.
local function reject_built_entity(entity, actor, message)
  local item_name = get_refund_item_name(entity)

  if actor and actor.valid then
    if actor.object_name == "LuaPlayer" then
      if item_name and actor.insert({name = item_name, count = 1}) == 0 then
        actor.surface.spill_item_stack({
          position = actor.position,
          stack = {name = item_name, count = 1},
          enable_looted = true,
          force = actor.force
        })
      end

      actor.print(message)
    elseif actor.type == "construction-robot" and item_name then
      actor.get_inventory(defines.inventory.robot_cargo).insert({name = item_name, count = 1})
    end
  end

  entity.destroy({raise_destroy = false})
end

local function overlaps_boundary(entity, square_size, square_position)
  local box = entity.bounding_box
  local min_x = math.floor(box.left_top.x + 0.001)
  local min_y = math.floor(box.left_top.y + 0.001)
  local max_x = math.ceil(box.right_bottom.x - 0.001) - 1
  local max_y = math.ceil(box.right_bottom.y - 0.001) - 1

  for y = min_y, max_y do
    for x = min_x, max_x do
      if square_layout.is_anchor_ring_position(square_size, {x = x, y = y}, square_position) then
        return true
      end
    end
  end

  return false
end

-- The Boundary is reserved for Anchors, and Managed Line items are only placed
-- through Anchor Slot Configuration.
function anchor_runtime.handle_entity_built(event)
  local entity = event.entity

  if not entity.valid then
    return
  end

  local actor = event.player_index and game.get_player(event.player_index) or event.robot
  local planet = planet_state.for_surface(entity.surface)

  if definitions.is_managed_entity_name(entity.name) then
    local message = planet and {"message.the-square-managed-line-use-anchor-slot"}
      or {"message.the-square-managed-line-invalid-surface"}

    reject_built_entity(entity, actor, message)
    return
  end

  if planet and overlaps_boundary(entity, planet:get_square_size(), planet:get_square_position()) then
    reject_built_entity(entity, actor, {"message.the-square-edge-reserved"})
  end
end

-- A mined Anchor entity leaves its line owned but unconfigured.
function anchor_runtime.handle_entity_removed(entity)
  local planet = planet_state.for_surface(entity.surface)
  local managed_lines = planet and managed_line_state.get(planet:get_name())
  local anchor = managed_lines and managed_line_state.find_by_entity(managed_lines, entity)

  if not anchor then
    return
  end

  if anchor.entity and anchor.entity.valid then
    anchor.entity.destroy({raise_destroy = false})
  end

  managed_line_state.clear(anchor)
  anchor_runtime.reconcile(planet:get_name())
end

-- Anchors keep the direction their flow needs.
function anchor_runtime.handle_entity_rotated(entity)
  local planet = planet_state.for_surface(entity.surface)
  local managed_lines = planet and managed_line_state.get(planet:get_name())
  local anchor = managed_lines and managed_line_state.find_by_entity(managed_lines, entity)

  if anchor and anchor.direction and entity.direction ~= anchor.direction then
    entity.direction = anchor.direction
  end
end

return anchor_runtime
