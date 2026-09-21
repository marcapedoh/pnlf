@echo off
chcp 65001 >nul
title PNLF-PFNL — Lancement
cd /d "%~dp0"

echo.
echo  ========================================
echo   PNLF-PFNL  —  Demarrage des serveurs
echo  ========================================
echo.

netstat -ano | findstr /R /C:":5432 .*LISTENING" >nul
if errorlevel 1 (
  echo  [ERREUR] PostgreSQL n'est pas demarre ^(port 5432^).
  echo  Ouvrez Services Windows, cherchez postgresql, puis Demarrer.
  echo  Ou lancez pgAdmin : le serveur Postgres doit etre "Running".
  echo.
  pause
  exit /b 1
)
echo  [OK] Base PostgreSQL  —  port 5432

netstat -ano | findstr /R /C:":8000 .*LISTENING" >nul
if not errorlevel 1 (
  echo  [INFO] Django tourne deja sur le port 8000
) else (
  echo  [..]  Lancement de Django  —  port 8000
start "PNLF-Django API" /D "%~dp0" cmd /k ".venv\Scripts\python.exe backend\manage.py runserver 127.0.0.1:8000"
)

timeout /t 4 /nobreak >nul

netstat -ano | findstr /R /C:":4200 .*LISTENING" >nul
if not errorlevel 1 (
  echo  [INFO] Angular tourne deja sur le port 4200
) else (
  echo  [..]  Lancement d'Angular  —  port 4200
  start "PNLF-Angular" /D "%~dp0frontend" cmd /k "npm start"
)

echo.
echo  Attente du frontend ^(environ 20 secondes^)...
timeout /t 20 /nobreak >nul
start "" "http://localhost:4200"
echo.
echo  [OK] Navigateur ouvert : http://localhost:4200
echo  Laissez les deux fenetres noires ouvertes.
echo  Autres appareils ^(meme Wi-Fi^) : http://VOTRE-IP:4200
echo.
pause
