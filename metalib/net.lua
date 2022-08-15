local via = "luv"

if via == "luv" then
    return require("net-luv")
elseif via == "luasocket" then
    return require("net-luasocket")
else
    error("unknown via: " .. tostring(via))
end
