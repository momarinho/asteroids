@echo off
setlocal
cd /d "%~dp0"

title Asteroids - Mulheres na Ciencia

rem Preservar banco de dados caso esteja na raiz de execucoes anteriores
if exist "%~dp0asteroids.db" (
  if not exist "%~dp0go-backend\asteroids.db" (
    copy /Y "%~dp0asteroids.db" "%~dp0go-backend\asteroids.db" >nul 2>&1
  )
)

echo Iniciando servidor local do ranking...
if exist "%~dp0go-backend\server.exe" (
  pushd "%~dp0go-backend"
  start "Asteroids Backend" /B server.exe
  popd
) else if exist "%~dp0server.exe" (
  start "Asteroids Backend" /B "%~dp0server.exe"
)
timeout /t 2 /nobreak >nul

if not exist "%~dp0asteroids.exe" (
  echo [ERRO] asteroids.exe nao foi encontrado.
  echo Extraia todo o conteudo do ZIP antes de executar este arquivo.
  pause
  exit /b 1
)

echo Iniciando o jogo...
"%~dp0asteroids.exe"
set EXIT_CODE=%ERRORLEVEL%

echo Encerrando servidor...
taskkill /FI "WINDOWTITLE eq Asteroids Backend" /T /F >nul 2>&1
taskkill /IM server.exe /F >nul 2>&1
exit /b %EXIT_CODE%
