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
# Parse device arguments if provided, otherwise prompt if multiple devices are connected
DEVICE_ARG=""
if [ ! -z "$1" ]; then
    if [[ "$1" == "-d" ]]; then
        DEVICE_ARG="$1 $2"
    else
        DEVICE_ARG="-d $1"
    fi
else
    echo "-> Checking connected devices..."
    DEVICES_RAW=$(flutter devices 2>/dev/null | grep " • ")
    if [ ! -z "$DEVICES_RAW" ]; then
        DEVICE_COUNT=$(echo "$DEVICES_RAW" | wc -l)
        if [ "$DEVICE_COUNT" -eq 1 ]; then
            # Single device, use it automatically
            DEVICE_ID=$(echo "$DEVICES_RAW" | cut -d'•' -f2 | xargs)
            DEVICE_ARG="-d $DEVICE_ID"
        else
            # Multiple devices, show menu
            echo "-------------------------------------------"
            echo "Multiple connected devices found:"
            
            # Read lines into array
            mapfile -t lines <<< "$DEVICES_RAW"
            declare -a ids
            declare -a names
            
            for i in "${!lines[@]}"; do
                line="${lines[$i]}"
                name=$(echo "$line" | cut -d'•' -f1 | xargs)
                id=$(echo "$line" | cut -d'•' -f2 | xargs)
                ids[$i]="$id"
                names[$i]="$name"
                echo "$((i+1))) $name ($id)"
            done
            echo "-------------------------------------------"
            
            read -p "Select target device [1-${#lines[@]}]: " choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#lines[@]}" ]; then
                selected_idx=$((choice-1))
                echo "-> Target set to: ${names[$selected_idx]} (${ids[$selected_idx]})"
                DEVICE_ARG="-d ${ids[$selected_idx]}"
            else
                echo "-> Invalid choice. Let Flutter select automatically."
            fi
        fi
    fi
fi

# Step 2: Run Flutter App
echo "-> Launching Flutter client..."
echo "-------------------------------------------"
flutter run $DEVICE_ARG

# Script will exit here after flutter run terminates, triggering the cleanup trap.
