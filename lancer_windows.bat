@echo off
setlocal
cd /d "%~dp0"
if not "%~1"=="" (
  "%~1" --path "%~dp0."
  exit /b
)
if defined GODOT_EXE (
  "%GODOT_EXE%" --path "%~dp0."
  exit /b
)
where godot >nul 2>nul
if not errorlevel 1 (
  godot --path "%~dp0."
  exit /b
)
echo Faites glisser Godot 4.6.3 Standard .exe sur ce fichier.
echo Ou importez project.godot dans Godot puis appuyez sur F5.
pause
exit /b 1
