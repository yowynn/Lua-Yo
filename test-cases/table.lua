print("Test: table module")

require("table_extend")

for k, v in pairs(table) do
    print(k, v)
end
