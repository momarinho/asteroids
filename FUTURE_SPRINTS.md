# Future Sprints: Flutter & Go Migration Roadmap

This document outlines the roadmap for migrating the Python/Pygame Asteroids game into a modern, multiplatform app using **Flutter + Flame** for the client and **Go (Golang)** for the backend services.

---

## Migration Phase 1: Flutter & Flame client foundation [COMPLETED]

### Sprint 1: Project Setup & Core Movement [COMPLETED]
* **Goals:** Establish the Flutter + Flame codebase and port the basic movement mechanics.
* **Status:** Complete. Basic Flame loop setup, scaling, canvas bounds, and physics presetting are functional. Joystick and Keyboard inputs are operational.

### Sprint 2: Core Gameplay & Physics [COMPLETED]
* **Goals:** Migrate game entities, shooting mechanics, and basic collisions.
* **Status:** Complete. Asteroids draw irregular polygons, split into smaller components, 4 weapon systems are complete with screen shake, recoil, and sound triggers.

### Sprint 3: UI, Audio & Shop Integration [COMPLETED]
* **Goals:** Use Flutter widgets to create rich menus, the HUD, and the upgrade shop.
* **Status:** Complete. Shop overlays, HUD, Game Over overlays, Leaderboard overlay, and low-health warning sound loop are all built using native Flutter widgets integrated on top of Flame.

---

## Migration Phase 2: Online Services (Go Backend) [COMPLETED]

### Sprint 4: Go Backend API & Persistence [COMPLETED]
* **Goals:** Create a lightweight Go service to support online features.
* **Status:** Complete. Built REST API in Go using Gin, GORM, and pure-Go SQLite. Added anti-cheat HMAC-SHA256 signature verification.

### Sprint 5: Connected Features & Leaderboards [COMPLETED]
* **Goals:** Connect the Flutter app to the Go backend and display online rankings.
* **Status:** Complete. Integrated network client with SharedPreferences fallback. Leaderboards list scores dynamically by fetching data from the Go API.

---

## Migration Phase 3: Game Expansion & Multiplayer [ACTIVE]

### Sprint 6: PvE Hazards & Level Progression [COMPLETED]
* **Goals:** Port phase management and add waves.
* **Status:** Complete. Level manager drives waves, scaling asteroid count and speeds, and handles campaign progression.

### Sprint 7: Gameplay Polish & Visual Juice [ACTIVE]
* **Goals:** Add feedback animations, implement dynamic in-game power-ups, introduce active UFO enemies, and expand asteroid variety to make the game feel premium and highly polished before implementing networking.
* **Planned Work:**
  - **Visual Juice & Effects:**
    - Animated thrust flame visual emerging from the player's engine on acceleration.
    - Fade/particle effects during wrap-around screen traversal.
    - Bullet trails/effects for blaster, spread shot, and bomb projectiles.
  - **Active Hazards & Enemies:**
    - Classic UFO enemy ship spawning at random intervals, pursuing and shooting at the player.
    - Specialized Asteroid Types: Armored (high durability), Explosive (detonates dealing AoE damage), and Golden/Resource (fast-moving, high credit drop).
  - **Dynamic In-game Power-ups:**
    - Shield bubble drop (absorbs one collision hit).
    - Time distortion/freeze drop (temporarily slows down all asteroids).
    - Credit magnet/double credit drop.
  - **Score Multiplier & Combo System:**
    - Accumulative combo score multiplier for rapid consecutive asteroid destructions, resetting upon taking damage or going idle.

### Sprint 8: Real-Time Online Multiplayer (Go WebSockets) [PLANNED]
**Goal:** Introduce online co-op / versus multiplayer using WebSockets.

* **Planned Work (Server-Side Go):**
  - Integrate a WebSocket server (e.g. using `github.com/gorilla/websocket` or Gin websockets).
  - Design a **Lobby/Room System**: Players can create a room, receive a 4-digit code (e.g., `ABCD`), and share it.
  - Implement a real-time game loop on the server (30 ticks/second) that runs the physics simulation authoritative.
  - Broadcast the game state (player positions, angles, active bullets, and asteroid states) to all clients in the room.

* **Planned Work (Client-Side Flutter):**
  - Implement WebSocket client connection in `ApiService`.
  - Create a **Lobby Selection Overlay**: UI to choose "Create Room" or "Join Room" (with a code input keyboard).
  - Adapt `AsteroidsGame` and `PlayerComponent` to support rendering other players (represented by custom colored ships).
  - Synchronize inputs: Client sends joystick/keyboard inputs and firing commands to the server; receives and interpolates positions of other entities.
  - Sfx & particles replication on network events (shooting, hitting, explosions).

* **Stretch Goals:**
  - Friendly Fire setting togglable in Lobby.
  - Quick chat/ping system in game (emojis/messages).
  - Spectator mode for rooms that have already started.
