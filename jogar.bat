@echo off
chcp 65001 >nul
title Asteroids - Mulheres na Ciência
echo =========================================================
echo    ASTEROIDS - FEIRA DE CIÊNCIAS: MULHERES NA CIÊNCIA
echo =========================================================
echo [1/2] Iniciando servidor local e banco de dados SQLite...

rem Libera a porta 8080 caso esteja em uso por uma instancia anterior
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr :8080') do taskkill /f /pid %%a >nul 2>&1

cd /d "%~dp0go-backend"

if not exist "server.exe" (
    echo.
    echo [ERRO] O arquivo server.exe não foi encontrado na pasta go-backend!
    echo Verifique se os arquivos foram baixados corretamente.
    echo =========================================================
    pause
    exit /b 1
)

start "Asteroids Server" server.exe

echo [2/2] Abrindo o jogo...
timeout /t 2 >nul

set LAUNCHED=0

rem 1. Tenta abrir no Microsoft Edge em modo janela de aplicativo
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app=http://localhost:8080
    set LAUNCHED=1
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --app=http://localhost:8080
    set LAUNCHED=1
) else if exist "%LocalAppData%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%LocalAppData%\Microsoft\Edge\Application\msedge.exe" --app=http://localhost:8080
    set LAUNCHED=1
)

rem 2. Se nao abriu no Edge, tenta Google Chrome em modo aplicativo
if "%LAUNCHED%"=="0" (
    if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
        start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080
        set LAUNCHED=1
    ) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
        start "" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080
        set LAUNCHED=1
    ) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
        start "" "%LocalAppData%\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080
        set LAUNCHED=1
    )
)

rem 3. Se nao abriu no Chrome, tenta Brave Browser em modo aplicativo
if "%LAUNCHED%"=="0" (
    if exist "%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe" (
        start "" "%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe" --app=http://localhost:8080
        set LAUNCHED=1
    ) else if exist "%LocalAppData%\BraveSoftware\Brave-Browser\Application\brave.exe" (
        start "" "%LocalAppData%\BraveSoftware\Brave-Browser\Application\brave.exe" --app=http://localhost:8080
        set LAUNCHED=1
    )
)

rem 4. Fallback universal para o navegador padrao do Windows
if "%LAUNCHED%"=="0" (
    start http://localhost:8080
)

echo.
echo =========================================================
echo Jogo em execução:   http://localhost:8080
echo Ranking ao vivo:    http://localhost:8080/live
echo.
echo DICA: Pressione F11 para jogar em Tela Cheia!
echo Para encerrar o jogo, feche a janela do servidor.
echo =========================================================
pause
