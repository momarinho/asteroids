@echo off
title Asteroids - Mulheres na Ciencia
echo =========================================================
echo    ASTEROIDS - FEIRA DE CIENCIAS: MULHERES NA CIENCIA
echo =========================================================
echo [1/2] Iniciando servidor local e banco de dados SQLite...

rem Libera a porta 8080 caso esteja em uso por uma instancia anterior
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr :8080') do taskkill /f /pid %%a >nul 2>&1

cd /d "%~dp0go-backend"
start "Asteroids Server" server.exe

echo [2/2] Abrindo o jogo...
timeout /t 2 >nul

set LAUNCHED=0

rem Tenta abrir no Microsoft Edge em modo janela de aplicativo
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app=http://localhost:8080
    set LAUNCHED=1
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app=http://localhost:8080
    set LAUNCHED=1
)

rem Se nao abriu no Edge, tenta Google Chrome em modo aplicativo
if "%LAUNCHED%"=="0" (
    if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
        start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080
        set LAUNCHED=1
    ) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
        start "" "%LocalAppData%\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080
        set LAUNCHED=1
    )
)

rem Fallback para o navegador padrao do sistema
if "%LAUNCHED%"=="0" (
    start http://localhost:8080
)

echo.
echo =========================================================
echo Jogo em execucao:   http://localhost:8080
echo Ranking ao vivo:    http://localhost:8080/live
echo.
echo DICA: Pressione F11 para jogar em Tela Cheia!
echo Para encerrar o jogo, feche a janela do servidor.
echo =========================================================
pause
