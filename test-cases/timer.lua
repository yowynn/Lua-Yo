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
local lastTime = os.time()
while true do
    local now = os.time()
    timer.update(now - lastTime)
    lastTime = now
end
