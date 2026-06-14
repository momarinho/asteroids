from __future__ import annotations
import random
import pygame
from asteroid import Asteroid
from constants import (
    ASTEROID_MIN_RADIUS,
    ASTEROID_MAX_RADIUS,
    SCREEN_HEIGHT,
    SCREEN_WIDTH,
)

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from main import GameSession

class LevelManager:
    def __init__(self, session: GameSession) -> None:
        self.session = session
        self.current_level = 1
        self.state = "playing"  # "playing", "stage_clear"
        self.asteroids_remaining_to_spawn = 0
        self.speed_multiplier = 1.0
        self.wave_size = 3
        self.total_asteroids = 3
        self.bonus_credits = 0
        self.stage_clear_bonus = 0
        self.lives_bonus = 0

        # Define screen edges for spawning
        self.edges = [
            (
                pygame.Vector2(1, 0),
                lambda y: pygame.Vector2(-ASTEROID_MAX_RADIUS, y * SCREEN_HEIGHT),
            ),
            (
                pygame.Vector2(-1, 0),
                lambda y: pygame.Vector2(SCREEN_WIDTH + ASTEROID_MAX_RADIUS, y * SCREEN_HEIGHT),
            ),
            (
                pygame.Vector2(0, 1),
                lambda x: pygame.Vector2(x * SCREEN_WIDTH, -ASTEROID_MAX_RADIUS),
            ),
            (
                pygame.Vector2(0, -1),
                lambda x: pygame.Vector2(x * SCREEN_WIDTH, SCREEN_HEIGHT + ASTEROID_MAX_RADIUS),
            ),
        ]

        # Initialize Level 1
        self.start_level(1)

    def start_level(self, level: int) -> None:
        self.current_level = level
        self.session.current_level = level
        self.state = "playing"

        # Clean up any leftover entities from previous stage
        self.clean_up()

        # Procedural difficulty scaling calculations
        self.total_asteroids = 3 + (level - 1) * 2
        self.asteroids_remaining_to_spawn = self.total_asteroids

        # Wave size starts at 3, scaling by 1 every 3 levels, capped at 6
        self.wave_size = min(6, 3 + (level - 1) // 3)

        # Baseline speed starts at 1.0 and increases by 0.12 per level, capped at 2.5
        self.speed_multiplier = min(2.5, 1.0 + (level - 1) * 0.12)

        # Spawn the initial wave
        self.spawn_wave()

    def clean_up(self) -> None:
        # Safely remove all active asteroids, shots, and other transient objects
        # from the update and draw lists, leaving only the player and asteroid field.
        for sprite in list(self.session.updatable):
            if sprite is not self.session.player and sprite is not self.session.asteroid_field:
                sprite.kill()
        for sprite in list(self.session.drawable):
            if sprite is not self.session.player and sprite is not self.session.asteroid_field:
                sprite.kill()

    def spawn_wave(self) -> None:
        to_spawn = min(self.wave_size, self.asteroids_remaining_to_spawn)
        self.asteroids_remaining_to_spawn -= to_spawn

        # Select asteroid kinds (sizes/tiers) procedurally based on level
        if self.current_level == 1:
            kinds = [1, 2]
        elif self.current_level == 2:
            kinds = [1, 2, 3]
        elif self.current_level == 3:
            kinds = [2, 3]
        elif self.current_level == 4:
            kinds = [2, 3, 4]
        else:
            # Level 5 and beyond: expand up to tier 5 (increasing split potential/frequency)
            max_kind = min(5, 3 + (self.current_level - 5) // 2)
            kinds = list(range(max(1, max_kind - 2), max_kind + 1))

        for _ in range(to_spawn):
            edge = random.choice(self.edges)
            speed = random.randint(40, 100) * self.speed_multiplier
            velocity = edge[0] * speed
            velocity = velocity.rotate(random.randint(-30, 30))
            position = edge[1](random.uniform(0, 1))

            kind = random.choice(kinds)
            # Spawning adds the Asteroid automatically to containers set in create_session
            asteroid = Asteroid(position.x, position.y, ASTEROID_MIN_RADIUS * kind)
            asteroid.velocity = velocity

    def update(self, dt: float) -> None:
        if self.state == "playing":
            # Check if all active asteroids are cleared
            if len(self.session.asteroids) == 0:
                if self.asteroids_remaining_to_spawn > 0:
                    self.spawn_wave()
                else:
                    self.trigger_stage_clear()

    def trigger_stage_clear(self) -> None:
        self.state = "stage_clear"
        self.stage_clear_bonus = self.current_level * 100
        self.lives_bonus = self.session.lives * 50
        self.bonus_credits = self.stage_clear_bonus + self.lives_bonus
        self.session.credits += self.bonus_credits

    def advance_level(self) -> None:
        self.start_level(self.current_level + 1)
