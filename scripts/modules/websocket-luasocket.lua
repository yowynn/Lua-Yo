--- lua websockets module (via luasocket)
---@author: Wynn Yo 2023-05-30 16:31:34
local M = {}

-- # REFERENCES:

-- https://github.com/openresty/lua-resty-websocket/blob/master/lib/resty/websocket/client.lua
-- https://github.com/cloudwu/skynet/blob/master/lualib/http/websocket.lua
-- https://zhuanlan.zhihu.com/p/556813075

-- # USAGE:
--[[ -----------------------------------------------------------
local websocket = require("websocket")
local client, err = websocket.connect("ws://localhost/www/chat.lua", function(peer)
    print("connect:", peer)
    peer:onRecv(function(data, opcode)
        print("recv:", data, opcode)
    end)
    peer:send("hello from lua websocket我爱你中国")
end, function(peer, reason)
    print("close:", reason)
end)
if not client then
    print("connect failed:", err)
    return
end
while true do
    websocket.update()
end
-- client:close("bye")
--]] -----------------------------------------------------------

-- # DEPENDENCIES:
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
assert(error, "`error` not found")
assert(pairs, "`pairs` not found")
assert(print, "`print` not found")
assert(require, "`require` not found")
assert(setmetatable, "`setmetatable` not found")
assert(tonumber, "`tonumber` not found")
assert(tostring, "`tostring` not found")
assert(xpcall, "`xpcall` not found")
assert(coroutine.create, "`coroutine.create` not found")
assert(coroutine.resume, "`coroutine.resume` not found")
assert(coroutine.status, "`coroutine.status` not found")
assert(coroutine.yield, "`coroutine.yield` not found")
assert(debug.traceback, "`debug.traceback` not found")
assert(math.random, "`math.random` not found")
assert(string.char, "`string.char` not found")
assert(string.format, "`string.format` not found")
assert(string.lower, "`string.lower` not found")
assert(string.match, "`string.match` not found")
assert(string.pack, "`string.pack` not found")
assert(string.unpack, "`string.unpack` not found")

-- # CONSTANTS_DEFINITION:
local _BASE64_ENCODE_MAP = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- # PRIVATE_DEFINITION:

--- the client object set
local _client_objects = setmetatable({}, {__mode = "k"})

--- the server object set
local _server_objects = setmetatable({}, {__mode = "k"})

-- # MODULE_DEFINITION:

--- base64 encode
function M._base64_encode(data)
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
        return _BASE64_ENCODE_MAP:sub(c + 1, c + 1)
    end) .. ({"", "==", "="})[#data % 3 + 1])
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
    local ok, err = _socket:settimeout(0)
    if not ok then
        return nil, "set socket timeout failed: " .. err
    end
    return M._onConnectInternal(client)
end

function M:_onConnectInternal()
    _client_objects[self] = true
    self.m_createdTime = socket.gettime()
    self.m_lastAccessTime = self.m_createdTime
    if self.m_onConnect then
        local ok, err = xpcall(self.m_onConnect, debug.traceback, self)
        if not ok then
            error("websocket connect callback error: " .. tostring(err))
        end
    end
    return self
end

--- send message
---@param message string @message to send
---@param opcode number @the opcode, 1 for text, 2 for binary, 9 for ping, 10 for pong, default is 1
function M:send(message, opcode, mask)
    opcode = opcode or 1
    local fin = true
    local payloadLen = #message
    local payload = message
    local payloadLenBase, payloadLenExt = 0, ""
    local maskKey = ""
    if payloadLen < 126 then
        payloadLenBase = payloadLen
        payloadLenExt = ""
    elseif payloadLen <= 0xFFFF then
        payloadLenBase = 126
        payloadLenExt = string.pack(">I2", payloadLen)
    elseif payloadLen <= 0x7FFFFFFF then
        payloadLenBase = 127
        payloadLenExt = string.pack(">I8", payloadLen)
    else
        return nil, "message too long"
    end
    if mask then
        maskKey = string.char(
            math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255)
        )
        payload = payload:gsub(".", function(c)
            return string.char(c:byte() ~ maskKey:byte((#maskKey % 4) + 1))
        end)
    end
    local frame = string.char(
        (fin and 0x80 or 0) + opcode,
        (mask and 0x80 or 0) + payloadLenBase
    ) .. payloadLenExt .. maskKey .. payload
    local ok, err = self.m_socket:send(frame)
    return ok, err
end

function M:onRecv(msgHandler)
    self.m_onRecv = msgHandler
    if msgHandler == false then
        if self.m_recvThread then
            self.m_recvThread = nil
        end
    else
        if not self.m_recvThread then
            self.m_recvThread = coroutine.create(M._recvCoroutine)
        end
    end
end

function M:_onReceiveInternal(data, opcode)
    self.m_lastAccessTime = socket.gettime()
    if self.m_onRecv then
        self.m_onRecv(data, opcode)
    end
end

function M:_recvCoroutine()
    local fin = true
    local rsv = 0
    local opcode = nil
    local mask = false
    local payloadLen = nil
    local maskKey = ""
    local _nextlen = 2
    local _nextop = "head"
    while true do
        local _socket = self.m_socket
        local _data, err = _socket:receive(_nextlen)
        if _data then
            if _nextop == "head" then
                local _1, _2 = _data:byte(1, 2)
                fin = _1 & 0x80 ~= 0
                rsv = _1 & 0x70
                opcode = _1 & 0x0F
                mask = _2 & 0x80 ~= 0
                payloadLen = _2 & 0x7F
                _nextlen = mask and 4 or 0          -- mask fragment
                if payloadLen == 126 then
                    _nextlen = _nextlen + 2
                elseif payloadLen == 127 then
                    _nextlen = _nextlen + 8
                end
                if rsv ~= 0 then
                    self:close("recving invalid rsv: " .. tostring(rsv))
                    return
                elseif not fin then
                    self:close("TODO: recving not support fragmented message")
                    return
                elseif opcode >= 0x3 and opcode <= 0x7 then
                    self:close("recving reserved opcode: " .. tostring(opcode))
                    return
                elseif opcode >= 0xB and opcode <= 0xF then
                    self:close("recving reserved opcode: " .. tostring(opcode))
                    return
                end
                if _nextlen > 0 then
                    _nextop = "head-ext"
                else
                    _nextlen = payloadLen
                    _nextop = "payload"
                end
            elseif _nextop == "head-ext" then
                if payloadLen == 126 then
                    payloadLen = string.unpack(">I2", _data)
                elseif payloadLen == 127 then
                    payloadLen = string.unpack(">I8", _data)
                end
                if mask then
                    maskKey = _data:sub(-4)
                else
                    maskKey = ""
                end
                _nextlen = payloadLen
                _nextop = "payload"
            elseif _nextop == "payload" then
                if mask then
                    _data = _data:gsub(".", function(c)
                        return string.char(c:byte() ~ maskKey:byte((#maskKey % 4) + 1))
                    end)
                end
                if opcode == 0x8 then
                    if _nextlen < 2 then
                        self:close("recving invalid close frame")
                        return
                    end
                    local len = #_data - 2
                    local code, reason = string.unpack(">I2c" .. len, _data)
                    M._onCloseInternal(self, tostring(code) .. " " .. tostring(reason))
                    return
                elseif opcode == 0x9 then
                    -- TODO: ping
                elseif opcode == 0xA then
                    -- TODO: pong
                elseif opcode >= 0x0 and opcode <= 0x2 then
                    M._onReceiveInternal(self, _data, opcode)
                else
                    self:close("recving invalid opcode: " .. tostring(opcode))
                    return
                end
                _nextlen = 2
                _nextop = "head"
            end
        elseif err == "timeout" then
            coroutine.yield()
        else
            self:close("receive error while recving: " .. tostring(err))
            return
        end
    end
end

--- close the websocket
---@param reason string @the reason to close
---@param opcode number @the opcode, 1000 for normal, 1001 for going away, 1002 for protocol error, 1003 for unsupported data, 1005 for no status, 1006 for abnormal close, 1007 for invalid payload, 1008 for policy violation, 1009 for message too big, 1010 for extension required, 1011 for internal server error, 1012 for service restart, 1013 for try again later, 1014 for bad gateway, 1015 for TLS handshake
function M:close(reason, opcode)
    if self.m_socket then
        opcode = opcode or 1000
        reason = reason or ""
        local len = #reason
        self:send(string.pack(">I2c" .. tostring(len), opcode, reason))
        M._onCloseInternal(self, opcode .. " " .. reason)
    end
end

function M:_onCloseInternal(reason)
    _client_objects[self] = nil
    _server_objects[self] = nil
    self:onRecv(false)
    self.m_socket:close()
    self.m_socket = nil
    if self.m_onClose then
        local ok, err = xpcall(self.m_onClose, debug.traceback, self, reason)
        if not ok then
            error("websocket close callback error: " .. tostring(err))
        end
    end
end

--- update the websocket loop
function M.update()
    --- client receive
    for client in pairs(_client_objects) do
        local recvThread = client.m_recvThread
        if recvThread and coroutine.status(recvThread) ~= "dead" then
            local ok, err = coroutine.resume(recvThread, client)
            if not ok then
                M:close(self, "[net]receive coroutine failed: " .. tostring(err))
                return
            end
        end
    end
end

-- # MODULE_EXPORT:

M.__index = {
    send = M.send,
    onRecv = M.onRecv,
    close = M.close,
}

M.__proto = {
    connect = M.connect,
    update = M.update,
}

return M.__proto
