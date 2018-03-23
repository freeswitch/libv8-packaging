set toolsversion=v141
echo toolsversion=%toolsversion%
set MSBuildToolsPath="C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild"
echo %MSBuildToolsPath%         

set static=false
cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Release /p:Platform=Win32 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Release /p:Platform=x64 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Debug /p:Platform=Win32 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Debug /p:Platform=x64 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%

rem set static=true
rem cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Release /p:Platform=Win32 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
rem cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Release /p:Platform=x64 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
rem cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Debug /p:Platform=Win32 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%
rem cmd /C %MSBuildToolsPath% libv8.2017.sln /p:Configuration=Debug /p:Platform=x64 /t:Build /p:PlatformToolset=%toolsversion% /p:libv8Static=%static%

echo Done! Packages (zip files) were placed to the "out" folder.