@REM lua test-case.lua %1 %2 %3 %4 %5 %6 %7 %8 %9
@REM *.*  /s  /w >p:\11.txt


@echo off

if exist list.txt del list.txt /q
:input
cls
set input=:
set /p input=Please input path:
set "input=%input:"=%"
:: 上面这句为判断%input%中是否存在引号，有则剔除。
if "%input%"==":" goto input
if not exist "%input%" goto input
for %%i in ("%input%") do if /i "%%~di"==%%i goto input
pushd %cd%
cd /d "%input%">nul 2>nul || exit
set cur_dir=%cd%
popd
:: %%~nxi只显示文件名,%%i显示带路径的文件信息
for /f "delims=" %%i in ('dir /b /a-d /s "%input%"') do echo %%i>>list.txt
if not exist list.txt goto no_file
start list.txt
exit

:no_file
cls
echo %cur_dir% Folder does not have a separate document
pause
