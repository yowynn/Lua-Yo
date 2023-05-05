print("Test: table module")

require("table_extend")
require("table_serialization")


case("serialization", function(t)
    print("dump:")
    print(table.dump(t))
    print("serialize:")
    local s = table.serialize(t)
    print(s)
    print("dump deserialize:")
    print(table.dump(table.deserialize(s)))
end)

local t = {1,2,aa="hah"}
local t2 = {t = t}
t.t2 = t2
t[t2] = {}
t[print] = {[math.huge] = 666}
test("serialization", t)
