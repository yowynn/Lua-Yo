# Windows-Lua-LuaRocks-ENV.md

### 参考

[windows-lua-luarocks-install-guide: Guide how to install lua and luarocks in window pc](https://github.com/d954mas/windows-lua-luarocks-install-guide)

## 安装编译器 (MinGW)

1. 下载 [MinGW Installation Manager Setup Tool](https://sourceforge.net/projects/mingw/), 并运行, 等待安装完成.
2. 安装完成后, 运行 MinGW Installation Manager
3. 勾选依赖的包

    左侧列表切换 Basic Setup 后, 勾选

    - mingw32-base
    - mingw32-gcc-g++
    - msys-base
4. 执行 Installation → Apply Changes
5. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 MinGW 运行目录 (默认 `C:\MinGW\bin`)

## 安装 Lua

1. 下载 [Lua 源码](http://www.lua.org/ftp/). 解压到目录 (示例 `D:\Lua-Yo\lua-5.4.4`)
2. 编译 Lua 源码 (示例输出到 `D:\Lua-Yo\lua`)

    ```bat
    @echo off
    :: ========================
    :: file build-lua.cmd
    :: ========================
    setlocal
    :: you may change the following variable's value
    :: to suit the downloaded version
    set lua_version=5.4.4
    set work_dir=%~dp0
    :: Removes trailing backslash
    :: to enhance readability in the following steps
    set work_dir=%work_dir:~0,-1%
    set lua_install_dir=%work_dir%\lua
    set compiler_bin_dir=%work_dir%\tdm-gcc\bin
    set lua_build_dir=%work_dir%\lua-%lua_version%
    set path=%compiler_bin_dir%;%path%
    cd /D %lua_build_dir%
    mingw32-make PLAT=mingw
    echo.
    echo **** COMPILATION TERMINATED ****
    echo.
    echo **** BUILDING BINARY DISTRIBUTION ****
    echo.
    :: create a clean "binary" installation
    mkdir %lua_install_dir%
    mkdir %lua_install_dir%\doc
    mkdir %lua_install_dir%\bin
    mkdir %lua_install_dir%\include
    mkdir %lua_install_dir%\lib
    copy %lua_build_dir%\doc\*.* %lua_install_dir%\doc\*.*
    copy %lua_build_dir%\src\*.exe %lua_install_dir%\bin\*.*
    copy %lua_build_dir%\src\*.dll %lua_install_dir%\bin\*.*
    copy %lua_build_dir%\src\luaconf.h %lua_install_dir%\include\*.*
    copy %lua_build_dir%\src\lua.h %lua_install_dir%\include\*.*
    copy %lua_build_dir%\src\lualib.h %lua_install_dir%\include\*.*
    copy %lua_build_dir%\src\lauxlib.h %lua_install_dir%\include\*.*
    copy %lua_build_dir%\src\lua.hpp %lua_install_dir%\include\*.*
    copy %lua_build_dir%\src\liblua.a %lua_install_dir%\lib\liblua.a
    echo.
    echo **** BINARY DISTRIBUTION BUILT ****
    echo.
    %lua_install_dir%\bin\lua.exe -e "print [[Hello!]];print[[Simple Lua test successful!!!]]"
    echo.

    pause

    ```

3. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 Lua 运行目录 (默认 `D:\Lua-Yo\lua\bin`)

## 安装 LuaRocks

1. 下载 LuaRocks. 解压至目录 (示例 `D:\Lua-Yo\lua\luarocks`)
2. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 LuaRocks 运行目录 (默认 `D:\Lua-Yo\lua\luarocks`)
3. [optional]更改默认安装路径 (示例 `D:\Lua-Yo\lua\rocks`)

    ```
    luarocks config --lua-version 5.4 home_tree D:\Lua-Yo\lua\rocks

    ```

4. 用 LuaRocks 生成环境变量 `luarocks --lua-version 5.4 path`, 结果类似于:

    ```
    SET LUA_PATH=D:\Lua-Yo\lua\luarocks\lua\?.lua;D:\Lua-Yo\lua\luarocks\lua\?\init.lua;D:\Lua-Yo\lua\luarocks\?.lua;D:\Lua-Yo\lua\luarocks\?\init.lua;D:\Lua-Yo\lua\luarocks\..\share\lua\5.4\?.lua;D:\Lua-Yo\lua\luarocks\..\share\lua\5.4\?\init.lua;.\?.lua;.\?\init.lua;D:\Lua-Yo\lua\rocks/share/lua/5.4/?.lua;D:\Lua-Yo\lua\rocks/share/lua/5.4/?/init.lua
    SET LUA_CPATH=D:\Lua-Yo\lua\luarocks\?.dll;D:\Lua-Yo\lua\luarocks\..\lib\lua\5.4\?.dll;D:\Lua-Yo\lua\luarocks\loadall.dll;.\?.dll;D:\Lua-Yo\lua\rocks/lib/lua/5.4/?.dll
    SET PATH=D:\Lua-Yo\lua\rocks/bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Users\WDAGUtilityAccount\AppData\Local\Microsoft\WindowsApps;C:\MinGW\bin;D:\Lua-Yo\lua\bin;D:\Lua-Yo\lua\luarocks;

    ```

5. 将上面所展示的值, **增量**添加到环境变量

## 使用 LuaRocks 安装依赖

1. 通过 Lua 包名安装 (示例 `luarocks --lua-version 5.4 install dkjson`), 输出类似于:

    ```
    Installing https://luarocks.org/dkjson-2.6-1.src.rock

    dkjson 2.6-1 depends on lua >= 5.1, < 5.5 (5.4-1 provided by VM)
    No existing manifest. Attempting to rebuild...
    dkjson 2.6-1 is now installed in A:\Github\Lua-Yo\rocks (license: MIT/X11)

    ```

    💡 命令中须显式指定 Lua 版本 `--lua-version 5.4`


## 使用中的问题

1. 安装 luasocket 库失败, 报错类似于:

    ```
    ...
    mingw32-gcc -O2 -c -o src/wsocket.o -IA:\Github\Lua-Yo\lua/include src/wsocket.c -DLUASOCKET_DEBUG -DWINVER=0x0501 -Ic:/mingw/include
    In file included from src/wsocket.h:11:0,
                     from src/socket.h:18,
                     from src/wsocket.c:12:
    src/wsocket.c: In function 'socket_gaistrerror':
    src/wsocket.c:419:14: error: 'ERROR_NOT_ENOUGH_MEMORY' undeclared (first use in this function)
             case EAI_MEMORY: return PIE_MEMORY;
                  ^
    src/wsocket.c:419:14: note: each undeclared identifier is reported only once for each function it appears in

    Error: Build error: Failed compiling object src/wsocket.o

    ```

    - 尝试在 src/wsocket.h 中添加:

        ```
        #include <winerror.h>

        ```


## 其他链接

1. **[MinGW-w64](https://www.mingw-w64.org/downloads/#mingw-builds) 下载**
