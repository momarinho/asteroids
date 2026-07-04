import random

import pygame

from circleshape import CircleShape
from constants import ASTEROID_MIN_RADIUS, LINE_WIDTH
from logger import log_event


class Asteroid(CircleShape):
    def __init__(self, x: float, y: float, radius: float) -> None:
        super().__init__(x, y, radius)
        self.num_points = random.randint(8, 14)
        self.points_offsets = [random.uniform(0.75, 1.25) for _ in range(self.num_points)]
        self.angle = random.uniform(0, 360)
        self.rotation_speed = random.uniform(-40, 40)  # degrees per second

    def draw(self, screen: pygame.Surface) -> None:
        import math
        points = []
        angle_rad = math.radians(self.angle)
        for i in range(self.num_points):
            point_angle = angle_rad + (2 * math.pi * i) / self.num_points
            r = self.radius * self.points_offsets[i]
            x = self.position.x + r * math.cos(point_angle)
            y = self.position.y + r * math.sin(point_angle)
            points.append(pygame.Vector2(x, y))
        
        pygame.draw.polygon(screen, "white", points, LINE_WIDTH)

    def update(self, dt: float, *_: object) -> None:
        self.position += self.velocity * dt
        self.angle += self.rotation_speed * dt
        self.wrap_around()

    def split(self) -> None:
        self.kill()

        # Spawn explosion particles
        from particle import spawn_explosion
        num_particles = max(8, int(self.radius * 0.8))
        colors = ["white", "orange", "yellow", "gray"]
        for _ in range(num_particles):
            color = random.choice(colors)
            spawn_explosion(
                self.position.x,
                self.position.y,
                num_particles=1,
                color=color,
                size=random.uniform(2.0, 4.0),
                speed_range=(40, 180),
            )

        # Trigger screen shake proportional to size
        from screen_shake import trigger_screen_shake
        shake_intensity = self.radius * 0.15
        trigger_screen_shake(0.15, shake_intensity)

        if self.radius <= ASTEROID_MIN_RADIUS:
            return

        log_event("asteroid_split")
        angle = random.uniform(20, 50)
        velocity_a = self.velocity.rotate(angle)
        velocity_b = self.velocity.rotate(-angle)
        new_radius = self.radius - ASTEROID_MIN_RADIUS

        asteroid_a = Asteroid(self.position.x, self.position.y, new_radius)
        asteroid_b = Asteroid(self.position.x, self.position.y, new_radius)
        asteroid_a.velocity = velocity_a * 1.2
        asteroid_b.velocity = velocity_b * 1.2

