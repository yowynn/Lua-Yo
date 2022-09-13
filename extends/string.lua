local module = {}

function module.split(str, sep)
    local index = 0
    local p = 1
    return function()
        if p > #str then
            return
        end
        local p1, p2 = str:find(sep, p, true)
        if p1 then
            local item = str:sub(p, p1 - 1)
            index = index + 1
            p = p2 + 1
            return index, item
        else
            local item = str:sub(p)
            index = index + 1
            p = #str + 1
            return index, item
        end
    end
end

--- 从HTML文本中获取纯文本
---@param s string 给定字符串
---@return string 剔除HTML标签后的字符串
function module.plaintext(s)
    local str = string.gsub(s, "<.->", "")
    return str
end

--- 返回给定utf-8字符串的视觉宽度
---@param s string 给定字符串
---@param w1 number 占1字节字符视觉宽度, 默认为1 (数字字母一般在此)
---@param w2 number 占2字节字符视觉宽度, 默认为1
---@param w3 number 占3字节字符视觉宽度, 默认为2 (汉字一般在此)
---@param w4 number 占4字节字符视觉宽度, 默认为2
---@return number 字符串视觉宽度
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


local function module_initializer(filterK)
    for k, v in pairs(module) do
        if filterK(k) then
            if not string[k] then
                string[k] = v
            end
        end
    end
    return string
end

return module_initializer(function(k)
    return k:sub(1, 1) ~= "_"
end)
