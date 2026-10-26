@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
 title POKS Casino 3D - Lancement Windows
set "POKS_PROJECT=%~dp0"
if not "%~1"=="" set "POKS_PROJECT=%~1\"
if exist "%~dp0UnityPoker\Assets\POKS\Scenes\Salon.unity" set "POKS_PROJECT=%~dp0UnityPoker\"
if exist "%~dp0POKS-Unity6-HDRP\UnityPoker\Assets\POKS\Scenes\Salon.unity" set "POKS_PROJECT=%~dp0POKS-Unity6-HDRP\UnityPoker\"
if not exist "%POKS_PROJECT%Assets\POKS\Scenes\Salon.unity" goto choose_project
:project_found
if exist "%POKS_PROJECT%Build\Windows\POKS-Casino-3D.exe" goto built_game
if not exist "%POKS_PROJECT%Assets\POKS\Scripts\Editor\LaunchBridge.cs" goto install_bridge
:bridge_ready
set "POKS_EDITOR="
if exist "%ProgramFiles%\Unity\Hub\Editor\6000.0.62f1\Editor\Unity.exe" set "POKS_EDITOR=%ProgramFiles%\Unity\Hub\Editor\6000.0.62f1\Editor\Unity.exe"
if defined POKS_EDITOR goto editor_found
for /d %%U in ("%ProgramFiles%\Unity\Hub\Editor\6000.0.*") do if exist "%%~fU\Editor\Unity.exe" set "POKS_EDITOR=%%~fU\Editor\Unity.exe"
if defined POKS_EDITOR goto editor_found
for /d %%U in ("%LOCALAPPDATA%\Programs\Unity\Hub\Editor\6000.0.*") do if exist "%%~fU\Editor\Unity.exe" set "POKS_EDITOR=%%~fU\Editor\Unity.exe"
if defined POKS_EDITOR goto editor_found
echo Unity 6 n'a pas ete trouve automatiquement.
echo Si Unity est installe ailleurs, selectionnez son fichier Unity.exe.
for /f "usebackq delims=" %%U in (`powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Selectionnez Unity 6 - Unity.exe'; $d.Filter='Unity Editor (Unity.exe)|Unity.exe'; if($d.ShowDialog() -eq 'OK'){[Console]::WriteLine($d.FileName)}"`) do set "POKS_EDITOR=%%U"
if defined POKS_EDITOR goto editor_found
echo.
echo Le projet fourni est un projet Unity. Aucun jeu Windows compile n'est present.
echo Un raccourci seul ne remplace pas l'installation de Unity 6.
echo Installez Unity 6000.0.62f1 dans Unity Hub, puis relancez ce fichier.
start "" "https://unity.com/releases/editor/whats-new/6000.0.62f1"
pause
exit /b 2
:editor_found
if not exist "%POKS_EDITOR%" goto launch_error
call :shortcut
if not exist "%LOCALAPPDATA%\POKS\Launcher" mkdir "%LOCALAPPDATA%\POKS\Launcher"
set "POKS_LOG=%LOCALAPPDATA%\POKS\Launcher\Unity.log"
>"%POKS_PROJECT%POKS-LAUNCH.request" echo Launch
if not exist "%POKS_PROJECT%POKS-LAUNCH.request" goto launch_error
echo.
echo POKS - Demarrage dans Unity 6.
echo Premier lancement : laissez terminer les imports et les shaders.
echo Le Salon doit ensuite passer automatiquement en mode Play.
echo Journal : "%POKS_LOG%"
echo.
rem An existing editor consumes the request file; do not start a competing instance.
powershell.exe -NoProfile -Command "$p=$env:POKS_PROJECT.TrimEnd('\'); $found=Get-CimInstance Win32_Process -Filter 'Name = ''Unity.exe''' -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -and $_.CommandLine.IndexOf($p,[StringComparison]::OrdinalIgnoreCase) -ge 0 }; if($found){exit 0}else{exit 1}" >nul 2>&1
if not errorlevel 1 goto already_open
start "POKS Unity" /wait "%POKS_EDITOR%" -projectPath "%POKS_PROJECT%." -executeMethod Poks.Editor.LaunchBridge.StartGame -logFile "%POKS_LOG%"
if errorlevel 1 goto launch_error
exit /b 0
:already_open
echo Unity est deja ouvert pour ce projet. La demande de lancement lui a ete transmise.
echo Si rien ne demarre, consultez la fenetre Console de Unity pour une erreur rouge.
pause
exit /b 0
:built_game
call :shortcut
start "POKS Casino 3D" /d "%POKS_PROJECT%Build\Windows" "%POKS_PROJECT%Build\Windows\POKS-Casino-3D.exe"
if errorlevel 1 goto launch_error
exit /b 0
:choose_project
echo Selectionnez le dossier UnityPoker extrait du grand ZIP du projet.
for /f "usebackq delims=" %%P in (`powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description='Choisissez UnityPoker : le dossier contenant Assets, Packages et ProjectSettings'; if($d.ShowDialog() -eq 'OK'){[Console]::WriteLine($d.SelectedPath)}"`) do set "POKS_PROJECT=%%P\"
if exist "%POKS_PROJECT%Assets\POKS\Scenes\Salon.unity" goto project_found
echo Projet introuvable. Extrayez d'abord POKS-Unity6-HDRP.zip, puis placez ce lanceur dans UnityPoker.
pause
exit /b 3
:install_bridge
if not exist "%~dp0POKS-LaunchBridge.cs.txt" goto missing_bridge
copy /-Y "%~dp0POKS-LaunchBridge.cs.txt" "%POKS_PROJECT%Assets\POKS\Scripts\Editor\LaunchBridge.cs" >nul
if errorlevel 1 goto launch_error
goto bridge_ready
:missing_bridge
echo Il manque la mise a jour du lanceur : POKS-LaunchBridge.cs.txt.
echo Extrayez tout le petit ZIP du lanceur, puis double-cliquez LANCER-POKS.cmd.
pause
exit /b 4
:shortcut
set "POKS_SHORTCUT_TARGET=%~f0"
powershell.exe -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'POKS Casino 3D.lnk')); $s.TargetPath=$env:POKS_SHORTCUT_TARGET; $s.WorkingDirectory=Split-Path $env:POKS_SHORTCUT_TARGET; $s.Arguments=([string][char]34)+$env:POKS_PROJECT.TrimEnd('\')+([string][char]34); $s.Description='Lancer POKS : jeu compile si present, sinon Unity 6'; $s.Save()" >nul 2>&1
exit /b 0
:launch_error
echo.
echo Le lancement a echoue. Aucun message d'erreur n'est masque.
if defined POKS_LOG if exist "%POKS_LOG%" powershell.exe -NoProfile -Command "Get-Content -LiteralPath $env:POKS_LOG -Tail 35"
echo Envoyez le message affiche ou une capture de la fenetre Console de Unity.
pause
exit /b 1
