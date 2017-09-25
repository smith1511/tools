
set driver_version=385.08
set driver_filename=%driver_version%-tesla-desktop-winserver2016-international-whql.exe

if exist initialised.txt exit /b 0

@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
choco install -y 7zip

powershell.exe Invoke-WebRequest -Uri "http://us.download.nvidia.com/Windows/Quadro_Certified/%driver_version%/%driver_filename%" -OutFile "%driver_filename%"
7z x -y %driver_filename%
setup.exe -s -forcereboot

start shutdown /r /t 300

echo done > initialised.txt