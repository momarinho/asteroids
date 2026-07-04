from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

import pygame

from asteroid import Asteroid
from asteroidfield import AsteroidField
from constants import PLAYER_LIVES, SCREEN_HEIGHT, SCREEN_WIDTH
from logger import log_event, log_state
from player import Player
from shot import Shot
from weapon import Blaster, BombLauncher, RapidFire, SpreadShot, Weapon
from level_manager import LevelManager
from shop import Shop

GameState = str
GameMode = str

STATE_MENU: GameState = "menu"
STATE_SETTINGS: GameState = "settings"
STATE_PLAYING: GameState = "playing"
STATE_GAME_OVER: GameState = "game_over"
STATE_STAGE_CLEAR: GameState = "stage_clear"
STATE_SHOP: GameState = "shop"


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
    current_level: int = 1
    credits: int = 0


@dataclass(frozen=True)
class MovementPreset:
    label: str
    acceleration: float
    max_speed: float
    friction: float


def create_session(mode: GameMode, weapon_class: Callable[[], Weapon]) -> GameSession:
    asteroids = pygame.sprite.Group()
    shots = pygame.sprite.Group()
    updatable = pygame.sprite.Group()
    drawable = pygame.sprite.Group()

    from bomb import Bomb, BombExplosion
    from particle import Particle

    Player.containers = (updatable, drawable)
    Asteroid.containers = (asteroids, updatable, drawable)
    Shot.containers = (shots, updatable, drawable)
    Bomb.containers = (updatable, drawable)
    BombExplosion.containers = (updatable, drawable)
    Particle.containers = (updatable, drawable)
    AsteroidField.containers = updatable

    player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
    player.set_weapon(weapon_class())
    asteroid_field = AsteroidField(mode)

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
        current_level=1,
        credits=0,
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
    starting_weapon_label: str,
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
            f"Movement Preset: {movement_preset_label}",
            f"Starting Weapon: {starting_weapon_label}",
            "Tab to open settings",
            "Up/Down to select mode",
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
    active_preset_index: int,
    weapons: list[tuple[str, Callable[[], Weapon]]],
    active_weapon_index: int,
    selected_row: int,
) -> None:
    screen.fill("black")
    draw_centered_lines(
        screen,
        title_font,
        ["Settings"],
        150,
        gap=8,
    )

    movement_label = presets[active_preset_index].label
    weapon_label = weapons[active_weapon_index][0]

    row_0_prefix = "> " if selected_row == 0 else "  "
    row_1_prefix = "> " if selected_row == 1 else "  "

    settings_lines = [
        f"{row_0_prefix}Movement Preset: < {movement_label} >",
        f"{row_1_prefix}Starting Weapon: < {weapon_label} >",
    ]

    draw_centered_lines(screen, body_font, settings_lines, 280, gap=24)
    draw_centered_lines(
        screen,
        body_font,
        [
            "Up/Down to select setting",
            "Left/Right to change value",
            "Esc to return to menu",
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


def draw_stage_clear(
    screen: pygame.Surface,
    title_font: pygame.font.Font,
    body_font: pygame.font.Font,
    level_manager: LevelManager,
) -> None:
    screen.fill("black")
    draw_centered_lines(
        screen,
        title_font,
        [f"Stage {level_manager.current_level} Clear!"],
        160,
        gap=12,
    )
    draw_centered_lines(
        screen,
        body_font,
        [
            f"Current Score: {level_manager.session.score}",
            f"Stage Clear Bonus: +{level_manager.stage_clear_bonus} credits",
            f"Remaining Lives Bonus: +{level_manager.lives_bonus} credits",
            f"Total Credits Earned: +{level_manager.bonus_credits} credits",
            f"Total Credits: {level_manager.session.credits}",
            "",
            "Press Enter to proceed to the next stage",
            "Press Esc to return to the menu",
        ],
        260,
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

    if session.mode == "campaign":
        stage_text = font.render(f"Stage: {session.current_level}", True, "white")
        credits_text = font.render(f"Credits: {session.credits}", True, "white")
        screen.blit(stage_text, (20, 230))
        screen.blit(credits_text, (20, 265))


def load_sound(path: str) -> pygame.mixer.Sound | None:
    sound_path = Path(path)
    if not sound_path.exists():
        return None

    try:
        return pygame.mixer.Sound(sound_path)
    except (pygame.error, NotImplementedError):
        return None


def play_music() -> None:
    try:
        pygame.mixer.music.load("assets/sounds/music.wav")
        pygame.mixer.music.play(-1)
    except pygame.error:
        pass


def stop_music() -> None:
    try:
        pygame.mixer.music.stop()
    except pygame.error:
        pass


def apply_movement_preset(preset: MovementPreset) -> None:
    Player.movement_acceleration = preset.acceleration
    Player.movement_max_speed = preset.max_speed
    Player.movement_friction = preset.friction


def main():
    from sound_generator import generate_all_missing_sounds
    generate_all_missing_sounds()

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
    low_health_sound = load_sound("assets/sounds/low_health.wav")
    purchase_sound = load_sound("assets/sounds/purchase.wav")
    powerup_sound = load_sound("assets/sounds/powerup.wav")

    Player.shoot_sound = shoot_sound
    Shop.purchase_sound = purchase_sound
    Shop.powerup_sound = powerup_sound

    from bomb import BombExplosion
    BombExplosion.explosion_sound = player_hit_sound

    from background import BackgroundStars
    background_stars = BackgroundStars(80)
    game_surface = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT))

    dt = 0.0
    pressed_keys: set[int] = set()
    game_state: GameState = STATE_MENU
    mode_options: list[tuple[str, GameMode]] = [
        ("Classic", "classic"),
        ("Campaign", "campaign"),
    ]
    movement_presets = [
        MovementPreset("Arcade Tight", 700, 220, 5.0),
        MovementPreset("Balanced", 650, 250, 4.0),
        MovementPreset("Floaty Classic", 450, 320, 2.0),
    ]
    weapon_options: list[tuple[str, Callable[[], Weapon]]] = [
        ("Blaster", Blaster),
        ("Spread Shot", SpreadShot),
        ("Rapid Fire", RapidFire),
        ("Bomb Launcher", BombLauncher),
    ]
    selected_mode_index = 0
    selected_settings_row = 0
    active_movement_preset_index = 1
    active_weapon_index = 0
    active_mode: GameMode | None = None
    session: GameSession | None = None
    level_manager: LevelManager | None = None
    shop: Shop | None = None
    apply_movement_preset(movement_presets[active_movement_preset_index])
    
    low_health_warn_timer = 0.0


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
                        selected_settings_row = 0
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
                        starting_weapon = weapon_options[0][1] if active_mode == "campaign" else weapon_options[active_weapon_index][1]
                        session = create_session(
                            active_mode, starting_weapon
                        )
                        if active_mode == "campaign" and session is not None:
                            level_manager = LevelManager(session)
                        else:
                            level_manager = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_PLAYING
                        play_music()

                elif game_state == STATE_SETTINGS:
                    if event.key == pygame.K_ESCAPE:
                        game_state = STATE_MENU
                    if event.key == pygame.K_UP:
                        selected_settings_row = (selected_settings_row - 1) % 2
                    if event.key == pygame.K_DOWN:
                        selected_settings_row = (selected_settings_row + 1) % 2
                    if event.key == pygame.K_LEFT:
                        if selected_settings_row == 0:
                            active_movement_preset_index = (
                                active_movement_preset_index - 1
                            ) % len(movement_presets)
                            apply_movement_preset(
                                movement_presets[active_movement_preset_index]
                            )
                        elif selected_settings_row == 1:
                            active_weapon_index = (active_weapon_index - 1) % len(
                                weapon_options
                            )
                    if event.key == pygame.K_RIGHT:
                        if selected_settings_row == 0:
                            active_movement_preset_index = (
                                active_movement_preset_index + 1
                            ) % len(movement_presets)
                            apply_movement_preset(
                                movement_presets[active_movement_preset_index]
                            )
                        elif selected_settings_row == 1:
                            active_weapon_index = (active_weapon_index + 1) % len(
                                weapon_options
                            )

                elif game_state == STATE_PLAYING:
                    if active_mode == "campaign" and event.key == pygame.K_k:
                        # QA Cheat key to instantly kill all active asteroids
                        if session is not None:
                            for asteroid in list(session.asteroids):
                                asteroid.kill()

                elif game_state == STATE_STAGE_CLEAR:
                    if event.key == pygame.K_ESCAPE:
                        session = None
                        active_mode = None
                        level_manager = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_MENU
                        stop_music()
                    elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                        if level_manager is not None and session is not None:
                            shop = Shop(session)
                            game_state = STATE_SHOP
                            pressed_keys.clear()
                            dt = 0.0

                elif game_state == STATE_SHOP:
                    if event.key == pygame.K_ESCAPE:
                        session = None
                        active_mode = None
                        level_manager = None
                        shop = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_MENU
                        stop_music()
                    elif event.key in (pygame.K_UP, pygame.K_DOWN, pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_c):
                        if shop is not None:
                            action = shop.handle_input(event.key)
                            if action == "proceed":
                                if level_manager is not None and session is not None:
                                    level_manager.advance_level()
                                    session.player.respawn(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
                                    shop = None
                                    pressed_keys.clear()
                                    dt = 0.0
                                    game_state = STATE_PLAYING

                elif game_state == STATE_GAME_OVER:
                    if event.key == pygame.K_ESCAPE:
                        return
                    if event.key == pygame.K_r and active_mode is not None:
                        starting_weapon = weapon_options[0][1] if active_mode == "campaign" else weapon_options[active_weapon_index][1]
                        session = create_session(
                            active_mode, starting_weapon
                        )
                        if active_mode == "campaign" and session is not None:
                            level_manager = LevelManager(session)
                        else:
                            level_manager = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_PLAYING
                        play_music()
                    if event.key == pygame.K_m:
                        session = None
                        active_mode = None
                        level_manager = None
                        shop = None
                        pressed_keys.clear()
                        dt = 0.0
                        game_state = STATE_MENU
                        stop_music()

            if event.type == pygame.KEYUP:
                pressed_keys.discard(event.key)

        if game_state == STATE_MENU:
            screen.fill("black")
            background_stars.draw(screen)
            draw_menu(
                screen,
                title_font,
                body_font,
                mode_options,
                selected_mode_index,
                movement_presets[active_movement_preset_index].label,
                weapon_options[active_weapon_index][0],
            )
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_SETTINGS:
            screen.fill("black")
            background_stars.draw(screen)
            draw_settings(
                screen,
                title_font,
                body_font,
                movement_presets,
                active_movement_preset_index,
                weapon_options,
                active_weapon_index,
                selected_settings_row,
            )
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_GAME_OVER:
            screen.fill("black")
            background_stars.draw(screen)
            draw_game_over(
                screen,
                title_font,
                body_font,
                mode_label_from_value(mode_options, active_mode),
            )
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_STAGE_CLEAR:
            screen.fill("black")
            background_stars.draw(screen)
            if level_manager is not None:
                draw_stage_clear(screen, title_font, body_font, level_manager)
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if game_state == STATE_SHOP:
            screen.fill("black")
            background_stars.draw(screen)
            if shop is not None:
                shop.draw(screen, title_font, body_font)
            pygame.display.flip()
            dt = clock.tick(60) / 1000
            continue

        if session is None:
            game_state = STATE_MENU
            dt = clock.tick(60) / 1000
            continue

        # Update background stars
        player_vel = pygame.Vector2(0, 0)
        if session is not None:
            player_vel = session.player.velocity
        background_stars.update(player_vel, dt)

        # Update screen shake
        import screen_shake
        import random
        shake_offset_x = 0
        shake_offset_y = 0
        if screen_shake.shake_timer > 0:
            screen_shake.shake_timer -= dt
            current_intensity = screen_shake.shake_intensity * (screen_shake.shake_timer / screen_shake.shake_duration)
            shake_offset_x = random.uniform(-current_intensity, current_intensity)
            shake_offset_y = random.uniform(-current_intensity, current_intensity)

        # Low health sound chime loop
        if session is not None and session.lives == 1:
            low_health_warn_timer -= dt
            if low_health_warn_timer <= 0:
                low_health_warn_timer = 3.5
                if low_health_sound is not None:
                    low_health_sound.play()

        game_surface.fill("black")
        background_stars.draw(game_surface)

        session.updatable.update(dt, pressed_keys)

        if active_mode == "campaign" and level_manager is not None:
            level_manager.update(dt)
            if level_manager.state == "stage_clear":
                game_state = STATE_STAGE_CLEAR
                pressed_keys.clear()
                dt = clock.tick(60) / 1000
                continue

        player_destroyed = False
        for asteroid in session.asteroids.copy():
            if not session.player.is_invulnerable() and asteroid.collides_with(
                session.player
            ):
                log_event("player_hit")
                if player_hit_sound is not None:
                    player_hit_sound.play()

                # Spawn player hit particles
                from particle import spawn_explosion
                colors = ["cyan", "white", "blue", "gray"]
                for _ in range(30):
                    color = random.choice(colors)
                    spawn_explosion(
                        session.player.position.x,
                        session.player.position.y,
                        num_particles=1,
                        color=color,
                        size=random.uniform(2.5, 5.0),
                        speed_range=(80, 250),
                    )

                # Trigger screen shake!
                from screen_shake import trigger_screen_shake
                trigger_screen_shake(0.4, 12.0)

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
            stop_music()
            continue

        for drawable_object in session.drawable:
            drawable_object.draw(game_surface)

        screen.fill("black")
        screen.blit(game_surface, (shake_offset_x, shake_offset_y))

        draw_hud(screen, body_font, session)
        pygame.display.flip()

        dt = clock.tick(60) / 1000


if __name__ == "__main__":
    main()
