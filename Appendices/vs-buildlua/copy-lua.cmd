@echo off
set work_dir=%~dp0
set work_dir=%work_dir:~0,-1%
set bin_dir=%work_dir%\x64\Release
set lua_dir=%work_dir%\..\..\lua
set lua_bin_dir=%lua_dir%\bin
set lua_lib_dir=%lua_dir%\lib
copy "%bin_dir%\lua.exe" "%lua_bin_dir%\lua.exe"
copy "%bin_dir%\lua54.dll" "%lua_bin_dir%\lua54.dll"
copy "%bin_dir%\luac.exe" "%lua_bin_dir%\luac.exe"
copy "%bin_dir%\lua54.lib" "%lua_lib_dir%\lua54.lib"

pause
