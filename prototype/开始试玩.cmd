@echo off
setlocal
set "GODOT_ROOT=%USERPROFILE%\.cache\heirloom-ledger\godot-4.7.2"
set "GODOT_EXE=%GODOT_ROOT%\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
  echo Godot portable runtime was not found.
  echo Expected: %GODOT_EXE%
  echo The runtime is downloaded from the official Godot Windows page.
  pause
  exit /b 1
)
echo Starting Heirloom Ledger prototype...
echo This console stays open so startup errors remain visible.
"%GODOT_EXE%" --path "%~dp0."
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo The prototype exited with code %EXIT_CODE%.
  pause
)
endlocal
exit /b %EXIT_CODE%
