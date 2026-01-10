@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Simple Claude Conductor
echo ========================================
echo.

:: Check if project is initialized
if not exist "project.yaml" (
    echo ERROR: Project not initialized!
    echo.
    echo Please run INITIALIZE_MY_PROJECT.bat first.
    echo.
    pause
    exit /b 1
)

:: Check if Claude is installed
where claude >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Claude CLI not found!
    echo.
    echo Please install it first:
    echo   npm install -g @anthropic-ai/claude-code
    echo.
    pause
    exit /b 1
)

:: Get project name from project.yaml
set "PROJECT_NAME=Your Project"
for /f "tokens=2 delims=:" %%a in ('findstr /C:"name:" project.yaml 2^>nul') do (
    set "PROJECT_NAME=%%a"
    set "PROJECT_NAME=!PROJECT_NAME:"=!"
    for /f "tokens=* delims= " %%b in ("!PROJECT_NAME!") do set "PROJECT_NAME=%%b"
    goto :found_name
)
:found_name

echo Starting Claude for: %PROJECT_NAME%
echo.
echo ----------------------------------------
echo   Quick Reference
echo ----------------------------------------
echo.
echo COMMANDS YOU CAN TYPE:
echo   "execute the plan"    - Start or continue building
echo   "show progress"       - See what's been done
echo   "continue"            - Resume if interrupted
echo   "summarize"           - Get executive summary
echo   "help"                - See more commands
echo.
echo FILES TO CHECK:
echo   STATUS.md             - Quick project status
echo   Questions_For_You.md  - Questions from Claude
echo   docs\planning\        - Detailed planning files
echo.
echo ----------------------------------------
echo.
echo Press Ctrl+C to exit Claude at any time.
echo Your progress is automatically saved.
echo.
echo Starting Claude in 3 seconds...
timeout /t 3 >nul

:: Start Claude
cls
echo ========================================
echo   Claude is starting...
echo ========================================
echo.
echo TIP: Start by saying:
echo   "Generate a plan for my project"
echo.
echo Or if you already have a plan:
echo   "Execute the plan"
echo.
echo ========================================
echo.

:: Run Claude
claude

echo.
echo ========================================
echo   Claude session ended
echo ========================================
echo.
echo Your progress has been saved to:
echo   - STATUS.md (quick overview)
echo   - docs\planning\ (detailed files)
echo.
echo Run this file again to continue where you left off.
echo.
pause
