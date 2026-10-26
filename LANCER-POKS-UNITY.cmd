@echo off
setlocal
if not exist "%~dp0UnityPoker\LANCER-POKS.cmd" goto missing
call "%~dp0UnityPoker\LANCER-POKS.cmd"
exit /b %errorlevel%
:missing
echo Extrayez tout le ZIP avant de lancer ce fichier.
echo Le dossier UnityPoker doit se trouver a cote de ce lanceur.
pause
exit /b 1
