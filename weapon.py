from __future__ import annotations
import pygame
from shot import Shot
from bomb import Bomb
from constants import PLAYER_SHOOT_SPEED, PLAYER_SHOOT_COOLDOWN_SECONDS

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from player import Player

class Weapon:
    def __init__(self, name: str, cooldown: float, recoil: float, muzzle_flash_size: float) -> None:
        self.name = name
        self.cooldown = cooldown
        self.recoil = recoil
        self.muzzle_flash_size = muzzle_flash_size

    def fire(self, player: Player) -> bool:
        """Fires the weapon. Returns True if successfully fired."""
        raise NotImplementedError


class Blaster(Weapon):
    def __init__(self) -> None:
        super().__init__("Blaster", PLAYER_SHOOT_COOLDOWN_SECONDS, 25.0, 8.0)

    def fire(self, player: Player) -> bool:
        shot = Shot(player.position.x, player.position.y)
        shot.velocity = pygame.Vector2(0, 1).rotate(player.rotation) * PLAYER_SHOOT_SPEED
        return True


class SpreadShot(Weapon):
    def __init__(self) -> None:
        super().__init__("Spread Shot", 0.5, 55.0, 12.0)

    def fire(self, player: Player) -> bool:
        angles = [-15, 0, 15]
        for angle in angles:
            shot = Shot(player.position.x, player.position.y)
            # Shotgun stats: smaller shots and half range (lifetime)
            shot.radius = 4
            shot.life_timer = 0.6
            shot.velocity = pygame.Vector2(0, 1).rotate(player.rotation + angle) * (PLAYER_SHOOT_SPEED * 0.9)
        return True


class RapidFire(Weapon):
    def __init__(self) -> None:
        super().__init__("Rapid Fire", 0.15, 12.0, 6.0)

    def fire(self, player: Player) -> bool:
        shot = Shot(player.position.x, player.position.y)
        # Machine gun stats: smaller shots and slightly reduced range (lifetime)
        shot.radius = 3
        shot.life_timer = 0.8
        shot.velocity = pygame.Vector2(0, 1).rotate(player.rotation) * PLAYER_SHOOT_SPEED
        return True


class BombLauncher(Weapon):
    def __init__(self) -> None:
        super().__init__("Bomb Launcher", 1.5, 150.0, 18.0)

    def fire(self, player: Player) -> bool:
        direction = pygame.Vector2(0, 1).rotate(player.rotation)
        Bomb(player.position.x, player.position.y, direction)
        return True
