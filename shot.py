import pygame

from circleshape import CircleShape
from constants import LINE_WIDTH, SHOT_LIFETIME_SECONDS, SHOT_RADIUS


class Shot(CircleShape):
    def __init__(self, x: float, y: float) -> None:
        super().__init__(x, y, SHOT_RADIUS)
        self.life_timer = SHOT_LIFETIME_SECONDS

    def draw(self, screen: pygame.Surface) -> None:
        pygame.draw.circle(
            screen,
            "white",
            self.position,
            self.radius,
            LINE_WIDTH,
        )

    def update(self, dt: float, *_: object) -> None:
        self.position += self.velocity * dt
        self.wrap_around()
        self.life_timer -= dt

        if self.life_timer <= 0:
            self.kill()
