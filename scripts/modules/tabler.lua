--- tabler: show data as pretty string table
---@author: Wynn Yo 2022-09-07 17:57:46
local M = {}

---@class ColumnDefine @column define object
---@field key string @column key
---@field title string @column title, default is the same as `key`
---@field width number @column visual width (one chinese character is 2), default is `nil` (auto)
---@field align "left" | "right" @column align, default is `left`
---@field handler fun(data: any): string @column data handler, default is `tostring`

-- # USAGE
--[[ -----------------------------------------------------------
local tabler = require("tabler")
local data = {
    { name = "Wynn", age = 18, },
    { name = "爱新觉罗·闪电", age = 19, },
}
local columns = {
    { key = "name", title = "名字", width = 20, },
    { key = "age", title = "年龄", width = 50, align = "right", handler = function(val)
        return val .. " years old"
    end, },
}
print(tabler.defines(columns).show(data))
--]] -----------------------------------------------------------

-- # DEPENDENCIES:
assert(error, "`error` not found")
assert(ipairs, "`ipairs` not found")
assert(pairs, "`pairs` not found")
assert(tonumber, "`tonumber` not found")
assert(tostring, "`tostring` not found")
assert(type, "`type` not found")
assert(math.floor, "`math.floor` not found")
assert(math.max, "`math.max` not found")
assert(string.byte, "`string.byte` not found")
assert(string.len, "`string.len` not found")
assert(table.concat, "`table.concat` not found")
assert(table.insert, "`table.insert` not found")

-- # PRIVATE_DEFINITION:

--- current context columns info
M._ctx_columns = nil

-- # MODULE_DEFINITION:

--- check if the table is array
---@param tb table @the table to check
---@return boolean @if the table is array
function M.isArray(tb)
    local i = 1
    for _ in pairs(tb) do
        if tb[i] == nil then
            return false
        end
        i = i + 1
    end
    return true
end

--- get the visual width of utf8 string
---@param s string @the string to check
---@param w1 number @the width of 1 bit utf8 char, default is `1`
---@param w2 number @the width of 2 bit utf8 char, default is `1`
---@param w3 number @the width of 3 bit utf8 char, default is `2`
---@param w4 number @the width of 4 bit utf8 char, default is `2`
---@return number @the visual width of utf8 string
function M.width(s, w1, w2, w3, w4)
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

--- define a column
---@param key string @the column key to be defined
---@param override ColumnDefine | table @the override column define config
---@return ColumnDefine @the column define object
function M._define(key, override)
    local column = {}
    override = override or column
    column.key = key
    column.title = tostring(override.title) or tostring(key)
    column.width = tonumber(override.width) or nil
    column.align = override.align == "right" and "right" or "left"
    column.handler = override.handler or tostring
    return column
end

--- define columns
---@param defineList ColumnDefine[] | string[] @the column define list, if string, will use default config
---@return table @module self to support chain call
function M.defines(defineList)
    local columns = {}
    for i, v in ipairs(defineList) do
        local column
        if type(v) == "table" then
            column = M._define(v.key, v)
        else
            column = M._define(v, nil)
        end
        columns[#columns + 1] = column
    end
    M._ctx_columns = columns
    return M.__proto
end

--- show data as pretty string table
---@param list table[] @the data list to show
---@return string @the pretty string table
function M.show(list)
    local showtitle = true
    local columnsep = "  "
    local widths = {}
    local showlist = {}
    local xpairs = M.isArray(list) and ipairs or pairs
    for idx, item in xpairs(list) do
        local showitem = {}
        showlist[#showlist + 1] = showitem
        for i, column in pairs(M._ctx_columns) do
            local key = column.key
            local val = item[key]
            if column.handler then
                val = column.handler(val, item, key)
            else
                val = val == nil and "" or tostring(val)
            end
            if val then
                local width = M.width(val)
                widths[i] = math.max(widths[i] or showtitle and M.width(column.title) or 0, width)
                showitem[i] = val
            end
        end
    end
    local showcolumns = {}
    local titles = {}
    for i, column in pairs(M._ctx_columns) do
        local width = widths[i]
        if width then
            width = column.width or width
            local alignRight = column.align == "right"
            local format = function(data)
                local w = M.width(data)
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

-- # MODULE_EXPORT:

M.__proto = {
    defines = M.defines,
    show = M.show,
}

return M.__proto
