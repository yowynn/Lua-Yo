@echo off
chcp 65001
setlocal
set path=%~dp0/env/bin;%path%
set lua_path=%~dp0scripts/extends/?.lua;%~dp0metalib/?.lua;%~dp0extends/?.lua;%lua_path%
lua %~dp0test-cases\%1.lua %2 %3 %4 %5 %6 %7 %8 %9
