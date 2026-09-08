@echo off
setlocal
set "GODOT_EXE=C:\Users\cyh\.cache\heirloom-ledger\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
  echo Godot portable runtime was not found.
  pause
  exit /b 1
)
powershell -NoProfile -File "%~dp0run_checks.ps1"
:done
pause
endlocal
