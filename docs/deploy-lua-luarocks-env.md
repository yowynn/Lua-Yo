### 参考

[windows-lua-luarocks-install-guide: Guide how to install lua and luarocks in window pc](https://github.com/d954mas/windows-lua-luarocks-install-guide)

<aside>
💡 本示例中，项目检出路径 `%ROOT%` 为：`P:\Applications\Lua-Yo`

</aside>

## 安装 make 编译器

1. MinGW - Minimalist GNU for Windows

    [MinGW - Minimalist GNU for Windows Project Top Page - OSDN](https://osdn.net/projects/mingw/)

2. MSYS2 - Minimal SYStem 2 (MinGW-w64)

    [MSYS2](https://www.msys2.org/)

3. CMake（可选，有些 rocks 的编译需要用到，比如 `luv`）

    [Download | CMake](https://cmake.org/download/)


## 安装 Lua

1. 下载 [Lua 源码](http://www.lua.org/ftp/)，解压到目录 （示例 `.\archives\lua\`）。
2. 打开批处理脚本（`.\deploy-lua-make.cmd`），配置编译环境变量：

    ```bash
    # 设置你下载的 lua 源码版本
    set LUA_VERSION=5.4.4
    # 设置你的 make 编译器查找路径
    set COMPILER_DIR=P:\Applications\msys64\mingw64\bin
    # 设置你的编译器的可执行文件名
    set MAKE=mingw32-make
    ```

3. 运行批处理脚本，编译 Lua。（结果输出到 `.\env\` 目录）
4. 添加环境变量
    1. 定位到：`win+pause` → `高级系统设置` → `高级` → `环境变量`
    2. 添加以下项目：

        ```bash
        SET PATH=P:\Applications\Lua-Yo\env/bin;%PATH%
        ```


    <aside>
    💡 此步可以忽略，因为后面 luarocks 部分还会添加此条环境变量。

    </aside>


## 安装 LuaRocks

1. 下载 [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download)，解压至目录 （示例 `.\archives\luarocks\`）。
2. 打开批处理脚本（`.\deploy-luarocks.cmd`），配置编译环境变量：

    ```bash
    # 设置你下载的 luarocks 源码版本
    set LUAROCKS_VERSION=3.9.2
    # 设置绑定的 lua 版本
    LUA_VERSION=5.4
    # 设置你下载的 luarocks 位数
    set LUAROCKS_ARCH=64
    ```

3. 运行批处理脚本，拷贝和配置 LuaRocks。（结果输出到 `.\env\` 目录）
    - 脚本会指定自定义的 luarocks 配置文件路径：`.\env\cfg\luarocks.lua`
    - 脚本最后会输出要添加的环境变量，类似如下：

        ```bash
        SET LUAROCKS_CONFIG=P:\Applications\Lua-Yo\env\cfg\luarocks.lua
        SET LUA_PATH=P:\Applications\Lua-Yo\env\bin\lua\?.lua;P:\Applications\Lua-Yo\env\bin\lua\?\init.lua;P:\Applications\Lua-Yo\env\bin\?.lua;P:\Applications\Lua-Yo\env\bin\?\init.lua;P:\Applications\Lua-Yo\env\bin\..\share\lua\5.4\?.lua;P:\Applications\Lua-Yo\env\bin\..\share\lua\5.4\?\init.lua;.\?.lua;.\?\init.lua;P:\Applications\Lua-Yo\env/share/lua/5.4/?.lua;P:\Applications\Lua-Yo\env/share/lua/5.4/?/init.lua;%LUA_PATH%
        SET LUA_CPATH=P:\Applications\Lua-Yo\env\bin\?.dll;P:\Applications\Lua-Yo\env\bin\..\lib\lua\5.4\?.dll;P:\Applications\Lua-Yo\env\bin\loadall.dll;.\?.dll;P:\Applications\Lua-Yo\env/lib/lua/5.4/?.dll;%LUA_CPATH%
        SET PATH=P:\Applications\Lua-Yo\env/bin;%PATH%
        ```

4. 添加环境变量
    1. 定位到：`win+pause` → `高级系统设置` → `高级` → `环境变量`
    2. 添加上面提到的环境变量。

## 测试环境是否部署成功

```powershell
PS C:\Users\Wynn> lua -v
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
PS C:\Users\Wynn> luarocks --version
luarocks 3.9.2
LuaRocks main command-line interface
```

<aside>
💡 如不成功也可能需要重启电脑或者终端。

</aside>

## 使用 LuaRocks 安装依赖

```powershell
# 安装 socket 库
luarocks install luasocket

# 安装 dkjson 库
luarocks install dkjson

# 安装 lua-uv 库
luarocks install luv
```

## 其他常见使用方式

### 列出已经安装的 rocks

```powershell
luarocks list
```
