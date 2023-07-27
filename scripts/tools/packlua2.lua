--- packlua: pack multi-lua files into one lua file
---@author: Wynn Yo 2022-08-04 16:46:54
local M = {}

-- # REFERENCES:

-- # USAGE:
--[[ -----------------------------------------------------------
-- TODO: WRITE USAGE HERE
--]] -----------------------------------------------------------

-- # CONFIGS:
local CONFIG = {
    --- the global module name of the out file (It doesn't matter what it is)
    GLOBAL_MOD_NAME = "_GLOBAL_MOD_",
    --- require patterns
    REQUIRE_PATTERNS = {
        "^(%s*)require%s*%(%s*[\"']([%w/%._%-]+)[\"']%s*%)",
        "(%s+)require%s*%(%s*[\"']([%w/%._%-]+)[\"']%s*%)",
        "^(%s*)require%s*[\"']([%w/%._%-]+)[\"']",
        "(%s+)require%s*[\"']([%w/%._%-]+)[\"']",
    },
    --- replace require function literals
    REQUIRE_REPLACE_LITERALS = {
        "_ENV.require",
        "_G.require",
    },
}

-- # DEPENDENCIES:
assert(error, "`error` function not found")
assert(print, "`print` function not found")
assert(tostring, "`tostring` function not found")
assert(io.open, "`io.open` function not found")
assert(table.concat, "`table.concat` function not found")

-- # PRIVATE_DEFINITION:

-- # CONSTANTS_DEFINITION:



local _TEMPLATE_HEADER_BUILDER = function()
    local _TEMPLATE_HEADER = [=[
-- *************************************************************
-- **              genarate by ©packlua.lua                   **
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



-- # MODULE_DEFINITION:



return M

