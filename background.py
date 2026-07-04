import pygame
import random
from constants import SCREEN_WIDTH, SCREEN_HEIGHT

class BackgroundStars:
    def __init__(self, num_stars: int = 80) -> None:
        self.stars = []
        for _ in range(num_stars):
            x = random.uniform(0, SCREEN_WIDTH)
            y = random.uniform(0, SCREEN_HEIGHT)
            layer = random.randint(1, 3)
            self.stars.append({
                "pos": pygame.Vector2(x, y),
                "layer": layer
            })

    def update(self, player_velocity: pygame.Vector2, dt: float) -> None:
        drift = pygame.Vector2(-8, -4)  # very slow base drift
        for star in self.stars:
            multiplier = star["layer"] * 0.05
            star["pos"] += (drift - player_velocity * multiplier) * dt
            
            # Wrap around edges
            if star["pos"].x < 0:
                star["pos"].x = SCREEN_WIDTH
            elif star["pos"].x > SCREEN_WIDTH:
                star["pos"].x = 0
                
            if star["pos"].y < 0:
                star["pos"].y = SCREEN_HEIGHT
            elif star["pos"].y > SCREEN_HEIGHT:
                star["pos"].y = 0

    def draw(self, screen: pygame.Surface) -> None:
        for star in self.stars:
            if star["layer"] == 1:
                color = (75, 75, 75)
                size = 1.0
            elif star["layer"] == 2:
                color = (135, 135, 135)
                size = 1.5
            else:
                color = (220, 220, 220)
                size = 2.0
            pygame.draw.circle(screen, color, star["pos"], size)
