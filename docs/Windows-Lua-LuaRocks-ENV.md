### 参考

[windows-lua-luarocks-install-guide: Guide how to install lua and luarocks in window pc](https://github.com/d954mas/windows-lua-luarocks-install-guide)

## 安装编译器 (MinGW)

1. 下载 [MinGW Installation Manager Setup Tool](https://sourceforge.net/projects/mingw/), 并运行, 等待安装完成.
2. 安装完成后, 运行 MinGW Installation Manager
3. 勾选依赖的包

    左侧列表切换 Basic Setup 后, 勾选

    - mingw32-base
    - mingw32-gcc-g++
    - msys-base
4. 执行 Installation → Apply Changes
5. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 MinGW 运行目录 (默认 `C:\MinGW\bin`)

## 安装 Lua

1. 下载 [Lua 源码](http://www.lua.org/ftp/). 解压到目录 (示例 `D:\Lua-Yo\lua-5.4.4`)
2. 编译 Lua 源码 (示例输出到 `D:\Lua-Yo\env`)

    ```bash
    :: example at path: D:\Lua-Yo

    setlocal
    set LUA_VERSION=5.4.4
    set COMPILER_DIR=P:\Applications\msys64\mingw64\bin
    set MAKE=mingw32-make

    set work_dir=%~dp0
    set work_dir=%work_dir:~0,-1%
    set source_dir=%work_dir%\lua-%LUA_VERSION%
    set target_dir=%work_dir%\env

    cd /D %source_dir%
    set path=%COMPILER_DIR%;%path%
    %MAKE% PLAT=mingw

    mkdir %target_dir%
    mkdir %target_dir%\bin
    mkdir %target_dir%\include
    mkdir %target_dir%\lib
    copy %source_dir%\src\*.exe %target_dir%\bin\*.*
    copy %source_dir%\src\*.dll %target_dir%\bin\*.*
    copy %source_dir%\src\luaconf.h %target_dir%\include\*.*
    copy %source_dir%\src\lua.h %target_dir%\include\*.*
    copy %source_dir%\src\lualib.h %target_dir%\include\*.*
    copy %source_dir%\src\lauxlib.h %target_dir%\include\*.*
    copy %source_dir%\src\lua.hpp %target_dir%\include\*.*
    copy %source_dir%\src\liblua.a %target_dir%\lib\liblua.a
    ```

3. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 Lua 运行目录 (示例 `D:\Lua-Yo\env\bin`)

## 安装 LuaRocks

1. 下载 [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download). 解压至目录 (示例 `D:\Lua-Yo\env\bin`)
2. 添加环境变量
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 在 `Path` 项中添加 LuaRocks 运行目录 (示例 `D:\Lua-Yo\env\bin`)
3. [optional]更改默认配置路径
    1. `win`+`pause` → 高级系统设置 → 高级 → 环境变量
    2. 添加 `LUAROCKS_CONFIG` 项设置值为新的配置文件的路径 (示例 `D:\Lua-Yo\env\cfg\luarocks.lua`)
    3. 注意应该保证该文件存在, 不然可能会因为读不到该文件而 fallback 到原始目录
4. 更改 LuaRocks 的配置

    ```bash
    :: example at path: D:\Lua-Yo

    set work_dir=%~dp0
    set work_dir=%work_dir:~0,-1%
    set target_dir=%work_dir%\env

    :: 设置模块安装目录
    luarocks config home_tree %target_dir%
    luarocks config rocks_trees[1] %target_dir%

    :: 指定lua相关的环境
    luarocks config lua_interpreter lua.exe
    luarocks config lua_version %LUA_VERSION%
    luarocks config variables.LUA_DIR %target_dir%
    luarocks config variables.LUA_BINDIR %target_dir%\bin
    luarocks config variables.LUA_INCDIR %target_dir%\include
    luarocks config variables.LUA_LIBDIR %target_dir%\bin
    ```

5. 用 LuaRocks 生成环境变量 `luarock path`, 结果类似于:

    ```
    SET LUA_PATH=D:\Lua-Yo\env\bin\lua\?.lua;D:\Lua-Yo\env\bin\lua\?\init.lua;D:\Lua-Yo\env\bin\?.lua;D:\Lua-Yo\env\bin\?\init.lua;D:\Lua-Yo\env\bin\..\share\lua\5.4\?.lua;D:\Lua-Yo\env\bin\..\share\lua\5.4\?\init.lua;.\?.lua;.\?\init.lua;D:\Lua-Yo\env/share/lua/5.4/?.lua;D:\Lua-Yo\env/share/lua/5.4/?/init.lua
    SET LUA_CPATH=D:\Lua-Yo\env\bin\?.dll;D:\Lua-Yo\env\bin\..\lib\lua\5.4\?.dll;D:\Lua-Yo\env\bin\loadall.dll;.\?.dll;D:\Lua-Yo\env/lib/lua/5.4/?.dll
    SET PATH=D:\Lua-Yo\env/bin;%PATH%
    ```

6. 将上面所展示的值, **增量**添加到环境变量

## 使用 LuaRocks 安装依赖

1. 通过 Lua 包名安装 (示例 `luarocks install dkjson`), 输出类似于:

    ```
    Installing https://luarocks.org/dkjson-2.6-1.src.rock

    dkjson 2.6-1 depends on lua >= 5.1, < 5.5 (5.4-1 provided by VM)
    No existing manifest. Attempting to rebuild...
    dkjson 2.6-1 is now installed in A:\Github\Lua-Yo\rocks (license: MIT/X11)
    ```


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

    - 解决方案
        - 尝试用 [MSYS2](https://www.msys2.org/) 来编译 (安装完成后, 运行 `MSYS2 MinGW x64`)

            ```bash
            # 首次安装编译环境, 详见 https://www.msys2.org/
            pacman -S --needed base-devel mingw-w64-x86_64-toolchain
            # 安装LuaRocks, 详见 https://packages.msys2.org/package/mingw-w64-x86_64-lua-luarocks?repo=mingw64
            pacman -S mingw-w64-x86_64-lua-luarocks

            # 这里的Luarocks配置, 应该可以从以上在Windows中的设置继承

            # 安装LuaSocket
            luarocks install luasocket
            ```


## 其他链接

1. **[MinGW-w64](https://www.mingw-w64.org/downloads/#mingw-builds) 下载**
