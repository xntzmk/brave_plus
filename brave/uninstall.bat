@echo off
setlocal EnableExtensions
title Brave++ uninstaller

set "APP="
for %%R in ("%ProgramFiles%" "%ProgramFiles(x86)%" "%LOCALAPPDATA%") do (
  for /d %%B in ("%%~R\BraveSoftware\*") do (
    if exist "%%~B\Application\brave.exe" if not defined APP set "APP=%%~B\Application"
  )
)
if not defined APP (
  echo [!] Brave installation not found.
  pause
  exit /b 1
)

net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

tasklist /fi "imagename eq brave.exe" 2>nul | find /i "brave.exe" >nul
if not errorlevel 1 (
  echo [!] Brave is running. Fully quit Brave and run this script again.
  pause
  exit /b 1
)

if exist "%APP%\version.dll.bak" (
  move /y "%APP%\version.dll.bak" "%APP%\version.dll" >nul
) else (
  del /f /q "%APP%\version.dll" 2>nul
)
if exist "%APP%\chrome++.ini.bak" (
  move /y "%APP%\chrome++.ini.bak" "%APP%\chrome++.ini" >nul
) else (
  del /f /q "%APP%\chrome++.ini" 2>nul
)

echo.
echo [OK] Uninstalled. Start Brave to restore the stock behaviour.
pause
exit /b 0