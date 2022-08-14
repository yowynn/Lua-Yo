@echo off
:: =============================================================
:: file build-lua-mingw.cmd
:: =============================================================
setlocal
:: set your download lua version
set LUA_VERSION=5.4.4
:: set your make tool path
set COMPILER_DIR=P:\Applications\msys64\mingw64\bin
:: set your make tool
set MAKE=mingw32-make

set work_dir=%~dp0
:: Removes trailing backslash
set work_dir=%work_dir:~0,-1%
set source_dir=%work_dir%\lua-%LUA_VERSION%
set target_dir=%work_dir%\env
:: start building
echo **** BUILDING LUA ****
cd /D %source_dir%
set path=%COMPILER_DIR%;%path%
%MAKE% PLAT=mingw
echo **** SUCCESSFUL ****
echo.
:: create a clean "binary" installation
echo **** COPY TO TARGET PATH ****
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
echo **** SUCCESSFUL ****
echo.
:: optional: clean up
echo **** CLEAN TEMP FILES ****
del %source_dir%\src\*.exe
del %source_dir%\src\*.dll
del %source_dir%\src\*.o
del %source_dir%\src\*.a
echo **** SUCCESSFUL ****
echo.
:: test lua
echo **** LUA TEST ****
%target_dir%\bin\lua.exe -e "print [[Hello!]];print[[Simple Lua test successful!!!]]"
echo.
pause
