import sys
from dataclasses import dataclass

import pygame

from asteroid import Asteroid
from asteroidfield import AsteroidField
from constants import SCREEN_HEIGHT, SCREEN_WIDTH
from logger import log_event, log_state
from player import Player
from shot import Shot

GameState = str
GameMode = str

STATE_MENU: GameState = "menu"
STATE_PLAYING: GameState = "playing"
STATE_GAME_OVER: GameState = "game_over"


@dataclass
class GameSession:
    mode: GameMode
    asteroids: pygame.sprite.Group
    shots: pygame.sprite.Group
    updatable: pygame.sprite.Group
    drawable: pygame.sprite.Group
    player: Player
    asteroid_field: AsteroidField


def create_session(mode: GameMode) -> GameSession:
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

    return GameSession(
        mode=mode,
        asteroids=asteroids,
        shots=shots,
        updatable=updatable,
        drawable=drawable,
        player=player,
        asteroid_field=asteroid_field,
    )


def draw_centered_lines(
    screen: pygame.Surface,
    font: pygame.font.Font,
    lines: list[str],
    start_y: int,
    gap: int = 16,
) -> None:
    current_y = start_y
    for line in lines:
        text_surface = font.render(line, True, "white")
        text_rect = text_surface.get_rect(center=(SCREEN_WIDTH // 2, current_y))
        screen.blit(text_surface, text_rect)
        current_y += text_surface.get_height() + gap


def draw_menu(
    screen: pygame.Surface,
    title_font: pygame.font.Font,
    body_font: pygame.font.Font,
    modes: list[tuple[str, GameMode]],
    selected_index: int,
) -> None:
    screen.fill("black")

    draw_centered_lines(
        screen,
        title_font,
        ["Asteroids", "Mode Select"],
        160,
        gap=8,
    )

    menu_lines = []
    for index, (label, _) in enumerate(modes):
        prefix = ">" if index == selected_index else " "
        menu_lines.append(f"{prefix} {label}")

    draw_centered_lines(screen, body_font, menu_lines, 300, gap=18)
    draw_centered_lines(
        screen,
        body_font,
        [
            "Up/Down to select",
            "Enter to start",
            "Esc to quit",
        ],
        470,
        gap=12,
    )


def draw_game_over(
    screen: pygame.Surface,
    title_font: pygame.font.Font,
    body_font: pygame.font.Font,
    mode_label: str,
) -> None:
    screen.fill("black")
    draw_centered_lines(
        screen,
        title_font,
        ["Game Over"],
        220,
        gap=12,
    )
    draw_centered_lines(
        screen,
        body_font,
        [
            f"Last mode: {mode_label}",
            "Press R to restart",
            "Press M to return to menu",
            "Press Esc to quit",
        ],
        320,
        gap=14,
    )


def mode_label_from_value(modes: list[tuple[str, GameMode]], mode: GameMode | None) -> str:
    if mode is None:
        return "None"

    for label, value in modes:
        if value == mode:
            return label
    return mode


def main():
    pygame.init()
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Asteroids")
    clock = pygame.time.Clock()
    title_font = pygame.font.Font(None, 72)
    body_font = pygame.font.Font(None, 36)

    dt = 0.0
    pressed_keys: set[int] = set()
    game_state: GameState = STATE_MENU
    mode_options: list[tuple[str, GameMode]] = [("Classic", "classic")]
    selected_mode_index = 0
    active_mode: GameMode | None = None
    session: GameSession | None = None

    print(f"Starting Asteroids with pygame version: {pygame.version.ver}")
    print(f"Screen width: {SCREEN_WIDTH}")
    print(f"Screen height: {SCREEN_HEIGHT}")

    while True:
        if game_state == STATE_PLAYING and session is not None:
            log_state()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return

            if event.type == pygame.KEYDOWN:
                pressed_keys.add(event.key)

                if game_state == STATE_MENU:
                    if event.key == pygame.K_ESCAPE:
                        return
                    if event.key == pygame.K_UP:
                        selected_mode_index = (selected_mode_index - 1) % len(mode_options)
                    if event.key == pygame.K_DOWN:
                        selected_mode_index = (selected_mode_index + 1) % len(mode_options)
                    if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                        active_mode = mode_options[selected_mode_index][1]
                        session = create_session(active_mode)
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_PLAYING

                elif game_state == STATE_GAME_OVER:
                    if event.key == pygame.K_ESCAPE:
                        return
                    if event.key == pygame.K_r and active_mode is not None:
                        session = create_session(active_mode)
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_PLAYING
                    if event.key == pygame.K_m:
                        session = None
                        active_mode = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_MENU

            if event.type == pygame.KEYUP:
                pressed_keys.discard(event.key)

        if game_state == STATE_MENU:
            draw_menu(screen, title_font, body_font, mode_options, selected_mode_index)
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_GAME_OVER:
            draw_game_over(
                screen,
                title_font,
                body_font,
                mode_label_from_value(mode_options, active_mode),
            )
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if session is None:
            game_state = STATE_MENU
            dt = clock.tick(60) / 1000
            continue

        screen.fill("black")
        session.updatable.update(dt, pressed_keys)

        player_destroyed = False
        for asteroid in session.asteroids.copy():
            if asteroid.collides_with(session.player):
                log_event("player_hit")
                print("Game over!")
                player_destroyed = True
                break
            for shot in session.shots.copy():
                if asteroid.collides_with(shot):
                    log_event("asteroid_shot")
                    asteroid.split()
                    shot.kill()
                    break

        if player_destroyed:
            session = None
            pressed_keys.clear()
            dt = 0.0
            game_state = STATE_GAME_OVER
            continue

        for drawable_object in session.drawable:
            drawable_object.draw(screen)
        pygame.display.flip()

        dt = clock.tick(60) / 1000


if __name__ == "__main__":
    main()
