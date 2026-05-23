local anchor_placement = require("lib.anchor_placement")

local managed_line_placement = {}

local function finish_placement(anchor, side, position, force, actor, callbacks)
  callbacks = callbacks or {}

  if not anchor_placement.assign(anchor, side, position) then
    return false
  end

  if callbacks.after_assign then
    callbacks.after_assign(anchor, force, actor)
  end

  return true
end

function managed_line_placement.place_built_entity(context)
  if not (context and context.entity and context.entity.valid) then
    return false
  end

  local entity = context.entity
  local anchor = context.anchor
  local side = context.side
  local position = context.position
  local starter_anchors = context.starter_anchors
  local actor = context.actor
  local callbacks = context.callbacks or {}

  local ok, reason = anchor_placement.check(anchor, position, context.square_size, starter_anchors)

  if not ok then
    if callbacks.reject then
      callbacks.reject(entity, actor, reason)
    end
    return false, reason
  end

  entity.destroy({raise_destroy = false})
  finish_placement(anchor, side, position, entity.force, actor, callbacks)

  if callbacks.after_placement then
    callbacks.after_placement()
  end

  return true
end

function managed_line_placement.place_from_slot(context)
  if not (context and context.player and context.player.valid) then
    return false
  end

  local player = context.player
  local anchor = context.anchor
  local position = context.position
  local starter_anchors = context.starter_anchors
  local callbacks = context.callbacks or {}

  local ok, reason, side = anchor_placement.check(anchor, position, context.square_size, starter_anchors)

  if not ok then
    if callbacks.reject_slot then
      callbacks.reject_slot(player, reason)
    end
    return false, reason
  end

  if callbacks.consume_cursor_item and not callbacks.consume_cursor_item(player, context.item_name) then
    return false, "cursor-mismatch"
  end

  finish_placement(anchor, side, position, player.force, player, callbacks)

  if callbacks.after_placement then
    callbacks.after_placement()
  end

  return true
end

return managed_line_placement
