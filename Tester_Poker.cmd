@echo off
setlocal
set "POKE3D_LAUNCHER=%~f0"
set "POKE3D_COMPATIBLE=%~1"
title Casino Minuit - Lancement
powershell.exe -NoLogo -NoProfile -Command "$content = [IO.File]::ReadAllText($env:POKE3D_LAUNCHER); $body = ($content -split '(?m)^# POKER_POWERSHELL\r?$', 2)[1]; & ([scriptblock]::Create($body))"
if errorlevel 1 (
  echo.
  echo Le lancement a echoue. Copiez le message affiche ci-dessus.
  pause
  exit /b 1
)
exit /b 0
# POKER_POWERSHELL
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Immutable game revision; all human models and textures are in this archive.
$gameRevision = '8e2a35d78e1ba7e8abe87111b3aa186b3bcc7172'
$gameHash = 'b11729733e00141cc121ca8ea1e1debcd3b10f5fc6c446e866d1f127ee94b7f6'
$godotVersion = '4.6.3-stable'
$godotArchive = 'Godot_v4.6.3-stable_win64.exe.zip'
# Official SHA512-SUMS.txt, godotengine/godot-builds release 4.6.3-stable.
$godotHash = 'd44ea7ef5bab754cacd49d581b6062836b2eea12a82e1d183aebfad9cd8c7db2bd82513337bd657d6d2d5c04d46239c0570b029faf1343e81e8a2fa7b85dd83b'

function Get-VerifiedArchive {
    param([string]$Url, [string]$Path, [string]$ExpectedHash, [string]$Algorithm)
    if (Test-Path -LiteralPath $Path) {
        if ((Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash -ieq $ExpectedHash) { return }
        Remove-Item -LiteralPath $Path -Force
    }
    $download = $Path + '.' + [guid]::NewGuid().ToString('N') + '.download'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $download -UseBasicParsing -TimeoutSec 300
        if ((Get-FileHash -LiteralPath $download -Algorithm $Algorithm).Hash -ine $ExpectedHash) {
            throw 'Le fichier telecharge ne correspond pas a son empreinte. Installation annulee.'
        }
        Move-Item -LiteralPath $download -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download -Force }
    }
}

try {
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows 10 64 bits est necessaire.' }
    if (-not $env:LOCALAPPDATA) { throw 'Le dossier LOCALAPPDATA de Windows est indisponible.' }
    $cache = Join-Path $env:LOCALAPPDATA 'CasinoMinuit'
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
    $engineFolder = Join-Path $cache ('godot-' + $godotVersion)
    $engine = Join-Path $engineFolder 'Godot_v4.6.3-stable_win64.exe'
    Write-Host 'CASINO MINUIT - Poker 3D' -ForegroundColor Yellow
    Write-Host 'Premier lancement : telechargement du moteur et du jeu (environ 100 Mo).'
    Write-Host 'Aucune installation manuelle de Godot et aucun droit administrateur requis.'
    if (-not (Test-Path -LiteralPath $engine)) {
        Write-Host '1/3 - Telechargement et verification de Godot officiel...'
        $archive = Join-Path $cache $godotArchive
        Get-VerifiedArchive -Url ('https://github.com/godotengine/godot-builds/releases/download/' + $godotVersion + '/' + $godotArchive) -Path $archive -ExpectedHash $godotHash -Algorithm SHA512
        New-Item -ItemType Directory -Path $engineFolder -Force | Out-Null
        Expand-Archive -LiteralPath $archive -DestinationPath $engineFolder -Force
        if (-not (Test-Path -LiteralPath $engine)) { throw 'Le moteur Godot manque dans son archive.' }
    }
    $besideLauncher = Split-Path -Parent $env:POKE3D_LAUNCHER
    if (Test-Path -LiteralPath (Join-Path $besideLauncher 'project.godot')) {
        $projectFolder = $besideLauncher
        Write-Host '2/3 - Utilisation du projet situe a cote de ce lanceur.'
    } else {
        $gameRoot = Join-Path $cache ('game-' + $gameRevision)
        $projectFolder = Join-Path $gameRoot ('poke3D-' + $gameRevision)
        if (-not (Test-Path -LiteralPath (Join-Path $projectFolder 'project.godot'))) {
            Write-Host '2/3 - Telechargement et verification du jeu et des modeles 3D...'
            $sourceZip = Join-Path $cache ('game-' + $gameRevision + '.zip')
            Get-VerifiedArchive -Url ('https://codeload.github.com/alexlaurent22x-crypto/poke3D/zip/' + $gameRevision) -Path $sourceZip -ExpectedHash $gameHash -Algorithm SHA256
            New-Item -ItemType Directory -Path $gameRoot -Force | Out-Null
            Expand-Archive -LiteralPath $sourceZip -DestinationPath $gameRoot -Force
            if (-not (Test-Path -LiteralPath (Join-Path $projectFolder 'project.godot'))) { throw 'Le projet manque dans son archive.' }
        }
    }
    # Import first, so this also works on a fresh download containing GLB and PNG assets.
    Write-Host '3/3 - Preparation des modeles. Patientez, puis la fenetre du jeu va apparaitre...'
    $importLog = Join-Path $cache 'import.log'
    $importErrors = Join-Path $cache 'import-errors.log'
    $import = Start-Process -FilePath $engine -WorkingDirectory $projectFolder -ArgumentList @('--headless', '--path', '.', '--editor', '--import', '--quit') -Wait -PassThru -RedirectStandardOutput $importLog -RedirectStandardError $importErrors
    if ($import.ExitCode -ne 0) { throw ('Import interrompu. Diagnostic : ' + $importErrors) }
    $arguments = '--path .'
    $compatible = $env:POKE3D_COMPATIBLE -ieq 'opengl'
    if ($compatible) { $arguments += ' --rendering-method gl_compatibility' }
    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut((Join-Path $desktop 'Casino Minuit.lnk'))
        $shortcut.TargetPath = $engine
        $shortcut.Arguments = $arguments
        $shortcut.WorkingDirectory = $projectFolder
        $shortcut.IconLocation = $engine + ',0'
        $shortcut.Description = 'Casino Minuit - Texas Holdem 3D hors ligne'
        $shortcut.Save()
        Write-Host 'Raccourci Casino Minuit cree sur le Bureau.' -ForegroundColor Green
    } catch {
        Write-Host 'Le raccourci Bureau ne peut pas etre cree ; le jeu va quand meme demarrer.'
    }
    Start-Process -FilePath $engine -WorkingDirectory $projectFolder -ArgumentList $arguments
    Write-Host 'Jeu lance. Au prochain essai, utilisez le raccourci Casino Minuit du Bureau.'
} catch {
    Write-Host ('Erreur : ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
