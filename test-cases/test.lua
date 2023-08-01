print("Lua-Yo: Test~")
print("")
local moduleName = ...
print(string.format("module: %s", tostring(moduleName)))

local list = {}
function case(caseName, func)
    list[caseName] = func
end

function test(caseName, ...)
    print(string.format("case: %s", tostring(caseName)))
    local func = assert(list[caseName], "case not found")
    print(">> input:")
    print(...)
    print(">> output:")
    print(func(...))
    print("")
end

local function _dofile(path, ...)
    local f = assert(loadfile(path))
    return f(...)
end

_dofile("test-cases/" .. moduleName .. ".lua", select(2, ...))
