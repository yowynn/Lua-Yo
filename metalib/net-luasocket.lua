#!/usr/bin/env lua5.4

--- the net module (via luasocket)
---@author: Wynn Yo 2022-06-24 10:18:31
---@usage:
--[[
    local net = require "net"
    -- #server side:
    local server = net.listen("0.0.0.0", 1234, function(client)
        print("net conncet", client:getPeerInfo().host)
        client:onRecv(function(client, message)
            print("server receive: " .. message)
            client:send("server send: " .. message)
        end, function(client, reason)
            print("net close: " .. reason)
        end)
    end)

    -- #client side:
    local client = net.connect("127.0.0.1", 1234, function(client)
        print("net conncet", client:getPeerInfo().host)
        client:onRecv(function(client, message)
            print("client receive: " .. message)
        end, function(client, reason)
            print("net close: " .. reason)
        end)
        client:send("client send: hello")
    end)
--]]

---@dependencies
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
local assert = assert
local pairs = pairs
local setmetatable = setmetatable
local tonumber = tonumber
local xpcall = xpcall
local coroutine = coroutine
local debug_traceback = debug.traceback
local math_floor = math.floor
local string_char = string.char

---@class net
local module = {}
module.DEFAULT_BACKLOG = nil
module._server_objects = nil
module._client_objects = nil
module.__index = nil

function module._new(_socket)
    local self = {}
    self.m_socket = _socket or (socket.tcp or socket.tcp4)()
    self.m_host = nil
    self.m_port = nil
    self.m_onConnect = nil
    self.m_onClose = nil
    self.m_marks = {}
    self.m_onRecv = nil
    self.m_recvThread = nil
    setmetatable(self, module)
    return self
end

function module:mark(key, value)
    assert(key, "[net]key is nil")
    if value ~= nil then
        self.m_marks[key] = value
    end
    return self.m_marks[key]
end

function module.listen(host, port, onConnect, onClose, backlog)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    backlog = backlog or module.DEFAULT_BACKLOG
    local server = module._new()
    server.m_host = host
    server.m_port = port
    server.m_onConnect = onConnect
    server.m_onClose = onClose
    local _socket = server.m_socket
    _socket:setoption("reuseaddr", true)
    _socket:bind(host, port)
    local ok, err = _socket:listen(backlog)
    if not ok then
        module.close(server, "[net]listen failed: " .. err)
        return nil
    else
        return module._onListen(server)
    end
end

function module.connect(host, port, onConnect, onClose)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    local client = module._new()
    client.m_host = host
    client.m_port = port
    client.m_onConnect = onConnect
    client.m_onClose = onClose
    local _socket = client.m_socket
    local ok, err = _socket:connect(host, port)
    if not ok then
        module.close(client, "[net]connect failed: " .. err)
        return nil
    else
        return module._onConnect(client)
    end
end

function module:_onListen()
    module._server_objects[self] = true
    return self
end

function module:_onConnect()
    module._client_objects[self] = true
    if self.m_onConnect then
        local ok, err = xpcall(self.m_onConnect, debug_traceback, self)
        if not ok then
            module.close(self, "[net]execute onConnect failed: " .. err)
            return
        end
    end
    return self
end

function module:getPeerInfo()
    local _socket = self.m_socket
    local host, port, family = _socket:getpeername()
    return {
        host = host,
        port = port,
        family = family,
    }
end

function module.update()
    --- server accept
    for server in pairs(module._server_objects) do
        local _socket = server.m_socket
        local ok, err = _socket:settimeout(0)
        if ok then
            local _accept, err = _socket:accept()
            if _accept then
                local client = module._new(_accept)
                local peerInfo = client:getPeerInfo()
                client.m_host = peerInfo.host
                client.m_port = peerInfo.port
                client.m_onConnect = server.m_onConnect
                client.m_onClose = server.m_onClose
                module._onConnect(client)
            elseif err ~= "timeout" then
                module.close(server, "[net]accept failed: " .. err)
            end
        else
            module.close(server, "[net]settimeout failed (accept): " .. err)
        end
    end
    --- client receive
    for client in pairs(module._client_objects) do
        local recvThread = client.m_recvThread
        if recvThread then
            coroutine.resume(recvThread, client)
        end
    end
end

function module:onRecv(msgHandler)
    self.m_onRecv = msgHandler
    if self.m_recvThread then
        self.m_recvThread = coroutine.create(module._recvCoroutine)
    end
end

function module:_recvCoroutine()
    local _recvingLength = nil
    while true do
        local _socket = self.m_socket
        local ok, err = _socket:settimeout(0)
        if ok then
            if _recvingLength == nil then
                local _data, err = _socket:receive(4)
                if _data then
                    local _1, _2, _3, _4 = _data:byte(_data, 1, 4)
                    _recvingLength = _1 * 16777216 + _2 * 65536 + _3 * 256 + _4
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    module.close(self, "[net]receive failed (length): " .. err)
                    return
                end
            else
                local _data, err = _socket:receive(_recvingLength)
                if _data then
                    _recvingLength = nil
                    if self.m_onRecv then
                        local ok, err = xpcall(self.m_onRecv, debug_traceback, self, _data)
                        if not ok then
                            module.close(self, "[net]execute onRecv failed: " .. err)
                            return
                        end
                    end
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    module.close(self, "[net]receive failed (data): " .. err)
                    return
                end
            end
        else
            module.close(self, "[net]settimeout failed (receive): " .. err)
            break
        end
    end
end

function module:send(message)
    assert(message, "[net]message is nil")
    local _socket = assert(self.m_socket, "[net]bad status (send)")
    local _sendingLength = #message
    local _1, _2, _3, _4 = math_floor(_sendingLength / 16777216), math_floor(_sendingLength / 65536) % 256,
        math_floor(_sendingLength / 256) % 256, _sendingLength % 256
    local _data = string_char(_1, _2, _3, _4) .. message
    local ok, err = _socket:send(_data)
    if not ok then
        module.close(self, "[net]send failed: " .. err)
    end
end

function module:close(reason)
    local _socket = self.m_socket
    if _socket then
        if self.m_onClose then
            local ok, err = xpcall(self.m_onClose, debug_traceback, self, reason)
            if not ok then
                module.close(self, "[net]execute onClose failed: " .. err)
            end
        end
        self.m_socket = nil
        self.m_recvThread = nil
        module._client_objects[self] = nil
        module._server_objects[self] = nil
        _socket:close()
    end
end

local function module_initializer()
    module._server_objects = {}
    module._client_objects = {}
    --- dafault backlog
    module.DEFAULT_BACKLOG = 128
    --- instance methods
    module.__index = {
        mark = module.mark,
        onRecv = module.onRecv,
        send = module.send,
        close = module.close,
        getPeerInfo = module.getPeerInfo,
    }
    --- static methods
    local static = {
        listen = module.listen,
        connect = module.connect,
        update = module.update,
        close = module.close,
    }
    return static
end

return module_initializer()
