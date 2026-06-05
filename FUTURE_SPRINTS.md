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
- Add a short dash move with cooldown.
- Add collision damage states instead of instant game over.
- Create different weapon types.
- Add alternate fire modes like spread shot, laser, or charged shot.
- Add bombs that can be dropped.
- Add muzzle flash or recoil feedback when shooting.

Stretch goals:

- Add ricochet shots that bounce off screen edges.
- Add shotgun-style spread fire.
- Add EMP blasts that slow or disable enemies.

## Sprint 3: World Rules and Survival Depth

Goal: make each run last longer and become less predictable.

Planned work:

- Make the objects wrap around the screen instead of disappearing.
- Add waves with brief breaks between them.
- Add timed survival mode and endless mode.
- Add asteroid sizes with different behaviors, not just different radii.
- Add rare special asteroids that split differently or drop power-ups.
- Add explosive asteroids.
- Add color variation by asteroid type or danger level.

Stretch goals:

- Add meteor showers that temporarily flood the map.
- Add moving hazards like lasers, mines, or rotating barriers.
- Add debris fields that block or absorb shots.

## Sprint 4: Visual and Audio Identity

Goal: give the game a stronger look and clearer moment-to-moment feedback.

Planned work:

- Add an explosion effect for the asteroids.
- Add screen shake on large collisions or bomb detonations.
- Add stars with parallax scrolling.
- Add a background image.
- Make the asteroids lumpy instead of perfectly round.
- Add looping background music.
- Add audio cues for low health, power-ups, and boss spawns.

Stretch goals:

- Add a retro CRT shader or scanline overlay.
- Add dynamic music intensity as the game gets harder.

## Sprint 5: Enemies and PvE Expansion

Goal: evolve the game beyond asteroid-only survival.

Planned work:

- Add enemy ships that shoot back.
- Add small drones that chase the player.
- Add enemies that spawn in formations.
- Add elite enemies with unique movement patterns.
- Add boss asteroids or mini-boss waves.
- Add magnetic or gravity-based enemies that pull the player.

Stretch goals:

- Add pirate ships that steal or destroy power-ups.
- Add a defense mode where players protect a base or station.
- Add boss rush mode.

## Sprint 6: Power-Ups and Progression

Goal: add build variety and reasons to keep playing.

Planned work:

- Add a shield power-up.
- Add a speed power-up.
- Add unlockable ships with different stats.
- Add ship classes with different strengths and weaknesses.
- Add a between-wave shop.
- Add upgrade trees for weapons, movement, and defense.
- Add achievements for survival time, accuracy, and combos.
- Add persistent high scores saved to disk.

Stretch goals:

- Add permanent unlocks across runs.
- Add optional side objectives during a run.

## Sprint 7: UX, Accessibility, and Session Flow

Goal: make the game easier to use, revisit, and share.

Planned work:

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

- Separate game logic into systems for input, movement, spawning, and collisions.
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
