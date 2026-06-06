# Asteroids

A small Asteroids-style arcade game built with Python and Pygame.

This project started as a course-driven foundation and has already grown beyond the base tutorial into a more complete playable prototype with its own game flow, HUD, balancing, and roadmap.

## Current Features

- Mode selection screen
- Settings screen for movement presets
- Gameplay and game over states
- Player movement and rotation
- Shooting with cooldown
- Asteroid spawning, collisions, and splitting
- Score system
- Multiple lives and respawn
- Temporary invulnerability after respawn
- Shot lifetime cleanup
- HUD with score, lives, cooldown, invulnerability, and danger level
- Progressive difficulty over time
- Basic gameplay sound effects

## Controls

- `W`: move forward
- `S`: move backward
- `A`: rotate left
- `D`: rotate right
- `Space`: shoot
- `Tab`: open movement settings from the main menu
- `Enter`: start selected mode
- `R`: restart after game over
- `M`: return to menu after game over
- `Esc`: quit

## Run

Make sure your environment has Python and the project dependencies installed, then run:

```bash
python main.py
```

## Project Status

This is currently a playable prototype and is under active iteration.

Completed so far:

- Core arcade loop
- Session flow and menu structure
- Run systems and player recovery
- Presentation pass for HUD and audio
- First balancing pass for difficulty scaling

## Roadmap

The public roadmap lives in [FUTURE_SPRINTS.md](/home/mateus/Documents/asteroids-python/FUTURE_SPRINTS.md:1).

Detailed per-sprint planning is kept separately in `.planning/` and is intentionally not tracked by Git.
