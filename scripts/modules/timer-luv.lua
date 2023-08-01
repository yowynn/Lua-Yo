--- timer: the timer module (via luv)
---@author: Wynn Yo 2022-06-22 14:53:35
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

-- # DEPENDENCIES:
local luv = require("luv") -- @https://github.com/luvit/luv
assert(print, "`print` not found")
assert(select, "`select` not found")
assert(setmetatable, "`setmetatable` not found")
assert(table.pack, "`table.pack` not found")
assert(table.unpack, "`table.unpack` not found")

-- # MODULE_DEFINITION:

function M.start(timeout_sec, interval_sec, callback, ...)
    timeout_sec = timeout_sec and timeout_sec > 0 and timeout_sec or 0
    interval_sec = interval_sec and interval_sec > 0 and interval_sec or 0
    local handler = luv.new_timer()
    local callargs = table.pack(...)
    handler:start(timeout_sec * 1000, interval_sec * 1000, function()
        callback(table.unpack(callargs, 1, callargs.n))
    end)
    local t = setmetatable({
        timeout = timeout_sec,
        interval = interval_sec,
        callback = callback,
        callargs = callargs,
        _ctx_handler = handler,
    }, M)
    return t
end

function M:stop()
    local handler = self and self._ctx_handler
    if not handler then
        return
    end
    handler:stop()
end

--- show timer rest time
function M:rest()
    local handler = self and self._ctx_handler
    if not handler then
        return
    end
    return handler:get_due_in() / 1000
end

function M.update()
    luv.run("nowait")
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
