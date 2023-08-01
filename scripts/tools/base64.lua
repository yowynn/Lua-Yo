--- base64: base64 encoding and decoding with Lua
---@author: Alex Kloss <alexthkloss@web.de> 2009
--- licensed under the terms of the LGPL2
local M = {}

-- # USAGE:
--[[ -----------------------------------------------------------
lua base64.lua [-e] [-d] text/data
--]] -----------------------------------------------------------

-- # CONFIGS:

--- use as command line tool
local USE_AS_CLI = true

-- # DEPENDENCIES:
assert(_VERSION >= "Lua 5.1", "Lua version >= 5.1 required")
assert(ipairs, "`ipairs` not found")
assert(print, "`print` not found")
assert(string.byte, "`string.byte` not found")
assert(string.char, "`string.char` not found")
assert(string.find, "`string.find` not found")
assert(string.gsub, "`string.gsub` not found")
assert(string.sub, "`string.sub` not found")

-- # CONSTANTS_DEFINITION:

--- character table string
local _BASE64_ENCODE_MAP = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- # PRIVATE_DEFINITION:

local _base64_encode_repl1 = function(x)
    local r, b = "", string.byte(x)
    for i = 8, 1, -1 do
        r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
    end
    return r;
end

local _base64_encode_repl2 = function(x)
    if #x < 6 then
        return ""
    end
    local c = 0
    for i = 1, 6 do
        c = c + (string.sub(x, i, i) == "1" and 2 ^ (6 - i) or 0)
    end
    return string.sub(_BASE64_ENCODE_MAP, c + 1, c + 1)
end

local _base64_decode_repl1 = function(x)
    if x == "=" then
        return ""
    end
    local r, f = "", string.find(_BASE64_ENCODE_MAP, x) - 1
    for i = 6, 1, -1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
    end
    return r;
end

local _base64_decode_repl2 = function(x)
    if #x ~= 8 then
        return ""
    end
    local c = 0
    for i = 1, 8 do
        c = c + (string.sub(x, i, i) == "1" and 2 ^ (8 - i) or 0)
    end
    return string.char(c)
end

-- # MODULE_DEFINITION:

--- encode data to base64 string
---@param data string @the data to encode
---@return string @the base64 string
function M.encode(data)
    data = string.gsub(data, ".", _base64_encode_repl1)
    data = data .. "0000"
    data = string.gsub(data, "%d%d%d?%d?%d?%d?", _base64_encode_repl2)
    data = data .. ({"", "==", "="})[#data % 3 + 1]
    return data
end

--- decode base64 string to data
---@param data string @the base64 string to decode
---@return string @the data
function M.decode(data)
    data = string.gsub(data, "[^" .. _BASE64_ENCODE_MAP .. "=]", "")
    data = string.gsub(data, ".", _base64_decode_repl1)
    data = string.gsub(data, "%d%d%d?%d?%d?%d?%d?%d?", _base64_decode_repl2)
    return data
end

-- # MODULE_EXPORT:

if USE_AS_CLI and arg then
    local func = M.encode
    for n, v in ipairs(arg) do
        if n > 0 then
            if v == "-h" then
                print("base64.lua [-e] [-d] text/data")
                break
            elseif v == "-e" then
                func = M.encode
            elseif v == "-d" then
                func = M.decode
            else
                print(func(v))
            end
        end
    end
else
    return M
end
