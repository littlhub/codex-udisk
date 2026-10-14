@echo off
setlocal

:: Codex CLI Portable - All-in-one
:: Usage: Double-click codex.bat

:: Set paths (relative to this script)
set "SCRIPT_DIR=%~dp0"
set "CODEX_HOME=%SCRIPT_DIR%codex-home"
set "CODEX_BIN=%SCRIPT_DIR%codex-bin"

:: Check required files
if not exist "%CODEX_HOME%\auth.json" (
    echo Error: auth.json not found
    pause
    exit /b 1
)
if not exist "%CODEX_HOME%\config.toml" (
    echo Error: config.toml not found
    pause
    exit /b 1
)
if not exist "%CODEX_HOME%\server-cert.pem" (
    echo Error: server-cert.pem not found
    pause
    exit /b 1
)
if not exist "%CODEX_BIN%\bin\codex.exe" (
    echo Error: codex.exe not found
    pause
    exit /b 1
)

:: Set environment variables
set "CODEX_HOME=%CODEX_HOME%"
set "OPENAI_API_KEY="
set "CODEX_CA_CERTIFICATE=%CODEX_HOME%\server-cert.pem"
set "ALLOW_LOGIN_SKIP=true"
set "PATH=%CODEX_BIN%\bin;%CODEX_BIN%\codex-path;%PATH%"

:: Ensure TEMP directory exists
set "TEMP_DIR=C:\Users\%USERNAME%\AppData\Local\Temp\dsh-portable"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" 2>nul

:: Run Codex
echo ========================================
echo   Codex CLI - Agnes AI (Portable)
echo ========================================
echo.
"%CODEX_BIN%\bin\codex.exe" -m agnes-2.5-flash -c web_search="disabled"
pause
