--- net: the net module (via luasocket)
---@author: Wynn Yo 2022-06-24 10:18:31
local M = {}

-- # USAGE:
--[[ -----------------------------------------------------------
local net = require("net")
local mode = "client" or "server"
if mode == "client" then
    -- #client side:
    local client = net.connect("127.0.0.1", 54188, function(client)
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
    local server = net.listen("0.0.0.0", 54188, function(client)
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

-- # DEPENDENCIES:
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
assert(assert, "`assert` not found")
assert(pairs, "`pairs` not found")
assert(setmetatable, "`setmetatable` not found")
assert(tonumber, "`tonumber` not found")
assert(tostring, "`tostring` not found")
assert(xpcall, "`xpcall` not found")
assert(coroutine.create, "`coroutine.create` not found")
assert(coroutine.resume, "`coroutine.resume` not found")
assert(coroutine.status, "`coroutine.status` not found")
assert(coroutine.yield, "`coroutine.yield` not found")
assert(debug.traceback, "`debug.traceback` not found")
assert(math.floor, "`math.floor` not found")
assert(os.time, "`os.time` not found")
assert(string.byte, "`string.byte` not found")
assert(string.char, "`string.char` not found")

-- # CONSTANTS_DEFINITION:

--- default backlog
M.DEFAULT_BACKLOG = 128

-- # PRIVATE_DEFINITION:

--- map to hold server objects
M._server_objects = {}

--- map to hold client objects
M._client_objects = {}

-- # MODULE_DEFINITION:

function M._new(_stream)
    local self = {}
    self.m_stream = _stream or (socket.tcp or socket.tcp4)()
    self.m_host = nil
    self.m_port = nil
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

--- add custom key-value infomaion to the net object
--- return current value if the value in not present
function M:mark(key, value)
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
function M.listen(host, port, onConnect, onClose, backlog)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    backlog = backlog or M.DEFAULT_BACKLOG
    local server = M._new()
    server.m_host = host
    server.m_port = port
    server.m_onConnect = onConnect
    server.m_onClose = onClose
    local _stream = server.m_stream
    _stream:bind(host, port)
    _stream:setoption("reuseaddr", true)
    local ok, err = _stream:listen(backlog)
    if not ok then
        M.close(server, "[net]listen failed: " .. tostring(err))
        return nil
    else
        return M._onListen(server)
    end
end

--- connect to the given host and port
---@param host string
---@param port number
---@param onConnect fun(client:net) @callback when client connected
---@param onClose fun(client:net, reason:string) @callback when client closed
function M.connect(host, port, onConnect, onClose)
    assert(host, "[net]host is nil")
    assert(tonumber(port), "[net]port is nil")
    local client = M._new()
    client.m_host = host
    client.m_port = port
    client.m_onConnect = onConnect
    client.m_onClose = onClose
    local _stream = client.m_stream
    local ok, err = _stream:connect(host, port)
    if not ok then
        M.close(client, "[net]connect failed: " .. tostring(err))
        return nil
    else
        return M._onConnect(client)
    end
end

function M:_onListen()
    M._server_objects[self] = true
    self.m_createdTime = os.time()
    self.m_lastAccessTime = self.m_createdTime
    return self
end

function M:_onConnect()
    M._client_objects[self] = true
    self.m_createdTime = os.time()
    self.m_lastAccessTime = self.m_createdTime
    if self.m_onConnect then
        local ok, err = xpcall(self.m_onConnect, debug.traceback, self)
        if not ok then
            M.close(self, "[net]execute onConnect failed: " .. tostring(err))
            return
        end
    end
    return self
end

function M:_onReceive(message)
    self.m_lastAccessTime = os.time()
    if self.m_onRecv then
        local ok, err = xpcall(self.m_onRecv, debug.traceback, self, message)
        if not ok then
            M.close(self, "[net]execute onRecv failed: " .. err)
            return
        end
    end
end

--- return a table of host, port and family infos
function M:getPeerInfo()
    local _stream = self.m_stream
    local host, port, family = _stream:getpeername()
    return {
        host = host,
        port = port,
        family = family,
    }
end

--- return the create time of the net object
function M:getCreatedTime()
    return self.m_createdTime
end

--- return the last access time of the net object
function M:getLastAccessTime()
    return self.m_lastAccessTime
end

--- need to be called in the main thread
function M.update()
    --- server accept
    for server in pairs(M._server_objects) do
        local _stream = server.m_stream
        local ok, err = _stream:settimeout(0)
        if ok then
            local _accept, err = _stream:accept()
            if _accept then
                server.m_lastAccessTime = os.time()
                local client = M._new(_accept)
                local peerInfo = client:getPeerInfo()
                client.m_host = peerInfo.host
                client.m_port = peerInfo.port
                client.m_onConnect = server.m_onConnect
                client.m_onClose = server.m_onClose
                M._onConnect(client)
            elseif err ~= "timeout" then
                server.m_lastAccessTime = os.time()
                M.close(server, "[net]accept failed: " .. tostring(err))
            end
        else
            M.close(server, "[net]settimeout failed (accept): " .. tostring(err))
        end
    end
    --- client receive
    for client in pairs(M._client_objects) do
        local recvThread = client.m_recvThread
        if recvThread and coroutine.status(recvThread) ~= "dead" then
            local ok, err = coroutine.resume(recvThread, client)
            if not ok then
                M.close(client, "[net]receive coroutine failed: " .. tostring(err))
                return
            end
        end
    end
end

--- set a handler to handle received message, and begin to receive message
---@param msgHandler fun(target:net, message:string)
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

function M:_recvCoroutine()
    local _recvingLength = nil
    while true do
        local _stream = self.m_stream
        local ok, err = _stream:settimeout(0)
        if ok then
            if _recvingLength == nil then
                local _data, err = _stream:receive(4)
                if _data then
                    local _1, _2, _3, _4 = string.byte(_data, 1, 4)
                    _recvingLength = _1 * 16777216 + _2 * 65536 + _3 * 256 + _4
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    M.close(self, "[net]receive failed: " .. tostring(err))
                    return
                end
            else
                local _data, err = _stream:receive(_recvingLength)
                if _data then
                    _recvingLength = nil
                    M._onReceive(self, _data)
                elseif err == "timeout" then
                    coroutine.yield()
                else
                    M.close(self, "[net]receive failed: " .. tostring(err))
                    return
                end
            end
        else
            M.close(self, "[net]settimeout failed (receive): " .. tostring(err))
            return
        end
    end
end

--- send message to the peer
---@param message string
function M:send(message)
    assert(message, "[net]message is nil")
    local _stream = assert(self.m_stream, "[net]bad status (send)")
    local _sendingLength = #message
    local _1, _2, _3, _4 = math.floor(_sendingLength / 16777216), math.floor(_sendingLength / 65536) % 256,
        math.floor(_sendingLength / 256) % 256, _sendingLength % 256
    local _data = string.char(_1, _2, _3, _4) .. message
    local ok, err = _stream:send(_data)
    if not ok then
        M.close(self, "[net]send failed: " .. tostring(err))
    end
end

--- close the net object
---@param reason string @witch pass to the onClose callback
function M:close(reason)
    local _stream = self.m_stream
    if _stream then
        self:onRecv(false)
        self.m_stream = nil
        M._client_objects[self] = nil
        M._server_objects[self] = nil
        _stream:close()
        if self.m_onClose then
            local ok, err = xpcall(self.m_onClose, debug.traceback, self, reason)
            if not ok then
                M.close(self, "[net]execute onClose failed: " .. tostring(err))
            end
        end
    end
end

-- # MODULE_EXPORT:

M.__index = {
    mark = M.mark,
    onRecv = M.onRecv,
    send = M.send,
    close = M.close,
    getPeerInfo = M.getPeerInfo,
    getCreatedTime = M.getCreatedTime,
    getLastAccessTime = M.getLastAccessTime,
}

M.__proto = {
    listen = M.listen,
    connect = M.connect,
    update = M.update,
    close = M.close,
}

return M.__proto
