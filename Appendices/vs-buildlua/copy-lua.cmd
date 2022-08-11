@echo off
set work_dir=%~dp0
set work_dir=%work_dir:~0,-1%
set bin_dir=%work_dir%\x64\Release
set lua_dir=%work_dir%\..\..\lua
set lua_bin_dir=%lua_dir%\bin
set lua_lib_dir=%lua_dir%\lib
set lua_include_dir=%lua_dir%\include
set lua_src_dir=%work_dir%\..\..\lua-5.4.4\src
copy "%bin_dir%\lua.exe" "%lua_bin_dir%\lua.exe"
copy "%bin_dir%\lua54.dll" "%lua_bin_dir%\lua54.dll"
copy "%bin_dir%\luac.exe" "%lua_bin_dir%\luac.exe"
copy "%bin_dir%\lua54.lib" "%lua_lib_dir%\lua54.lib"

copy %lua_src_dir%\luaconf.h %lua_include_dir%\*.*
copy %lua_src_dir%\lua.h %lua_include_dir%\*.*
copy %lua_src_dir%\lualib.h %lua_include_dir%\*.*
copy %lua_src_dir%\lauxlib.h %lua_include_dir%\*.*
copy %lua_src_dir%\lua.hpp %lua_include_dir%\*.*

pause
