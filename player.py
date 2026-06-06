import pygame

from circleshape import CircleShape
from constants import (
    LINE_WIDTH,
    PLAYER_ACCELERATION,
    PLAYER_FRICTION,
    PLAYER_INVULNERABLE_SECONDS,
    PLAYER_MAX_SPEED,
    PLAYER_RADIUS,
    PLAYER_SHOOT_COOLDOWN_SECONDS,
    PLAYER_SHOOT_SPEED,
    PLAYER_TURN_SPEED,
)
from shot import Shot


class Player(CircleShape):
    shoot_sound: pygame.mixer.Sound | None = None
    movement_acceleration: float = PLAYER_ACCELERATION
    movement_max_speed: float = PLAYER_MAX_SPEED
    movement_friction: float = PLAYER_FRICTION

    def __init__(self, x: int, y: int) -> None:
        super().__init__(x, y, PLAYER_RADIUS)
        self.rotation = 0
        self.shoot_timer = 0.0
        self.invulnerable_timer = 0.0

    def rotate(self, dt: float) -> None:
        self.rotation += PLAYER_TURN_SPEED * dt

    def accelerate(self, dt: float, direction_multiplier: float = 1.0) -> None:
        direction = pygame.Vector2(0, 1).rotate(self.rotation)
        self.velocity += (
            direction * self.movement_acceleration * direction_multiplier * dt
        )

    def move(self, dt: float) -> None:
        self.position += self.velocity * dt

    def apply_friction(self, dt: float) -> None:
        self.velocity *= max(0.0, 1 - self.movement_friction * dt)

    def clamp_speed(self) -> None:
        if self.velocity.length() > self.movement_max_speed:
            self.velocity.scale_to_length(self.movement_max_speed)

    def shoot(self) -> None:
        if self.shoot_timer > 0:
            return

        self.shoot_timer = PLAYER_SHOOT_COOLDOWN_SECONDS
        shot = Shot(self.position.x, self.position.y)
        shot.velocity = pygame.Vector2(0, 1).rotate(self.rotation) * PLAYER_SHOOT_SPEED
        if self.shoot_sound is not None:
            self.shoot_sound.play()

    def _is_key_pressed(
        self,
        keys: pygame.key.ScancodeWrapper | set[int],
        key: int,
    ) -> bool:
        if isinstance(keys, set):
            return key in keys or bool(pygame.key.get_pressed()[key])
        return bool(keys[key])

    def triangle(self) -> list[pygame.Vector2]:
        forward = pygame.Vector2(0, 1).rotate(self.rotation)
        right = pygame.Vector2(0, 1).rotate(self.rotation + 90) * self.radius / 1.5
        a = self.position + forward * self.radius
        b = self.position - forward * self.radius - right
        c = self.position - forward * self.radius + right
        return [a, b, c]

    def draw(self, screen: pygame.Surface) -> None:
        if self.is_invulnerable() and pygame.time.get_ticks() % 200 < 100:
            return

        pygame.draw.polygon(
            screen,
            "white",
            self.triangle(),
            LINE_WIDTH,
        )

    def update(
        self, dt: float, keys: pygame.key.ScancodeWrapper | set[int] | None = None
    ) -> None:
        if keys is None:
            keys = pygame.key.get_pressed()

        self.shoot_timer = max(0.0, self.shoot_timer - dt)
        self.invulnerable_timer = max(0.0, self.invulnerable_timer - dt)

        if self._is_key_pressed(keys, pygame.K_a):
            self.rotate(-dt)
        if self._is_key_pressed(keys, pygame.K_d):
            self.rotate(dt)

        if self._is_key_pressed(keys, pygame.K_w):
            self.accelerate(dt, 1.0)
        if self._is_key_pressed(keys, pygame.K_s):
            self.accelerate(dt, -1.0)

        self.clamp_speed()
        self.apply_friction(dt)
        self.move(dt)

        if self._is_key_pressed(keys, pygame.K_SPACE):
            self.shoot()

    def respawn(self, x: float, y: float) -> None:
        self.position = pygame.Vector2(x, y)
        self.rotation = 0
        self.velocity = pygame.Vector2(0, 0)
        self.invulnerable_timer = PLAYER_INVULNERABLE_SECONDS

    def is_invulnerable(self) -> bool:
        return self.invulnerable_timer > 0
