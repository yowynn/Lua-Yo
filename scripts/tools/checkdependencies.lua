--- check dependencies: assert all dependencies are available
---@author: AUTHOR & DATE HERE
local M = {}

-- # REFERENCES:

-- # USAGE:
--[[ -----------------------------------------------------------
lua checkdependencies.lua path/to/file.lua
--]] -----------------------------------------------------------

-- # CONFIGS:

--- use as command line tool
local USE_AS_CLI = true

-- # DEPENDENCIES:
-- TODO: ASSERT DEPENDENCIES HERE

-- # CONSTANTS_DEFINITION:

local LUA_FUNCTION_LITERAL = { -- lua 5.4
    -- basic
    "_G",
    "_VERSION",
    "assert",
    "collectgarbage",
    "dofile",
    "error",
    "getmetatable",
    "ipairs",
    "load",
    "loadfile",
    "next",
    "pairs",
    "pcall",
    "print",
    "rawequal",
    "rawget",
    "rawlen",
    "rawset",
    "require",
    "select",
    "setmetatable",
    "tonumber",
    "tostring",
    "type",
    "warn",
    "xpcall",
    -- coroutine
    "coroutine.close",
    "coroutine.create",
    "coroutine.isyieldable",
    "coroutine.resume",
    "coroutine.running",
    "coroutine.status",
    "coroutine.wrap",
    "coroutine.yield",
    -- debug
    "debug.debug",
    "debug.gethook",
    "debug.getinfo",
    "debug.getlocal",
    "debug.getmetatable",
    "debug.getregistry",
    "debug.getupvalue",
    "debug.getuservalue",
    "debug.sethook",
    "debug.setlocal",
    "debug.setmetatable",
    "debug.setupvalue",
    "debug.setuservalue",
    "debug.traceback",
    "debug.upvalueid",
    "debug.upvaluejoin",
    -- io
    "io.close",
    "io.flush",
    "io.input",
    "io.lines",
    "io.open",
    "io.output",
    "io.popen",
    "io.read",
    "io.stderr",
    "io.stdin",
    "io.stdout",
    "io.tmpfile",
    "io.type",
    "io.write",
    -- "file:close",
    -- "file:flush",
    -- "file:lines",
    -- "file:read",
    -- "file:seek",
    -- "file:setvbuf",
    -- "file:write",
    -- math
    "math.abs",
    "math.acos",
    "math.asin",
    "math.atan",
    "math.ceil",
    "math.cos",
    "math.deg",
    "math.exp",
    "math.floor",
    "math.fmod",
    "math.huge",
    "math.log",
    "math.max",
    "math.maxinteger",
    "math.min",
    "math.mininteger",
    "math.modf",
    "math.pi",
    "math.rad",
    "math.random",
    "math.randomseed",
    "math.sin",
    "math.sqrt",
    "math.tan",
    "math.tointeger",
    "math.type",
    "math.ult",
    -- os
    "os.clock",
    "os.date",
    "os.difftime",
    "os.execute",
    "os.exit",
    "os.getenv",
    "os.remove",
    "os.rename",
    "os.setlocale",
    "os.time",
    "os.tmpname",
    -- package
    "package.config",
    "package.cpath",
    "package.loaded",
    "package.loadlib",
    "package.path",
    "package.preload",
    "package.searchers",
    "package.searchpath",
    -- string
    "string.byte",
    "string.char",
    "string.dump",
    "string.find",
    "string.format",
    "string.gmatch",
    "string.gsub",
    "string.len",
    "string.lower",
    "string.match",
    "string.pack",
    "string.packsize",
    "string.rep",
    "string.reverse",
    "string.sub",
    "string.unpack",
    "string.upper",
    -- table
    "table.concat",
    "table.insert",
    "table.move",
    "table.pack",
    "table.remove",
    "table.sort",
    "table.unpack",
    -- utf8
    "utf8.char",
    "utf8.charpattern",
    "utf8.codepoint",
    "utf8.codes",
    "utf8.len",
    "utf8.offset",
}

-- # PRIVATE_DEFINITION:

local function _readLua(path)
    local f = io.open(path, "rb")
    if f == nil then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

-- # MODULE_DEFINITION:

function M.checkDependencies(luafile, startLiteral)
    local content = _readLua(luafile)
    if not content then
        print("[CheckDependencies]read file failed: " .. tostring(luafile))
        return
    end
    local whereToStart = 1
    if startLiteral then
        local start = string.find(content, whereToStart, 1, true)
        if start then
            whereToStart = start
        end
    end
    local builder = {}
    for _, v in ipairs(LUA_FUNCTION_LITERAL) do
        local vp = "%f[%w_]" .. string.gsub(v, "%.", "%%.") .. "%f[^%w_]"
        if string.find(content, vp, whereToStart, false) then
            builder[#builder + 1] = "assert("
            builder[#builder + 1] = v
            builder[#builder + 1] = ", \"`"
            builder[#builder + 1] = v
            builder[#builder + 1] = "` not found\")\n"
        end
    end
    local result = table.concat(builder)
    if result == "" then
        print("[CheckDependencies]no dependencies found: " .. tostring(luafile))
        return
    end
    print("[CheckDependencies]dependencies found: " .. tostring(luafile))
    print(result)
end

-- # MODULE_EXPORT:

if USE_AS_CLI then
    local luafile, startLiteral = ...
    if not luafile then
        print("Usage: lua checkdependencies.lua <luafile> [startLiteral]")
        return
    end
    M.checkDependencies(luafile, startLiteral)
else
    return M
end
