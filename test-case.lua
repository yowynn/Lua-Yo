local case_name = select(1, ...)
if not case_name then
    error("case_name is nil")
end
print("test-case: " .. case_name)

require "extends.table_dump-test"

