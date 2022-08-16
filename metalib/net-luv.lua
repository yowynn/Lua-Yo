#!/usr/bin/env lua5.4

--- the net module (via luv)
---@author: Wynn Yo 2022-08-12 19:01:08
---@usage:
--[[ --
    local net = require("net")
    local mode = "client" or "server"
    if mode == "client" then
        -- #client side:
        local client = net.connect("127.0.0.1", 1234, function(client)
            print("net conncet", client:getPeerInfo().host)
            client:onRecv(function(client, message)
                print("client receive: " .. message)
            end)
            client:send("client send: hello")
        end, function(client, reason)
            print("net close: " .. reason)
        end)
    elseif mode == "server" then
        -- #server side:
        local server = net.listen("0.0.0.0", 1234, function(client)
            print("net conncet", client:getPeerInfo().host)
            client:onRecv(function(client, message)
                print("server receive: " .. message)
                client:send("server send: " .. message)
            end)
        end, function(client, reason)
            print("net close: " .. reason)
        end)
    end
    while true do
        net.update()
    end
--]] --
---@dependencies
local luv = require("luv") -- @https://github.com/luvit/luv
local assert = assert
local pairs = pairs
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local xpcall = xpcall
local coroutine = coroutine
local debug_traceback = debug.traceback
local math_floor = math.floor
local os_time = os.time
local string_char = string.char

---@class net
local module = {}

--- default backlog
module.DEFAULT_BACKLOG = nil

--- map to hold server objects
module._server_objects = nil

--- map to hold client objects
module._client_objects = nil

module.__index = nil

function module._new(_stream)
    local self = {}
    self.m_stream = _stream or luv.new_tcp()
    self.m_host = nil
    self.m_port = nil
    self.m_onConnect = nil
    self.m_onClose = nil
    self.m_marks = {}
    self.m_onRecv = nil
    self.m_recvThread = nil
    self.m_createdTime = nil
    self.m_lastAccessTime = nil
    setmetatable(self, module)
    return self
end

--- add custom key-value infomaion to the net object
--- return current value if the value in not present
function module:mark(key, value)
    assert(key, "[net]key is nil")
    if value ~= nil then
        self.m_marks[key] = value
    end
    return self.m_marks[key]
end

--- listen on the given host and port
---@param host string
---@param port number
---@param onConnect fun(client:net) @callback when client connected
---@param onClose fun(client:net, reason:string) @callback when client closed
---@param backlog number @default: module.DEFAULT_BACKLOG
function module.listen(host, port, onConnect, onClose, backlog)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    backlog = backlog or module.DEFAULT_BACKLOG
    local server = module._new()
    server.m_host = host
    server.m_port = port
    server.m_onConnect = onConnect
    server.m_onClose = onClose
    local _stream = server.m_stream
    _stream:bind(host, port)
    local err = _stream:listen(backlog, function(err)
        server.m_lastAccessTime = os_time()
        if err then
            module.close(server, "[net]accept failed: " .. tostring(err))
            return
        end
        local client = module._new()
        _stream:accept(client.m_stream)
        local peerInfo = client:getPeerInfo()
        client.m_host = peerInfo.host
        client.m_port = peerInfo.port
        client.m_onConnect = server.m_onConnect
        client.m_onClose = server.m_onClose
        module._onConnect(client)
    end)
    if err ~= 0 then
        module.close(server, "[net]listen failed: " .. tostring(err))
        return nil
    else
        return module._onListen(server)
    end
end

--- connect to the given host and port
---@param host string
---@param port number
---@param onConnect fun(client:net) @callback when client connected
---@param onClose fun(client:net, reason:string) @callback when client closed
function module.connect(host, port, onConnect, onClose)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    local client = module._new()
    client.m_host = host
    client.m_port = port
    client.m_onConnect = onConnect
    client.m_onClose = onClose
    local _stream = client.m_stream
    _stream:connect(host, port, function(err)
        if err then
            module.close(client, "[net]connect failed: " .. tostring(err))
            return
        end
        module._onConnect(client)
    end)
    return client
end

function module:_onListen()
    module._server_objects[self] = true
    self.m_createdTime = os_time()
    self.m_lastAccessTime = self.m_createdTime
    return self
end

function module:_onConnect()
    module._client_objects[self] = true
    self.m_createdTime = os_time()
    self.m_lastAccessTime = self.m_createdTime
    if self.m_onConnect then
        local ok, err = xpcall(self.m_onConnect, debug_traceback, self)
        if not ok then
            module.close(self, "[net]execute onConnect failed: " .. tostring(err))
            return
        end
    end
    return self
end

function module:_onReceive(message)
    self.m_lastAccessTime = os_time()
    if self.m_onRecv then
        local ok, err = xpcall(self.m_onRecv, debug_traceback, self, message)
        if not ok then
            module.close(self, "[net]execute onRecv failed: " .. tostring(err))
            return
        end
    end
end

--- return a table of host, port and family infos
function module:getPeerInfo()
    local _stream = self.m_stream
    local peername = _stream:getpeername()
    return {
        host = peername.ip,
        port = peername.port,
        family = peername.family,
    }
end

--- return the create time of the net object
function module:getCreatedTime()
    return self.m_createdTime
end

--- return the last access time of the net object
function module:getLastAccessTime()
    return self.m_lastAccessTime
end

--- need to be called in the main thread
function module.update()
    luv.run("nowait")
end

--- set a handler to handle received message, and begin to receive message
---@param msgHandler fun(target:net, message:string)
function module:onRecv(msgHandler)
    self.m_onRecv = msgHandler
    if msgHandler == false then
        if self.m_recvThread then
            self.m_recvThread = nil
            local _stream = self.m_stream
            if not _stream then
                module.close(self, "[net]bad status (onRecv)")
                return
            end
            _stream:read_stop()
        end
    else
        if not self.m_recvThread then
            self.m_recvThread = coroutine.create(module._recvCoroutine)
            local _stream = self.m_stream
            if not _stream then
                module.close(self, "[net]bad status (onRecv)")
                return
            end
            if not _stream:is_readable() then
                module.close(self, "[net]receive failed: " .. "stream is not readable")
                return
            end
            _stream:read_start(function(err, chunk)
                if err then
                    module.close(self, "[net]receive failed: " .. tostring(err))
                    return
                end
                if chunk then
                    local recvThread = self.m_recvThread
                    if recvThread and coroutine.status(recvThread) ~= "dead" then
                        local ok, err = coroutine.resume(self.m_recvThread, self, chunk)
                        if not ok then
                            module.close(self, "[net]receive coroutine failed: " .. tostring(err))
                            return
                        end
                    end
                else
                    module.close(self, "[net]receive failed: " .. "receive nothing")
                    return
                end
            end)
        end
    end
end

function module:_recvCoroutine(data)
    local _buffer = data
    local _p = 0
    local _recvingLength = nil
    while true do
        local _len = #_buffer - _p
        if _recvingLength == nil then
            if _len >= 4 then
                local _1, _2, _3, _4 = _buffer:byte(_p + 1, _p + 4)
                _recvingLength = _1 * 16777216 + _2 * 65536 + _3 * 256 + _4
                _p = _p + 4
            else
                self, data = coroutine.yield()
                _buffer = _buffer .. data
            end
        else
            if _len >= _recvingLength then
                local message = _buffer:sub(_p + 1, _p + _recvingLength)
                _p = _p + _recvingLength
                _recvingLength = nil
                module._onReceive(self, message)
            else
                self, data = coroutine.yield()
                _buffer = _buffer .. data
            end
        end
        if _p >= #_buffer then
            _buffer = ""
            _p = 0
        end
    end
end

--- send message to the peer
---@param message string
function module:send(message)
    assert(message, "[net]message is nil")
    local _stream = assert(self.m_stream, "[net]bad status (send)")
    assert(_stream:is_writable(), "[net]send failed: " .. "stream is not writable")
    local _sendingLength = #message
    local _1, _2, _3, _4 = math_floor(_sendingLength / 16777216), math_floor(_sendingLength / 65536) % 256,
        math_floor(_sendingLength / 256) % 256, _sendingLength % 256
    local _data = string_char(_1, _2, _3, _4) .. message
    _stream:write(_data)
end

--- close the net object
---@param reason string @witch pass to the onClose callback
function module:close(reason)
    local _stream = self.m_stream
    if _stream then
        self:onRecv(false)
        self.m_stream = nil
        module._client_objects[self] = nil
        module._server_objects[self] = nil
        -- _stream:shutdown()
        _stream:close()
        if self.m_onClose then
            local ok, err = xpcall(self.m_onClose, debug_traceback, self, reason)
            if not ok then
                module.close(self, "[net]execute onClose failed: " .. tostring(err))
            end
        end
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
        getCreatedTime = module.getCreatedTime,
        getLastAccessTime = module.getLastAccessTime,
    }
    --- static methods
    local static = {
        listen = module.listen,
        connect = module.connect,
        update = module.update,
        close = module.close
    }
    return static
end

return module_initializer()
