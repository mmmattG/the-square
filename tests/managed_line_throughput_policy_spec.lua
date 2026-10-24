package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = require("tests.helper")
local assert_equal = helper.assert_equal
local run_test = helper.run_test

local throughput_policy = require("lib.managed_line_throughput_policy")

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
end)
