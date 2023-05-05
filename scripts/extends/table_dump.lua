---@author: Wynn Yo 2023-05-05 11:23:05

-- # DEPENDENCIES
assert(_VERSION >= "Lua 5.1", "Lua version >= 5.1 required")

-- # CONSTANTS_DEFINITION


--- the table indent string
local LITERAL_INDENT = "    "
--- the structual newline string
local LITERAL_NEWLINE = "\n"
--- the reference table name
local LITERAL_REFS = "_refs"
--- the folding flag for verbose mode
local LITERAL_VERBOSE_FOLDING_TAG = "..."
--- the limit tag for verbose mode
local LITERAL_VERBOSE_LIMIT_TAG = "DUMP_LIMIT"
--- the default verbose mode, if true will show additional information for read but difficult to rebuild table
local DEFAULT_VERBOSE = false
--- the default depth limit, table deeper than this will be folded and show `DUMP_LIMIT_HINT`
local DEFAULT_DEPTH_LIMIT = 10
--- the hint for depth limit item
local DUMP_LIMIT_HINT = "DUMP_LIMIT"

-- # PRIVATE_DEFINITION

local _ctx_verbose = DEFAULT_VERBOSE
local _ctx_depth_limit = DEFAULT_DEPTH_LIMIT
local _ctx_refs, _ctx_ref_i = {}, {}

--- analyze the ref status of the table
local function _analyze_ref(v, depth)
    local i = _ctx_ref_i[v]
    if i then
        if i == 0 then
            i = #_ctx_refs + 1
            _ctx_refs[i] = v
            _ctx_ref_i[v] = i
        end
    else
        local t = type(v)
        if t == "table" then
            local mt = getmetatable(v)
            if mt and type(mt) ~= "table" then
                i = #_ctx_refs + 1
                _ctx_refs[i] = v
                _ctx_ref_i[v] = i
            end
            if mt then
                _analyze_ref(mt)
                i = #_ctx_refs + 1
                _ctx_refs[i] = v
                _ctx_ref_i[v] = i
            end
        end
    end
end

local _dumpKey, _dumpValue

local function _type_and_value(o)
    local t = type(o)
    if t == "boolean" then return 1, o and 1 or 0 end
    if t == "number" then return 2, o end
    if t == "string" then return 3, o end
    if t == "table" then return 4, tostring(o) end
    if t == "function" then return 5, tostring(o) end
    if t == "thread" then return 6, tostring(o) end
    if t == "userdata" then return 7, tostring(o) end
    return 8, tostring(o)
end

local function _comp_key(a, b)
    local ta, va = _type_and_value(a)
    local tb, vb = _type_and_value(b)
    if ta == tb then
        return va < vb
    else
        return ta < tb
    end
end

--- parse the value that can't be handled
local function _parse_limit(v, isDepthLimit)
    if _ctx_verbose then
        local foldTag = isDepthLimit and LITERAL_VERBOSE_FOLDING_TAG or ""
        return "<" .. LITERAL_VERBOSE_LIMIT_TAG .. ": " .. tostring(v) .. foldTag .. ">"
    else
        return DUMP_LIMIT_HINT
    end
end

--- parse boolean value
local function _parse_boolean(v)
    return v and "true" or "false"
end

--- parse number value
local function _parse_number(v)
    if v ~= v then -- NaN
        return "0/0"
    elseif v == math.huge then -- inf
        return "math.huge"
    elseif v == -math.huge then -- -inf
        return "-math.huge"
    else
        return tostring(v)
    end
end

--- parse string value
local function _parse_string(v)
    if _ctx_verbose then
        return "\"" .. v .. "\""
    else
        return string.format("%q", v)
    end
end

--- parse table value
local function _parse_table(v, depth)
    local frag = {}
    depth = (depth or 0) + 1
    table.insert(frag, "{")
    if _ctx_verbose then
        table.insert(frag, " ")
        table.insert(frag, tostring(v))
    end
    table.insert(frag, LITERAL_NEWLINE)
    local keys = {}
    for k in pairs(v) do
        table.insert(keys, k)
    end
    table.sort(keys, _comp_key)
    for _, k in ipairs(keys) do
        local kstr = _dumpKey(k, depth)
        if kstr ~= nil then
            table.insert(frag, string.rep(LITERAL_INDENT, depth))
            table.insert(frag, kstr)
            table.insert(frag, " = ")
            table.insert(frag, _dumpValue(v[k], depth))
            if not _ctx_verbose then
                table.insert(frag, ",")
            end
            table.insert(frag, LITERAL_NEWLINE)
        end
    end
    if _ctx_verbose then
        local mt = getmetatable(v)
        if mt then
            table.insert(frag, string.rep(LITERAL_INDENT, depth))
            table.insert(frag, "<.metatable> = ")
            table.insert(frag, _dumpValue(mt, depth))
            table.insert(frag, LITERAL_NEWLINE)
        end
    end
    table.insert(frag, string.rep(LITERAL_INDENT, depth - 1))
    table.insert(frag, "}")
    return table.concat(frag)
end

--- check reference value
local function _check_ref(v, mark)
    local i = _ctx_ref_i[v]
    if i then
        if i == 0 then
            table.insert(_ctx_refs, v)
            i = #_ctx_refs
            _ctx_ref_i[v] = i
        end
        return LITERAL_REFS .. "[" .. i .. "]"
    end
    local t = type(v)

end

--- dump the table value
_dumpValue = function(v, depth)
    local t = type(v)
    if t == "boolean" then
        return _parse_boolean(v)
    elseif t == "number" then
        return _parse_number(v)
    elseif t == "string" then
        return _parse_string(v)
    elseif t == "table" then
        depth = depth or 0
        if depth >= _ctx_depth_limit then
            return _parse_limit(v, true)
        else
            return _parse_table(v, depth)
        end
    else
        return _parse_limit(v)
    end
end


--- dump the table key
_dumpKey = function(k, depth)
    local t = type(k)
    if t == "boolean" then
        return "[" .. _parse_boolean(k) .. "]"
    elseif t == "number" then
        return "[" .. _parse_number(k) .. "]"
    elseif t == "string" then
        if string.find(k, "^[_%a][_%w]*$") then
            return k
        else
            return "[" .. _parse_string(k) .. "]"
        end
    elseif t == "table" then
        depth = depth or 0
        if depth >= _ctx_depth_limit then
            return "[" .. _parse_limit(k, true) .. "]"
        else
            return "[" .. _parse_table(k, depth) .. "]"
        end
    else
        return _parse_limit(k)
    end
end
