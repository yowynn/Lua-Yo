--[[
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
--]]

-- [[
local timer1 =  require("timer-luasocket")
local timer2 =  require("timer-luv")
local EMPTY = function() end

local t11 = timer1.start(2, 10, EMPTY)
local t21 = timer2.start(2, 10, EMPTY)


timer1.start(0, 0.5, function()
    print("timer1", t11:rest(), t21:rest())
end)

while true do
    timer1.update()
    timer2.update()
end
--]]
