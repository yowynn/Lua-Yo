@echo off
:: ========================
:: file build-luarocks.cmd
:: ========================
setlocal
:: you may change the following variable's value
:: to suit the downloaded version
set luarocks_version=3.9.1
set work_dir=%~dp0
:: Removes trailing backslash
:: to enhance readability in the following steps
set work_dir=%work_dir:~0,-1%


set luarocks_install_dir=%work_dir%\lua\luarocks
set luarocks_build_dir=%work_dir%\luarocks-%luarocks_version%
echo %luarocks_build_dir%
:: just copy the downloaded files to the build directory
mkdir %luarocks_install_dir%
copy "%luarocks_build_dir%\luarocks.exe" "%luarocks_install_dir%\luarocks.exe"
copy "%luarocks_build_dir%\luarocks-admin.exe" "%luarocks_install_dir%\luarocks-admin.exe"

pause
