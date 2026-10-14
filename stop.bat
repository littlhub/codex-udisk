@echo off
echo Stopping Codex processes...
taskkill /F /IM codex.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo Done.
pause
