#!/bin/bash

# Configuration
LOG_FILE="go-backend.log"

echo "==========================================="
echo "   ASTEROIDS MULTIPLATFORM LAUNCHER        "
echo "==========================================="

# Ensure clean exit: stop backend when launcher script ends
cleanup() {
    if [ ! -z "$BACKEND_PID" ]; then
        echo ""
        echo "Stopping Go backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Free port 8080 if it is already in use by a zombie/old process
PORT_PID=$(lsof -t -i:8080 2>/dev/null)
if [ ! -z "$PORT_PID" ]; then
    echo "-> Port 8080 already in use by PID $PORT_PID. Cleaning up old process..."
    kill -9 $PORT_PID 2>/dev/null || true
    sleep 0.5
fi

# Step 1: Start Go Backend
echo "-> Starting Go backend server..."
cd go-backend
# Run in background and redirect output to log file to keep console clean
go run . > "../$LOG_FILE" 2>&1 &
BACKEND_PID=$!
cd ..

# Verify the server started in background
sleep 1.5
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "[ERROR] Go backend failed to start. Check $LOG_FILE for details."
    exit 1
fi
echo "[OK] Backend server is running in the background (logging to $LOG_FILE)."

# Step 2: Run Flutter App
echo "-> Launching Flutter client..."
echo "-------------------------------------------"
flutter run

# Script will exit here after flutter run terminates, triggering the cleanup trap.
