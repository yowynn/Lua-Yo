--- filesystem module
---@author: Wynn Yo 2023-04-28 15:23:55

-- # DEPENDENCIES
local lfs = require("lfs") -- @https://lunarmodules.github.io/luafilesystem/

-- # MODULE_DEFINITION
local M = {}

--- split a path into dir, name, extention
--- e.g. "`D:/test/example.txt`" -> "`D:/test/`", "`example`", "`.txt`", `false`
---@param path string @the path to split
---@return string @the directory part of the path
---@return string @the name part of the path
---@return string @the extension part of the path
---@return boolean @true if the path is a directory, otherwise false
function M.splitPath(path, splitExt)
    local dir, nameWithExt, dirFlag = path:match("^(.-)([^\\/]*)([\\/]*)$")
    local isDir = dirFlag ~= ""
    if splitExt and not isDir then
        local name = nameWithExt:match("^(.+)%.[^%.\\/]+$") or nameWithExt
        local ext = nameWithExt:sub(#name + 1)
        return dir, name, ext, false
    else
        return dir, nameWithExt, "", isDir
    end
end

--- get path info
---@param path string @the path to get info
---@return table @the path info from `lfs.attributes`
function M.pathInfo(path)
    path = path:gsub("[\\/]+$", "")
    return lfs.attributes(path)
end

--- create file
---@param path string @the file path to create
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.createFile(path)
    local dir, _, _, isDir = M.splitPath(path, false)
    if isDir then
        return false, "path is a directory"
    end
    local ok, err = M.createDirectory(dir)
    if not ok then
        return false, err
    end
    local file, err = io.open(path, "w")
    if not file then
        return false, err
    end
    file:close()
    return true
end

--- remove file
---@param path string @the file path to remove
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.removeFile(path)
    local ok, err = os.remove(path)
    if not ok then
        return false, err
    end
    return true
end

--- move file
---@param src string @the source file path
---@param dst string @the destination file path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.moveFile(src, dst)
    local dir = M.splitPath(dst, false)
    if dir ~= "" then
        local ok, err = M.createDirectory(dir)
        if not ok then
            return false, err
        end
    end
    local ok, err = os.rename(src, dst)
    if not ok then
        return false, err
    end
    return true
end

--- copy file
---@param src string @the source file path
---@param dst string @the destination file path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.copyFile(src, dst)
    local dir = M.splitPath(dst, false)
    if dir ~= "" then
        local ok, err = M.createDirectory(dir)
        if not ok then
            return false, err
        end
    end
    local srcFile, err = io.open(src, "rb")
    if not srcFile then
        return false, err
    end
    local dstFile, err = io.open(dst, "wb")
    if not dstFile then
        srcFile:close()
        return false, err
    end
    local data = srcFile:read("*a")
    srcFile:close()
    dstFile:write(data)
    dstFile:close()
    return true
end

--- create directory, recursively
---@param path string @the directory path to create
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.createDirectory(path)
    local attr = M.pathInfo(path)
    if attr and attr.mode == "directory" then
        return true
    end
    local dir, name = M.splitPath(path)
    if name == "" then
        return true
    end
    local ok, err = M.createDirectory(dir)
    if not ok then
        return false, err
    end
    local ok, err = lfs.mkdir(path)
    if not ok then
        return false, err
    end
    return true
end

--- remove directory, recursively
---@param path string @the directory path to remove
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.removeDirectory(path)
    path = path:gsub("[\\/]+$", "")
    local attr = M.pathInfo(path)
    if not attr then
        return true
    end
    if attr.mode ~= "directory" then
        return false, "path is not a directory"
    end
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local filepath = path .. "/" .. file
            local attr = M.pathInfo(filepath)
            if attr.mode == "directory" then
                local ok, err = M.removeDirectory(filepath)
                if not ok then
                    return false, err
                end
            else
                local ok, err = M.removeFile(filepath)
                if not ok then
                    return false, err
                end
            end
        end
    end
    return lfs.rmdir(path)
end

--- move directory
---@param src string @the source directory path
---@param dst string @the destination directory path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.moveDirectory(src, dst)
    local dir = M.splitPath(dst, false)
    if dir ~= "" then
        local ok, err = M.createDirectory(dir)
        if not ok then
            return false, err
        end
    end
    local ok, err = os.rename(src, dst)
    if not ok then
        return false, err
    end
    return true
end

return M
