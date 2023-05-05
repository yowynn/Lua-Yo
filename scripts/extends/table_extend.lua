---@author: Wynn Yo 2023-04-19 18:34:04

-- # DEPENDENCIES
assert(_VERSION >= "Lua 5.1", "Lua version >= 5.1 required")

-- # CONSTANTS_DEFINITION
local METATABLE_WEAKK = { __mode = "k" }
local METATABLE_WEAKV = { __mode = "v" }
local METATABLE_WEAKKV = { __mode = "kv" }

-- # PRIVATE_DEFINITION

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

-- # MODULE_DEFINITION
local M = table

--- init a table
---@param _out table @optional, the table to init
---@param _weak "k"|"v"|"kv" @optional, the weak mode of the table, default is nil
---@return table @the inited table
function M.init(_out, _weak)
    local out = _out and M.clear(_out) or {}
    local weak = _weak or nil
    if weak then
        if weak == "k" then
            setmetatable(out, METATABLE_WEAKK)
        elseif weak == "v" then
            setmetatable(out, METATABLE_WEAKV)
        elseif weak == "kv" then
            setmetatable(out, METATABLE_WEAKKV)
        else
            error("invalid weak mode: " .. tostring(weak))
        end
    end
    return out
end

--- clear a table, remove all keys and values
---@param t table @the table to clear
---@param _rm_mt boolean @optional, remove metatable of the table, default is false
---@return table @the cleared table
function M.clear(t, _rm_mt)
    if _rm_mt then
        setmetatable(t, nil)
    end
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

--- reverse key and value of a table
---@param t table @the table to reverse
---@param _out table @optional, the output table
---@return table @the reversed table
function M.rindex(t, _out)
    local out = _out or {}
    for k, v in pairs(t) do
        out[v] = k
    end
    return out
end

--- get all keys of a table
---@param t table @the table to get keys
---@param _out table @optional, the output table
---@param _f number @optional, the from index to fill the output table, default is the original table's length + 1
---@return any[] @the list of keys
---@return number @count of keys added
function M.keys(t, _out, _f)
    local out = _out or {}
    local f = _f or #out + 1
    local i = f
    for k in pairs(t) do
        out[i] = k
        i = i + 1
    end
    return out, i - f
end

--- get all values of a table
---@param t table @the table to get values
---@param _out table @optional, the output table
---@param _f number @optional, the from index to fill the output table, default is the original table's length + 1
---@return any[] @the list of values
---@return number @count of values added
function M.values(t, _out, _f)
    local out = _out or {}
    local f = _f or #out + 1
    local i = f
    for _, v in pairs(t) do
        out[i] = v
        i = i + 1
    end
    return out, i - f
end

--- check if a table is an array
---@param t table @the table to check
---@return boolean @true if the table is an array
---@return number @the length of the array
function M.isarray(t)
    local i = 1
    for _ in pairs(t) do
        if t[i] == nil then
            return false, i - 1
        end
        i = i + 1
    end
    return true, i - 1
end

--- deep copy a table (append only)
---@param t table @the table to copy
---@param _out table @optional, the output table
---@return table @the copied table
function M.deepcopy(t, _out)
    local out = _out or {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            out[k] = M.deepcopy(v, out[k])
        else
            out[k] = v
        end
    end
    return out
end

--- deep restore a table (keep everything same as the original table)
---@param t table @the table to restore
---@param _out table @optional, the output table
---@return table @the restored table
function M.deeprestore(t, _out)
    local out = _out or {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            local ov = out[k]
            if type(ov) ~= "table" then ov = nil end
            out[k] = M.deeprestore(v, ov)
        else
            out[k] = v
        end
    end
    for k in pairs(out) do
        if t[k] == nil then
            out[k] = nil
        end
    end
    return out
end

--- compare function generator for simple order (number or string), be used in `table.sort`
---@param _k any @optional, the index to get the value to compare, default is the object itself
---@param _desc boolean @optional, if true, the order will be descending, otherwise ascending, default is false
---@return (fun(a:any,b:any):boolean,boolean) @the compare function, the first return value is the compare result, the second return value is true if the two values are equal
function M.comp(_k, _desc)
    local k = _k or nil
    local desc = _desc and true or false
    if k == nil then
        if desc then
            return function(a, b)
                if a == b then return false, true end
                return a > b, false
            end
        else
            return function(a, b)
                if a == b then return false, true end
                return a < b, false
            end
        end
    else
        if desc then
            return function(a, b)
                local va, vb = a[k], b[k]
                if va == vb then return false, true end
                return va > vb, false
            end
        else
            return function(a, b)
                local va, vb = a[k], b[k]
                if va == vb then return false, true end
                return va < vb, false
            end
        end
    end
end

--- compare function generator for any-type items, be used in `table.sort`
---@param _k any @optional, the index to get the value to compare, default is the object itself
---@param _desc boolean @optional, if true, the order will be descending, otherwise ascending, default is false
---@return (fun(a:any,b:any):boolean,boolean) @the compare function, the first return value is the compare result, the second return value is true if the two values are equal
function M.comp_complex(_k, _desc)
    local k = _k or nil
    local desc = _desc and true or false
    if k == nil then
        if desc then
            return function(a, b)
                local ta, va = _type_and_value(a)
                local tb, vb = _type_and_value(b)
                if ta == tb then
                    if va == vb then return false, true end
                    return va > vb
                end
                return ta > tb
            end
        else
            return function(a, b)
                local ta, va = _type_and_value(a)
                local tb, vb = _type_and_value(b)
                if ta == tb then
                    if va == vb then return false, true end
                    return va < vb
                end
                return ta < tb
            end
        end
    else
        if desc then
            return function(a, b)
                local ta, va = _type_and_value(a[k])
                local tb, vb = _type_and_value(b[k])
                if ta == tb then
                    if va == vb then return false, true end
                    return va > vb, false
                end
                return ta > tb, false
            end
        else
            return function(a, b)
                local ta, va = _type_and_value(a[k])
                local tb, vb = _type_and_value(b[k])
                if ta == tb then
                    if va == vb then return false, true end
                    return va < vb, false
                end
                return ta < tb, false
            end
        end
    end
end

--- compare function generator that combine multiple compare functions, be used in `table.sort`
---@param comp1 (fun(a:any,b:any):boolean,boolean) @the first compare function
---@param comp2 (fun(a:any,b:any):boolean,boolean) @the second compare function
---@vararg (fun(a:any,b:any):boolean,boolean) @the other compare functions
---@return (fun(a:any,b:any):boolean,boolean) @the combined compare function, the first return value is the compare result, the second return value is true if the two values are equal
function M.comp_combine(comp1, comp2, ...)
    if select("#", ...) > 0 then
        comp2 = M.comp_combine(comp2, ...)
    end
    return function(a, b)
        local r1, e1 = comp1(a, b)
        if e1 then return comp2(a, b) end
        return r1, false
    end
end

--- traverse a table, but just select given keys in given order
---@param t table @the table to traverse
---@param _klist any[] @optional, the key list, default is the key list of the table
---@param _comp (fun(a:any,b:any):boolean,boolean) @optional, the compare function to generate the key list, if present, force to generate the key list
---@return fun():any,any @the iterator function, the first return value is the key, the second return value is the value
---@return table @the table to traverse
---@return any @the current key
function M.pairs_selected(t, _klist, _comp)
    local klist = _klist
    local comp = _comp
    if not klist or comp then
        klist = M.keys(t, M.clear(klist or {}))
        table.sort(klist, comp)
    end
    local i = 0
    return function()
        i = i + 1
        local k = klist[i]
        if k == nil then return nil end
        return k, t[k]
    end, t, nil
end

return M
