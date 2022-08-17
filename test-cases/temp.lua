local json = require("json")
print(json.encode([==[
#!/usr/bin/env lua5.4

--- ${1:MOD_NAME}: ${2:MOD_DESC}
---@author: Wynn Yo
-- # USAGE
--[[ -----------------------------------------------------------

--]] -----------------------------------------------------------
-- # DEPENDENCIES
local module = {}

--# STATIC_CONFIG_DEFINITION

--# CONTEXT_VALUE_DEFINITION

--# METHODS_DEFINITION

--# WRAP_MODULE
local function module_initializer()
    -- # STATIC_CONFIG_INIT

    -- # CONTEXT_VALUE_INIT

    -- # MODULE_EXPORT

    ---@class ${1:MOD_NAME} @${2:MOD_DESC}
    local ${1:MOD_NAME} = {

    }

    return ${1:MOD_NAME}
end

return module_initializer()
]==]))
