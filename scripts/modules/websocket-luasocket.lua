--- lua websockets module (via luasocket)
---@author: Wynn Yo 2023-05-30 16:31:34

-- # REFERENCE PROJECTS
-- https://github.com/openresty/lua-resty-websocket/blob/master/lib/resty/websocket/client.lua
-- https://github.com/cloudwu/skynet/blob/master/lualib/http/websocket.lua
-- https://zhuanlan.zhihu.com/p/556813075

-- # DEPENDENCIES
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/

-- # STATIC CONFIG DEFINITION

-- # CONTEXT VALUE DEFINITION

-- # MODULE DEFINITION

local M = {}

--- base64 encode
do
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function encode(data)
        return ((data:gsub(".", function(x)
            local r, b = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r;
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if (#x < 6) then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end) .. ({"", "==", "="})[#data % 3 + 1])
    end
    M._base64_encode = encode
end

function M._new(_socket)
    local self, err = {}
    if not _socket then
        _socket, err = (socket.tcp or socket.tcp4)()
        if not _socket then
            return nil, err
        end
    end
    self.m_socket = _socket
    self.m_protocol = nil
    self.m_host = nil
    self.m_port = nil
    self.m_uri = nil
    self.m_onConnect = nil
    self.m_onClose = nil
    self.m_marks = {}
    self.m_onRecv = nil
    self.m_recvThread = nil
    self.m_createdTime = nil
    self.m_lastAccessTime = nil
    setmetatable(self, M)
    return self
end


--- connect to a websocket server
---@param url string @websocket server url
---@param onConnect fun(client:net) @callback when client connected
---@param onClose fun(client:net, reason:string) @callback when client closed
function M.connect(url, onConnect, onClose)
    -- parse url
    local protocol, host, port, uri = string.match(url, "^([Ww][Ss][Ss]?)://([^:/]+):?(%d*)(/?[^#]*)")
    if not protocol then
        return nil, "invalid url"
    else
        protocol = string.lower(protocol)
    end
    if port == "" then
        port = protocol == "wss" and 443 or 80
    else
        port = tonumber(port)
    end
    if uri == "" then
        uri = "/"
    end

    -- connect
    local client, err = M._new()
    if not client then
        return nil, "new client failed: " .. err
    end
    client.m_protocol = protocol
    client.m_host = host
    client.m_port = port
    client.m_uri = uri
    client.m_onConnect = onConnect
    client.m_onClose = onClose
    local _socket = client.m_socket
    local ok, err = _socket:connect(host, port)
    if not ok then
        return nil, "connect failed: " .. err
    end

    -- ssl handshake
    if protocol == "wss" then
        -- TODO ssl handshake
    end

    -- send handshake
    local key = M._base64_encode(string.char(
        math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255),
        math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255),
        math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255),
        math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255)
    ))
    local handshake = string.format(
        "GET %s HTTP/1.1\r\n" ..
        "Host: %s:%d\r\n" ..
        "Upgrade: websocket\r\n" ..
        "Connection: Upgrade\r\n" ..
        "Sec-WebSocket-Key: %s\r\n" ..
        "Sec-WebSocket-Version: 13\r\n" ..
        "\r\n",
        uri, host, port, key)
    local ok, err = _socket:send(handshake)
    if not ok then
        return nil, "send handshake failed: " .. err
    end
    -- receive handshake response
    local responseStatus, err = _socket:receive("*l")
    if not responseStatus then
        return nil, "receive handshake failed: " .. err
    end
    while true do
        local line, err = _socket:receive("*l")
        if not line then
            return nil, "receive handshake failed: " .. err
        end
        if line == "" then
            break
        end
    end
    local statusCode, reason = string.match(responseStatus, "^HTTP/1%.1 (%d+) (.+)$")
    if statusCode ~= "101" then -- 101 Switching Protocols
        return nil, "handshake failed: " .. (reason or "invalid handshake response")
    end
    return client
end




-- test

-- local client, err = M.connect("wss://api.ihuman.cc/dev/chat")
local client, err = M.connect("ws://localhost/www/chat.lua")

print(client, err)
