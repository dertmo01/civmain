@echo off
setlocal EnableDelayedExpansion
title CIVILWATCH - Start Everything
color 0B

set "REPO=%~dp0"
set "LARAVEL=%REPO%laravel"
set "CIVMAIN=%REPO%civ-main"
set "FLUTTER=C:\Users\Administrator\Downloads\flutter\bin\flutter.bat"
set "MYSQLD=C:\xampp\mysql\bin\mysqld.exe"
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"
set "HTTPD=C:\xampp\apache\bin\httpd.exe"
set "PHP=C:\xampp\php\php.exe"
set "BACKEND_URL=http://127.0.0.1:8000"
set "FLUTTER_PORT=5000"

echo ============================================================
echo    CIVILWATCH BOOT  (Ctrl-C anytime to stop)
echo    Repo: %REPO%
echo ============================================================
echo.

rem ---------- 1. MySQL ----------
tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | findstr /I "mysqld.exe" >nul
if %errorlevel%==0 (
  echo [1/6] MySQL ............ already running
) else (
  echo [1/6] MySQL ............ starting...
  start "CIVILWATCH-MySQL" /min "%MYSQLD%" --standalone
  timeout /t 6 /nobreak >nul
)
tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | findstr /I "mysqld.exe" >nul
if %errorlevel%==0 (echo        OK) else (echo        WARNING: mysqld did not appear)
echo.

rem ---------- 2. Apache / phpMyAdmin ----------
tasklist /FI "IMAGENAME eq httpd.exe" 2>nul | findstr /I "httpd.exe" >nul
if %errorlevel%==0 (
  echo [2/6] Apache ........... already running
) else (
  echo [2/6] Apache ........... starting...
  start "CIVILWATCH-Apache" /min "%HTTPD%"
  timeout /t 4 /nobreak >nul
)
tasklist /FI "IMAGENAME eq httpd.exe" 2>nul | findstr /I "httpd.exe" >nul
if %errorlevel%==0 (echo        OK) else (echo        WARNING: httpd did not appear)
echo.

rem ---------- 3. Import civilwatch DB only if missing ----------
"%MYSQL%" -u root -e "USE civilwatch" >nul 2>&1
if %errorlevel%==0 (
  echo [3/6] Database civilwatch .... present
) else (
  echo [3/6] Database civilwatch .... missing - importing civilwatch_FINAL.sql ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$src='%REPO%laravel\civilwatch_FINAL.sql'; $dst=$env:TEMP+'\civilwatch_import.sql'; $lines=[System.IO.File]::ReadAllLines($src); $clean=$lines | Where-Object { $_ -notmatch 'M!999999' }; [System.IO.File]::WriteAllLines($dst,$clean,[System.Text.UTF8Encoding]::new($false)); cmd /c ('C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 < ""' + $dst + '""')" >nul 2>&1
  if %errorlevel%==0 (echo        Import OK) else (echo        WARNING: import failed - check %REPO%laravel\civilwatch_FINAL.sql)
)
echo.

rem ---------- 4. Laravel backend (only touches what is missing) ----------
if not exist "%LARAVEL%\.env" (
  echo        .env missing - creating from example
  copy /y "%LARAVEL%\.env.example" "%LARAVEL%\.env" >nul
)
findstr /r /c:"^APP_KEY=." "%LARAVEL%\.env" >nul 2>&1
if errorlevel 1 (
  echo        No APP_KEY - generating
  cd /d "%LARAVEL%" && call "%PHP%" artisan key:generate --force >nul
)
cd /d "%LARAVEL%" && call "%PHP%" artisan migrate --force >nul 2>&1

echo [4/6] Backend (Laravel :8000) ...
powershell -NoProfile -Command "if (-not (Test-NetConnection 127.0.0.1 -Port 8000 -InformationLevel Quiet -WarningAction SilentlyContinue)) { Start-Process '%PHP%' -ArgumentList 'artisan','serve','--host=127.0.0.1','--port=8000' -WorkingDirectory '%LARAVEL%' -WindowStyle Hidden }"
set /a tries=0
:waitbackend
timeout /t 2 /nobreak >nul
powershell -NoProfile -Command "try{Invoke-WebRequest '%BACKEND_URL%/api/ping' -UseBasicParsing -TimeoutSec 2|Out-Null;exit 0}catch{exit 1}"
if %errorlevel%==0 goto backendup
set /a tries+=1
if %tries% lss 15 goto waitbackend
echo        WARNING: backend did not answer within ~30s
goto afterbackend
:backendup
echo        Backend up at %BACKEND_URL%
:afterbackend
echo.

rem ---------- 5. Open pages in Chrome ----------
echo [5/6] Opening in Chrome...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "%BACKEND_URL%"
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost/phpmyadmin/"
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:%FLUTTER_PORT%"

echo.
echo ============================================================
echo    Web Admin  : %BACKEND_URL%
echo    phpMyAdmin : http://localhost/phpmyadmin/
echo    Flutter    : http://localhost:%FLUTTER_PORT%  (started below)
echo    Logins     : admin@civilwatch.ph (password set at seed/import time)
echo    Demo citizen: +639171234567 / PIN 123456
echo ============================================================
echo.

rem ---------- 6. Flutter web ----------
echo Starting Flutter web (first boot takes ~30s to compile)...
cd /d "%CIVMAIN%"
call "%FLUTTER%" run -d chrome --web-port %FLUTTER_PORT%

cd /d "%REPO%"
pause