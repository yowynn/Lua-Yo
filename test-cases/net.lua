local m = select(1, ...)
local mode = m == "c" and "client" or m == "s" and "server" or nil
print("start net test: " .. mode)

local net = require("net")

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
