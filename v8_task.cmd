set PATH=%~1;%PATH%
set INCLUDE=%~2;%INCLUDE%
set libv8platform=%~3
set libv8configuration=%~4
set libv8version=%~5
set libv8static=%~6
set libv8BuildWithMSVSVersion=%~7

echo PATH=%PATH%
echo INCLUDE=%INCLUDE%

echo %libv8platform%
echo %libv8configuration%
echo %libv8version%
echo static = %libv8static%
echo libv8BuildWithMSVSVersion=%libv8BuildWithMSVSVersion%

if "%libv8configuration%" == "debug" (
    set arguments=-- is_debug=true
) else (
    set arguments=-- is_debug=false
)

if "%libv8static%" == "true" (
    set arguments=%arguments% is_component_build=false v8_static_library=true
    set static=.static
) else (
    set arguments=%arguments% is_component_build=true
    set static=
)

REM if "%libv8platform%" == "x64" (
REM set arguments=%arguments% target_cpu=amd64
REM ) else (
REM set arguments=%arguments% target_cpu=x86
REM )

set arguments=%arguments% use_jumbo_build=true enable_nacl=false remove_webcore_debug_symbols=true
set arguments=%arguments% v8_enable_i18n_support=false v8_use_external_startup_data=false 

echo %arguments%

If Not Exist "depot_tools.zip" (
    call powershell -command "& { iwr https://storage.googleapis.com/chrome-infra/depot_tools.zip -OutFile depot_tools.zip }"
)

If Not Exist "depot_tools" (
    call powershell -command "& { Add-Type -AssemblyName System.IO.Compression.FileSystem; function Unzip { param([string]$zipfile, [string]$outpath);     [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)}; Unzip "depot_tools.zip" "depot_tools" }"
)

set GYP_MSVS_VERSION=%libv8BuildWithMSVSVersion%
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set PATH=%CD%\depot_tools;%PATH%

If Exist "v8" (
    cd v8
) else (
    REM From a cmd.exe shell, run the command gclient (without arguments). 
    REM On first run, gclient will install all the Windows-specific bits 
    REM needed to work with the code, including msysgit and python.
    call gclient
        
    call fetch v8 2^>nul
    cd v8
    echo call git checkout %libv8version%
    call git checkout %libv8version%
    call gclient sync
)

If Not Exist "out.gn/%libv8platform%.%libv8configuration%%static%" (
    call python tools/dev/v8gen.py gen -b %libv8platform%.%libv8configuration% %libv8platform%.%libv8configuration%%static% %arguments%
    call ninja -C out.gn/%libv8platform%.%libv8configuration%%static% d8
)

exit 0