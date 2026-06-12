import pygame
from circleshape import CircleShape
from constants import LINE_WIDTH

class Bomb(CircleShape):
    containers: tuple[pygame.sprite.Group, ...]

    def __init__(self, x: float, y: float, direction: pygame.Vector2) -> None:
        super().__init__(x, y, 12)
        # Slow velocity
        self.velocity = direction * 200.0
        self.fuse_timer = 1.0  # Explodes after 1 second
        self.explosion_radius = 120.0

    def draw(self, screen: pygame.Surface) -> None:
        # Draw bomb body (red circle)
        pygame.draw.circle(
            screen,
            "red",
            self.position,
            self.radius,
            0,  # filled
        )
        # Draw orange outline
        pygame.draw.circle(
            screen,
            "orange",
            self.position,
            self.radius,
            LINE_WIDTH,
        )

    def update(self, dt: float, *_: object) -> None:
        self.position += self.velocity * dt
        self.wrap_around()
        self.fuse_timer -= dt
        if self.fuse_timer <= 0:
            self.explode()

    def explode(self) -> None:
        self.kill()
        BombExplosion(self.position.x, self.position.y, self.explosion_radius)


class BombExplosion(CircleShape):
    containers: tuple[pygame.sprite.Group, ...]
    explosion_sound: pygame.mixer.Sound | None = None

    def __init__(self, x: float, y: float, max_radius: float) -> None:
        super().__init__(x, y, 1.0)  # Start small
        self.max_radius = max_radius
        self.duration = 0.5  # half a second
        self.timer = 0.0

        if self.explosion_sound is not None:
            self.explosion_sound.play()

        # Split/destroy asteroids in radius immediately
        from asteroid import Asteroid
        if hasattr(Asteroid, "containers") and Asteroid.containers:
            asteroids_group = Asteroid.containers[0]
            for asteroid in list(asteroids_group):
                distance = self.position.distance_to(asteroid.position)
                if distance <= self.max_radius + asteroid.radius:
                    from logger import log_event
                    log_event("asteroid_shot")
                    asteroid.split()

    def draw(self, screen: pygame.Surface) -> None:
        progress = self.timer / self.duration
        current_radius = self.radius
        color_val = max(0, min(255, int(255 * (1 - progress))))

        # Draw a beautiful expansion ring
        # Outer ring (red-orange)
        pygame.draw.circle(
            screen,
            (color_val, int(color_val * 0.4), 0),
            self.position,
            current_radius,
            max(1, int(LINE_WIDTH * (1 - progress) * 3)),
        )
        # Inner ring (yellow)
        if current_radius > 10:
            pygame.draw.circle(
                screen,
                (color_val, color_val, 0),
                self.position,
                current_radius * 0.6,
                max(1, int(LINE_WIDTH * (1 - progress) * 2)),
            )

    def update(self, dt: float, *_: object) -> None:
        self.timer += dt
        if self.timer >= self.duration:
            self.kill()
            return

        progress = self.timer / self.duration
        # Quadratic ease-out expansion
        self.radius = self.max_radius * (1 - (1 - progress) ** 2)
