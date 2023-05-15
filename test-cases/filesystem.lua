print("Test: filesystem module")
local filesystem = require("filesystem")

--[[ filesystem.splitPath
do
    print("## TEST: filesystem.splitPath")
    local function test_splitPath(path)
        print(string.format("split path: <%s>", path))
        local dir, name, ext, isDir = filesystem.splitPath(path, true)
        print(string.format("\tsplit ext: <%s>, <%s>, <%s>  -- %s", dir, name, ext, isDir and "Directory" or "File"))
        dir, name, _, isDir = filesystem.splitPath(path, false)
        print(string.format("\tno split ext: <%s>, <%s>  -- %s", dir, name, isDir and "Directory" or "File"))
        print("")
    end
    -- some test paths
    test_splitPath("/home/user/documents/report.txt")
    test_splitPath("C:\\Users\\Wynn\\Desktop\\project\\code.lua")
    test_splitPath("/var/www/html/index.html")
    -- test more boundary cases
    test_splitPath("")  -- empty string
    test_splitPath("/")  -- root directory
    test_splitPath("file")  -- no path
    test_splitPath("file.")  -- file with no extension
    test_splitPath("file.txt.")  -- file with empty extension
    test_splitPath(".hidden")  -- hidden file
    test_splitPath("/dir/")  -- directory with trailing slash
    test_splitPath("/dir//file.txt")  -- double slashes in path
    test_splitPath("/dir/./file.txt")  -- current directory in path
    test_splitPath("/dir/../file.txt")  -- parent directory in path
end-- ]]

--[[ filesystem.moveFile
do
    print("## TEST: filesystem.moveFile")
    local function test_moveFile(src, dst)
        print(string.format("move file: <%s> -> <%s>", src, dst))
        local ok, err = filesystem.moveFile(src, dst)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    -- some test paths
    test_moveFile("testbox/filesystem/1.txt", "testbox/filesystem/folder2/1.txt")
    test_moveFile("testbox/filesystem/folder2", "testbox/filesystem/folder3/")
    test_moveFile("testbox/filesystem/folder3/1.txt", "testbox/filesystem/1/2/3/4.txt")
end-- ]]

--[[ filesystem.copyFile
do
    print("## TEST: filesystem.copyFile")
    local function test_copyFile(src, dst)
        print(string.format("copy file: <%s> -> <%s>", src, dst))
        local ok, err = filesystem.copyFile(src, dst)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    -- some test paths
    test_copyFile("testbox/filesystem/1.txt", "testbox/filesystem/copydir/1.txt")
end-- ]]

--[[ filesystem.createDirectory / filesystem.createFile / filesystem.removeDirectory / filesystem.removeFile
do
    print("## TEST: filesystem.createDirectory / filesystem.createFile")
    local function test_createDirectory(path)
        print(string.format("create directory: <%s>", path))
        local ok, err = filesystem.createDirectory(path)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    local function test_createFile(path)
        print(string.format("create file: <%s>", path))
        local ok, err = filesystem.createFile(path)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    local function test_removeDirectory(path)
        print(string.format("remove directory: <%s>", path))
        local ok, err = filesystem.removeDirectory(path)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    local function test_removeFile(path)
        print(string.format("remove file: <%s>", path))
        local ok, err = filesystem.removeFile(path)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    -- some test paths
    test_createDirectory("testbox/filesystem/a/b")
    test_createFile("testbox/filesystem/abc/6.txt")
    test_createFile("testbox/filesystem/a/b/你好.txt")
    test_removeDirectory("testbox/filesystem/a")
    test_removeFile("testbox/filesystem/abc/6.txt")
    test_removeFile("testbox/filesystem/abc/6.txt")
end-- ]]

--[[ filesystem.copyDirectory
do
    print("## TEST: filesystem.copyDirectory")
    local function test_copyDirectory(src, dst)
        print(string.format("copy directory: <%s> -> <%s>", src, dst))
        local ok, err = filesystem.copyDirectory(src, dst)
        print(string.format("\t%s", ok and "Success" or "Failed"))
        if not ok then
            print(string.format("\t%s", err))
        end
        print("")
    end
    -- some test paths
    test_copyDirectory("testbox/filesystem", "testbox/filesystem2")
    -- test_copyDirectory([=[C:\Users\Wynn\Desktop\Pink noise]=], [=[C:\Users\Wynn\Desktop\Pink noise2\test]=])
end-- ]]

--[[ filesystem.each
do
    print("## TEST: filesystem.each")
    local function test_each(path, isRecursive, containSelf, filter)
        print(string.format("each: <%s>, %s, %s", path, isRecursive and "recursive" or "non-recursive", containSelf and "contain self" or "not contain self"))
        for path, isDir in filesystem.each(path, isRecursive, containSelf, filter) do
            print(string.format("\t%s  -- %s", path, isDir and "Directory" or "File"))
        end
        print("")
    end
    -- some test paths
    test_each(".", true, true, function(path, isFolder)
        if isFolder and path:sub(-4, -1) == ".git" then
            return false
        end
        return true
    end)
end-- ]]
