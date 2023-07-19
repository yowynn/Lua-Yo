local websocket = require "websocket-luasocket"
local client, err = websocket.connect("ws://localhost/www/chat.lua", function(peer)
    print("connect:", peer)
    peer:onRecv(function(data, opcode)
        print("recv:", data, opcode)
    end)
    peer:send("hello from lua websocket我爱你中国")
end, function(peer, reason)
    print("close:", reason)
end)

if not client then
    print("connect failed:", err)
    return
end

while true do
    websocket.update()
end
