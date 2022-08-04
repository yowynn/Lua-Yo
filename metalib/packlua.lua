
--- pack a muiti-file lua project to a single lua file
---@author: Wynn Yo 2022-08-04 16:46:54

local module = {}
module.pieces = {}
module.requiremap = {}
module.requirepatterns = {}
module._GLOBAL_MODULE_NAME = "_GLOBAL_MOD_"

function module._readlua(path)
    local f = io.open(path, "rb")
    if f == nil then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

function module._writelua(path, content)
    local f = io.open(path, "wb")
    if f == nil then
        return nil
    end
    f:write(content)
    f:close()
    return true
end

function module.addRequireIdentifier(identifier)
    identifier = identifier:gsub("%.", "%%.")
    module.requirepatterns[#module.requirepatterns + 1] = "^(%s*)" .. identifier .. "%s*%(%s*[\"']([%w/%._]+)[\"']%s*%)"
    module.requirepatterns[#module.requirepatterns + 1] = "(%s+)" .. identifier .. "%s*%(%s*[\"']([%w/%._]+)[\"']%s*%)"
    module.requirepatterns[#module.requirepatterns + 1] = "^(%s*)" .. identifier .. "%s*[\"']([%w/%._]+)[\"']"
    module.requirepatterns[#module.requirepatterns + 1] = "(%s+)" .. identifier .. "%s*[\"']([%w/%._]+)[\"']"
end

function module._greplace(template, replacemap)
    return template:gsub("(_[%w_]+_)", replacemap)
end

function module._push(piece)
    module.pieces[#module.pieces + 1] = piece
end

function module._content()
    return table.concat(module.pieces)
end

local _head_template = [=[
--- genarate by packlua.lua
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
function module._push_head()
    local piece = _head_template
    module._push(piece)
end

local _requiremap_template = [=[

-- # _MOD_NAME_
--[[MOD BEGIN]] _GLOBAL_MOD_._requiremap[_MOD_NAME_Q_] = function()
_MOD_CONTENT_
--[[MOD BEGIN]] end
]=]
function module._push_requiremap(_MOD_NAME_, _MOD_CONTENT_)
    local piece = module._greplace(_requiremap_template, {
        _MOD_NAME_ = _MOD_NAME_,
        _MOD_NAME_Q_ = string.format("%q", _MOD_NAME_),
        _MOD_CONTENT_ = _MOD_CONTENT_
    })
    module._push(piece)
end

local _require_template = [=[_GLOBAL_MOD_["#REQUIRE"](_MOD_NAME_Q_)]=]
function module._push_luafile_recursive(path)
    if module.requiremap[path] then
        return
    else
        module.requiremap[path] = true
    end
    local luapath = path
    if luapath:sub(-4):lower() == ".lua" then
        luapath = luapath:sub(1, -5)
    end
    luapath = luapath:gsub("\\", "/"):gsub("([^%.])%.", "%1/") .. ".lua"
    local piece = module._readlua(luapath)
    if piece == nil then
        print("read file failed: " .. path)
        return
    else
        print("read file: " .. path)
    end
    for _, pattern in ipairs(module.requirepatterns) do
        piece = piece:gsub(pattern, function(prefix, _MOD_NAME_)
            module._push_luafile_recursive(_MOD_NAME_)
            return prefix .. module._greplace(_require_template, {
                _MOD_NAME_Q_ = string.format("%q", _MOD_NAME_)
            })
        end)
    end
    module._push_requiremap(path, piece)
end

local _tail_template = [=[

return _GLOBAL_MOD_["#REQUIRE"](_MOD_NAME_Q_)
]=]
function module._push_tail(_MOD_NAME_)
    local piece = module._greplace(_tail_template, {
        _MOD_NAME_Q_ = string.format("%q", _MOD_NAME_)
    })
    module._push(piece)
end

function module.setGlobalName(_GLOBAL_MOD_)
    _head_template = _head_template:gsub(module._GLOBAL_MODULE_NAME, _GLOBAL_MOD_)
    _requiremap_template = _requiremap_template:gsub(module._GLOBAL_MODULE_NAME, _GLOBAL_MOD_)
    _require_template = _require_template:gsub(module._GLOBAL_MODULE_NAME, _GLOBAL_MOD_)
    _tail_template = _tail_template:gsub(module._GLOBAL_MODULE_NAME, _GLOBAL_MOD_)
    module._GLOBAL_MODULE_NAME = _GLOBAL_MOD_
end

function module.pack(rootLuaPath, toLuaPath)
    module.pieces = {}
    module.requiremap = {}
    module.requirepatterns = {}
    module.addRequireIdentifier("require")
    module.setGlobalName("LOCAL")
    module._push_head()
    module._push_luafile_recursive(rootLuaPath)
    module._push_tail(rootLuaPath)
    local content = module._content()
    module._writelua(toLuaPath, content)
end

local rootLuaPath, toLuaPath = ...
if rootLuaPath ~= nil and toLuaPath ~= nil then
    module.pack(rootLuaPath, toLuaPath)
end

return module.pack
