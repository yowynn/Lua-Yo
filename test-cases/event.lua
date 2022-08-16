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
