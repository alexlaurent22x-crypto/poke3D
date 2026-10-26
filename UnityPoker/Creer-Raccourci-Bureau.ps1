$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$shell = New-Object -ComObject WScript.Shell
$link = $shell.CreateShortcut((Join-Path $desktop 'POKS Casino 3D.lnk'))
$link.TargetPath = Join-Path $PSScriptRoot 'LANCER-POKS.cmd'
$link.WorkingDirectory = $PSScriptRoot
$link.Description = 'Ouvrir le nouveau projet POKS Casino 3D dans Unity 6 HDRP'
$link.Save()
Write-Host 'Raccourci Unity créé sur le Bureau. Le jeu se lance avec Play dans Unity.'
