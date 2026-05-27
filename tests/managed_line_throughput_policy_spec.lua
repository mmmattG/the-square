package.path = "./?.lua;./?/init.lua;" .. package.path

local throughput_policy = require("lib.managed_line_throughput_policy")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual))
  end
end

local function run_test(name, fn)
  local ok, err = pcall(fn)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

run_test("Managed Line throughput policy owns planet-specific budget rules", function()
  assert_equal(
    throughput_policy.should_gate_gleba_fruit("gleba", {flow = "ingress", kind = "item", resource = "yumako"}),
    true,
    "Gleba fruit ingress should be gated"
  )
  assert_equal(
    throughput_policy.get_gleba_fruit_for_seed_anchor({flow = "egress", kind = "item", resource = "jellynut-seed"}),
    "jellynut",
    "seed egress should map to matching fruit budget"
  )
  assert_equal(
    throughput_policy.should_skip_regular_egress("gleba", {resource = "yumako-seed"}),
    true,
    "Gleba seed egress is consumed by the policy budget pass"
  )
  assert_equal(
    throughput_policy.should_gate_biter_egg("nauvis", {flow = "ingress", kind = "item", resource = "biter-egg"}),
    true,
    "Nauvis biter egg ingress should be gated"
  )
  assert_equal(
    throughput_policy.should_skip_regular_egress("nauvis", {resource = "bioflux"}),
    true,
    "Nauvis bioflux egress is consumed by the biter egg budget pass"
  )
  assert_equal(
    throughput_policy.BITER_BIOFLUX_BUFFER_CAPACITY,
    30,
    "Biter egg support should buffer thirty bioflux worth of egg budget"
  )
end)
