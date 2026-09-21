@echo off
chcp 65001 >nul
title PNLF-PFNL — Arret
cd /d "%~dp0"

echo  Arret des serveurs PNLF ^(ports 8000 et 4200^)...
echo.

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":8000 .*LISTENING"') do (
  echo  Django PID %%P
  taskkill /PID %%P /F >nul 2>&1
)
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":4200 .*LISTENING"') do (
  echo  Angular PID %%P
  taskkill /PID %%P /F >nul 2>&1
)

echo.
echo  Termine. PostgreSQL n'a pas ete arrete ^(la base reste disponible^).
echo.
pause
