import pygame
import random

class Particle(pygame.sprite.Sprite):
    containers: tuple[pygame.sprite.Group, ...]

    def __init__(self, x: float, y: float, velocity: pygame.Vector2, color: str | pygame.Color, size: float, lifetime: float) -> None:
        if hasattr(self, "containers"):
            super().__init__(*self.containers)
        else:
            super().__init__()
        self.position = pygame.Vector2(x, y)
        self.velocity = velocity
        self.color = color
        self.size = size
        self.initial_lifetime = lifetime
        self.lifetime = lifetime

    def update(self, dt: float, *_: object) -> None:
        self.position += self.velocity * dt
        self.lifetime -= dt
        if self.lifetime <= 0:
            self.kill()

    def draw(self, screen: pygame.Surface) -> None:
        alpha_ratio = max(0.0, self.lifetime / self.initial_lifetime)
        current_size = max(1.0, self.size * alpha_ratio)
        pygame.draw.circle(screen, self.color, self.position, current_size)

def spawn_explosion(x: float, y: float, num_particles: int = 15, color: str | pygame.Color = "white", size: float = 3.0, speed_range: tuple[float, float] = (50, 150)) -> None:
    for _ in range(num_particles):
        angle = random.uniform(0, 360)
        speed = random.uniform(speed_range[0], speed_range[1])
        velocity = pygame.Vector2(0, 1).rotate(angle) * speed
        lifetime = random.uniform(0.3, 0.8)
        Particle(x, y, velocity, color, size, lifetime)
