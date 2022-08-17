#!/usr/bin/env lua5.4

--- event: the event module for rpc or local call
---@author: Wynn Yo 2022-08-15 16:37:56
-- # USAGE
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
    local dump = require("table_dump")
    local function regevent(client)
        local send = function(eventName, ...)
            local message = dump(table.pack(eventName, ...), false)
            client:send(message)
        end
        local recv = event.reg(client, send)
        client:onRecv(function(client, message)
            local args = load("return " .. message)()
            return recv(table.unpack(args))
        end)
    end
    local m = ...
    local mode = m == "c" and "client" or "s" and "server"
    if mode == "client" then
        -- #client side:
        local client = net.connect("127.0.0.1", 1234, function(client)
            regevent(client)
            event(client).OpenNotepad()
        end, print)
    elseif mode == "server" then
        -- #server side:
        function event.OpenNotepad()
            print("open notepad from", event.from())
            os.execute("@start notepad")
        end
        local server = net.listen("0.0.0.0", 1234, function(client)
            regevent(client)
        end, print)
    end
    while true do
        net.update()
    end
--]] -----------------------------------------------------------
-- # DEPENDENCIES
local module = {}
local assert = assert
local error = error
local rawset = rawset
local pcall = pcall
local print = print
local setmetatable = setmetatable
local tostring = tostring

-- # STATIC_CONFIG_DEFINITION

-- # CONTEXT_VALUE_DEFINITION

module._current_holder = nil
--- the map of registered event
module._event_map = nil
--- the map of registered holder
module._holder_map = nil

-- # METHODS_DEFINITION

--- reg a holder
---@param holder any
---@param sendHandler fun(eventName: string, ...) @will call when send event to holder
---@return fun(eventName: string, ...) @please call it when receive event from holder
function module.reg(holder, sendHandler)
    assert(holder, "[event]holder is nil")
    assert(sendHandler, "[event]sendHandler is nil")
    local recvHandler = function(eventName, ...)
        if not module._holder_map[holder] then
            return
        end
        local data, err = module._invoke(holder, eventName, ...)
        if err then
            print("[event]invoke error", err)
        else
            return data
        end
    end
    module._holder_map[holder] = {
        send = sendHandler,
        recv = recvHandler,
    }
    return recvHandler
end

--- unreg a holder
function module.unreg(holder)
    assert(holder, "[event]holder is nil")
    module._holder_map[holder] = nil
end

function module._sender(holder)
    local handler = module._holder_map[holder]
    return handler and handler.send
end

function module._recver(holder)
    local handler = module._holder_map[holder]
    return handler and handler.recv
end

function module._local(holder)
    return function(eventName, ...)
        return module._invoke(holder, eventName, ...)
    end
end

function module._invoke(holder, eventName, ...)
    local oldHolder = module._current_holder
    module._current_holder = holder
    local eventHandler = module._event_map[eventName]
    local ok, ret
    if eventHandler then
        ok, ret = pcall(eventHandler, ...)
    else
        ok, ret = false, "event not found: " .. tostring(eventName)
    end
    module._current_holder = oldHolder
    if ok then
        return ret
    else
        return nil, ret
    end
end

function module.event_call(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        print("[event]event_call error: " .. tostring(err))
    end
end

function module.event_info(...)
    print("[event]event_info: ", ...)
end

--- get the from holder in the context
function module.from()
    return module._current_holder
end

function module._buildContext()
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
        context._ctx_to_handler = module._sender(holder) or context._NOCALL_FUNC
        return _context
    end

    --- set event to
    function context.to(holder_s, isMulticast)
        assert(not context._ctx_to_handler, "[event]target is already set")
        if isMulticast then
            --- cautious to use this, message encode multi-times
            context._ctx_to_handler = function(eventName, ...)
                for _, holder in pairs(holder_s) do
                    module._sender(holder)(eventName, ...)
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
    end

    _context = setmetatable({
        from = context.from,
        to = context.to,
        nocall = context.nocall,
    }, {
        __index = function(t, k)
            local proxy = function(...)
                local holder = context._ctx_from_holder
                local eventHandler = context._ctx_to_handler or module._local(holder)
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

-- # WRAP_MODULE

local function module_initializer()
    -- # STATIC_CONFIG_INIT

    -- # CONTEXT_VALUE_INIT

    module._current_holder = nil
    module._event_map = {}
    module._holder_map = setmetatable({}, {
        __mode = "k",
    })

    -- # MODULE_EXPORT

    ---@class event @the event module for rpc or local call
    local event = {
        reg = module.reg,
        unreg = module.unreg,
        from = module.from,
    }
    setmetatable(event, {
        __index = module._event_map,
        __newindex = module._event_map,
        __call = module._buildContext(),
    })
    --- default event define
    event.call = module.event_call
    event.info = module.event_info

    return event
end

return module_initializer()
