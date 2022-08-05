

local INDENT = "\t"
local NEWLINE = "\n"

local _VERBOSE = true
local _DEPTH_LIMIT = math.huge

local dumptable, dumptablekey, dumptablevalue, dumpstring, dumpnumber, dumpboolean, dumporiginal, dumpall

function dumptable(t, depth)
    depth = (depth or 0) + 1
    local s = "{"
    if _VERBOSE then
        s = s .. " " .. dumporiginal(t, false)
    end
    s = s .. NEWLINE
    local vkpairs = {}
    for k, v in pairs(t) do
        vkpairs[#vkpairs + 1] = INDENT:rep(depth) .. dumptablekey(k, depth) .. " = " .. dumptablevalue(v, depth)
    end
    table.sort(vkpairs)
    for _, v in ipairs(vkpairs) do
        s = s .. v
        if not _VERBOSE then
            s = s .. ","
        end
        s = s .. NEWLINE
    end
    if _VERBOSE then
        local mt = getmetatable(t)
        if mt then
            s = s .. INDENT:rep(depth) .. ".metatable = " .. dumptable(mt, depth) .. NEWLINE
        end
    end
    s = s .. INDENT:rep(depth - 1) .. "}"
    return s
end

function dumptablekey(t, depth)
    local s = dumpall(t, depth)
    return "[" .. s .. "]"
end

function dumptablevalue(t, depth)
    local s = dumpall(t, depth)
    return s
end

function dumpstring(t, depth)
    local s = "\"" .. t .. "\""
    return s
end

function dumpnumber(t, depth)
    local s = tostring(t)
    return s
end

function dumpboolean(t, depth)
    local s = tostring(t)
    return s
end

function dumporiginal(t, fold)
    fold = fold and "..." or ""
    if _VERBOSE then
        return "<" .. tostring(t) .. fold .. ">"
    else
        return "nil" .. INDENT .. "--[[" .. tostring(t) .. fold .. "]]"
    end
end

function dumpall(t, depth)
    if depth >= _DEPTH_LIMIT then
        return dumporiginal(t, true)
    end
    if type(t) == "table" then
        return dumptable(t, depth)
    elseif type(t) == "string" then
        return dumpstring(t, depth)
    elseif type(t) == "number" then
        return dumpnumber(t, depth)
    elseif type(t) == "boolean" then
        return dumpboolean(t, depth)
    else
        return dumporiginal(t, false)
    end
end

--- Dump a table to a string.
---@param t table|any @table / target to dump
---@param verbose boolean @if true, dump the additional information, such as metatable, etc.
---@param depth number @depth limit
---@return string
local function dump(t, verbose, depth)
    _VERBOSE = verbose == nil and true or verbose
    _DEPTH_LIMIT = depth == nil and math.huge or depth
    local s = dumpall(t, 0)
    return s
end

if table and not table.dump then
    table.dump = dump
end
return dump
