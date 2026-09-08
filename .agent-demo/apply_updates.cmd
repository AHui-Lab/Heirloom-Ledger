@echo off
setlocal
set "SRC=%~dp0prototype"
set "DST=%~dp0..\prototype"

if not exist "%~dp0..\.git" goto not_in_repo
if not exist "%DST%" goto missing
if not exist "%SRC%\scripts" goto missing
if not exist "%SRC%\data" goto missing
if not exist "%SRC%\tests" goto missing

echo [1/3] Copying scripts ...
xcopy "%SRC%\scripts" "%DST%\scripts" /Y /I /E /Q >nul
echo [2/3] Copying data ...
xcopy "%SRC%\data" "%DST%\data" /Y /I /E /Q >nul
echo [3/3] Copying tests ...
xcopy "%SRC%\tests" "%DST%\tests" /Y /I /E /Q >nul

echo.
echo All files copied. Now:
echo   1) Open prototype\project.godot with Godot 4, or
echo   2) run prototype\start_game.cmd (Chinese filename on desktop),
echo   3) then prototype\run_tests.cmd for the 8 regression checks.
echo.
pause
exit /b 0

:not_in_repo
echo.
echo ERROR: target repo folder not found.
echo The .cmd must stay inside the ".agent-demo" folder next to "prototype".
echo Expected target : %DST%
echo.
pause
exit /b 1

:missing
echo.
echo ERROR: one of the patch source folders is missing under:
echo %SRC%
echo Expected subfolders: scripts, data, tests
echo.
pause
exit /b 1
