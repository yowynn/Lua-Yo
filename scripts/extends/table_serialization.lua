---@author: Wynn Yo 2023-05-05 14:56:31

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
local DUMP_UNSUPPORTED_HINT = "%s"

-- # PRIVATE_DEFINITION

local _ctx_verbose = DEFAULT_VERBOSE
local _ctx_depth_limit = DEFAULT_DEPTH_LIMIT
local _ctx_refs, _ctx_ref_i = {}, {}
local _ctx_ref_loop = {}

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
    if ta == tb then
        return va < vb
    else
        return ta < tb
    end
end

--- sorted key pairs
local function _sorted_pairs(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, _tvcompare)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k ~= nil then
            return k, t[k]
        end
    end
end

--- check if unsupported object
local function _unsupported(o, depth)
    local t = type(o)
    if t == "function" or t == "thread" or t == "userdata" then
        return "not literal type"
    elseif t == "table" then
        if depth >= _ctx_depth_limit then
            return "table depth limit"
        end
        local mt = getmetatable(o)
        if mt and type(mt) ~= "table" then
            return "table with protected metatable"
        end
    end
end

--- check if exists self loop
local function _selfloop(o)
    if _ctx_ref_loop[o] then
        return "self loop"
    end
end

--- check if object is marked in references
local function _markref(o, special)
    local loop = _ctx_ref_loop[o]

    local oi = _ctx_ref_i[o]
    local i = oi
    if special and special >= 0 then
        if not i or i < 0 then
            i = #_ctx_refs + 1
            _ctx_refs[i] = o
        else
            i = 0
        end
        if special > 1 then
            i = 0
        end
    else
        i = i or -1
    end
    _ctx_ref_i[o] = i
    return oi
end

--- any to reference
local function _any2ref(o)
    local t = type(o)
    if t == "table" or t == "function" or t == "userdata" or t == "thread" then
        if _markref(o) then
            return
        end
        if _unsupported(o, -1) then
            _markref(o, true)
        end
        if t == "table" then
            local mt = getmetatable(o)
            if mt then
                _any2ref(mt)
            end
            for k, v in _sorted_pairs(o) do
                _any2ref(k)
                _any2ref(v)
            end
            _markref(o, false)
        end
    end
end

--- analayze references
local function _analyze_refs(o)
    _ctx_refs, _ctx_ref_i, _ctx_ref_loop = {}, {}, {}
    _any2ref(o)
    local n = #_ctx_refs
    local c = 0
    for i = 1, n do
        local ref = _ctx_refs[i]
        _ctx_refs[i] = nil
        if _ctx_ref_i[ref] == 0 then
            c = c + 1
            _ctx_ref_i[ref] = c
            _ctx_refs[c] = ref
        else
            _ctx_ref_i[ref] = nil
        end
    end
end

local _key2literal, _val2literal = nil, nil

--- boolean to literal string
local function _boolean2literal(b)
    return b and "true" or "false"
end

--- number to literal string
local function _number2literal(n)
    if n ~= n then              -- (NaN)
        return "0/0"
    elseif n == math.huge then  -- (inf)
        return "math.huge"
    elseif n == -math.huge then -- (-inf)
        return "-math.huge"
    else
        return tostring(n)
    end
end

--- string to literal string
local function _string2literal(s)
    return string.format("%q", s)
end

--- table to literal string
local function _table2literal(t, depth)
    local frag = {}
    depth = (depth or 0) + 1
    table.insert(frag, "{")
    if _ctx_verbose then
        table.insert(frag, " ")
        table.insert(frag, tostring(t))
    end
    table.insert(frag, LITERAL_NEWLINE)
    for k, v in _sorted_pairs(t) do
        table.insert(frag, string.rep(LITERAL_INDENT, depth))
        table.insert(frag, _key2literal(k, depth))
        table.insert(frag, " = ")
        table.insert(frag, _val2literal(v, depth))
        if not _ctx_verbose then
            table.insert(frag, ",")
        end
        table.insert(frag, LITERAL_NEWLINE)
    end
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    if _ctx_verbose then
        local mt = getmetatable(t)
        if mt then
            table.insert(frag, string.rep(LITERAL_INDENT, depth))
            table.insert(frag, "<.metatable> = ")
            table.insert(frag, _val2literal(mt, depth))
            table.insert(frag, LITERAL_NEWLINE)
        end
    end
    table.insert(frag, string.rep(LITERAL_INDENT, depth - 1))
    table.insert(frag, "}")
    return table.concat(frag)
end

--- reference to literal string
local function _ref2literal(r)
    local i = _ctx_ref_i[r]
    if i then
        return string.format("%s[%d]", LITERAL_REFS, i)
    else
        return nil
    end
end

--- illegal to literal string
local function _illegal2literal(i)
    local i = string.format(DUMP_UNSUPPORTED_HINT, tostring(i))
    if _ctx_verbose then
        return i
    else
        return string.format("%q", i)
    end
end

--- value to literal string
_val2literal = function(v, depth)
    local ref = _ref2literal(v)
    if ref then
        return ref
    end
    local t = type(v)
    if t == "boolean" then
        return _boolean2literal(v)
    elseif t == "number" then
        return _number2literal(v)
    elseif t == "string" then
        return _string2literal(v)
    elseif t == "table" then
        return _table2literal(v, depth)
    else
        return tostring(v)
    end
end

--- key to literal string
_key2literal = function(k, depth)
    local ref = _ref2literal(k)
    if ref then
        return "[" .. ref .. "]"
    end
    local t = type(k)
    if t == "boolean" then
        return "[" .. _boolean2literal(k) .. "]"
    elseif t == "number" then
        return "[" .. _number2literal(k) .. "]"
    elseif t == "string" then
        if _ctx_verbose or string.find(k, "^[_%a][_%w]*$") then
            return k
        else
            return "[" .. _string2literal(k) .. "]"
        end
    elseif t == "table" then
        return "[" .. _table2literal(k, depth) .. "]"
    else
        return "[" .. tostring(k) .. "]"
    end
end
