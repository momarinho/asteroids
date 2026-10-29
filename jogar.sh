#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================================="
echo "   ASTEROIDS - FEIRA DE CIENCIAS: MULHERES NA CIENCIA"
echo "========================================================="

# Libera a porta 8080 caso já esteja ocupada por um processo anterior
PORT_PID=$(lsof -t -i:8080 2>/dev/null || true)
if [ ! -z "$PORT_PID" ]; then
    kill -9 $PORT_PID 2>/dev/null || true
    sleep 0.5
fi

# Inicia servidor local em segundo plano
cd "$DIR/go-backend"
./server &
SERVER_PID=$!

trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

sleep 1

echo "Abrindo o jogo..."
if command -v google-chrome >/dev/null 2>&1; then
    google-chrome --app="http://localhost:8080" >/dev/null 2>&1 &
elif command -v chromium >/dev/null 2>&1; then
    chromium --app="http://localhost:8080" >/dev/null 2>&1 &
elif command -v chromium-browser >/dev/null 2>&1; then
    chromium-browser --app="http://localhost:8080" >/dev/null 2>&1 &
elif command -v microsoft-edge >/dev/null 2>&1; then
    microsoft-edge --app="http://localhost:8080" >/dev/null 2>&1 &
elif command -v brave-browser >/dev/null 2>&1; then
    brave-browser --app="http://localhost:8080" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:8080"
fi

echo "Jogo rodando em: http://localhost:8080"
echo "Ranking ao vivo: http://localhost:8080/live"
echo "Pressione Ctrl+C para encerrar."
wait $SERVER_PID
