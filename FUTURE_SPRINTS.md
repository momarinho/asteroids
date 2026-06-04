# Future Sprints

You've done all the required steps, but if you'd like to make the game your own, here are some ideas.

## Gameplay

- Add a scoring system.
- Implement multiple lives and respawning.
- Add acceleration to the player movement.
- Make the objects wrap around the screen instead of disappearing.
- Create different weapon types.
- Add a shield power-up.
- Add a speed power-up.
- Add bombs that can be dropped.
- Add boss asteroids or mini-boss waves.
- Add enemy ships that shoot back.
- Add timed survival mode and endless mode.
- Add combo scoring for destroying multiple asteroids quickly.
- Add asteroid sizes with different behaviors, not just different radii.
- Add rare special asteroids that split differently or drop power-ups.

## Multiplayer

- Add local co-op with two players on the same screen.
- Add online co-op with shared waves and revives.
- Add versus mode with survival scoring.
- Add optional friendly fire.
- Add shared lives or shared score in co-op.
- Let one player pilot while the other controls special weapons.
- Add drop-in/drop-out multiplayer during a run.

## Game Modes

- Add hardcore mode with only one life.
- Add time attack mode with a target score.
- Add boss rush mode.
- Add challenge runs with random gameplay modifiers.
- Add a daily run with a fixed seed.
- Add a defense mode where players protect a base or station.

## Combat and Effects

- Add an explosion effect for the asteroids.
- Add muzzle flash or recoil feedback when shooting.
- Add shot impact sparks when bullets hit asteroids.
- Add screen shake on large collisions or bomb detonations.
- Add projectile lifetime so shots disappear after some distance.
- Add alternate fire modes like spread shot, laser, or charged shot.
- Add ricochet shots that bounce off screen edges.
- Add missiles with target lock.
- Add a continuous laser beam with heat management.
- Add shotgun-style spread fire.
- Add mine deployment.
- Add EMP blasts that slow or disable enemies.

## Movement and Collision

- Make the ship have a triangular hit box instead of a circular one.
- Add a short dash move with cooldown.
- Add thrust-based momentum with friction for a more arcade-like feel.
- Add temporary invulnerability after respawn.
- Add collision damage states instead of instant game over.

## Enemies and AI

- Add enemy ships that shoot back.
- Add small drones that chase the player.
- Add pirate ships that steal or destroy power-ups.
- Add explosive asteroids.
- Add magnetic or gravity-based enemies that pull the player.
- Add enemies that spawn in formations.
- Add elite enemies with unique movement patterns.

## Visual Design

- Add a background image.
- Make the asteroids lumpy instead of perfectly round.
- Add stars with parallax scrolling.
- Add a retro CRT shader or scanline overlay.
- Add color variation by asteroid type or danger level.
- Add a proper HUD for score, lives, and cooldowns.
- Add animation to the ship thruster while moving.

## Audio

- Add shooting sound effects.
- Add collision and explosion sounds.
- Add looping background music.
- Add dynamic music intensity as the game gets harder.
- Add audio cues for low health, power-ups, and boss spawns.

## Progression

- Add increasing difficulty over time.
- Add waves with brief breaks between them.
- Add unlockable ships with different stats.
- Add persistent high scores saved to disk.
- Add achievements for survival time, accuracy, and combos.
- Add a between-wave shop.
- Add upgrade trees for weapons, movement, and defense.
- Add ship classes with different strengths and weaknesses.
- Add permanent unlocks across runs.
- Add optional side objectives during a run.

## Sandbox and World Systems

- Add gravity wells or planets that affect movement.
- Add temporary black holes.
- Add portals that teleport ships and asteroids.
- Add debris fields that block or absorb shots.
- Add meteor showers that temporarily flood the map.
- Add moving hazards like lasers, mines, or rotating barriers.

## Replay and Community Features

- Add local and online leaderboards.
- Add replay recording for best runs.
- Add seed sharing for challenge runs.
- Add a spectator mode.
- Add detailed run statistics and post-game analytics.

## UX and Accessibility

- Add a main menu and pause menu.
- Add a short playable tutorial.
- Add gamepad support.
- Add key rebinding.
- Add accessibility options for contrast, screen shake, and HUD size.
- Add auto-fire as an accessibility toggle.
- Add colorblind-friendly palette presets.

## Technical Improvements

- Separate game logic into systems for input, movement, spawning, and collisions.
- Add a proper game state machine for menu, playing, paused, and game over.
- Add config constants for tuning difficulty without touching gameplay code.
- Add automated tests for collision, splitting, and shot cooldown behavior.
- Add debug overlays for FPS, sprite counts, and collision radii.
- Add deterministic seeds for easier debugging and balancing.
- Add save/load support for settings and progression.
- Add serialization for replays or game snapshots.
- Add performance profiling for large wave counts.

## Go Integration Ideas

- Add a Go-based leaderboard service with HTTP endpoints for submitting and listing scores.
- Add a Go multiplayer backend for lobbies, matchmaking, and state synchronization.
- Add a Go service for persistent player profiles, progression, and achievements.
- Add a Go-based replay or telemetry processor for post-game analytics.
- Add a local Go API for saving settings, runs, and stats outside the main Python process.
- Keep the game loop and rendering in Python while using Go only for backend or tooling concerns.
- Prefer a separate `go-services/` folder instead of mixing Go directly into the pygame runtime.
- Use HTTP or WebSocket communication between Python and Go for simpler integration.
- Avoid forcing Go into the frame-by-frame gameplay loop unless the architecture is intentionally redesigned.
