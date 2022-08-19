--- timer: the timer module (via luasocket)
---@author: Wynn Yo 2022-08-16 10:37:54
-- # USAGE:
--[[ -----------------------------------------------------------
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
--]] -----------------------------------------------------------
-- # DEPENDENCIES
local module = {}
local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
local setmetatable = setmetatable
local table_pack = table.pack
local table_unpack = table.unpack

-- # STATIC_CONFIG_DEFINITION

-- # CONTEXT_VALUE_DEFINITION

--- the timers to update
module._updating_timers = nil

--- the timers to delete
module._ctx_deleting_timers = nil

module.__index = nil

-- # METHODS_DEFINITION

function module.start(timeout_sec, interval_sec, callback, ...)
    timeout_sec = timeout_sec and timeout_sec > 0 and timeout_sec or 0
    interval_sec = interval_sec and interval_sec > 0 and interval_sec or 0
    local callargs = table_pack(...)
    local t = setmetatable({
        timeout = timeout_sec,
        interval = interval_sec,
        callback = callback,
        callargs = callargs,
        _ctx_nexttime = socket.gettime() + timeout_sec,
    }, module)
    module._updating_timers[t] = true
    return t
end

function module:stop()
    if self then
        module._ctx_deleting_timers[#module._ctx_deleting_timers + 1] = self
    end
end

function module.update()
    local now = socket.gettime()
    for i = 1, #module._ctx_deleting_timers do
        local t = module._ctx_deleting_timers[i]
        module._updating_timers[t] = nil
        module._ctx_deleting_timers[i] = nil
    end
    for t in pairs(module._updating_timers) do
        while t._ctx_nexttime <= now do
            t.callback(table_unpack(t.callargs, 1, t.callargs.n))
            if t.interval > 0 then
                t._ctx_nexttime = now + t.interval
            else
                module.stop(t)
                break
            end
        end
    end
end

-- # WRAP_MODULE

local function module_initializer()
    -- # STATIC_CONFIG_INIT

    -- # CONTEXT_VALUE_INIT

    module._updating_timers = {}
    module._ctx_deleting_timers = {}
    module.__index = {
        stop = module.stop,
    }

    -- # MODULE_EXPORT

    ---@class timer @the timer module (via luasocket)
    local timer = {
        start = module.start,
        stop = module.stop,
        update = module.update,
    }

    return timer
end

return module_initializer()
