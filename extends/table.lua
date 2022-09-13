local module = {}

--- key as value, while value as key
function module.ridx(tb)
    local out = {}
    for k, v in pairs(tb) do
        out[v] = k
    end
    return out
end

function module.keys(tb)
    local out = {}
    for k in pairs(tb) do
        out[#out + 1] = k
    end
    return out
end

function module.values(tb)
    local out = {}
    for _, v in pairs(tb) do
        out[#out + 1] = v
    end
    return out
end

function module.isArray(tb)
    local i = 1
    for _ in pairs(tb) do
        if tb[i] == nil then
            return false
        end
        i = i + 1
    end
    return true
end

function module.order_natural(tkey)
    local function typevalue(o)
        local t = type(o)
        if t == "boolean" then
            return 1, o and 1 or 0
        end
        if t == "number" then
            return 2, o
        end
        if t == "string" then
            return 3, o
        end
        if t == "function" then
            return 4, tostring(o)
        end
        if t == "userdata" then
            return 5, tostring(o)
        end
        if t == "thread" then
            return 6, tostring(o)
        end
        if t == "table" then
            return 7, tostring(o)
        end
        return 8, tostring(o)
    end
    if tkey then
        return function(a, b)
            local ta, va = typevalue(a[tkey])
            local tb, vb = typevalue(b[tkey])
            if ta == tb then
                return va < vb
            else
                return ta < tb
            end
        end
    else
        return function(a, b)
            local ta, va = typevalue(a)
            local tb, vb = typevalue(b)
            if ta == tb then
                return va < vb
            else
                return ta < tb
            end
        end
    end
end

function module.order_descending(tkey)
    if tkey then
        return function(a, b)
            return a[tkey] > b[tkey]
        end
    else
        return function(a, b)
            return a > b
        end
    end
end

function module.order_ascending(tkey)
    if tkey then
        return function(a, b)
            return a[tkey] < b[tkey]
        end
    else
        return function(a, b)
            return a < b
        end
    end
end

function module.order_combine(...)
    local funcCount = select("#", ...)
    if funcCount < 2 then
        error("at least 2 order functions to combine")
    elseif funcCount == 2 then
        local func1, func2 = ...
        return function(a, b)
            if func1(a, b) then
                return true
            elseif func1(b, a) then
                return false
            else
                return func2(a, b)
            end
        end
    else
        local orderFuncs = table.pack(...)
        return function(a, b)
            for i, orderFunc in ipairs(orderFuncs) do
                if orderFunc(a, b) then
                    return true
                elseif orderFunc(b, a) then
                    return false
                end
            end
            return false
        end
    end
end


local function module_initializer(filterK)
    for k, v in pairs(module) do
        if filterK(k) then
            if not table[k] then
                table[k] = v
            end
        end
    end
    return table
end

return module_initializer(function(k)
    return k:sub(1, 1) ~= "_"
end)
