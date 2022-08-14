@echo off
:: ========================
:: file build-luarocks.cmd
:: ========================
setlocal
:: set your download luarocks version
set LUAROCKS_VERSION=3.9.1
:: set lue version luarocks uses
set LUA_VERSION=5.4

set work_dir=%~dp0
:: Removes trailing backslash
set work_dir=%work_dir:~0,-1%
set source_dir=%work_dir%\luarocks-%LUAROCKS_VERSION%
set target_dir=%work_dir%\env
:: just copy the downloaded files to the build directory
echo **** COPY TO TARGET PATH ****
mkdir %target_dir%\bin
copy %source_dir%\luarocks.exe %target_dir%\bin\*.*
copy %source_dir%\luarocks-admin.exe %target_dir%\bin\*.*
echo **** SUCCESSFUL ****
echo.
:: test lua
echo **** LUAROCKS TEST ****
mkdir %target_dir%\cfg
set luarocks_config=%target_dir%\cfg\luarocks.lua
if not exist %luarocks_config% (type nul>%luarocks_config%)
%target_dir%\bin\luarocks.exe config home_tree %target_dir%
%target_dir%\bin\luarocks.exe config rocks_trees[1] %target_dir%
%target_dir%\bin\luarocks.exe config lua_interpreter lua.exe
%target_dir%\bin\luarocks.exe config lua_version %LUA_VERSION%
%target_dir%\bin\luarocks.exe config variables.LUA_DIR %target_dir%
%target_dir%\bin\luarocks.exe config variables.LUA_BINDIR %target_dir%\bin
%target_dir%\bin\luarocks.exe config variables.LUA_INCDIR %target_dir%\include
%target_dir%\bin\luarocks.exe config variables.LUA_LIBDIR %target_dir%\bin
%target_dir%\bin\luarocks.exe
echo.
pause
