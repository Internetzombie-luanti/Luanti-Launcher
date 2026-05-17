@echo off
setlocal enabledelayedexpansion

:: UTF‑8 aktivieren
chcp 65001 >nul

title Luanti Launcher
mode con cols=100 lines=32

:: ================== GITHUB / VERSION ==================
chcp 65001 >nul
set "apiURL=https://api.github.com/repos/luanti-org/luanti/releases/latest"
set "metaFile=%TEMP%\luanti_meta.txt"
set "localVersion="

if exist "luanti_version.txt" (
    set /p localVersion=<luanti_version.txt
)

goto start

:: ================== LOGO (Unicode hinter GOTO!) ==================
:logo
chcp 65001 >nul
color 0A
echo.
echo.
echo  ╔══════════════════════════════════════════════════════════════════════════════╗
echo  ║                                                                              ║
echo  ║      ██╗     ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗                         ║
echo  ║      ██║     ██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██║                         ║
echo  ║      ██║     ██║   ██║███████║██╔██╗ ██║   ██║   ██║                         ║
echo  ║      ██║     ██║   ██║██╔══██║██║╚██╗██║   ██║   ██║                         ║
echo  ║      ███████╗╚██████╔╝██║  ██║██║ ╚████║   ██║   ██║                         ║
echo  ║      ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝                         ║
echo  ║                                                                              ║
echo  ╚══════════════════════════════════════════════════════════════════════════════╝
echo.
exit /b

:: ================== SPLASH ==================
:splash
cls
color 0A
call :logo
echo  Lade...
ping -n 2 127.0.0.1 >nul
goto menu

:: ================== UPDATE CHECK ==================
:check_update
chcp 65001 >nul
cls
color 0A
call :logo
echo  Prüfe Updates...
echo.

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-RestMethod -Uri '%apiURL%' -Headers @{ 'User-Agent'='Luanti-Updater' }; Write-Output $r.tag_name; Write-Output ($r.assets | Where-Object { $_.browser_download_url -like '*win64.zip' }).browser_download_url" > "%metaFile%"

set "onlineVersion="
set "downloadURL="
set /a line=0

for /f "usebackq delims=" %%L in ("%metaFile%") do (
    set /a line+=1
    if !line! EQU 1 set "onlineVersion=%%L"
    if !line! EQU 2 set "downloadURL=%%L"
)

if not defined onlineVersion (
    echo  ❌ Fehler beim Abrufen der Online-Version.
    echo.
    pause
    goto menu
)

echo  Online-Version: %onlineVersion%
echo.
pause
goto menu

:: ================== UPDATE INSTALLIEREN ==================
:update
if not defined onlineVersion (
    call :check_update
)

cls
color 0A
call :logo
echo  Lade Update herunter...
echo.

REM Alte ZIP löschen
if exist "luanti.zip" del /f /q "luanti.zip"

REM Neue Version herunterladen
powershell -Command "(New-Object Net.WebClient).DownloadFile('%downloadURL%', 'luanti.zip')"

if not exist "luanti.zip" (
    echo  ❌ Fehler: Download fehlgeschlagen.
    echo.
    pause
    goto menu
)

echo  Entpacke Update...
tar -xf luanti.zip

if errorlevel 1 (
    echo  ❌ Fehler beim Entpacken. Alte Version bleibt erhalten.
    echo.
    pause
    goto menu
)

REM ZIP nach erfolgreichem Entpacken löschen
del /f /q "luanti.zip"

echo  Suche neuen Luanti-Ordner...
for /d %%i in ("luanti-*") do (
    set "newFolder=%%i"
)

if not defined newFolder (
    echo  ❌ Fehler: Neuer Luanti-Ordner wurde nicht gefunden.
    echo.
    pause
    goto menu
)

echo  Entferne alte Version...
if exist "luanti" (
    rmdir /s /q "luanti"
)

echo  Übernehme neue Version...
rename "%newFolder%" "%onlineVersion%"

>luanti_version.txt echo %onlineVersion%
set "localVersion=%onlineVersion%"

echo ^+---------------------------------------+
echo ^|        Update abgeschlossen!         ^|
echo ^+---------------------------------------+
pause
goto menu

:: ================== SPIEL STARTEN ==================
:startgame
chcp 65001 >nul
cls
color 0A
call :logo
echo  Starte Luanti...
echo.

REM Versionsnummer aus Datei lesen
set /p version=<luanti_version.txt

REM Pfad zur EXE bauen
set "exePath=%version%\bin\luanti.exe"

REM Prüfen, ob EXE existiert
if not exist "%exePath%" (
    echo +--------------------------------------+
    echo ^| ❌ Fehler: luanti.exe fehlt!      ^|
    echo ^| Bitte manuell starten             ^|
    echo ^| Ordner: %version%\bin            ^|
    echo +--------------------------------------+
    echo.
    pause
    exit /b 
)

REM Spiel starten
start "" "%exePath%"
exit /b


:: ================== MENÜ ==================
:menu
cls
color 0A
call :logo
echo  [1] Update prüfen
echo  [2] Update installieren
echo  [3] ▶ Luanti starten
echo.
echo  [0] Beenden
echo.
set /p choice="   Eingabe: "

if "%choice%"=="1" goto check_update
if "%choice%"=="2" goto update
if "%choice%"=="3" goto startgame
if "%choice%"=="0" goto end

goto menu

:: ================== START ==================
:start
call :splash

:end
exit /b
