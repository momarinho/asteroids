# Asteroids

A real-time multiplayer arcade game built with Go (backend) and Flutter/Dart (frontend) using WebSockets for authoritative physics simulation and game state replication.

## 🎮 Features

- **Real-Time Multiplayer**: Go backend server handling 30 ticks/second authoritative physics
- **WebSocket Integration**: Low-latency game state synchronization across clients
- **Anti-Cheat Protection**: HMAC-SHA256 signature verification on all client inputs
- **Flutter Cross-Platform**: Native support for iOS, Android, and Web
- **Responsive Gameplay**: Optimized rendering and input handling for mobile devices

## 🏗️ Architecture

```
┌─────────────────────┐
│  Flutter Client     │
│  (iOS/Android/Web)  │
└──────────┬──────────┘
           │
     WebSocket (JSON)
           │
┌──────────▼──────────┐
│   Go Backend        │
│ (Physics @ 30 Hz)   │
└─────────────────────┘
```

## 🛠️ Tech Stack

- **Backend**: Go, WebSocket server, physics engine
- **Frontend**: Flutter 3.x, Dart, WebSocket client
- **Protocol**: Real-time game state JSON over WebSocket
- **Security**: HMAC-SHA256 for input validation

## 🎯 Key Implementation Details

- **Authoritative Physics**: Server computes all physics calculations; clients receive authoritative updates
- **Tick Rate**: 30 server ticks per second for smooth gameplay
- **Anti-Cheat**: Client inputs signed with HMAC-SHA256; server validates all mutations
- **Latency Handling**: Optimistic client-side prediction with server corrections

## 📱 Running Locally

### Backend (Go)
```bash
# Coming soon: Full setup instructions
go run ./cmd/server
```

### Frontend (Flutter)
```bash
flutter pub get
flutter run
```

## 📄 License

MIT License — See LICENSE file for details.
