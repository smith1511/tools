set port=%1

rem Create a config file to tell vrayspawner about the new location of IO
echo [Directories]> "C:\Autodesk\3ds Max 2018\vrayspawner.ini"
echo AppName=C:\Autodesk\3ds Max 2018\3dsmaxio.exe>> "C:\Autodesk\3ds Max 2018\vrayspawner.ini"

rem Install Backburner if available.
msiexec /i Backburner.msi /qn

rem start vray spawner
"C:\Autodesk\3ds Max 2018\vrayspawner2018.exe" -port=%port%
