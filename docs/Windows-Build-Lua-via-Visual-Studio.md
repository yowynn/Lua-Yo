## 建立空白解决方案

1. 文件 → 新建项目 → 空白解决方案
2. 输出**解决方案名称** (示例为 `vs-buildlua`), 选择**位置**后, 点击**创建**

## 准备 Lua 源码

[Lua: download area](http://www.lua.org/ftp/)

## 编译静态库文件 (`lua54.lib`)

1. 创建项目
    1. 文件 → 新建项目 → 空项目 (C++)
    2. 输出项目名称 (示例为 `lualib`), 添加到当前解决方案
2. 添加源文件

    在项目**源文件**筛选器中, 添加以下 `.c` 文件 (除了 `lua.c`, `luac.c` 之外的所有)

    > 实际会添加的源文件:
    `lapi.c`, `lauxlib.c`, `lbaselib.c`, `lcode.c`, `lcorolib.c`, `lctype.c`, `ldblib.c`, `ldebug.c`, `ldo.c`, `ldump.c`, `lfunc.c`, `lgc.c`, `linit.c`, `liolib.c`, `llex.c`, `lmathlib.c`, `lmem.c`, `loadlib.c`, `lobject.c`, `lopcodes.c`, `loslib.c`, `lparser.c`, `lstate.c`, `lstring.c`, `lstrlib.c`, `ltable.c`, `ltablib.c`, `ltm.c`, ~~`lua.c`~~, ~~`luac.c`~~, `lundump.c`, `lutf8lib.c`, `lvm.c`, `lzio.c`
    >
3. 添加头文件
    1. 找到 `.h` 文件所在的路径 `path/to/include` (Lua 默认和 `.c` 文件在一起)
    2. 右键项目 → 属性 → 配置属性 → C/C++ →  常规 → 附加包含目录 ⇒ 增量添加 `path/to/include`

    > `.h` 文件和 `.c` 文件在同一目录, 可以不用手动附加包含目录
    >

    > 实际会用到的头文件:
    `lapi.h`, `lauxlib.h`, `lcode.h`, `lctype.h`, `ldebug.h`, `ldo.h`, `lfunc.h`, `lgc.h`, `ljumptab.h`, `llex.h`, `llimits.h`, `lmem.h`, `lobject.h`, `lopcodes.h`, ~~`lopnames.h`~~, `lparser.h`, `lprefix.h`, `lstate.h`, `lstring.h`, `ltable.h`, `ltm.h`, `lua.h`, `luaconf.h`, `lualib.h`, `lundump.h`, `lvm.h`, `lzio.h`
    >
4. 修改项目属性 (右键 `lualib` 项目 → 属性)
    1. [optional] 配置属性 → 常规 → 目标文件名 ⇒ 设置为 `lua54`
    2. 配置属性 → 常规 → 配置类型 ⇒ 设置为 `静态库(.lib)`
        - `静态库(.lib)` 会生成一个目标文件 `lua54.lib`
    3. [optional] 配置属性 → C/C++ → 代码生成 → 运行库 ⇒ 设置为 `多线程 (/MT)`
        - 这个设置决定生成的目标在运行时是否依赖其他 `.dll` 库
    4. 配置属性 → C/C++ → 高级 → 编译为 ⇒ 设置为 `编译为 C 代码 (/TC)`
5. 生成
    1. 设置解决方案配置 (示例 `Release`) 和目标平台 (示例 `x64`)
    2. 生成 → 生成 `lualib`

## 编译动态库文件 (`lua54.dll`)

1. 创建项目
    1. 文件 → 新建项目 → 空项目 (C++)
    2. 输出项目名称 (示例为 `lualib(dyna)`), 添加到当前解决方案
2. 添加源文件

    在项目**源文件**筛选器中, 添加以下 `.c` 文件 (除了 `lua.c`, `luac.c` 之外的所有)

    > 实际会添加的源文件:
    `lapi.c`, `lauxlib.c`, `lbaselib.c`, `lcode.c`, `lcorolib.c`, `lctype.c`, `ldblib.c`, `ldebug.c`, `ldo.c`, `ldump.c`, `lfunc.c`, `lgc.c`, `linit.c`, `liolib.c`, `llex.c`, `lmathlib.c`, `lmem.c`, `loadlib.c`, `lobject.c`, `lopcodes.c`, `loslib.c`, `lparser.c`, `lstate.c`, `lstring.c`, `lstrlib.c`, `ltable.c`, `ltablib.c`, `ltm.c`, ~~`lua.c`~~, ~~`luac.c`~~, `lundump.c`, `lutf8lib.c`, `lvm.c`, `lzio.c`
    >
3. 添加头文件
    1. 找到 `.h` 文件所在的路径 `path/to/include` (Lua 默认和 `.c` 文件在一起)
    2. 右键项目 → 属性 → 配置属性 → C/C++ →  常规 → 附加包含目录 ⇒ 增量添加 `path/to/include`

    > `.h` 文件和 `.c` 文件在同一目录, 可以不用手动附加包含目录
    >

    > 实际会用到的头文件:
    `lapi.h`, `lauxlib.h`, `lcode.h`, `lctype.h`, `ldebug.h`, `ldo.h`, `lfunc.h`, `lgc.h`, `ljumptab.h`, `llex.h`, `llimits.h`, `lmem.h`, `lobject.h`, `lopcodes.h`, ~~`lopnames.h`~~, `lparser.h`, `lprefix.h`, `lstate.h`, `lstring.h`, `ltable.h`, `ltm.h`, `lua.h`, `luaconf.h`, `lualib.h`, `lundump.h`, `lvm.h`, `lzio.h`
    >
4. 修改项目属性 (右键 `lualib(dyna)` 项目 → 属性)
    1. [optional] 配置属性 → 常规 → 目标文件名 ⇒ 设置为 `lua54`
    2. 配置属性 → 常规 → 配置类型 ⇒ 设置为 `动态库(.dll)`
        - `动态库(.dll)` 会生成两个目标文件 `lua54.lib` 和 `lua54.dll`
    3. 配置属性 → C/C++ → 预处理器 → 预处理器定义 ⇒ 增量添加 `LUA_BUILD_AS_DLL`
        - 在生成 `动态库(.dll)` 时, 加入此选项会生成 `lua54.lib`, 此时动态库才能被引用到其他项目中
    4. [optional] 配置属性 → C/C++ → 代码生成 → 运行库 ⇒ 设置为 `多线程 (/MT)`
        - 这个设置决定生成的目标在运行时是否依赖其他 `.dll` 库
    5. 配置属性 → C/C++ → 高级 → 编译为 ⇒ 设置为 `编译为 C 代码 (/TC)`
5. 生成
    1. 设置解决方案配置 (示例 `Release`) 和目标平台 (示例 `x64`)
    2. 生成 → 生成 `lualib(dyna)`

## 编译解释器 (`lua.exe`) (基于库文件)

1. 创建项目
    1. 文件 → 新建项目 → 空项目 (C++)
    2. 输出项目名称 (示例为 `lua`), 添加到当前解决方案
2. 添加对 `lualib` / `lualib(dyna)` 项目引用
    1. 右键 `lua` 项目 → 添加 → 引用
    2. 添加对项目 `lualib` / `lualib(dyna)` 的引用
3. 添加源文件

    在项目**源文件**筛选器中, 添加以下 `.c` 文件

    > 实际会添加的源文件:
    `luac.c`
    >
4. 添加头文件
    1. 找到 `.h` 文件所在的路径 `path/to/include` (Lua 默认和 `.c` 文件在一起)
    2. 右键项目 → 属性 → 配置属性 → C/C++ →  常规 → 附加包含目录 ⇒ 增量添加 `path/to/include`

    > `.h` 文件和 `.c` 文件在同一目录, 可以不用手动附加包含目录
    >

    > 实际会用到的头文件:
    ~~`lapi.h`~~, `lauxlib.h`, ~~`lcode.h`~~, ~~`lctype.h`~~, ~~`ldebug.h`~~, ~~`ldo.h`~~, ~~`lfunc.h`~~, ~~`lgc.h`~~, ~~`ljumptab.h`~~, ~~`llex.h`~~, ~~`llimits.h`~~, ~~`lmem.h`~~, ~~`lobject.h`~~, ~~`lopcodes.h`~~, ~~`lopnames.h`~~, ~~`lparser.h`~~, `lprefix.h`, ~~`lstate.h`~~, ~~`lstring.h`~~, ~~`ltable.h`~~, ~~`ltm.h`~~, `lua.h`, `luaconf.h`, `lualib.h`, ~~`lundump.h`~~, ~~`lvm.h`~~, ~~`lzio.h`~~
    >
5. 修改项目属性 (右键 `lua` 项目 → 属性)
    1. [optional] 配置属性 → 常规 → 目标文件名 ⇒ 设置为 `lua`
    2. 配置属性 → 常规 → 配置类型 ⇒ 设置为 `应用程序(.exe)`
    3. [optional] 配置属性 → C/C++ → 代码生成 → 运行库 ⇒ 设置为 `多线程 (/MT)`
        - 这个设置决定生成的目标在运行时是否依赖其他 `.dll` 库
    4. 配置属性 → C/C++ → 高级 → 编译为 ⇒ 设置为 `编译为 C 代码 (/TC)`
6. 生成
    1. 设置解决方案配置 (示例 `Release`) 和目标平台 (示例 `x64`)
    2. 生成 → 生成 `lua`

## 编译编译器 (`luac.exe`)

1. 创建项目
    1. 文件 → 新建项目 → 空项目 (C++)
    2. 输出项目名称 (示例为 `luac`), 添加到当前解决方案
2. 添加源文件

    在项目**源文件**筛选器中, 添加以下 `.c` 文件 (除了 `lua.c` 之外的所有)

    > 实际会添加的源文件:
    `lapi.c`, `lauxlib.c`, `lbaselib.c`, `lcode.c`, `lcorolib.c`, `lctype.c`, `ldblib.c`, `ldebug.c`, `ldo.c`, `ldump.c`, `lfunc.c`, `lgc.c`, `linit.c`, `liolib.c`, `llex.c`, `lmathlib.c`, `lmem.c`, `loadlib.c`, `lobject.c`, `lopcodes.c`, `loslib.c`, `lparser.c`, `lstate.c`, `lstring.c`, `lstrlib.c`, `ltable.c`, `ltablib.c`, `ltm.c`, ~~`lua.c`~~, `luac.c`, `lundump.c`, `lutf8lib.c`, `lvm.c`, `lzio.c`
    >
3. 添加头文件
    1. 找到 `.h` 文件所在的路径 `path/to/include` (Lua 默认和 `.c` 文件在一起)
    2. 右键项目 → 属性 → 配置属性 → C/C++ →  常规 → 附加包含目录 ⇒ 增量添加 `path/to/include`

    > `.h` 文件和 `.c` 文件在同一目录, 可以不用手动附加包含目录
    >

    > 实际会用到的头文件:
    `lapi.h`, `lauxlib.h`, `lcode.h`, `lctype.h`, `ldebug.h`, `ldo.h`, `lfunc.h`, `lgc.h`, `ljumptab.h`, `llex.h`, `llimits.h`, `lmem.h`, `lobject.h`, `lopcodes.h`, `lopnames.h`, `lparser.h`, `lprefix.h`, `lstate.h`, `lstring.h`, `ltable.h`, `ltm.h`, `lua.h`, `luaconf.h`, `lualib.h`, `lundump.h`, `lvm.h`, `lzio.h`
    >
4. 修改项目属性 (右键 `luac` 项目 → 属性)
    1. [optional] 配置属性 → 常规 → 目标文件名 ⇒ 设置为 `luac`
    2. 配置属性 → 常规 → 配置类型 ⇒ 设置为 `应用程序(.exe)`
    3. [optional] 配置属性 → C/C++ → 代码生成 → 运行库 ⇒ 设置为 `多线程 (/MT)`
        - 这个设置决定生成的目标在运行时是否依赖其他 `.dll` 库
    4. 配置属性 → C/C++ → 高级 → 编译为 ⇒ 设置为 `编译为 C 代码 (/TC)`
5. 生成
    1. 设置解决方案配置 (示例 `Release`) 和目标平台 (示例 `x64`)
    2. 生成 → 生成 `luac`

## 其他相关

### 查看 `.dll` 文件引用的其他 `.dll` 文件

1. 打开 VS 控制台 `Developer Command Prompt for VS 2022`
2. 输入指令

    ```powershell
    dumpbin -imports path/to/dllfile.dll
    ```
