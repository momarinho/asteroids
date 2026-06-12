# Future Sprints

This document turns the current idea backlog into a practical roadmap for future work on the game.

## Planning Notes

- The first sprints focus on improving the single-player core.
- Multiplayer and Go integration are intentionally later because they depend on stronger game structure.
- Each sprint has a main goal, a suggested scope, and optional stretch goals.

## Sprint 1: Core Arcade Polish

Goal: make the current prototype feel more like a complete arcade game.

Planned work:

- Add a mode selection screen that can be reused as new game modes are added.
- Add a scoring system.
- Add a proper HUD for score, lives, and cooldowns.
- Implement multiple lives and respawning.
- Add temporary invulnerability after respawn.
- Add increasing difficulty over time.
- Add projectile lifetime so shots disappear after some distance.
- Add collision and explosion sounds.
- Add shooting sound effects.

Stretch goals:

- Add combo scoring for destroying multiple asteroids quickly.
- Add animation to the ship thruster while moving.
- Add shot impact sparks when bullets hit asteroids.

## Sprint 2: Movement and Combat Feel

Goal: improve control responsiveness and make shooting more interesting.

Planned work:

- Add acceleration to the player movement.
- Add thrust-based momentum with friction for a more arcade-like feel.
- Make the objects wrap around the screen instead of disappearing (moved from Sprint 3).
- Add a short dash move with cooldown.
- Add collision damage states instead of instant game over.
- Design an extensible weapon system framework to support future items/pickups.
- Create different weapon types.
- Add alternate fire modes like spread shot, laser, or charged shot.
- Add bombs that can be dropped.
- Add muzzle flash or recoil feedback when shooting.

Stretch goals:

- Add ricochet shots that bounce off screen edges.
- Add shotgun-style spread fire.
- Add EMP blasts that slow or disable enemies.

## Sprint 3: Stage Mode & Level Progression

Goal: Move beyond a single endless mode and create the structural foundation for Campaign/Stage-based gameplay ("Modo Fases").

Planned work:

- Add a "Campaign/Stages" mode option to the menu.
- Create a level management system (e.g., `LevelManager`) that loads level definitions (number/sizes of asteroids, target goals).
- Implement level transition states (Victory/Level Clear screen) and level-clear conditions (e.g., all asteroids destroyed).
- Support procedural level parameters (increasing asteroid count and speed per stage).
- Add support for wave-based spawning within a single level.

Stretch goals:

- Add custom-tailored stage designs (e.g., starting with asteroids clustered in the corners).
- Add stage-specific timers (e.g., survive for 60 seconds with rapid spawns).

## Sprint 4: Inter-mission Shop & Power-Ups

Goal: Build the progression loop by letting players spend currency earned during gameplay on weapons, upgrades, and power-ups between stages.

Planned work:

- Introduce game currency (e.g., space credits/scrap metal) dropped by asteroids or rewarded per level.
- Build a Shop screen displayed between stages.
- Support purchasing alternate weapons (Spread Shot, Rapid Fire, Bomb Launcher) in the shop.
- Add upgrade trees for weapons (e.g., fire rate, shot speed, blast radius).
- Add passive and active power-ups (e.g., Shield to absorb one hit, Scrap Magnet, Engine Overdrive for speed).

Stretch goals:

- Add shop reroll mechanics.
- Add limited inventory slots or weight capacity to make build selection strategic.

## Sprint 5: Visual and Audio Identity

Goal: give the game a stronger look and clearer moment-to-moment feedback.

Planned work:

- Add an explosion effect for the asteroids.
- Add screen shake on large collisions or bomb detonations.
- Add stars with parallax scrolling.
- Make the asteroids lumpy instead of perfectly round.
- Add looping background music.
- Add audio cues for low health, power-ups, and shop purchases.

Stretch goals:

- Add a retro CRT shader or scanline overlay.
- Add dynamic music intensity as the game gets harder.

## Sprint 6: Enemies and PvE Hazards

Goal: evolve the game beyond asteroid-only survival.

Planned work:

- Refactor entity structure to introduce a clean base class for AI/enemies.
- Add hostile alien ships that patrol and shoot back.
- Add small chasing drones.
- Add boss asteroids or mini-boss stages (e.g. Boss at Stage 5).
- Add environmental hazards like space mines or laser gates.

Stretch goals:

- Add boss rush mode.
- Add elite formations spawning randomly in stages.

## Sprint 7: UX, Accessibility, and Session Flow

Goal: make the game easier to use, revisit, and share.

Planned work:

- Refactor UI and state management into modular classes to keep main loop clean.
- Add a main menu and pause menu.
- Add a proper game state machine for menu, playing, paused, and game over.
- Add a short playable tutorial.
- Add gamepad support.
- Add key rebinding.
- Add accessibility options for contrast, screen shake, and HUD size.
- Add auto-fire as an accessibility toggle.
- Add colorblind-friendly palette presets.

Stretch goals:

- Add detailed run statistics and post-game analytics.
- Add local leaderboards.

## Sprint 8: Replay, Seeds, and Challenge Systems

Goal: improve replayability and support more competitive play.

Planned work:

- Add challenge runs with random gameplay modifiers.
- Add a daily run with a fixed seed.
- Add deterministic seeds for easier debugging and balancing.
- Add seed sharing for challenge runs.
- Add replay recording for best runs.
- Add serialization for replays or game snapshots.

Stretch goals:

- Add a spectator mode.
- Add online leaderboards.

## Sprint 9: Technical Refactor and Scale Readiness

Goal: prepare the codebase for larger features like online systems and multiplayer.

Planned work:

- Consolidate game logic systems (input, movement, spawning, collisions) for multi-player readiness.
- Add config constants for tuning difficulty without touching gameplay code.
- Add automated tests for collision, splitting, and shot cooldown behavior.
- Add debug overlays for FPS, sprite counts, and collision radii.
- Add save/load support for settings and progression.
- Add performance profiling for large wave counts.

Stretch goals:

- Add tooling to inspect events, scores, and balance data.

## Sprint 10: Local Multiplayer

Goal: introduce multiplayer with the lowest integration risk first.

Planned work:

- Add local co-op with two players on the same screen.
- Add shared lives or shared score in co-op.
- Add optional friendly fire.
- Let one player pilot while the other controls special weapons.
- Add drop-in/drop-out multiplayer during a run.

Stretch goals:

- Add versus mode with survival scoring.
- Add hardcore co-op mode.

## Sprint 11: Online Multiplayer and Services

Goal: move from local multiplayer to connected play.

Planned work:

- Add online co-op with shared waves and revives.
- Add a Go multiplayer backend for lobbies, matchmaking, and state synchronization.
- Use HTTP or WebSocket communication between Python and Go for simpler integration.
- Keep the game loop and rendering in Python while using Go only for backend or tooling concerns.
- Prefer a separate `go-services/` folder instead of mixing Go directly into the pygame runtime.

Stretch goals:

- Add online versus mode.
- Add reconnect flow and session recovery.

## Sprint 12: Backend and Community Features

Goal: support long-term progression, stats, and community competition.

Planned work:

- Add a Go-based leaderboard service with HTTP endpoints for submitting and listing scores.
- Add a Go service for persistent player profiles, progression, and achievements.
- Add a Go-based replay or telemetry processor for post-game analytics.
- Add a local Go API for saving settings, runs, and stats outside the main Python process.
- Add local and online leaderboards.

Stretch goals:

- Add account-based progression.
- Add web dashboard for stats and leaderboards.

## Backlog Ideas

These are still valid, but should be pulled into a sprint only when their prerequisites are ready.

- Add missiles with target lock.
- Add a continuous laser beam with heat management.
- Add mine deployment.
- Make the ship have a triangular hit box instead of a circular one.
- Add gravity wells or planets that affect movement.
- Add temporary black holes.
- Add portals that teleport ships and asteroids.
- Avoid forcing Go into the frame-by-frame gameplay loop unless the architecture is intentionally redesigned.
