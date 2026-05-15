@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title 🚀 Luanti Launcher

:: GitHub API abrufen
set "apiURL=https://api.github.com/repos/luanti-org/luanti/releases/latest"
set "jsonFile=%TEMP%\luanti_latest.json"

:: Lokale Version lesen
set "localVersion="
if exist "luanti_version.txt" (
    set /p localVersion=<luanti_version.txt
)

echo Prüfe GitHub auf neue Version...
powershell -Command "Invoke-WebRequest -Uri '%apiURL%' -Headers @{ 'User-Agent' = 'Luanti-Updater' } -OutFile '%jsonFile%'"

:: Online-Version extrahieren
for /f %%A in ('powershell -Command "(Get-Content '%jsonFile%' | ConvertFrom-Json).tag_name"') do (
    set "onlineVersion=%%A"
)

:: Download-Link extrahieren
for /f %%B in ('powershell -Command "(Get-Content '%jsonFile%' | ConvertFrom-Json).assets | Where-Object { $_.browser_download_url -like '*win64.zip' } | Select-Object -ExpandProperty browser_download_url"') do (
    set "downloadURL=%%B"
)

:: Bereinige Versionswerte
set "localVersion=!localVersion: =!"
set "localVersion=!localVersion:"=!"
set "onlineVersion=!onlineVersion: =!"
set "onlineVersion=!onlineVersion:"=!"

:: Dynamischer Fenstertitel
set "windowTitle=Luanti Launcher – Lokal: !localVersion! / Online: !onlineVersion!"
title !windowTitle!

echo.
echo Lokale Version: !localVersion!
echo Online-Version: !onlineVersion!
echo.

:: Versionsvergleich
if "!localVersion!"=="!onlineVersion!" (
    echo ? Luanti ist aktuell.
) else (
    echo ?? Neue Version gefunden: !onlineVersion!

    :: Nur passende alte Version löschen
    set "oldFolder=luanti-!localVersion!-win64"
    if exist "!oldFolder!" (
        echo Entferne alte Version: !oldFolder!
        rmdir /s /q "!oldFolder!"
    )

    echo Lade herunter von: !downloadURL!
    powershell -Command "(New-Object Net.WebClient).DownloadFile('!downloadURL!', 'luanti.zip')"
    echo Entpacke Luanti...
    powershell -Command "Expand-Archive -Path 'luanti.zip' -DestinationPath '.' -Force"
    echo !onlineVersion! > luanti_version.txt
    echo ? Update abgeschlossen.
)

:: Starte Luanti (suche automatisch die EXE in Unterordnern)
set "foundExe="
for /r %%F in (*) do (
    if /i "%%~nxF"=="luanti.exe" (
        set "foundExe=%%F"
        goto :found
    )
)

:found
if defined foundExe (
    echo.
    echo ?? Starte Luanti im Vollbild...
    start /max "" "!foundExe!"
    exit
)

echo ? Fehler: Luanti.exe wurde nicht gefunden.
pause
exit
