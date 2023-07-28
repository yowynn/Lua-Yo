--- table extension for serialization
---@author: Wynn Yo 2023-05-05 14:56:31
local M = table

-- # CONFIGS:

--- the table indent string
local LITERAL_INDENT = "    "
--- the structual newline string
local LITERAL_NEWLINE = "\n"
--- the table item separator string
local LITERAL_SEPARATOR = ", "
--- the literal string format for illegal objects, `nil` to leap
local LITERAL_ILLEGAL_FORMAT = nil
--- the literal string format for illegal objects in verbose mode
local LITERAL_ILLEGAL_FORMAT_VERBOSE = "<%s>"
--- the literal string format for cycle objects
local LITERAL_CYCLE_FORMAT = "CYCLE: %s"
--- the literal string format for reference objects
local LITERAL_REF_FORMAT = "REF: %s"
--- the literal string format for metatable objects
local LITERAL_METATABLE_FORMAT = "<.metatable>"
--- the default verbose mode, if true will show additional information for read but difficult to rebuild table
local DEFAULT_VERBOSE = false
--- the default depth limit, table deeper than this will be folded and show `DUMP_LIMIT_HINT`
local DEFAULT_DEPTH_LIMIT = math.huge

-- # DEPENDENCIES:

assert(_VERSION >= "Lua 5.1", "Lua version >= 5.1 required")
assert(getmetatable, "`getmetatable` not found")
assert(load, "`load` not found")
assert(pairs, "`pairs` not found")
assert(tostring, "`tostring` not found")
assert(type, "`type` not found")
assert(math.huge, "`math.huge` not found")
assert(string.find, "`string.find` not found")
assert(string.format, "`string.format` not found")
assert(string.rep, "`string.rep` not found")
assert(table.concat, "`table.concat` not found")
assert(table.insert, "`table.insert` not found")
assert(table.sort, "`table.sort` not found")

-- # PRIVATE_DEFINITION:

local _ctx_verbose = DEFAULT_VERBOSE
local _ctx_depth_limit = DEFAULT_DEPTH_LIMIT
local _ctx_fragments, _ctx_lock, _ctx_ref = {}, {}, {}

--- get type index and value index
local function _tvindex(o)
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

--- compare types then values
local function _tvcompare(a, b)
    local ta, va = _tvindex(a)
    local tb, vb = _tvindex(b)
    if ta == tb then return va < vb else return ta < tb end
end

--- sorted key pairs
local function _sorted_pairs(t)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, _tvcompare)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k ~= nil then return k, t[k] end
    end
end

--- appand literal fragment
local function _append(frag)
    if type(frag) ~= "string" then return false end
    table.insert(_ctx_fragments, frag)
    return #_ctx_fragments
end

--- reset the top of the fragment list
local function _top(i)
    for j = #_ctx_fragments, i, -1 do
        _ctx_fragments[j] = nil
    end
end

--- check if object
local function _supported(o, depth)
    local t = type(o)
    if t == "function" or t == "thread" or t == "userdata" then
        return false, "not literal type"
    elseif t == "table" then
        if depth and depth >= _ctx_depth_limit then
            return false, "table depth limit"
        end
        local mt = getmetatable(o)
        if mt and type(mt) ~= "table" then
            return false, "table with protected metatable"
        end
    end
    return true
end

--- check cycle in table
local function _cycle(o, mark)
    if mark then
        if _ctx_lock[o] then return true end
        _ctx_lock[o] = true
        return false
    else
        _ctx_lock[o] = nil
    end
end

--- check if object ref to exists literal
local function _ref(o)
    if _ctx_ref[o] then return true end
    _ctx_ref[o] = true
    return false
end

local _appendkey, _appendval = nil, nil

--- illegal to literal string
local function _append_illegal(i, format)
    i = tostring(i)
    if format then i = string.format(format, i) end
    if _ctx_verbose then format = LITERAL_ILLEGAL_FORMAT_VERBOSE else format = LITERAL_ILLEGAL_FORMAT end
    i = format and string.format(format, i)
    if not _ctx_verbose then i = i and string.format("%q", i) end
    return _append(i)
end

--- boolean to literal string
local function _append_boolean(b)
    if b then return _append("true") else return _append("false") end
end

--- number to literal string
local function _append_number(n)
    if _ctx_verbose then
        return _append(tostring(n))
    elseif n ~= n then          -- (NaN)
        return _append("0/0")
    elseif n == math.huge then  -- (inf)
        return _append("math.huge")
    elseif n == -math.huge then -- (-inf)
        return _append("-math.huge")
    else
        return _append(tostring(n))
    end
end

--- string to literal string
local function _append_string(s)
    return _append(string.format("%q", s))
end

--- table to literal string
local function _append_table(t, depth)
    if _cycle(t, true) then return _append_illegal(t, LITERAL_CYCLE_FORMAT) end
    if _ref(t) then return _append_illegal(t, LITERAL_REF_FORMAT) end
    depth = (depth or 0) + 1
    _append("{")
    if _ctx_verbose then
        _append("  -- ")
        _append(tostring(t))
    end
    _append(LITERAL_NEWLINE)
    for k, v in _sorted_pairs(t) do
        local f = _append(string.rep(LITERAL_INDENT, depth))
        if _appendkey(k, depth) and _append(" = ") and _appendval(v, depth) then
            _append(LITERAL_SEPARATOR)
            _append(LITERAL_NEWLINE)
        else _top(f) end
    end
    if _ctx_verbose then
        local mt = getmetatable(t)
        if mt then
            _append(string.rep(LITERAL_INDENT, depth))
            _append(string.format(LITERAL_METATABLE_FORMAT, tostring(mt)))
            _append(" = ")
            _appendval(mt, depth)
            _append(LITERAL_NEWLINE)
        end
    end
    _append(string.rep(LITERAL_INDENT, depth - 1))
    _cycle(t, false)
    return _append("}")
end

--- key to literal string
_appendkey = function(k, depth)
    if not _supported(k, depth) then
        return _append_illegal(k)
    end
    local t = type(k)
    if t == "boolean" then
        local f = _append("[")
        if _append_boolean(k) then
            return _append("]")
        else return _top(f) end
    elseif t == "number" then
        local f = _append("[")
        if _append_number(k) then
            return _append("]")
        else return _top(f) end
    elseif t == "string" then
        if _ctx_verbose or string.find(k, "^[_%a][_%w]*$") then
            return _append(k)
        else
            local f = _append("[")
            if _append_string(k) then
                return _append("]")
            else return _top(f) end
        end
    elseif t == "table" then
        local f = _append("[")
        if _append_table(k, depth) then
            return _append("]")
        else return _top(f) end
    else
        return _append_illegal(k)
    end
end

--- value to literal string
_appendval = function(v, depth)
    if not _supported(v, depth) then
        return _append_illegal(v)
    end
    local t = type(v)
    if t == "boolean" then
        return _append_boolean(v)
    elseif t == "number" then
        return _append_number(v)
    elseif t == "string" then
        return _append_string(v)
    elseif t == "table" then
        return _append_table(v, depth)
    else
        return _append_illegal(v)
    end
end

-- # MODULE_DEFINITION:

--- dump table to literal string
---@param t table @table to dump
---@param _depth number @depth to dump, default is `inf`
---@return string @literal string
function M.dump(t, _depth)
    _ctx_verbose = true
    _ctx_depth_limit = _depth or math.huge
    _ctx_fragments, _ctx_lock, _ctx_ref = {}, {}, {}
    _appendval(t)
    return table.concat(_ctx_fragments)
end

--- serialize table to literal string, which can be deserialize to restore table
---@param t table @table to serialize
---@return string @serialized string
function M.serialize(t)
    _ctx_verbose = false
    _ctx_depth_limit = math.huge
    _ctx_fragments, _ctx_lock, _ctx_ref = {}, {}, {}
    _appendval(t)
    return table.concat(_ctx_fragments)
end

--- deserialize literal string to restore table
---@param s string @serialized string
---@return table @restored table
function M.deserialize(s)
    local f, err = load("return " .. s, "deserialize", "t", {})
    if not f then return nil, err end
    return f()
end

-- # MODULE_EXPORT:

return M
