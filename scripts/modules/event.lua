--- event: the event module for rpc or local call
---@author: Wynn Yo 2022-08-15 16:37:56
local M = {}

-- # USAGE:
--[[ -----------------------------------------------------------
local event = require("event")
-- # define event
function event.echo(...)
    local from = event.from()
    print("echo", from, ...)
end
-- # local call event
event().from("Holder_A").echo("hello")
event().from("Holder_B").echo("hello")
-- # net test
local net = require("net")
local table_ser = require("table_serialization")
local function regevent(client)
    local send = function(eventName, ...)
        local message = table_ser.serialize(table.pack(eventName, ...))
        client:send(message)
    end
    local recv = event.reg(client, send)
    client:onRecv(function(client, message)
        local args = table_ser.deserialize(message)
        return recv(table.unpack(args))
    end)
end
local m = ...
local mode = m == "c" and "client" or "s" and "server"
if mode == "client" then
    -- #client side:
    local client = net.connect("127.0.0.1", 54188, function(client)
        regevent(client)
        event(client).OpenNotepad()
    end, print)
elseif mode == "server" then
    -- #server side:
    function event.OpenNotepad()
        print("open notepad from", event.from())
        os.execute("@start notepad")
    end
    local server = net.listen("0.0.0.0", 54188, function(client)
        regevent(client)
    end, print)
end
while true do
    net.update()
end
--]] -----------------------------------------------------------

-- # DEPENDENCIES:
assert(assert, "`assert` not found")
assert(error, "`error` not found")
assert(pairs, "`pairs` not found")
assert(pcall, "`pcall` not found")
assert(print, "`print` not found")
assert(rawset, "`rawset` not found")
assert(select, "`select` not found")
assert(setmetatable, "`setmetatable` not found")
assert(tostring, "`tostring` not found")

-- # PRIVATE_DEFINITION:

M._current_holder = nil
--- the map of registered event
M._event_map = {}
--- the map of registered holder
M._holder_map = setmetatable({}, { __mode = "k", })

-- # MODULE_DEFINITION:

--- reg a holder
---@param holder any
---@param sendHandler fun(eventName: string, ...) @will call when send event to holder
---@return fun(eventName: string, ...) @please call it when receive event from holder
function M.reg(holder, sendHandler)
    assert(holder, "[event]holder is nil")
    assert(sendHandler, "[event]sendHandler is nil")
    local recvHandler = function(eventName, ...)
        if not M._holder_map[holder] then
            return
        end
        local data, err = M._invoke(holder, eventName, ...)
        if err then
            print("[event]invoke error", err)
        else
            return data
        end
    end
    M._holder_map[holder] = {
        send = sendHandler,
        recv = recvHandler,
    }
    return recvHandler
end

--- unreg a holder
function M.unreg(holder)
    assert(holder, "[event]holder is nil")
    M._holder_map[holder] = nil
end

function M._sender(holder)
    local handler = M._holder_map[holder]
    return handler and handler.send
end

function M._recver(holder)
    local handler = M._holder_map[holder]
    return handler and handler.recv
end

function M._local(holder)
    return function(eventName, ...)
        return M._invoke(holder, eventName, ...)
    end
end

function M._invoke(holder, eventName, ...)
    local oldHolder = M._current_holder
    M._current_holder = holder
    local eventHandler = M._event_map[eventName]
    local ok, ret
    if eventHandler then
        ok, ret = pcall(eventHandler, ...)
    else
        ok, ret = false, "event not found: " .. tostring(eventName)
    end
    M._current_holder = oldHolder
    if ok then
        return ret
    else
        return nil, ret
    end
end

function M.event_call(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        print("[event]event_call error: " .. tostring(err))
    end
end

function M.event_info(...)
    print("[event]event_info: ", ...)
end

--- get the from holder in the context
function M.from()
    return M._current_holder
end

function M._buildContext()
    local context = {}
    local _context = context

    context._NOCALL_FUNC = function()
    end

    function context._clear()
        context._ctx_from_holder = nil
        context._ctx_to_handler = nil
    end

    --- manual set event from
    function context.from(holder)
        context._ctx_from_holder = holder
        return _context
    end

    function context._to_mono(holder)
        assert(not context._ctx_to_handler, "[event]target is already set")
        context._ctx_to_handler = M._sender(holder) or context._NOCALL_FUNC
        return _context
    end

    --- set event to
    function context.to(holder_s, isMulticast)
        assert(not context._ctx_to_handler, "[event]target is already set")
        if isMulticast then
            --- cautious to use this, message encode multi-times
            context._ctx_to_handler = function(eventName, ...)
                for _, holder in pairs(holder_s) do
                    M._sender(holder)(eventName, ...)
                end
            end
        else
            context._to_mono(holder_s)
        end
        return _context
    end

    function context.nocall()
        assert(not context._ctx_to_handler, "[event]target is already set")
        context._ctx_to_handler = context._NOCALL_FUNC
        return _context
    end

    _context = setmetatable({
        from = context.from,
        to = context.to,
        nocall = context.nocall,
    }, {
        __index = function(t, k)
            local proxy = function(...)
                local holder = context._ctx_from_holder
                local eventHandler = context._ctx_to_handler or M._local(holder)
                context._clear()
                return eventHandler(k, ...)
            end
            rawset(t, k, proxy)
            return proxy
        end,
        __newindex = function(t, k, v)
            error("[event]context is readonly")
        end,
    })
    return function(_, ...)
        context._clear()
        if select("#", ...) > 0 then
            return context._to_mono(...)
        else
            return _context
        end
    end
end

-- # MODULE_EXPORT:

--- default event define
M._event_map.call = M.event_call
M._event_map.info = M.event_info

M.__proto = setmetatable({
    reg = M.reg,
    unreg = M.unreg,
    from = M.from,
}, {
    __index = M._event_map,
    __newindex = M._event_map,
    __call = M._buildContext(),
})

return M.__proto
