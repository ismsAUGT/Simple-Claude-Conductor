@echo off
REM Run Phase - Windows version
REM Spawns a Claude subagent to execute a specific phase
REM
REM Usage: run-phase.bat <phase_number> [model]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%\..\..\..\..
cd /d "%PROJECT_ROOT%"

set PLANNING_DIR=docs\planning
set TASK_PLAN=%PLANNING_DIR%\task-plan.md
set FINDINGS=%PLANNING_DIR%\findings.md
set PROGRESS=%PLANNING_DIR%\progress.md

REM Parse arguments
set PHASE_NUM=%1
set MODEL=%2

if "%PHASE_NUM%"=="" (
    echo Usage: run-phase.bat ^<phase_number^> [model]
    echo.
    echo Models: haiku, sonnet, opus
    echo Example: run-phase.bat 2 sonnet
    exit /b 1
)

if "%MODEL%"=="" set MODEL=sonnet

REM Validate phase exists
findstr /C:"### Phase %PHASE_NUM%:" "%TASK_PLAN%" >nul 2>&1
if errorlevel 1 (
    echo Error: Phase %PHASE_NUM% not found in %TASK_PLAN%
    exit /b 1
)

echo ========================================
echo   Spawning Phase %PHASE_NUM% Agent
echo ========================================
echo.
echo Phase Number: %PHASE_NUM%
echo Model: %MODEL%
echo.

REM Create temporary prompt file
set PROMPT_FILE=%TEMP%\claude_phase_%PHASE_NUM%_prompt.txt

REM Generate context injection
(
echo ## Context Injection - Phase %PHASE_NUM%
echo.
echo You are a Task agent executing Phase %PHASE_NUM% of a project plan.
echo.
echo ### Your Role
echo You are responsible for the IMPLEMENTATION work of this phase.
echo - Write code, create files, make edits
echo - Run tests as needed
echo - Complete all deliverables listed below
echo - Update progress files when done
echo.
echo ### Project Goal
type "%TASK_PLAN%" 2>nul | findstr /V "^$"
echo.
echo ### Your Instructions
echo 1. Complete ALL deliverables listed for this phase
echo 2. Update docs/planning/findings.md for any research discoveries
echo 3. After completing work, update docs/planning/progress.md
echo 4. Mark deliverables as complete in task-plan.md
echo 5. If you encounter blockers, document them and report back
echo.
echo ### Important Notes
echo - You are a subagent - focus on THIS phase only
echo - Don't modify other phases or expand scope
echo - Quality over speed - get it right
) > "%PROMPT_FILE%"

echo Context injection created.
echo.

REM Determine model flag
if /I "%MODEL%"=="haiku" (
    set MODEL_ID=claude-haiku-3-5-20241022
) else if /I "%MODEL%"=="sonnet" (
    set MODEL_ID=claude-sonnet-4-20250514
) else if /I "%MODEL%"=="opus" (
    set MODEL_ID=claude-opus-4-5-20251101
) else (
    set MODEL_ID=%MODEL%
)

echo ========================================
echo   Launching Claude Agent for Phase %PHASE_NUM%
echo   Model: %MODEL% (%MODEL_ID%)
echo ========================================
echo.

REM Spawn Claude with the context
REM Note: On Windows, we read the file and pass as prompt
set /p PROMPT=<"%PROMPT_FILE%"
claude --model %MODEL_ID% --dangerously-skip-permissions --prompt "%PROMPT_FILE%"

REM Clean up
del "%PROMPT_FILE%" 2>nul

echo.
echo ========================================
echo   Phase %PHASE_NUM% Agent Complete
echo ========================================
echo.
echo Next steps:
echo   1. Review the agent's work
echo   2. Check if deliverables are complete
echo   3. Run: execute-plan.bat status
echo.

endlocal
