@echo off
title Simple Claude Conductor
cd /d "%~dp0"

echo.
echo ========================================
echo   Simple Claude Conductor
echo ========================================
echo.

:: Check if portable Python exists
if exist "python-portable\python.exe" (
    set "PYTHON_PATH=python-portable\python.exe"
    echo Using portable Python...
    goto :found_python
)

:: Try 'python' command
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PYTHON_PATH=python"
    echo Using system Python...
    goto :found_python
)

:: Try 'py' command (Windows Python Launcher)
where py >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PYTHON_PATH=py"
    echo Using Python Launcher (py)...
    goto :found_python
)

:: No Python found
echo ERROR: Python not found!
echo.
echo Please either:
echo   1. Set up portable Python in the python-portable folder
echo      (see python-portable\SETUP_INSTRUCTIONS.md)
echo   2. Or install Python from https://www.python.org/downloads/
echo      (Make sure to check "Add Python to PATH" during install)
echo.
pause
exit /b 1

:found_python
echo.

:: Check if Flask is installed
%PYTHON_PATH% -c "import flask" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Flask not found. Installing...
    %PYTHON_PATH% -m pip install flask flask-cors --quiet
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo ERROR: Failed to install Flask.
        echo Please run manually: %PYTHON_PATH% -m pip install flask
        pause
        exit /b 1
    )
    echo Flask installed successfully.
    echo.
)

echo Starting web server...
echo.

:: Start the server in the background
start /b "" %PYTHON_PATH% server\app.py

:: Wait for server to start
echo Waiting for server to start...
timeout /t 2 /nobreak >nul

:: Check if server is running (try curl if available, otherwise just wait)
curl -s http://localhost:8080/health >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Waiting a bit longer...
    timeout /t 3 /nobreak >nul
)

:: Open browser
echo Opening browser...
start http://localhost:8080

echo.
echo ========================================
echo   Conductor is running!
echo ========================================
echo.
echo   URL: http://localhost:8080
echo.
echo   To stop: Close this window or press Ctrl+C
echo.
echo ========================================
echo.

:: Keep window open and wait for Ctrl+C
echo Press Ctrl+C to stop the server...
:loop
timeout /t 60 /nobreak >nul
goto loop
