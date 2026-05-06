@echo off
title OpenClaw Portable Launcher
color 0A

echo.
echo   OpenClaw Portable - Ultimate Version
echo   Port: 1620 (from config)
echo   No encryption, direct launch
echo.

set BASE=%~dp0
cd /d "%BASE%app\core"

set NODE=..\..\app\runtime\node-win-x64\node.exe
set OPENCLAW=node_modules\openclaw\openclaw.mjs

if not exist "%NODE%" (
    echo ERROR: Node.js runtime not found
    pause
    exit /b 1
)

if not exist "%OPENCLAW%" (
    echo ERROR: OpenClaw core not found
    pause
    exit /b 1
)

set OPENCLAW_HOME=%BASE%data

echo Starting OpenClaw on port 1620...
echo Please wait...
echo.

"%NODE%" "%OPENCLAW%" gateway run --allow-unconfigured

echo.
echo OpenClaw has stopped.
pause