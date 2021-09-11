@echo off
set tsay_path=C:\Windows\tsay.exe
set ttry_path=C:\Windows\ttry.exe
if exist %tsay_path% goto find
if exist %ttry_path% goto find
echo 本机没有找到【incaseformat】病毒，安装安全软件，排查信任区并确认实时监控是否开启.
echo.
pause
exit
:find
echo 本机存在【incaseformat】病毒，请联系管理员处理.
echo.
pause
exit