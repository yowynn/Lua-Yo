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

dofile("test-cases/" .. moduleName .. ".lua")
