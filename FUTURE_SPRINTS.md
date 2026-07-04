# Future Sprints: Flutter & Go Migration Roadmap

This document outlines the roadmap for migrating the Python/Pygame Asteroids game into a modern, multiplatform app using **Flutter + Flame** for the client and **Go (Golang)** for the backend services.

---

## Migration Phase 1: Flutter & Flame client foundation

### Sprint 1: Project Setup & Core Movement
**Goal:** Establish the Flutter + Flame codebase and port the basic movement mechanics.

* **Planned Work:**
  - Initialize the Flutter project and configure dependencies (`flame`, `flame_audio`, `flutter_bloc` or `riverpod`).
  - Create the main `FlameGame` instance and setup the game canvas loop.
  - Implement canvas scaling, resizing, and coordinate translation.
  - Port the `Player` movement: rotation, acceleration, friction, momentum, and wrapping.
  - Support basic keyboard input controls.
* **Stretch Goals:**
  - Add virtual joystick/button overlays for mobile touchscreens.
  - Port basic thrust particle effects.

### Sprint 2: Core Gameplay & Physics
**Goal:** Migrate game entities, shooting mechanics, and basic collisions.

* **Planned Work:**
  - Implement `AsteroidComponent` with random lumpy polygon shapes and spin.
  - Port asteroid splitting logic.
  - Implement the weapon framework and weapon types: `Blaster`, `SpreadShot`, `RapidFire`, `BombLauncher`.
  - Implement shots and bombs components.
  - Implement collision detection using Flame's hitbox system and port scoring/lives systems.
  - Add screen shake on asteroid destruction and bomb detonations.
* **Stretch Goals:**
  - Port detailed spark/dust particle systems on asteroid hits.
  - Implement damage states.

### Sprint 3: UI, Audio & Shop Integration
**Goal:** Use Flutter widgets to create rich menus, the HUD, and the upgrade shop.

* **Planned Work:**
  - Build the main menu, settings (movement presets), and game-over overlays using native Flutter widgets.
  - Build the HUD overlay (lives, score, cooldown meters, invulnerability flash) in Flutter.
  - Build a beautiful, responsive Shop screen between stages using Flutter's layout engine.
  - Port chiptunes and sfx playback using `flame_audio`.
* **Stretch Goals:**
  - Add dynamic animations to the shop cards (purchasing effects, hover states).
  - Support sound options (volume sliders, audio toggle) in settings.

---

## Migration Phase 2: Online Services (Go Backend)

### Sprint 4: Go Backend API & Persistence
**Goal:** Create a lightweight Go service to support online features.

* **Planned Work:**
  - Create the `go-backend/` project directory.
  - Implement a REST API using Go (e.g. Fiber or Gin) for high scores and player profiles.
  - Integrate a database (SQLite for local testing/simplicity, PostgreSQL-ready) to store scores.
  - Add secure endpoints for submitting high scores with anti-cheat checks (validation of scores).
* **Stretch Goals:**
  - Create a simple healthcheck and metrics dashboard endpoint.
  - Build a basic containerization configuration (`Dockerfile` + `compose.yaml`).

### Sprint 5: Connected Features & Leaderboards
**Goal:** Connect the Flutter app to the Go backend and display online rankings.

* **Planned Work:**
  - Add HTTP client integrations in the Flutter app to connect to the Go API.
  - Build the **Global Leaderboard UI** in the Flutter app using `FutureBuilder` or state management.
  - Implement anonymous account registration / player profiles in the game on first run.
  - Synchronize local settings and high scores with the backend.
* **Stretch Goals:**
  - Show a notification in-game when a player beats a global high score.
  - Add profile customization (avatars, titles purchased with space credits).

---

## Migration Phase 3: Game Expansion & Multiplayer

### Sprint 6: PvE Hazards & Level progression
**Goal:** Port phase management and add new enemy behaviors.

* **Planned Work:**
  - Port `LevelManager` to control asteroid count, speed, and waves.
  - Implement hostile alien ships and chasing drones using Flame's component system.
  - Add custom stage modifiers (e.g., gravity fields, portal gates).
* **Stretch Goals:**
  - Add mini-boss fight encounters on specific waves.

### Sprint 7: Multiplayer & Sync (Go WebSockets)
**Goal:** Introduce online multiplayer elements.

* **Planned Work:**
  - Expand Go backend to support WebSockets for real-time communication.
  - Design a lightweight lobby/matchmaking system in Go.
  - Synchronize player positions, bullets, and asteroid states across clients.
  - Implement local or online co-op mode.
* **Stretch Goals:**
  - Add chat/ping system in lobby and during play.
  - Spectator mode.
