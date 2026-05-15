@echo off
setlocal enabledelayedexpansion

:: UTF‑8 aktivieren
chcp 65001 >nul

title Luanti Launcher
mode con cols=100 lines=32

:: ================== GITHUB / VERSION ==================
set "apiURL=https://api.github.com/repos/luanti-org/luanti/releases/latest"
set "metaFile=%TEMP%\luanti_meta.txt"
set "localVersion="

if exist "luanti_version.txt" (
    set /p localVersion=<luanti_version.txt
)

goto start

:: ================== LOGO (Unicode hinter GOTO!) ==================
:logo
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

if exist "luanti.zip" del /f /q "luanti.zip"

powershell -Command "(New-Object Net.WebClient).DownloadFile('%downloadURL%', 'luanti.zip')"

if not exist "luanti.zip" (
    echo  ❌ Fehler: Download fehlgeschlagen.
    echo.
    pause
    goto menu
)

echo  Entpacke Update...
tar -xf luanti.zip

echo %onlineVersion% > luanti_version.txt
set "localVersion=%onlineVersion%"

echo.
echo  ✔ Update abgeschlossen!
echo.
pause
goto menu

:: ================== SPIEL STARTEN ==================
:startgame
cls
color 0A
call :logo
echo  Starte Luanti...
echo.

set "foundExe="
for /d %%D in (luanti-*-win64) do (
    if exist "%%D\bin\luanti.exe" set "foundExe=%%D\bin\luanti.exe"
)

if not defined foundExe (
    echo  ❌ Fehler: luanti.exe nicht gefunden.
    echo.
    pause
    goto menu
)

start "" "%foundExe%"
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
