@echo off
setlocal
set lua_path=%~dp0metalib/?.lua;%~dp0extends/?.lua;%lua_path%
lua %~dp0test-cases\%1.lua %2 %3 %4 %5 %6 %7 %8 %9
