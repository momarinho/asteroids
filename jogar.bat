@echo off
title Asteroids - Mulheres na Ciencia
echo =========================================================
echo    ASTEROIDS - FEIRA DE CIENCIAS: MULHERES NA CIENCIA
echo =========================================================
echo [1/2] Iniciando servidor local e banco de dados SQLite...

cd /d "%~dp0"
start "" "go-backend\server.exe"

echo [2/2] Abrindo o jogo no navegador padrao...
timeout /t 2 >nul
start http://localhost:8080

echo.
echo =========================================================
echo Jogo em execucao:   http://localhost:8080
echo Ranking ao vivo:    http://localhost:8080/live
echo.
echo DICA: Pressione F11 no navegador para jogar em Tela Cheia!
echo Para encerrar o jogo, feche a janela do servidor.
echo =========================================================
pause
