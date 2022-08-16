#!/usr/bin/env lua5.4

--- the timer module (via luv)
---@author: Wynn Yo 2022-06-22 14:53:35
---@usage:
--[[ --
    local timer = require("timer")
    local t1 = timer.start(2, 2, print, "hello22")
    local t2 = timer.start(4, 1, print, "hello41")
    timer.start(20, nil, function(msg, ...)
        for i = 1, select("#", ...) do
            local t = select(i, ...)
            print("stop timer:", t.timeout, t.interval)
            t:stop()
        end
        print(msg)
    end, "the end", t1, t2)
    while true do
        timer.update()
    end
--]] --
---@dependencies
local luv = require("luv") -- @https://github.com/luvit/luv
local setmetatable = setmetatable
local table_pack = table.pack
local table_unpack = table.unpack

---@class timer
local module = {}

module.__index = nil

function module.start(timeout_sec, interval_sec, callback, ...)
    timeout_sec = timeout_sec and timeout_sec > 0 and timeout_sec or 0
    interval_sec = interval_sec and interval_sec > 0 and interval_sec or 0
    local handler = luv.new_timer()
    local callargs = table_pack(...)
    handler:start(timeout_sec * 1000, interval_sec * 1000, function()
        callback(table_unpack(callargs, 1, callargs.n))
    end)
    local t = setmetatable({
        timeout = timeout_sec,
        interval = interval_sec,
        callback = callback,
        callargs = callargs,
        _ctx_handler = handler,
    }, module)
    return t
end

function module:stop()
    local handler = self and self._ctx_handler
    if not handler then
        return
    end
    handler:stop()
end

function module.update()
    luv.run("nowait")
end

local function module_initializer()
    module.__index = {
        stop = module.stop,
    }
    local static = {
        start = module.start,
        stop = module.stop,
        update = module.update
    }
    return static
end

return module_initializer()
