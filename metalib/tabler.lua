--- tabler: show data as pretty string table
---@author: Wynn Yo
-- # USAGE
--[[ -----------------------------------------------------------

--]] -----------------------------------------------------------
-- # DEPENDENCIES
local module = {}
module.__proto = {}

-- # STATIC_CONFIG_DEFINITION

-- # CONTEXT_VALUE_DEFINITION
module._ctx_columns = nil

-- # METHODS_DEFINITION

function module._define(key, override)
    local column = {}
    override = override or column
    column.key = key
    column.title = tostring(override.title) or tostring(key)
    column.width = tonumber(override.width) or nil
    column.align = override.align == "right" and "right" or "left"
    column.handler = override.handler or tostring
    return column
end

function module.defines(defineList)
    local columns = {}
    for i, v in ipairs(defineList) do
        local column
        if type(v) == "table" then
            column = module._define(v.key, v)
        else
            column = module._define(v, nil)
        end
        columns[#columns + 1] = column
    end
    module._ctx_columns = columns
    return module.__proto
end

function module.show(list)
    local showtitle = true
    local columnsep = "  "
    local widths = {}
    local showlist = {}
    for idx, item in ipairs(list) do
        local showitem = {}
        showlist[idx] = showitem
        for i, column in pairs(module._ctx_columns) do
            local key = column.key
            local val = item[key] ~= nil and (column.handler or tostring)(item[key])
            if val then
                local width = module.width(val)
                widths[i] = math.max(widths[i] or showtitle and module.width(column.title) or 0, width)
                showitem[i] = val
            end
        end
    end
    local showcolumns = {}
    local titles = {}
    for i, column in pairs(module._ctx_columns) do
        local width = widths[i]
        if width then
            width = column.width or width
            local alignRight = column.align == "right"
            local format = function(data)
                local w = module.width(data)
                if w >= width then
                    return data
                elseif alignRight then
                    return (" "):rep(width - w) .. data
                else
                    return data .. (" "):rep(width - w)
                end
            end
            showcolumns[#showcolumns + 1] = {
                key = column.key,
                format = format,
                index = i,
            }
            titles[i] = column.title
        end
    end
    if showtitle then
        table.insert(showlist, 1, titles)
    end
    local showtb = {}
    local itemtb = {}
    for idx, item in ipairs(showlist) do
        for i, column in pairs(showcolumns) do
            local val = item[column.index] or ""
            local showval = column.format(val)
            itemtb[i] = showval
        end
        showtb[idx] = table.concat(itemtb, columnsep)
    end
    local content = table.concat(showtb, "\n")
    return content
end

function module.width(s, w1, w2, w3, w4)
    w1 = w1 or 1
    w2 = w2 or 1
    w3 = w3 or 2
    w4 = w4 or 2
    local n = string.len(s)
    local n1, n2, n3, n4 = 0, 0, 0, 0
    local i, c = 1, nil
    while i <= n do
        c = string.byte(s, i)
        if math.floor(c / 2 ^ 7) % 2 == 1 then
            if math.floor(c / 2 ^ 6) % 2 == 1 then
                if math.floor(c / 2 ^ 5) % 2 == 1 then
                    if math.floor(c / 2 ^ 4) % 2 == 1 then
                        --- 4 bit
                        n4 = n4 + 1
                        i = i + 4
                    else
                        --- 3 bit
                        n3 = n3 + 1
                        i = i + 3
                    end
                else
                    --- 2 bit
                    n2 = n2 + 1
                    i = i + 2
                end
            else
                --- error
                error("bad string")
            end
        else
            --- 1 bit
            n1 = n1 + 1
            i = i + 1
        end
    end
    local width = n1 * w1 + n2 * w2 + n3 * w3 + n4 * w4
    return width
end

-- # WRAP_MODULE
local function module_initializer()
    -- # STATIC_CONFIG_INIT

    -- # CONTEXT_VALUE_INIT

    -- # MODULE_EXPORT

    ---@class tabler @show data as pretty string table
    module.__proto.defines = module.defines
    module.__proto.show = module.show
    return module.__proto
end

return module_initializer()
