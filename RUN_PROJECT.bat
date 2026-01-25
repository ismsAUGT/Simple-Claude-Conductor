@echo off
setlocal enabledelayedexpansion

title Simple Claude Conductor

echo.
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
for /f "tokens=1,* delims=:" %%a in ('findstr /C:"name:" project.yaml 2^>nul') do (
    set "val=%%b"
    set "val=!val:"=!"
    for /f "tokens=* delims= " %%c in ("!val!") do set "PROJECT_NAME=%%c"
    goto :found_name
)
:found_name

cls
echo.
echo ========================================
echo   Simple Claude Conductor
echo ========================================
echo.
echo Starting Claude for: %PROJECT_NAME%
echo.
echo ========================================
echo   Ready to Start!
echo ========================================
echo.
echo Claude should start without any prompts.
echo.
echo If you DO see a prompt asking about trust:
echo    Press 1 then Enter to select "Yes, proceed"
echo.
echo ========================================
echo   Commands You Can Type
echo ========================================
echo.
echo   "Generate a plan"     - Create a plan for your project
echo   "Execute the plan"    - Start building
echo   "Show progress"       - See what has been done
echo   "Continue"            - Resume if interrupted
echo   "Summarize"           - Get executive summary
echo.
echo ========================================
echo   Important Files
echo ========================================
echo.
echo   STATUS.md                           - Check progress
echo   Questions_For_You.md                - Answer questions
echo   output\                             - Your finished files
echo   File_References_For_Your_Project\   - Add samples (optional)
echo.
echo ========================================
echo.
echo Press Ctrl+C at any time to exit Claude.
echo Your progress is automatically saved.
echo.
echo Press any key to start Claude...
pause >nul

:: Start Claude - keep instructions visible (no cls)
echo.
echo ========================================
echo   Starting Claude...
echo ========================================
echo.
echo REMINDER: When Claude finishes loading, type:
echo.
echo   Generate a plan
echo.
echo (This instruction will scroll away but check STATUS.md if you forget)
echo.
echo ========================================
echo.

:: Run Claude with permissions bypass
claude --dangerously-skip-permissions

echo.
echo ========================================
echo   Generating Cost Report...
echo ========================================
python scripts\generate_cost_report.py . 2>nul
if %errorlevel% equ 0 (
    echo       Done! See output\cost_report.md
) else (
    echo       Skipped (no session data or Python not found)
)

echo.
echo ========================================
echo   Claude session ended
echo ========================================
echo.
echo Your progress has been saved!
echo.
echo ========================================
echo   REVIEW YOUR RESULTS
echo ========================================
echo.
echo   Open this file to see everything:
echo.
echo   STATUS.md
echo.
echo   (Contains: summary, outputs, next steps)
echo.
echo ========================================
echo.
echo Run this file again to continue where you left off.
echo.
pause
