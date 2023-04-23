:: deploy-luarocks.cmd

@echo off
setlocal

:: some environment variables settings

REM set your download luarocks version
set LUAROCKS_VERSION=3.9.2
REM set your lua environment version
set LUA_VERSION=5.4
REM set your os bit, 32 or 64
set LUAROCKS_ARCH=64

set work_dir=%~dp0
:: remove trailing backslash
set work_dir=%work_dir:~0,-1%
set source_dir=%work_dir%\archives\luarocks\luarocks-%LUAROCKS_VERSION%-windows-%LUAROCKS_ARCH%
set target_dir=%work_dir%\env
set LUAROCKS_CONFIG=%target_dir%\cfg\luarocks.lua

:: just copy the downloaded files to the build directory

echo **** COPY TO TARGET PATH ****
mkdir %target_dir%\bin
copy %source_dir%\luarocks.exe %target_dir%\bin\*.*
copy %source_dir%\luarocks-admin.exe %target_dir%\bin\*.*
echo **** SUCCESSFUL ****
echo.

:: init luarocks base config

echo **** INIT LUAROCKS BASE CONFIG ****
mkdir %target_dir%\cfg
if not exist %LUAROCKS_CONFIG% (type nul>%LUAROCKS_CONFIG%)
%target_dir%\bin\luarocks.exe config home_tree %target_dir%
%target_dir%\bin\luarocks.exe config rocks_trees[1] %target_dir%
%target_dir%\bin\luarocks.exe config lua_interpreter lua.exe
%target_dir%\bin\luarocks.exe config lua_version %LUA_VERSION%
%target_dir%\bin\luarocks.exe config variables.LUA_DIR %target_dir%
%target_dir%\bin\luarocks.exe config variables.LUA_BINDIR %target_dir%\bin
%target_dir%\bin\luarocks.exe config variables.LUA_INCDIR %target_dir%\include
%target_dir%\bin\luarocks.exe config variables.LUA_LIBDIR %target_dir%\bin
%target_dir%\bin\luarocks.exe
echo **** SUCCESSFUL ****
echo.

:: test luarocks

echo **** LUAROCKS TEST ****
%target_dir%\bin\luarocks.exe --version
:: list all installed rocks
%target_dir%\bin\luarocks.exe list
:: show environment path
echo Please add the following path to your environment variable to start using luarocks:
echo SET LUAROCKS_CONFIG=%LUAROCKS_CONFIG%
%target_dir%\bin\luarocks.exe --lua-version %LUA_VERSION% path
echo.

pause
