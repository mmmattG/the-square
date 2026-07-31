local item_ingress = {}

local function floor_with_epsilon(value)
  return math.floor(value + 1e-9)
end

function item_ingress.advance_lane_progress(item_lane_counts, rate_period_ticks, carried_progress, elapsed_ticks)
  local safe_elapsed_ticks = math.max(0, elapsed_ticks or 0)
  local safe_rate_period_ticks = math.max(1, rate_period_ticks or 1)
  local lane_one_emission = 0
  local lane_two_emission = 0

  for lane_index = 1, 2 do
    local lane_count = math.max(0, (item_lane_counts and item_lane_counts[lane_index]) or 0)
    local lane_progress = (carried_progress[lane_index] or 0)
      + ((lane_count * safe_elapsed_ticks) / safe_rate_period_ticks)
    local emission_count = floor_with_epsilon(lane_progress)

    if lane_index == 1 then
      lane_one_emission = emission_count
    else
      lane_two_emission = emission_count
    end

    carried_progress[lane_index] = lane_progress - emission_count
  end

  return lane_one_emission, lane_two_emission
end

function item_ingress.compute_lane_emissions(item_lane_counts, rate_period_ticks, carried_progress, elapsed_ticks)
  local next_progress = {
    carried_progress and carried_progress[1] or 0,
    carried_progress and carried_progress[2] or 0
  }
  local lane_one_emission, lane_two_emission = item_ingress.advance_lane_progress(
    item_lane_counts,
    rate_period_ticks,
    next_progress,
    elapsed_ticks
  )

  return {
    lane_emissions = {lane_one_emission, lane_two_emission},
    carried_progress = next_progress
  }
end

function item_ingress.get_total_items_per_second(item_lane_counts, rate_period_ticks)
  local total_lane_count = 0

  for lane_index = 1, 2 do
    total_lane_count = total_lane_count + math.max(0, (item_lane_counts and item_lane_counts[lane_index]) or 0)
  end

  return total_lane_count * (60 / math.max(1, rate_period_ticks or 1))
end

return item_ingress
