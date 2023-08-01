local event = require("event")
-- # define event
function event.echo(...)
    local from = event.from()
    print("echo", from, ...)
end
-- # local call event
event().from("Holder_A").echo("hello")
event().from("Holder_B").echo("hello")
event(nil).from("Holder_B").echo("hello-never")

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
local mode = m == "c" and "client" or m == "s" and "server" or nil
if mode == "client" then
    print("client")
    -- #client side:
    local client = net.connect("127.0.0.1", 54188, function(client)
        regevent(client)
        event(client).OpenNotepad()
    end, print)
elseif mode == "server" then
    print("server")
    -- #server side:
    function event.OpenNotepad()
        print("open notepad from", event.from())
        os.execute("@start notepad")
    end
    local server = net.listen("0.0.0.0", 54188, function(client)
        print("listen")
        regevent(client)
    end, print)
end
while true do
    net.update()
end
