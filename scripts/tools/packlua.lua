--- packlua: pack multi-lua files into one lua file
---@author: Wynn Yo 2022-08-04 16:46:54
local M = {}

-- # REFERENCES:

-- # USAGE:
--[[ -----------------------------------------------------------
1. copy `packlua.lua` to your project root
2. run:
    lua packlua.lua path/to/entry.lua path/to/output.lua
--]] -----------------------------------------------------------

-- # CONFIGS:

--- use as command line tool
local USE_AS_CLI = true

--- the configs of this module
local CONFIG = {
    --- the global module name of the out file (It doesn't matter what it is)
    GLOBAL_MOD_NAME = "PACKLUA",
    --- require patterns
    REQUIRE_PATTERNS = {
        "%f[%w]require%s*%(%s*[\"']([%w/%._%-]+)[\"']%s*%)",
        "%f[%w]require%s*[\"']([%w/%._%-]+)[\"']",
    },
    --- replace require function literals
    REQUIRE_REPLACE_LITERALS = {
        "_ENV.require",
        "_G.require",
    },
}

-- # DEPENDENCIES:

assert(error, "`error` not found")
assert(ipairs, "`ipairs` not found")
assert(pairs, "`pairs` not found")
assert(pcall, "`pcall` not found")
assert(print, "`print` not found")
assert(require, "`require` not found")
assert(tostring, "`tostring` not found")
assert(io.open, "`io.open` not found")
assert(table.concat, "`table.concat` not found")

-- # CONSTANTS_DEFINITION:

local _TEMPLATE_HEADER_BUILDER = function()
    local _TEMPLATE_HEADER = [=[
-- *************************************************************
-- **                genarate by ©packlua.lua                 **
-- *************************************************************

local _PACKLUA_GLOBAL_MOD_ = {}
_PACKLUA_GLOBAL_MOD_._loaded = {}
_PACKLUA_GLOBAL_MOD_._requiremap = {}
_PACKLUA_GLOBAL_MOD_["#REQUIRE"] = function(modname)
    if _PACKLUA_GLOBAL_MOD_._loaded[modname] then
        return _PACKLUA_GLOBAL_MOD_._loaded[modname]
    else
_PACKLUA_GETMOD_FROM_REQUIRE_
        _PACKLUA_GLOBAL_MOD_._loaded[modname] = mod
        return mod
    end
end

]=] -- _TEMPLATE_HEADER
    local getmod_builder = {}
    getmod_builder[#getmod_builder + 1] = "        local ok, mod = nil, nil\n"
    local require_literal = {
        "_PACKLUA_GLOBAL_MOD_._requiremap[modname]",
    }
    for _, v in ipairs(CONFIG.REQUIRE_REPLACE_LITERALS) do
        require_literal[#require_literal + 1] = v
    end
    for _, v in ipairs(require_literal) do
        getmod_builder[#getmod_builder + 1] = "        if not ok then\n"
        getmod_builder[#getmod_builder + 1] = "            local requirefunc = "
        getmod_builder[#getmod_builder + 1] = v
        getmod_builder[#getmod_builder + 1] = "\n"
        getmod_builder[#getmod_builder + 1] = "            if requirefunc then\n"
        getmod_builder[#getmod_builder + 1] = "                ok, mod = pcall(requirefunc, modname)\n"
        getmod_builder[#getmod_builder + 1] = "            end\n"
        getmod_builder[#getmod_builder + 1] = "        end\n"
    end
    getmod_builder[#getmod_builder + 1] = "        if not ok then\n"
    getmod_builder[#getmod_builder + 1] = "            error(\"module '\" .. modname .. \"' not found\")\n"
    getmod_builder[#getmod_builder + 1] = "        end\n"
    getmod_builder[#getmod_builder + 1] = "        mod = mod or true\n"
    local _PACKLUA_GETMOD_FROM_REQUIRE_ = table.concat(getmod_builder)
    _TEMPLATE_HEADER = _TEMPLATE_HEADER:gsub("_PACKLUA_GETMOD_FROM_REQUIRE_", _PACKLUA_GETMOD_FROM_REQUIRE_)
    _TEMPLATE_HEADER = _TEMPLATE_HEADER:gsub("_PACKLUA_GLOBAL_MOD_", CONFIG.GLOBAL_MOD_NAME)
    return _TEMPLATE_HEADER
end

local _TEMPLATE_MOD_BUILDER = function(modname, content)
    local _TEMPLATE_MOD = [=[

-- # _PACKLUA_MOD_NAME_
--[[MOD BEGIN]] _PACKLUA_GLOBAL_MOD_._requiremap[_PACKLUA_MOD_NAME_Q_] = function()
_PACKLUA_MOD_CONTENT_
--[[MOD END]] end

]=] -- _TEMPLATE_MOD
    _TEMPLATE_MOD = _TEMPLATE_MOD:gsub("(_[%w_]+_)", {
        _PACKLUA_MOD_NAME_ = modname,
        _PACKLUA_MOD_NAME_Q_ = ("%q"):format(modname),
        _PACKLUA_GLOBAL_MOD_ = CONFIG.GLOBAL_MOD_NAME,
        _PACKLUA_MOD_CONTENT_ = content,
    })

    return _TEMPLATE_MOD
end

local _TEMPLATE_LOCALREQUIRE_BUILDER = function(modname)
    local _TEMPLATE_LOCALREQUIRE = [=[_PACKLUA_GLOBAL_MOD_["#REQUIRE"](_PACKLUA_MOD_NAME_Q_)]=]
    _TEMPLATE_LOCALREQUIRE = _TEMPLATE_LOCALREQUIRE:gsub("(_[%w_]+_)", {
        _PACKLUA_MOD_NAME_Q_ = ("%q"):format(modname),
        _PACKLUA_GLOBAL_MOD_ = CONFIG.GLOBAL_MOD_NAME,
    })
    return _TEMPLATE_LOCALREQUIRE
end

local _TEMPLATE_FOOTER_BUILDER = function(modname)
    local _TEMPLATE_FOOTER = [=[

return _PACKLUA_GLOBAL_MOD_["#REQUIRE"](_PACKLUA_MOD_NAME_Q_)
]=]
    _TEMPLATE_FOOTER = _TEMPLATE_FOOTER:gsub("(_[%w_]+_)", {
        _PACKLUA_MOD_NAME_Q_ = ("%q"):format(modname),
        _PACKLUA_GLOBAL_MOD_ = CONFIG.GLOBAL_MOD_NAME,
    })
    return _TEMPLATE_FOOTER
end


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

local function _writeLua(path, content)
    local f = io.open(path, "wb")
    if f == nil then
        return nil
    end
    f:write(content)
    f:close()
    return true
end

local function _pushLuafileRecursive(path, pieces, requiremap)
    if requiremap[path] then
        return
    end
    requiremap[path] = true
    local luapath = path
    if luapath:sub(-4):lower() == ".lua" then
        luapath = luapath:sub(1, -5)
    end
    luapath = luapath:gsub("\\", "/"):gsub("([^%.])%.", "%1/") .. ".lua"
    local piece = _readLua(luapath)
    if not piece then
        print("[packlua]read file failed: " .. tostring(path))
        return
    end
    print("[packlua]read file success: " .. tostring(path))
    for _, pattern in ipairs(CONFIG.REQUIRE_PATTERNS) do
        piece = piece:gsub(pattern, function(modname)
            _pushLuafileRecursive(modname, pieces, requiremap)
            return _TEMPLATE_LOCALREQUIRE_BUILDER(modname)
        end)
    end
    pieces[#pieces + 1] = _TEMPLATE_MOD_BUILDER(path, piece)
end

-- # MODULE_DEFINITION:

--- custom configs
---@param configs table<string, any>
function M.config(configs)
    for k, v in pairs(configs) do
        CONFIG[k] = v
    end
end

--- pack a muiti-file lua project to a single lua file
---@param rootLuaPath string @the root lua file path
---@param toLuaPath string @the output lua file path
---@return boolean @success or not
function M.pack(rootLuaPath, toLuaPath)
    local pieces = {}
    local requiremap = {}
    pieces[#pieces + 1] = _TEMPLATE_HEADER_BUILDER()
    _pushLuafileRecursive(rootLuaPath, pieces, requiremap)
    pieces[#pieces + 1] = _TEMPLATE_FOOTER_BUILDER(rootLuaPath)
    local content = table.concat(pieces)
    return _writeLua(toLuaPath, content)
end

-- # MODULE_EXPORT:

if USE_AS_CLI then
    local rootLuaPath, toLuaPath = ...
    if rootLuaPath and toLuaPath then
        M.pack(rootLuaPath, toLuaPath)
    else
        print("Usage: lua packlua.lua path/to/entry.lua  path/to/output.lua")
    end
else
    return M
end
