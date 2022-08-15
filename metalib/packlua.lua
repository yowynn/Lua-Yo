#!/usr/bin/env lua5.4

--- pack a muiti-file lua project to a single lua file
---@author: Wynn Yo 2022-08-04 16:46:54
---@usage:
--[[ --
    1. copy `packlua.lua` to your project root
    2. run:
        lua packlua.lua path/to/entry.lua  path/to/output.lua
]] --
---@dependencies
local error = error
local print = print
local tostring = tostring
local io_open = io.open
local table_concat = table.concat

---@class packlua
local module = {}

--- the global module name of the out file (It doesn't matter what it is)
module._TEMPLATE_NAME = "_GLOBAL_MOD_"

--- the patterns to find out "require" statement
module._require_patterns = nil

module._ctx_pieces = nil
module._ctx_require_map = nil

function module._readLua(path)
    local f = io_open(path, "rb")
    if f == nil then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

function module._writeLua(path, content)
    local f = io_open(path, "wb")
    if f == nil then
        return nil
    end
    f:write(content)
    f:close()
    return true
end

--- global replace `_[%w_]+_` pattern to actual value
function module._greplace(template, replacemap)
    return template:gsub("(_[%w_]+_)", replacemap)
end

function module._pushPiece(piece)
    module._ctx_pieces[#module._ctx_pieces + 1] = piece
end

function module._contentPieces()
    return table_concat(module._ctx_pieces)
end

module._TEMPLATE_HEAD = [=[
-- *************************************************************
-- **              genarate by ©packlua.lua                   **
-- *************************************************************

local _GLOBAL_MOD_ = {}
_GLOBAL_MOD_._grequire = _G and _G.require or require or error("no fallback require")
_GLOBAL_MOD_._loaded = {}
_GLOBAL_MOD_._requiremap = {}
_GLOBAL_MOD_["#REQUIRE"] = function(modname)
    if _GLOBAL_MOD_._loaded[modname] then
        return _GLOBAL_MOD_._loaded[modname]
    else
        local requirefunc = _GLOBAL_MOD_._requiremap[modname] or _GLOBAL_MOD_._grequire
        local ok, mod = pcall(requirefunc, modname)
        if ok then
            mod = mod or true
            _GLOBAL_MOD_._loaded[modname] = mod
            return mod
        else
            error(mod)
        end
    end
end

]=]
function module._pushHead()
    local piece = module._TEMPLATE_HEAD
    module._pushPiece(piece)
end

module._TEMPLATE_REQUIREMAP = [=[

-- # _MOD_NAME_
--[[MOD BEGIN]] _GLOBAL_MOD_._requiremap[_MOD_NAME_Q_] = function()
_MOD_CONTENT_
--[[MOD BEGIN]] end

]=]
function module._pushRequiremap(_MOD_NAME_, _MOD_CONTENT_)
    local piece = module._greplace(module._TEMPLATE_REQUIREMAP, {
        _MOD_NAME_ = _MOD_NAME_,
        _MOD_NAME_Q_ = ("%q"):format(_MOD_NAME_),
        _MOD_CONTENT_ = _MOD_CONTENT_
    })
    module._pushPiece(piece)
end

module._TEMPLATE_LOCALREQUIRE = [=[_GLOBAL_MOD_["#REQUIRE"](_MOD_NAME_Q_)]=]
function module._pushLuafileRecursive(path)
    if module._ctx_require_map[path] then
        return
    else
        module._ctx_require_map[path] = true
    end
    local luapath = path
    if luapath:sub(-4):lower() == ".lua" then
        luapath = luapath:sub(1, -5)
    end
    luapath = luapath:gsub("\\", "/"):gsub("([^%.])%.", "%1/") .. ".lua"
    local piece = module._readLua(luapath)
    if piece == nil then
        print("[packlua]read file failed: " .. tostring(path))
        return
    else
        print("[packlua]read file success: " .. tostring(path))
    end
    for i = 1, #module._require_patterns do
        local pattern = module._require_patterns[i]
        piece = piece:gsub(pattern, function(prefix, _MOD_NAME_)
            module._pushLuafileRecursive(_MOD_NAME_)
            return prefix .. module._greplace(module._TEMPLATE_LOCALREQUIRE, {
                _MOD_NAME_Q_ = ("%q"):format(_MOD_NAME_)
            })
        end)
    end
    module._pushRequiremap(path, piece)
end

module._TEMPLATE_TAIL = [=[

return _GLOBAL_MOD_["#REQUIRE"](_MOD_NAME_Q_)
]=]
function module._push_tail(_MOD_NAME_)
    local piece = module._greplace(module._TEMPLATE_TAIL, {
        _MOD_NAME_Q_ = ("%q"):format(_MOD_NAME_)
    })
    module._pushPiece(piece)
end

--- set require patterns of your require identifier,
--- to find your require and replace it to `packlua`'s require
function module.AddRequireIdentifier(identifier)
    identifier = identifier:gsub("%.", "%%.")
    module._require_patterns[#module._require_patterns + 1] = "^(%s*)" .. identifier ..
                                                                  "%s*%(%s*[\"']([%w/%._]+)[\"']%s*%)"
    module._require_patterns[#module._require_patterns + 1] = "(%s+)" .. identifier ..
                                                                  "%s*%(%s*[\"']([%w/%._]+)[\"']%s*%)"
    module._require_patterns[#module._require_patterns + 1] = "^(%s*)" .. identifier .. "%s*[\"']([%w/%._]+)[\"']"
    module._require_patterns[#module._require_patterns + 1] = "(%s+)" .. identifier .. "%s*[\"']([%w/%._]+)[\"']"
end

--- [optional] set global module name, default is "_GLOBAL_MOD_"
function module.SetGlobalName(modname)
    module._TEMPLATE_HEAD = module._TEMPLATE_HEAD:gsub(module._TEMPLATE_NAME, modname)
    module._TEMPLATE_REQUIREMAP = module._TEMPLATE_REQUIREMAP:gsub(module._TEMPLATE_NAME, modname)
    module._TEMPLATE_LOCALREQUIRE = module._TEMPLATE_LOCALREQUIRE:gsub(module._TEMPLATE_NAME, modname)
    module._TEMPLATE_TAIL = module._TEMPLATE_TAIL:gsub(module._TEMPLATE_NAME, modname)
    module._TEMPLATE_NAME = modname
end

--- start pack your lua project
function module.pack(rootLuaPath, toLuaPath)
    module._ctx_pieces = {}
    module._ctx_require_map = {}
    module._pushHead()
    module._pushLuafileRecursive(rootLuaPath)
    module._push_tail(rootLuaPath)
    local content = module._contentPieces()
    module._writeLua(toLuaPath, content)
end

local function module_initializer()
    module._require_patterns = {}

    --- add the Require identifiers
    -- module.AddRequireIdentifier("_G.require")
    module.AddRequireIdentifier("require")

    --- set global module name, default is "_GLOBAL_MOD_"
    module.SetGlobalName("LOCAL")

    return module.pack
end

-- [[  use for command line, and as example
local _pathToEntry, _pathToOutput = ...
if _pathToEntry ~= nil and _pathToOutput ~= nil then
    local pack = module_initializer()
    pack(_pathToEntry, _pathToOutput)
end
-- ]]

return module_initializer()
