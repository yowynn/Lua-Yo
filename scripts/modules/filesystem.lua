--- filesystem module
---@author: Wynn Yo 2023-04-28 15:23:55
local M = {}

-- # DEPENDENCIES:
local lfs = require("lfs") -- @https://lunarmodules.github.io/luafilesystem/
assert(error, "`error` not found")
assert(require, "`require` not found")
assert(select, "`select` not found")
assert(io.open, "`io.open` not found")
assert(os.remove, "`os.remove` not found")
assert(os.rename, "`os.rename` not found")
assert(package.config, "`package.config` not found")

-- # CONSTANTS_DEFINITION:

--- path separator
M.PATH_SEPARATOR = package.config:sub(1, 1)

-- # MODULE_DEFINITION:

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

--- combine paths
---@param path1 string @the first path
---@param path2 string @the second path
---@vararg string @the rest paths
---@return string @the combined path
function M.combinePath(path1, path2, ...)
    if select("#", ...) > 0 then
        path2 = M.combinePath(path2, ...)
    end
    path1 = path1:gsub("[\\/]+$", "")
    return path1 .. M.PATH_SEPARATOR .. path2
end

--- check path validity at multi-platforms
---@param path string @the path to check
---@return boolean|string @pretty path if valid, otherwise false
---@return string @the error message if invalid
function M.checkPath(path)
    -- make path pretty and match the platform
    path = path:gsub("[\\/]+", M.PATH_SEPARATOR)
    path = path:gsub("^%s+", ""):gsub("%s+$", "")
    -- check path
    local invalidChars = "[<>:\"/\\|?*]"
    if path:match(invalidChars) then
        return false, "invalid characters"
    end
    if path:match("^%s") or path:match("%s$") then
        return false, "leading or trailing spaces"
    end
    if path:match("[\\/]%.$") then
        return false, "dot at the end of path"
    end
    return path
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
            local filepath = M.combinePath(path, file)
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

--- copy directory
---@param src string @the source directory path
---@param dst string @the destination directory path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.copyDirectory(src, dst)
    local dir = M.splitPath(dst, false)
    if dir ~= "" then
        local ok, err = M.createDirectory(dir)
        if not ok then
            return false, err
        end
    end
    local ok, err = M.createDirectory(dst)
    if not ok then
        return false, err
    end
    for file in lfs.dir(src) do
        if file ~= "." and file ~= ".." then
            local srcFile = M.combinePath(src, file)
            local dstFile = M.combinePath(dst, file)
            local attr = M.pathInfo(srcFile)
            if attr.mode == "directory" then
                local ok, err = M.copyDirectory(srcFile, dstFile)
                if not ok then
                    return false, err
                end
            else
                local ok, err = M.copyFile(srcFile, dstFile)
                if not ok then
                    return false, err
                end
            end
        end
    end
    return true
end

--- remove file or directory
---@param path string @the file or directory path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.remove(path)
    local attr = M.pathInfo(path)
    if not attr then
        return true
    end
    if attr.mode == "directory" then
        return M.removeDirectory(path)
    else
        return M.removeFile(path)
    end
end

--- move file or directory
---@param src string @the source file or directory path
---@param dst string @the destination file or directory path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.move(src, dst)
    local attr = M.pathInfo(src)
    if not attr then
        return false, "source file or directory not found"
    end
    if attr.mode == "directory" then
        return M.moveDirectory(src, dst)
    else
        return M.moveFile(src, dst)
    end
end

--- copy file or directory
---@param src string @the source file or directory path
---@param dst string @the destination file or directory path
---@return boolean @true if success, otherwise false
---@return string @the error message if failed
function M.copy(src, dst)
    local attr = M.pathInfo(src)
    if not attr then
        return false, "source file or directory not found"
    end
    if attr.mode == "directory" then
        return M.copyDirectory(src, dst)
    else
        return M.copyFile(src, dst)
    end
end

--- iterate files in directory
---@param path string @the directory path
---@param isRecursive boolean @iterate recursively
---@param containSelf boolean @contain self
---@param filter fun(path:string, isDirectory:boolean):boolean @the filter function
---@return (fun():string, boolean) @the iterator, return the file path and is directory
---@return string[] @the file list
function M.files(path, isRecursive, containSelf, filter)
    local filepath = path:gsub("[\\/]+$", "")
    local list = {}
    local function _iterate(path)
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local filepath = M.combinePath(path, file)
                local attr = M.pathInfo(filepath)
                local isDirectory = attr.mode == "directory"
                if not filter or filter(filepath, isDirectory) then
                    if isDirectory then
                        list[#list+1] = filepath .. M.PATH_SEPARATOR
                        if isRecursive then
                            _iterate(filepath)
                        end
                    else
                        list[#list+1] = filepath
                    end
                end
            end
        end
    end
    local attr = M.pathInfo(path)
    if attr then
        local isDirectory = attr.mode == "directory"
        if not filter or filter(filepath, isDirectory) then
            if containSelf then
                if isDirectory then
                    list[#list+1] = filepath .. M.PATH_SEPARATOR
                else
                    list[#list+1] = filepath
                end
            end
            if isDirectory then
                _iterate(filepath)
            end
        end
    end
    local i = 0
    return function(list)
        i = i + 1
        local path = list[i]
        if path then
            if path:sub(-1) == M.PATH_SEPARATOR then
                return path:sub(1, -2), true
            else
                return path, false
            end
        end
    end, list
end

-- # MODULE_EXPORT:

M.__proto = {
    splitPath = M.splitPath,
    combinePath = M.combinePath,
    checkPath = M.checkPath,
    pathInfo = M.pathInfo,
    createFile = M.createFile,
    removeFile = M.removeFile,
    moveFile = M.moveFile,
    copyFile = M.copyFile,
    createDirectory = M.createDirectory,
    removeDirectory = M.removeDirectory,
    moveDirectory = M.moveDirectory,
    copyDirectory = M.copyDirectory,
    remove = M.remove,
    move = M.move,
    copy = M.copy,
    files = M.files,
}

return M.__proto
