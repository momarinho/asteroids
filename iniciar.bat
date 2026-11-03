@echo off
setlocal
cd /d "%~dp0"

title Asteroids

echo Iniciando servidor...
start "Asteroids Backend" /B "%~dp0go-backend\server.exe"
timeout /t 2 /nobreak >nul

if not exist "%~dp0asteroids.exe" (
  echo [ERRO] asteroids.exe nao foi encontrado.
  echo Extraia todo o conteudo do ZIP antes de executar este arquivo.
  pause
  exit /b 1
)

"%~dp0asteroids.exe"
set EXIT_CODE=%ERRORLEVEL%

echo Encerrando servidor...
taskkill /FI "WINDOWTITLE eq Asteroids Backend" /T /F >nul 2>&1
exit /b %EXIT_CODE%
