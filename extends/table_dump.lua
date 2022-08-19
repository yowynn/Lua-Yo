local DEFINE_EXPAND_TO_TABLE = true -- expand to table

--- table.dump: dump table to string
---@author: Wynn Yo 2022-06-02 10:26:53
-- # DEPENDENCIES
local module = {}
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type
local math_huge = math.huge
local table_sort = table.sort

-- # STATIC_CONFIG_DEFINITION

module.LITERAL_INDENT = nil
module.LITERAL_NEWLINE = nil
module.LITERAL_FOLDING_TAG = nil
module.DEFAULT_VERBOSE = nil
module.DEFAULT_DEPTH_LIMIT = nil

-- # CONTEXT_VALUE_DEFINITION

module._ctx_verbose = nil
module._ctx_depth_limit = nil

-- # METHODS_DEFINITION

function module._dumpTable(t, depth)
    depth = (depth or 0) + 1
    local s = "{"
    if module._ctx_verbose then
        s = s .. " " .. module._dumpOriginal(t, false)
    end
    s = s .. module.LITERAL_NEWLINE
    local vkpairs = {}
    for k, v in pairs(t) do
        vkpairs[#vkpairs + 1] = module.LITERAL_INDENT:rep(depth) .. module._dumpTableKey(k, depth) .. " = " ..
                                    module._dumpTableValue(v, depth)
    end
    table_sort(vkpairs)
    for _, v in ipairs(vkpairs) do
        s = s .. v
        if not module._ctx_verbose then
            s = s .. ","
        end
        s = s .. module.LITERAL_NEWLINE
    end
    if module._ctx_verbose then
        local mt = getmetatable(t)
        if mt then
            s = s .. module.LITERAL_INDENT:rep(depth) .. ".metatable = " .. module._dumpTable(mt, depth) ..
                    module.LITERAL_NEWLINE
        end
    end
    s = s .. module.LITERAL_INDENT:rep(depth - 1) .. "}"
    return s
end

function module._dumpTableKey(t, depth)
    local s = module._dumpAll(t, depth)
    return "[" .. s .. "]"
end

function module._dumpTableValue(t, depth)
    local s = module._dumpAll(t, depth)
    return s
end

function module._dumpString(t, depth)
    local s
    if module._ctx_verbose then
        s = "\"" .. t .. "\""
    else
        s = ("%q"):format(t)
    end
    return s
end

function module._dumpNumber(t, depth)
    local s = tostring(t)
    return s
end

function module._dumpBoolean(t, depth)
    local s = tostring(t)
    return s
end

function module._dumpOriginal(t, fold)
    fold = fold and module.LITERAL_FOLDING_TAG or ""
    if module._ctx_verbose then
        return "<" .. tostring(t) .. fold .. ">"
    else
        return "\"DMPERR:" .. tostring(t) .. fold .. "\""
        -- return "nil" .. module.LITERAL_INDENT .. "--[[" .. tostring(t) .. fold .. "]]"
    end
end

function module._dumpAll(t, depth)
    if type(t) == "table" then
        if depth >= module._ctx_depth_limit then
            return module._dumpOriginal(t, true)
        else
            return module._dumpTable(t, depth)
        end
    elseif type(t) == "string" then
        return module._dumpString(t, depth)
    elseif type(t) == "number" then
        return module._dumpNumber(t, depth)
    elseif type(t) == "boolean" then
        return module._dumpBoolean(t, depth)
    else
        return module._dumpOriginal(t, false)
    end
end

--- Dump a table to a string.
---@param t table|any @table / target to dump
---@param verbose boolean @if true, dump the additional information, such as metatable, etc.
---@param depth number @depth limit
---@return string
function module.dump(t, verbose, depth)
    module._ctx_verbose = verbose == nil and module.DEFAULT_VERBOSE or verbose
    module._ctx_depth_limit = depth == nil and module.DEFAULT_DEPTH_LIMIT or depth
    local s = module._dumpAll(t, 0)
    return s
end

-- # WRAP_MODULE

local function module_initializer()
    -- # STATIC_CONFIG_INIT

    module.LITERAL_INDENT = "\t"
    module.LITERAL_NEWLINE = "\n"
    module.LITERAL_FOLDING_TAG = "..."
    module.DEFAULT_VERBOSE = true
    module.DEFAULT_DEPTH_LIMIT = math_huge

    -- # CONTEXT_VALUE_INIT

    -- # MODULE_EXPORT
    local table_dump = module.dump
    return table_dump
end

if DEFINE_EXPAND_TO_TABLE then
    if table and not table.dump then
        local table_dump = module_initializer()
        table.dump = table_dump
    end
end

return module_initializer()
