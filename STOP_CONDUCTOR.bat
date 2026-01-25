@echo off
title Stop Conductor
cd /d "%~dp0"

echo.
echo ========================================
echo   Stopping Simple Claude Conductor
echo ========================================
echo.

:: Try graceful shutdown first
echo Attempting graceful shutdown...
curl -s -X POST http://localhost:8080/api/shutdown >nul 2>&1

:: Wait a moment
timeout /t 2 /nobreak >nul

:: Check if it's still running
curl -s http://localhost:8080/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Server still running, forcing shutdown...
    :: Find and kill Python process running our server
    for /f "tokens=2" %%a in ('tasklist /fi "imagename eq python.exe" /fo list ^| find "PID:"') do (
        taskkill /pid %%a /f >nul 2>&1
    )
)

echo.
echo Conductor stopped.
echo.
pause
