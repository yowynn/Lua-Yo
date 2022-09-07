local module = {}

function module.ridx(tb)
    local out = {}
    for k, v in pairs(tb) do
        out[v] = k
    end
    return out
end

local function module_initializer(filterK)
    for k, v in pairs(module) do
        if filterK(k) then
            if not table[k] then
                table[k] = v
            end
        end
    end
end

return module_initializer(function(k)
    return k:sub(1, 1) ~= "_"
end)
