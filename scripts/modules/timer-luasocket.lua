--- timer: the timer M (via luasocket)
---@author: Wynn Yo 2022-08-16 10:37:54
local M = {}

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

local socket = require("socket") -- @https://lunarmodules.github.io/luasocket/
assert(assert, "`assert` not found")
assert(pairs, "`pairs` not found")
assert(print, "`print` not found")
assert(require, "`require` not found")
assert(select, "`select` not found")
assert(setmetatable, "`setmetatable` not found")
assert(table.pack, "`table.pack` not found")
assert(table.unpack, "`table.unpack` not found")

-- # PRIVATE_DEFINITION:

--- the timers to update
local _updating_timers = {}

--- the timer mark to delete
local _deleting_timers = {}

-- # MODULE_DEFINITION:

--- start a timer
---@param timeout_sec number @the timeout seconds
---@param interval_sec number @the interval seconds, if nil or 0, the timer will be stopped after timeout
---@param callback function @the callback function
---@vararg any @the rest arguments to pass to the callback function
---@return table @the timer object
function M.start(timeout_sec, interval_sec, callback, ...)
    timeout_sec = timeout_sec and timeout_sec > 0 and timeout_sec or 0
    interval_sec = interval_sec and interval_sec > 0 and interval_sec or 0
    local callargs = select("#", ...) > 0 and table.pack(...) or nil
    local t = setmetatable({
        timeout = timeout_sec,
        interval = interval_sec,
        callback = callback,
        callargs = callargs,
        _nexttime = socket.gettime() + timeout_sec,
    }, M)
    _updating_timers[t] = true
    return t
end

--- stop a timer
function M:stop()
    if self then
        _deleting_timers[#_deleting_timers + 1] = self
    end
end

--- show timer rest time
function M:rest()
    local rest = self._nexttime - socket.gettime()
    if rest < 0 then
        rest = 0
    end
    return rest
end

--- update the timer module, should be called in a loop
function M.update()
    local now = socket.gettime()
    local n = #_deleting_timers
    for i = 1, n do
        local t = _deleting_timers[i]
        _updating_timers[t] = nil
        _deleting_timers[i] = nil
    end
    for t in pairs(_updating_timers) do
        while t._nexttime <= now do
            local callargs = t.callargs
            t.callback(callargs and table.unpack(callargs, 1, callargs.n))
            if t.interval > 0 then
                t._nexttime = now + t.interval
            else
                M.stop(t)
                break
            end
        end
    end
end

-- # MODULE_EXPORT:

M.__index = {
    stop = M.stop,
    rest = M.rest,
}

M.__proto = {
    start = M.start,
    stop = M.stop,
    rest = M.rest,
    update = M.update,
}

return M.__proto
