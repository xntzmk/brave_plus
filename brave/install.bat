@echo off
setlocal EnableExtensions
title Brave++ installer

set "SRC=%~dp0"
set "APP="

rem --- locate Brave (Brave-Origin / Brave-Browser), Program Files or LocalAppData ---
for %%R in ("%ProgramFiles%" "%ProgramFiles(x86)%" "%LOCALAPPDATA%") do (
  for /d %%B in ("%%~R\BraveSoftware\*") do (
    if exist "%%~B\Application\brave.exe" if not defined APP set "APP=%%~B\Application"
  )
)

if not defined APP (
  echo [!] Brave installation not found.
  echo     Copy version.dll and chrome++.ini into ...\BraveSoftware\Brave-Origin\Application\ manually.
  pause
  exit /b 1
)

echo Brave directory: %APP%

rem --- require admin ---
net session >nul 2>&1
if errorlevel 1 (
  echo [*] Requesting administrator privileges...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

rem --- Brave must be closed (version.dll is locked while running) ---
tasklist /fi "imagename eq brave.exe" 2>nul | find /i "brave.exe" >nul
if not errorlevel 1 (
  echo [!] Brave is running. Fully quit Brave and run this script again.
  pause
  exit /b 1
)

if exist "%APP%\version.dll" copy /y "%APP%\version.dll" "%APP%\version.dll.bak" >nul
if exist "%APP%\chrome++.ini" copy /y "%APP%\chrome++.ini" "%APP%\chrome++.ini.bak" >nul

copy /y "%SRC%version.dll" "%APP%\version.dll" >nul
if errorlevel 1 goto fail
copy /y "%SRC%chrome++.ini" "%APP%\chrome++.ini" >nul
if errorlevel 1 goto fail

echo.
echo [OK] Installed. Start Brave to apply.
echo      Uninstall: run uninstall.bat (or delete version.dll and chrome++.ini there).
pause
exit /b 0

:fail
echo [!] Copy failed. Check permissions / antivirus.
pause
exit /b 1