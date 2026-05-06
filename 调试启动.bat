@echo off
title OpenClaw Debug Launcher
color 0C

echo.
echo OpenClaw Debug Launcher
echo =======================
echo.

echo [INFO] Starting debug mode...
echo [INFO] Time: %date% %time%
echo [INFO] Directory: %cd%
echo.

set BASE=%~dp0
cd /d "%BASE%app\core"

set NODE=..\..\app\runtime\node-win-x64\node.exe
set OPENCLAW=node_modules\openclaw\openclaw.mjs

echo [DEBUG] Checking files...
if not exist "%NODE%" (
    echo [ERROR] Node.js not found: %NODE%
    goto :error
)
echo [OK] Node.js found

if not exist "%OPENCLAW%" (
    echo [ERROR] OpenClaw not found: %OPENCLAW%
    goto :error
)
echo [OK] OpenClaw found

echo.
echo [DEBUG] Testing module...
"%NODE%" "%OPENCLAW%" --version
if errorlevel 1 (
    echo [ERROR] Module test failed
    goto :error
)
echo [OK] Module test passed

echo.
echo [DEBUG] Setting environment...
set OPENCLAW_PORT=1620
set OPENCLAW_HOME=%BASE%data
set OPENCLAW_STATE_DIR=%OPENCLAW_HOME%\.openclaw

echo [INFO] Port: %OPENCLAW_PORT%
echo [INFO] Data dir: %OPENCLAW_HOME%

echo.
echo [DEBUG] Checking port %OPENCLAW_PORT%...
netstat -ano | findstr ":%OPENCLAW_PORT%" >nul
if %errorlevel% equ 0 (
    echo [WARNING] Port %OPENCLAW_PORT% is in use
    echo [INFO] Trying port 1621...
    set OPENCLAW_PORT=1621
)

echo.
echo [DEBUG] Starting OpenClaw gateway...
echo [INFO] Command: "%NODE%" "%OPENCLAW%" gateway run --allow-unconfigured --port %OPENCLAW_PORT%
echo.

echo ========================================
echo   OPENCLAW STARTUP LOG
echo ========================================
"%NODE%" "%OPENCLAW%" gateway run --allow-unconfigured --port %OPENCLAW_PORT%
set EXIT_CODE=%errorlevel%

echo.
echo ========================================
echo   OPENCLAW EXITED
echo ========================================
echo Exit code: %EXIT_CODE%
echo.

if %EXIT_CODE% equ 0 (
    echo [INFO] OpenClaw exited normally
) else (
    echo [ERROR] OpenClaw exited with error code %EXIT_CODE%
)

goto :end

:error
echo.
echo [ERROR] Setup failed
echo.

:end
echo.
echo Press any key to exit...
pause >nul