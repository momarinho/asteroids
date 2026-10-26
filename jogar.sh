#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================================="
echo "   ASTEROIDS - FEIRA DE CIENCIAS: MULHERES NA CIENCIA"
echo "========================================================="

# Inicia servidor local em segundo plano
cd "$DIR/go-backend"
./server &
SERVER_PID=$!

trap "kill $SERVER_PID 2>/dev/null || true" EXIT

sleep 1

echo "Abrindo o jogo..."
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:8080"
elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome --app="http://localhost:8080"
fi

echo "Jogo rodando em: http://localhost:8080"
echo "Ranking ao vivo: http://localhost:8080/live"
echo "Pressione Ctrl+C para encerrar."
wait $SERVER_PID
