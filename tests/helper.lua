-- Shared assertions for the plain-Lua specs in this folder.
-- Specs only cover pure logic; anything that needs the Factorio API is checked in game.
package.path = "./?.lua;./?/init.lua;" .. package.path

local helper = {}

function helper.assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. "\nexpected: " .. tostring(expected) .. "\nactual: " .. tostring(actual), 2)
  end
end

function helper.assert_at_most(actual, expected, message)
  if actual > expected then
    error((message or "value too large") .. "\nexpected at most: " .. tostring(expected) .. "\nactual: " .. tostring(actual), 2)
  end
end

function helper.run_test(name, fn)
  local ok, err = pcall(fn)

  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    os.exit(1)
  end

  io.stdout:write("PASS " .. name .. "\n")
end

return helper
