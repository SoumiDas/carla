@echo off

rem BAT script that downloads and installs a ready to use
rem rpclib build for CARLA (carla.org).
rem Run it through a cmd with the x64 Visual C++ Toolset enabled.

setlocal

set LOCAL_PATH=%~dp0
set "FILE_N=    -[%~n0]:"

set BUILD_DIR=.
set DEL_SRC=false

:arg-parse
if not "%1"=="" (
    if "%1"=="--build-dir" (
        set BUILD_DIR=%~2
        shift
    )

    if "%1"=="--delete-src" (
        set DEL_SRC=true
    )

    shift
    goto :arg-parse
)

set RPC_VERSION=v2.2.1
set RPC_SRC=rpclib-src
set RPC_SRC_DIR=%BUILD_DIR%%RPC_SRC%\
set RPC_INSTALL=rpclib-install
set RPC_INSTALL_DIR=%BUILD_DIR%%RPC_INSTALL%\
set RPC_BUILD_DIR=%RPC_SRC_DIR%build

if exist "%RPC_INSTALL_DIR%" (
    goto already_build
)

if not exist "%RPC_SRC_DIR%" (
    echo %FILE_N% Cloning rpclib - version "%RPC_VERSION%"...
    echo.

    call git clone --depth=1 -b %RPC_VERSION% https://github.com/rpclib/rpclib.git %RPC_SRC_DIR%
    if errorlevel 1 goto error_git
    echo.
) else (
    echo %FILE_N% Not cloning rpclib because already exists a folder called "%RPC_SRC%".
)

if not exist "%RPC_BUILD_DIR%" (
    echo %FILE_N% Creating "%RPC_BUILD_DIR%"
    mkdir "%RPC_BUILD_DIR%"
)

cd "%RPC_BUILD_DIR%"
echo %FILE_N% Generating build...

cmake .. -G "Visual Studio 15 2017 Win64"^
        -DCMAKE_BUILD_TYPE=Release^
        -RPCLIB_BUILD_EXAMPLES=OFF^
        -DCMAKE_CXX_FLAGS_RELEASE=/MT^
        -DCMAKE_INSTALL_PREFIX=%RPC_INSTALL_DIR%^
        %RPC_SRC_DIR%
if errorlevel 1 goto error_cmake

echo %FILE_N% Building...
cmake --build . --config Release --target install

if errorlevel 1 goto error_install

rem Remove the downloaded rpclib source because is no more needed
if %DEL_SRC% == true (
  rd /s /q "%RPC_SRC_DIR%"
)

goto success

rem ============================================================================
rem -- Messages and Errors -----------------------------------------------------
rem ============================================================================

:success
    echo.
    echo %FILE_N% rpclib has been successfully installed in "%RPC_INSTALL_DIR%"!
    goto good_exit

:already_build
    echo %FILE_N% A rpclib installation already exists.
    echo %FILE_N% Delete "%RPC_INSTALL_DIR%" if you want to force a rebuild.
    goto good_exit

:error_git
    echo.
    echo %FILE_N% [GIT ERROR] An error ocurred while executing the git.
    echo %FILE_N% [GIT ERROR] Possible causes:
    echo %FILE_N%              - Make sure "git" is installed.
    echo %FILE_N%              - Make sure it is available on your Windows "path".
    goto bad_exit

:error_cmake
    echo.
    echo %FILE_N% [CMAKE ERROR] An error ocurred while executing the cmake.
    echo %FILE_N% [CMAKE ERROR] Possible causes:
    echo %FILE_N%                - Make sure "CMake" is installed.
    echo %FILE_N%                - Make sure it is available on your Windows "path".
    echo %FILE_N%                - CMake 3.9.0 or higher is required.
    goto bad_exit

:error_install
    echo.
    echo %FILE_N% [NMAKE ERROR] An error ocurred while installing using NMake.
    echo %FILE_N% [NMAKE ERROR] Possible causes:
    echo %FILE_N%                - Make sure you have Visual Studio installed.
    echo %FILE_N%                - Make sure you have the "x64 Visual C++ Toolset" in your path.
    echo %FILE_N%                  For example using the "Visual Studio x64 Native Tools Command Prompt",
    echo %FILE_N%                  or the "vcvarsall.bat".
    goto bad_exit

:good_exit
    echo %FILE_N% Exiting...
    endlocal
    set install_rpclib=done
    goto:EOF

:bad_exit
    if exist "%RPC_INSTALL_DIR%" rd /s /q "%RPC_INSTALL_DIR%"
    echo %FILE_N% Exiting with error...
    endlocal
    goto:EOF