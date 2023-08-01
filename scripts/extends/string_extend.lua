--- extend string module
---@author: Wynn Yo 2023-08-01 11:34:34
local M = {}

-- # REFERENCES:

-- # USAGE:
--[[ -----------------------------------------------------------
-- TODO: WRITE USAGE HERE
--]] -----------------------------------------------------------

-- # CONFIGS:

-- # DEPENDENCIES:
-- TODO: ASSERT DEPENDENCIES HERE

-- # CONSTANTS_DEFINITION:

-- # PRIVATE_DEFINITION:

-- # MODULE_DEFINITION:

--- split string by separator
---@param s string @the string to split
---@param sep string @the separator
---@return fun(): number, string @iterator, returns the index and split item
function M.split(s, sep)
    local index = 0
    local p = 1
    return function()
        if p > #s then
            return
        end
        local p1, p2 = s:find(sep, p, true)
        if p1 then
            local item = s:sub(p, p1 - 1)
            index = index + 1
            p = p2 + 1
            return index, item
        else
            local item = s:sub(p)
            index = index + 1
            p = #s + 1
            return index, item
        end
    end
end

--- get plain text from html text
---@param s string @the string to get plain text
---@return string @the plain text
function M.plaintext(s)
    local str = string.gsub(s, "<.->", "")
    return str
end

--- get visual width of utf-8 string
---@param s string @the string to get visual width
---@param w1 number @visual width of 1 byte character, default is 1 (number and letter are usually here)
---@param w2 number @visual width of 2 byte character, default is 1
---@param w3 number @visual width of 3 byte character, default is 2 (chinese character is usually here)
---@param w4 number @visual width of 4 byte character, default is 2
---@return number @the visual width of utf-8 string
function module.vlen_utf8(s, w1, w2, w3, w4)
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


-- # MODULE_EXPORT:

return M
