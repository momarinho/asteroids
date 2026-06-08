from __future__ import annotations

from pathlib import Path
from dataclasses import dataclass

import pygame

from asteroid import Asteroid
from asteroidfield import AsteroidField
from constants import PLAYER_LIVES, SCREEN_HEIGHT, SCREEN_WIDTH
from logger import log_event, log_state
from player import Player
from shot import Shot

GameState = str
GameMode = str

STATE_MENU: GameState = "menu"
STATE_SETTINGS: GameState = "settings"
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
    score: int
    lives: int


@dataclass(frozen=True)
class MovementPreset:
    label: str
    acceleration: float
    max_speed: float
    friction: float


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
        score=0,
        lives=PLAYER_LIVES,
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
    movement_preset_label: str,
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
            f"Movement preset: {movement_preset_label}",
            "Tab to open settings",
            "Up/Down to select",
            "Enter to start",
            "Esc to quit",
        ],
        450,
        gap=12,
    )


def draw_settings(
    screen: pygame.Surface,
    title_font: pygame.font.Font,
    body_font: pygame.font.Font,
    presets: list[MovementPreset],
    selected_index: int,
    active_index: int,
) -> None:
    screen.fill("black")
    draw_centered_lines(
        screen,
        title_font,
        ["Settings", "Movement Preset"],
        150,
        gap=8,
    )

    preset_lines = []
    for index, preset in enumerate(presets):
        selected_prefix = ">" if index == selected_index else " "
        active_suffix = " (Active)" if index == active_index else ""
        preset_lines.append(f"{selected_prefix} {preset.label}{active_suffix}")

    draw_centered_lines(screen, body_font, preset_lines, 280, gap=16)
    draw_centered_lines(
        screen,
        body_font,
        [
            "Up/Down to choose",
            "Enter to apply",
            "Esc to return",
        ],
        500,
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


def mode_label_from_value(
    modes: list[tuple[str, GameMode]], mode: GameMode | None
) -> str:
    if mode is None:
        return "None"

    for label, value in modes:
        if value == mode:
            return label
    return mode


def draw_hud(
    screen: pygame.Surface, font: pygame.font.Font, session: GameSession
) -> None:
    score_text = font.render(f"Score: {session.score}", True, "white")
    lives_text = font.render(f"Lives: {session.lives}", True, "white")
    danger_text = font.render(
        f"Danger: {session.asteroid_field.danger_level()}",
        True,
        "white",
    )

    if session.player.shoot_timer > 0:
        cooldown_label = f"Cooldown: {session.player.shoot_timer:.2f}s"
    else:
        cooldown_label = "Cooldown: Ready"

    if session.player.is_invulnerable():
        invulnerable_label = f"Invulnerable: {session.player.invulnerable_timer:.1f}s"
    else:
        invulnerable_label = "Invulnerable: No"

    if session.player.dash_cooldown_timer > 0:
        dash_label = f"Dash: {session.player.dash_cooldown_timer:.1f}s"
    else:
        dash_label = "Dash: Ready"

    cooldown_text = font.render(cooldown_label, True, "white")
    invulnerable_text = font.render(invulnerable_label, True, "white")
    dash_text = font.render(dash_label, True, "white")

    screen.blit(score_text, (20, 20))
    screen.blit(lives_text, (20, 55))
    screen.blit(cooldown_text, (20, 90))
    screen.blit(invulnerable_text, (20, 125))
    screen.blit(danger_text, (20, 160))
    screen.blit(dash_text, (20, 195))



def load_sound(path: str) -> pygame.mixer.Sound | None:
    sound_path = Path(path)
    if not sound_path.exists():
        return None

    try:
        return pygame.mixer.Sound(sound_path)
    except (pygame.error, NotImplementedError):
        return None


def apply_movement_preset(preset: MovementPreset) -> None:
    Player.movement_acceleration = preset.acceleration
    Player.movement_max_speed = preset.max_speed
    Player.movement_friction = preset.friction


def main():
    pygame.init()
    try:
        pygame.mixer.init()
    except pygame.error:
        pass

    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Asteroids")
    clock = pygame.time.Clock()
    title_font = pygame.font.Font(None, 72)
    body_font = pygame.font.Font(None, 36)
    shoot_sound = load_sound("assets/sounds/shoot.wav")
    player_hit_sound = load_sound("assets/sounds/player_hit.wav")
    asteroid_split_sound = load_sound("assets/sounds/asteroid_split.wav")
    Player.shoot_sound = shoot_sound

    dt = 0.0
    pressed_keys: set[int] = set()
    game_state: GameState = STATE_MENU
    mode_options: list[tuple[str, GameMode]] = [("Classic", "classic")]
    movement_presets = [
        MovementPreset("Arcade Tight", 700, 220, 5.0),
        MovementPreset("Balanced", 650, 250, 4.0),
        MovementPreset("Floaty Classic", 450, 320, 2.0),
    ]
    selected_mode_index = 0
    selected_settings_index = 1
    active_movement_preset_index = 1
    active_mode: GameMode | None = None
    session: GameSession | None = None
    apply_movement_preset(movement_presets[active_movement_preset_index])

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
                    if event.key == pygame.K_TAB:
                        selected_settings_index = active_movement_preset_index
                        game_state = STATE_SETTINGS
                    if event.key == pygame.K_UP:
                        selected_mode_index = (selected_mode_index - 1) % len(
                            mode_options
                        )
                    if event.key == pygame.K_DOWN:
                        selected_mode_index = (selected_mode_index + 1) % len(
                            mode_options
                        )
                    if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                        active_mode = mode_options[selected_mode_index][1]
                        session = create_session(active_mode)
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_PLAYING

                elif game_state == STATE_SETTINGS:
                    if event.key == pygame.K_ESCAPE:
                        game_state = STATE_MENU
                    if event.key == pygame.K_UP:
                        selected_settings_index = (
                            selected_settings_index - 1
                        ) % len(movement_presets)
                    if event.key == pygame.K_DOWN:
                        selected_settings_index = (
                            selected_settings_index + 1
                        ) % len(movement_presets)
                    if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                        active_movement_preset_index = selected_settings_index
                        apply_movement_preset(
                            movement_presets[active_movement_preset_index]
                        )
                        game_state = STATE_MENU

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
            draw_menu(
                screen,
                title_font,
                body_font,
                mode_options,
                selected_mode_index,
                movement_presets[active_movement_preset_index].label,
            )
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_SETTINGS:
            draw_settings(
                screen,
                title_font,
                body_font,
                movement_presets,
                selected_settings_index,
                active_movement_preset_index,
            )
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
            if not session.player.is_invulnerable() and asteroid.collides_with(
                session.player
            ):
                log_event("player_hit")
                if player_hit_sound is not None:
                    player_hit_sound.play()
                session.lives -= 1

                if session.lives <= 0:
                    print("Game over!")
                    player_destroyed = True
                else:
                    session.player.respawn(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)

                break
            for shot in session.shots.copy():
                if asteroid.collides_with(shot):
                    log_event("asteroid_shot")
                    if asteroid_split_sound is not None:
                        asteroid_split_sound.play()
                    session.score += int(asteroid.radius * 5)
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

        draw_hud(screen, body_font, session)
        pygame.display.flip()

        dt = clock.tick(60) / 1000


if __name__ == "__main__":
    main()
