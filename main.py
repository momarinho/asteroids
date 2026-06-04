import sys

import pygame

from asteroid import Asteroid
from asteroidfield import AsteroidField
from constants import SCREEN_HEIGHT, SCREEN_WIDTH
from logger import log_event, log_state
from player import Player
from shot import Shot


def main():
    pygame.init()
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    clock = pygame.time.Clock()
    dt = 0.0
    asteroids = pygame.sprite.Group()
    shots = pygame.sprite.Group()
    updatable = pygame.sprite.Group()
    drawable = pygame.sprite.Group()
    Player.containers = (updatable, drawable)
    Asteroid.containers = (asteroids, updatable, drawable)
    Shot.containers = (shots, updatable, drawable)
    AsteroidField.containers = updatable
    player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
    asteroid_field = AsteroidField()
    pressed_keys: set[int] = set()

    print(f"Starting Asteroids with pygame version: {pygame.version.ver}")
    print(f"Screen width: {SCREEN_WIDTH}")
    print(f"Screen height: {SCREEN_HEIGHT}")

    while True:
        log_state()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return
            if event.type == pygame.KEYDOWN:
                pressed_keys.add(event.key)
            if event.type == pygame.KEYUP:
                pressed_keys.discard(event.key)

        screen.fill("black")
        updatable.update(dt, pressed_keys)
        for asteroid in asteroids.copy():
            if asteroid.collides_with(player):
                log_event("player_hit")
                print("Game over!")
                sys.exit()
            for shot in shots.copy():
                if asteroid.collides_with(shot):
                    log_event("asteroid_shot")
                    asteroid.split()
                    shot.kill()
                    break
        for drawable_object in drawable:
            drawable_object.draw(screen)
        pygame.display.flip()

        dt = clock.tick(60) / 1000


if __name__ == "__main__":
    main()
