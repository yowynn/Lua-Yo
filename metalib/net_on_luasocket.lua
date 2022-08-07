#!/usr/bin/env lua5.4

--- the net module (via luasocket)
---@author: Wynn Yo 2022-06-24 10:18:31

---@usage:
-- $ #copy `packlua.lua` to your project root
-- $ lua packlua.lua path/to/entry.lua  path/to/output.lua
---@dependencies
local socket = require("socket") -- @https://github.com/lunarmodules/luasocket


local module = {}
module._ctx_server_objects = {}
module._ctx_client_objects = {}
