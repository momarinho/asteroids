import random
from collections.abc import Callable

import pygame

from asteroid import Asteroid
from constants import (
    ASTEROID_KINDS,
    ASTEROID_MAX_RADIUS,
    ASTEROID_MAX_SPAWN_RATE_MULTIPLIER,
    ASTEROID_MAX_SPEED_MULTIPLIER,
    ASTEROID_MIN_RADIUS,
    ASTEROID_SPAWN_RATE_SECONDS,
    ASTEROID_SPAWN_RATE_GROWTH,
    ASTEROID_SPEED_GROWTH,
    SCREEN_HEIGHT,
    SCREEN_WIDTH,
)

Edge = tuple[pygame.Vector2, Callable[[float], pygame.Vector2]]


class AsteroidField(pygame.sprite.Sprite):
    containers: pygame.sprite.Group

    edges: list[Edge] = [
        (
            pygame.Vector2(1, 0),
            lambda y: pygame.Vector2(-ASTEROID_MAX_RADIUS, y * SCREEN_HEIGHT),
        ),
        (
            pygame.Vector2(-1, 0),
            lambda y: pygame.Vector2(
                SCREEN_WIDTH + ASTEROID_MAX_RADIUS, y * SCREEN_HEIGHT
            ),
        ),
        (
            pygame.Vector2(0, 1),
            lambda x: pygame.Vector2(x * SCREEN_WIDTH, -ASTEROID_MAX_RADIUS),
        ),
        (
            pygame.Vector2(0, -1),
            lambda x: pygame.Vector2(
                x * SCREEN_WIDTH, SCREEN_HEIGHT + ASTEROID_MAX_RADIUS
            ),
        ),
    ]

    def __init__(self, mode: str = "classic") -> None:
        pygame.sprite.Sprite.__init__(self, self.containers)
        self.mode = mode
        self.spawn_timer = 0.0
        self.difficulty_timer = 0.0
        self.spawn_rate_multiplier = 1.0
        self.speed_multiplier = 1.0

    def spawn(
        self, radius: float, position: pygame.Vector2, velocity: pygame.Vector2
    ) -> None:
        asteroid = Asteroid(position.x, position.y, radius)
        asteroid.velocity = velocity

    def update(self, dt: float, *_: object) -> None:
        if self.mode == "campaign":
            return
        self.spawn_timer += dt
        self.difficulty_timer += dt

        self.spawn_rate_multiplier = min(
            ASTEROID_MAX_SPAWN_RATE_MULTIPLIER,
            1.0 + self.difficulty_timer * ASTEROID_SPAWN_RATE_GROWTH,
        )
        self.speed_multiplier = min(
            ASTEROID_MAX_SPEED_MULTIPLIER,
            1.0 + self.difficulty_timer * ASTEROID_SPEED_GROWTH,
        )

        spawn_interval = ASTEROID_SPAWN_RATE_SECONDS / self.spawn_rate_multiplier
        if self.spawn_timer > spawn_interval:
            self.spawn_timer = 0

            edge = random.choice(self.edges)
            speed = random.randint(40, 100) * self.speed_multiplier
            velocity = edge[0] * speed
            velocity = velocity.rotate(random.randint(-30, 30))
            position = edge[1](random.uniform(0, 1))
            kind = random.randint(1, ASTEROID_KINDS)
            self.spawn(ASTEROID_MIN_RADIUS * kind, position, velocity)

    def danger_level(self) -> str:
        if self.spawn_rate_multiplier >= 2.0 or self.speed_multiplier >= 1.7:
            return "High"
        if self.spawn_rate_multiplier >= 1.5 or self.speed_multiplier >= 1.35:
            return "Medium"
        return "Low"
