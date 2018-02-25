set port=%1

rem Create a config file to tell vrayspawner about the new location of IO
echo [Directories]> "C:\Autodesk\3ds Max 2018\vrayspawner.ini"
echo AppName=C:\Autodesk\3ds Max 2018\3dsmaxio.exe>> "C:\Autodesk\3ds Max 2018\vrayspawner.ini"

rem Install Backburner if available.
start /wait msiexec /i Backburner.msi /qn

rem start vray spawner
start "vrayspawner" "C:\Autodesk\3ds Max 2018\vrayspawner2018.exe" -port=%port%

:waitforproc
tasklist|find "3dsmaxio.exe"
IF ERRORLEVEL 0 GOTO done
TIMEOUT /T 1
GOTO waitforproc

:done
TIMEOUT /T 15
exit /b 0