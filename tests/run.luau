--!strict
-- The only host IO is test.sh's source bundle. Production source is unchanged.
local sources = require("../.cache/headless/sources")
local tree = { Name = "root" }
local nodes = {}
for path in pairs(sources) do
	local current = tree
	for component in path:gmatch("[^/]+") do
		local name = component:gsub("%.luau$", "")
		if not current[name] then
			current[name] = { Name = name, Parent = current }
		end
		current = current[name]
	end
	current.path = path
	nodes[path] = current
end
local cache, loading = {}, {}
local passed, failed = 0, 0
local suite = ""
local function describe(name, body)
	local previous = suite
	suite = if previous == "" then name else previous .. " / " .. name
	body()
	suite = previous
end
local function it(name, body)
	local ok, message = pcall(body)
	if ok then
		passed += 1
		print("PASS " .. suite .. " / " .. name)
	else
		failed += 1
		print("FAIL " .. suite .. " / " .. name .. ": " .. tostring(message))
	end
end
local function expect(actual)
	return {
		toEqual = function(expected)
			assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
		end,
		toBeClose = function(expected, tolerance)
			assert(math.abs(actual - expected) <= tolerance,
				"expected " .. tostring(expected) .. " +/- " .. tostring(tolerance) .. ", got " .. tostring(actual))
		end,
	}
end
local gameStub = {}
function gameStub:GetService(name)
	assert(name == "ReplicatedStorage", "unstubbed service " .. name)
	return { Shared = tree.src.shared }
end
local function loadModule(node)
	assert(type(node) == "table" and node.path, "require expects a module node")
	local path = node.path
	if cache[path] ~= nil then return cache[path] end
	assert(not loading[path], "circular require: " .. path)
	loading[path] = true
	local chunk, message = loadstring(sources[path], "@" .. path)
	assert(chunk, message)
	setfenv(chunk, setmetatable({
		script = node, require = loadModule, game = gameStub,
		describe = describe, it = it, expect = expect,
	}, { __index = getfenv() }))
	local result = chunk()
	assert(result ~= nil, "module returned nil: " .. path)
	cache[path], loading[path] = result, nil
	return result
end
local specs = {}
for path in pairs(sources) do
	if path:match("^tests/.*%.spec%.luau$") then table.insert(specs, path) end
end
table.sort(specs)
assert(#specs > 0, "no specs found")
for _, path in ipairs(specs) do
	local ok, message = pcall(loadModule, nodes[path])
	if not ok then
		failed += 1
		print("FAIL loading " .. path .. ": " .. tostring(message))
	end
end
print(string.format("headless: %d passed, %d failed", passed, failed))
assert(failed == 0, "headless tests failed")
