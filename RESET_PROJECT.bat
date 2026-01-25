@echo off
REM ============================================================
REM RESET_PROJECT.bat - Reset project to clean state for new run
REM ============================================================
REM
REM This script clears all project-specific files and resets
REM planning files to their templates, ready for a fresh start.
REM
REM Use this before running a new A/B test or starting fresh.
REM ============================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   RESET PROJECT - Clear for Fresh Start
echo ============================================================
echo.
echo This will:
echo   1. Reset planning files (task-plan.md, findings.md, progress.md)
echo   2. Clear STATUS.md to initial state
echo   3. Clear Questions_For_You.md
echo   4. Delete output folder contents
echo   5. Optionally delete temp/test folders
echo.
echo Your reference files in File_References_For_Your_Project\
echo will NOT be deleted.
echo.

set /p CONFIRM="Are you sure you want to reset? (Y/N): "
if /I not "%CONFIRM%"=="Y" (
    echo.
    echo Reset cancelled.
    exit /b 0
)

echo.
echo Resetting project files...
echo.

REM ============================================================
REM 1. Reset planning files from templates
REM ============================================================

echo [1/5] Resetting planning files...

REM Copy task-plan.md template
if exist ".claude\skills\planning-with-files\templates\task-plan.md" (
    copy /Y ".claude\skills\planning-with-files\templates\task-plan.md" "docs\planning\task-plan.md" >nul
    echo       - task-plan.md reset
) else (
    echo       - WARNING: task-plan.md template not found
)

REM Copy findings.md template
if exist ".claude\skills\planning-with-files\templates\findings.md" (
    copy /Y ".claude\skills\planning-with-files\templates\findings.md" "docs\planning\findings.md" >nul
    echo       - findings.md reset
) else (
    echo       - WARNING: findings.md template not found
)

REM Copy progress.md template
if exist ".claude\skills\planning-with-files\templates\progress.md" (
    copy /Y ".claude\skills\planning-with-files\templates\progress.md" "docs\planning\progress.md" >nul
    echo       - progress.md reset
) else (
    echo       - WARNING: progress.md template not found
)

REM Copy references.md template
if exist ".claude\skills\planning-with-files\templates\references.md" (
    copy /Y ".claude\skills\planning-with-files\templates\references.md" "docs\planning\references.md" >nul
    echo       - references.md reset
) else (
    echo       - WARNING: references.md template not found
)

REM ============================================================
REM 2. Reset STATUS.md
REM ============================================================

echo [2/5] Resetting STATUS.md...

(
echo # Project Status
echo.
echo **Last Updated**: Not started
echo.
echo ---
echo.
echo ## 👉 WHAT TO DO NEXT
echo.
echo **Project not yet started.**
echo.
echo **Your Next Step:** Run RUN_PROJECT.bat and type "Generate a plan"
echo.
echo ---
echo.
echo ## Quick Status
echo.
echo ^| Item ^| Status ^|
echo ^|------^|--------^|
echo ^| Plan Generated ^| No ^|
echo ^| Current Phase ^| - ^|
echo ^| Phases Completed ^| 0 / 0 ^|
echo.
echo ---
echo.
echo ## Progress Log
echo.
echo _No progress yet._
) > STATUS.md

echo       - STATUS.md reset

REM ============================================================
REM 3. Clear Questions_For_You.md
REM ============================================================

echo [3/5] Clearing Questions_For_You.md...

(
echo # Questions For You
echo.
echo _No questions yet. Claude will write questions here when needed._
) > Questions_For_You.md

echo       - Questions_For_You.md cleared

REM ============================================================
REM 4. Clear output folder
REM ============================================================

echo [4/5] Clearing output folder...

if exist "output" (
    del /Q "output\*" 2>nul
    echo       - output\ cleared
) else (
    mkdir output
    echo       - output\ created
)

REM ============================================================
REM 5. Optionally delete temp folders
REM ============================================================

echo [5/5] Checking for temp files...

set TEMP_FOUND=0

if exist "Temp Folder for Comparing Results of AB Test" set TEMP_FOUND=1
if exist "Temporary_just_implemented_report.md" set TEMP_FOUND=1
if exist "DELEGATION_ENFORCEMENT_IMPLEMENTATION.md" set TEMP_FOUND=1
if exist "IMPROVEMENTS-PROMPT.md" set TEMP_FOUND=1
if exist "IMPROVEMENTS-TO-DO.md" set TEMP_FOUND=1

if %TEMP_FOUND%==1 (
    echo.
    echo Found temp/test files:
    if exist "Temp Folder for Comparing Results of AB Test" echo       - Temp Folder for Comparing Results of AB Test\
    if exist "Temporary_just_implemented_report.md" echo       - Temporary_just_implemented_report.md
    if exist "DELEGATION_ENFORCEMENT_IMPLEMENTATION.md" echo       - DELEGATION_ENFORCEMENT_IMPLEMENTATION.md
    if exist "IMPROVEMENTS-PROMPT.md" echo       - IMPROVEMENTS-PROMPT.md
    if exist "IMPROVEMENTS-TO-DO.md" echo       - IMPROVEMENTS-TO-DO.md
    echo.
    set /p DELETE_TEMP="Delete these temp files? (Y/N): "
    if /I "!DELETE_TEMP!"=="Y" (
        if exist "Temp Folder for Comparing Results of AB Test" rmdir /S /Q "Temp Folder for Comparing Results of AB Test" 2>nul
        if exist "Temporary_just_implemented_report.md" del /Q "Temporary_just_implemented_report.md" 2>nul
        if exist "DELEGATION_ENFORCEMENT_IMPLEMENTATION.md" del /Q "DELEGATION_ENFORCEMENT_IMPLEMENTATION.md" 2>nul
        if exist "IMPROVEMENTS-PROMPT.md" del /Q "IMPROVEMENTS-PROMPT.md" 2>nul
        if exist "IMPROVEMENTS-TO-DO.md" del /Q "IMPROVEMENTS-TO-DO.md" 2>nul
        echo       - Temp files deleted
    ) else (
        echo       - Temp files kept
    )
) else (
    echo       - No temp files found
)

REM ============================================================
REM Done!
REM ============================================================

echo.
echo ============================================================
echo   RESET COMPLETE
echo ============================================================
echo.
echo Your project is now clean and ready for a fresh run.
echo.
echo Next steps:
echo   1. Make sure your reference files are in File_References_For_Your_Project\
echo   2. Run RUN_PROJECT.bat
echo   3. Type "Generate a plan" when Claude loads
echo.
echo ============================================================
echo.

pause
