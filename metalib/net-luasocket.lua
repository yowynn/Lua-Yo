--- net: the net module (via luasocket)
---@author: Wynn Yo 2022-06-24 10:18:31
-- # USAGE
--[[ -----------------------------------------------------------
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
--]] -----------------------------------------------------------
-- # DEPENDENCIES
local module = {}
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
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

-- # STATIC_CONFIG_DEFINITION

--- default backlog
module.DEFAULT_BACKLOG = nil

-- # CONTEXT_VALUE_DEFINITION

--- map to hold server objects
module._server_objects = nil

--- map to hold client objects
module._client_objects = nil

module.__index = nil

-- # METHODS_DEFINITION

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
    local _socket = server.m_socket
    _socket:setoption("reuseaddr", true)
    _socket:bind(host, port)
    local ok, err = _socket:listen(backlog)
    if not ok then
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
    local _socket = client.m_socket
    local ok, err = _socket:connect(host, port)
    if not ok then
        module.close(client, "[net]connect failed: " .. tostring(err))
        return nil
    else
        return module._onConnect(client)
    end
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
            module.close(self, "[net]execute onRecv failed: " .. err)
            return
        end
    end
end

--- return a table of host, port and family infos
function module:getPeerInfo()
    local _socket = self.m_socket
    local host, port, family = _socket:getpeername()
    return {
        host = host,
        port = port,
        family = family,
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
    --- server accept
    for server in pairs(module._server_objects) do
        local _socket = server.m_socket
        local ok, err = _socket:settimeout(0)
        if ok then
            local _accept, err = _socket:accept()
            if _accept then
                server.m_lastAccessTime = os_time()
                local client = module._new(_accept)
                local peerInfo = client:getPeerInfo()
                client.m_host = peerInfo.host
                client.m_port = peerInfo.port
                client.m_onConnect = server.m_onConnect
                client.m_onClose = server.m_onClose
                module._onConnect(client)
            elseif err ~= "timeout" then
                server.m_lastAccessTime = os_time()
                module.close(server, "[net]accept failed: " .. tostring(err))
            end
        else
            module.close(server, "[net]settimeout failed (accept): " .. tostring(err))
        end
    end
    --- client receive
    for client in pairs(module._client_objects) do
        local recvThread = client.m_recvThread
        if recvThread and coroutine.status(recvThread) ~= "dead" then
            local ok, err = coroutine.resume(recvThread, client)
            if not ok then
                module.close(self, "[net]receive coroutine failed: " .. tostring(err))
                return
            end
        end
    end
end

--- set a handler to handle received message, and begin to receive message
---@param msgHandler fun(target:net, message:string)
function module:onRecv(msgHandler)
    self.m_onRecv = msgHandler
    if msgHandler == false then
        if self.m_recvThread then
            self.m_recvThread = nil
        end
    else
        if not self.m_recvThread then
            self.m_recvThread = coroutine.create(module._recvCoroutine)
        end
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
                    local _1, _2, _3, _4 = _data:byte(1, 4)
                    _recvingLength = _1 * 16777216 + _2 * 65536 + _3 * 256 + _4
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    module.close(self, "[net]receive failed: " .. tostring(err))
                    return
                end
            else
                local _data, err = _socket:receive(_recvingLength)
                if _data then
                    _recvingLength = nil
                    module._onReceive(self, _data)
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    module.close(self, "[net]receive failed: " .. tostring(err))
                    return
                end
            end
        else
            module.close(self, "[net]settimeout failed (receive): " .. tostring(err))
            return
        end
    end
end

--- send message to the peer
---@param message string
function module:send(message)
    assert(message, "[net]message is nil")
    local _socket = assert(self.m_socket, "[net]bad status (send)")
    local _sendingLength = #message
    local _1, _2, _3, _4 = math_floor(_sendingLength / 16777216), math_floor(_sendingLength / 65536) % 256,
        math_floor(_sendingLength / 256) % 256, _sendingLength % 256
    local _data = string_char(_1, _2, _3, _4) .. message
    local ok, err = _socket:send(_data)
    if not ok then
        module.close(self, "[net]send failed: " .. tostring(err))
    end
end

--- close the net object
---@param reason string @witch pass to the onClose callback
function module:close(reason)
    local _socket = self.m_socket
    if _socket then
        self:onRecv(false)
        self.m_socket = nil
        module._client_objects[self] = nil
        module._server_objects[self] = nil
        _socket:close()
        if self.m_onClose then
            local ok, err = xpcall(self.m_onClose, debug_traceback, self, reason)
            if not ok then
                module.close(self, "[net]execute onClose failed: " .. tostring(err))
            end
        end
    end
end

-- # WRAP_MODULE

local function module_initializer()
    -- # STATIC_CONFIG_INIT

    --- dafault backlog
    module.DEFAULT_BACKLOG = 128

    -- # CONTEXT_VALUE_INIT

    module._server_objects = {}
    module._client_objects = {}

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

    -- # MODULE_EXPORT

    ---@class net @the net module (via luasocket)
    local net = {
        listen = module.listen,
        connect = module.connect,
        update = module.update,
        close = module.close,
    }
    return net
end

return module_initializer()
