from __future__ import annotations
import pygame
from constants import SCREEN_WIDTH, SCREEN_HEIGHT

# For type checking
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from main import GameSession

class ShopItem:
    def __init__(self, item_id: str, label: str, cost: int, description: str) -> None:
        self.item_id = item_id
        self.label = label
        self.cost = cost
        self.description = description
        self.purchased = False

class Shop:
    purchase_sound: pygame.mixer.Sound | None = None
    powerup_sound: pygame.mixer.Sound | None = None

    def __init__(self, session: GameSession) -> None:
        self.session = session
        self.selected_index = 0
        
        # Define items for sale in the shop
        self.items = [
            ShopItem("blaster", "Weapon: Blaster", 250, "Standard issue single-shot blaster."),
            ShopItem("spread_shot", "Weapon: Spread Shot", 500, "Shoots 3 bullets in a spread cone. Short range."),
            ShopItem("rapid_fire", "Weapon: Rapid Fire", 600, "Extremely high fire rate, lower damage/recoil."),
            ShopItem("bomb_launcher", "Weapon: Bomb Launcher", 800, "Launches slow-moving bombs that detonate in a massive area."),
            ShopItem("speed_boost", "Upgrade: Thruster Speed (+15%)", 300, "Increase ship acceleration permanently."),
            ShopItem("extra_life", "Support: Extra Life (+1)", 400, "Adds 1 life to your reserves (Max 5)."),
            # An option to exit the shop and start the next stage
            ShopItem("proceed", ">> START NEXT STAGE <<", 0, "Finish shopping and launch into the next stage.")
        ]

        # Sync purchase status with what the player already has
        player = self.session.player
        for item in self.items:
            if item.item_id in player.unlocked_weapons:
                item.purchased = True

    def handle_input(self, key: int) -> str | None:
        """Handles shop navigation and actions. Returns 'proceed' if launching next level."""
        if key == pygame.K_UP:
            self.selected_index = (self.selected_index - 1) % len(self.items)
        elif key == pygame.K_DOWN:
            self.selected_index = (self.selected_index + 1) % len(self.items)
        elif key in (pygame.K_RETURN, pygame.K_KP_ENTER):
            selected_item = self.items[self.selected_index]
            if selected_item.item_id == "proceed":
                return "proceed"
            else:
                self.process_purchase(selected_item)
        elif key == pygame.K_c:
            # Cheat key: add 500 credits for testing
            self.session.credits += 500
        return None

    def process_purchase(self, item: ShopItem) -> None:
        player = self.session.player
        is_weapon = item.item_id in ("blaster", "spread_shot", "rapid_fire", "bomb_launcher")

        # 1. Handle Weapon Upgrades (if weapon is already purchased/unlocked)
        if is_weapon and item.item_id in player.unlocked_weapons:
            weapon = player.unlocked_weapons[item.item_id]
            if weapon.level >= weapon.max_level:
                print("Arma já está no nível máximo!")
                return

            upgrade_cost = 200 * weapon.level
            if self.session.credits < upgrade_cost:
                print("Créditos insuficientes para upgrade!")
                return

            self.session.credits -= upgrade_cost
            weapon.upgrade()
            if self.purchase_sound is not None:
                self.purchase_sound.play()
            print(f"Melhorou {weapon.name} para o Lvl {weapon.level}!")
            return

        # 2. Handle New Purchases (for items not yet unlocked/purchased)
        if self.session.credits < item.cost:
            print("Créditos insuficientes!")
            return

        if item.item_id in ("spread_shot", "rapid_fire", "bomb_launcher"):
            if item.purchased:
                return

            self.session.credits -= item.cost
            item.purchased = True

            if item.item_id == "spread_shot":
                from weapon import SpreadShot
                player.unlocked_weapons["spread_shot"] = SpreadShot()
            elif item.item_id == "rapid_fire":
                from weapon import RapidFire
                player.unlocked_weapons["rapid_fire"] = RapidFire()
            elif item.item_id == "bomb_launcher":
                from weapon import BombLauncher
                player.unlocked_weapons["bomb_launcher"] = BombLauncher()

            # Equip immediately
            player.set_weapon(player.unlocked_weapons[item.item_id])
            if self.purchase_sound is not None:
                self.purchase_sound.play()
            print(f"Adquiriu e equipou: {item.label}!")

        elif item.item_id == "speed_boost":
            if item.purchased:
                print("Melhoria de motores já adquirida!")
                return

            self.session.credits -= item.cost
            item.purchased = True
            player.movement_acceleration += 150
            player.movement_max_speed += 50
            if self.powerup_sound is not None:
                self.powerup_sound.play()
            print("Motores aprimorados permanentemente!")

        elif item.item_id == "extra_life":
            if self.session.lives >= 5:
                print("Limite máximo de 5 vidas atingido!")
                return

            self.session.credits -= item.cost
            self.session.lives += 1
            if self.powerup_sound is not None:
                self.powerup_sound.play()
            print("Vida extra adquirida!")

    def draw(self, screen: pygame.Surface, title_font: pygame.font.Font, body_font: pygame.font.Font) -> None:
        # Draw Shop Header
        title_surface = title_font.render("UPGRADE SHOP", True, "yellow")
        title_rect = title_surface.get_rect(center=(SCREEN_WIDTH // 2, 80))
        screen.blit(title_surface, title_rect)
        
        credits_surface = body_font.render(f"Available Credits: {self.session.credits}c", True, "white")
        credits_rect = credits_surface.get_rect(center=(SCREEN_WIDTH // 2, 140))
        screen.blit(credits_surface, credits_rect)
        
        # Draw Shop Items
        start_y = 200
        gap = 40
        player = self.session.player
        
        for index, item in enumerate(self.items):
            status_text = ""
            text_color = "white"
            
            if item.item_id == "proceed":
                text_color = "green" if index == self.selected_index else "white"
                label_text = item.label
            else:
                is_weapon = item.item_id in ("blaster", "spread_shot", "rapid_fire", "bomb_launcher")
                
                if is_weapon and item.item_id in player.unlocked_weapons:
                    weapon = player.unlocked_weapons[item.item_id]
                    if weapon.level >= weapon.max_level:
                        status_text = f"Lvl {weapon.level} [MAX]"
                        text_color = "gray"
                    else:
                        upgrade_cost = 200 * weapon.level
                        status_text = f"Lvl {weapon.level} -> {weapon.level + 1} ({upgrade_cost}c)"
                        if index == self.selected_index:
                            text_color = "yellow"
                elif item.item_id == "speed_boost" and item.purchased:
                    status_text = "[MAX]"
                    text_color = "gray"
                else:
                    status_text = f"({item.cost}c)"
                    if index == self.selected_index:
                        text_color = "yellow"
                
                label_text = f"{item.label} {status_text}"
                if index == self.selected_index and text_color != "gray":
                    text_color = "yellow"
            
            prefix = "> " if index == self.selected_index else "  "
            item_surface = body_font.render(f"{prefix}{label_text}", True, text_color)
            item_rect = item_surface.get_rect(center=(SCREEN_WIDTH // 2, start_y + index * gap))
            screen.blit(item_surface, item_rect)
            
        # Draw Description of selected item at the bottom
        selected_item = self.items[self.selected_index]
        
        # Dynamic description for upgrades
        desc_text = selected_item.description
        is_weapon = selected_item.item_id in ("blaster", "spread_shot", "rapid_fire", "bomb_launcher")
        if is_weapon and selected_item.item_id in player.unlocked_weapons:
            weapon = player.unlocked_weapons[selected_item.item_id]
            desc_text = f"Upgrade {weapon.name} to Level {weapon.level + 1} (Lower cooldown and recoil)."
            if weapon.level >= weapon.max_level:
                desc_text = f"{weapon.name} is at maximum level (Lvl {weapon.level})."

        desc_surface = body_font.render(desc_text, True, "cyan")
        desc_rect = desc_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 100))
        screen.blit(desc_surface, desc_rect)
        
        controls_surface = body_font.render("UP/DOWN: Navigate  |  ENTER: Buy/Action  |  ESC: Main Menu  |  C: Add Credits (Cheat)", True, "gray")
        controls_rect = controls_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 50))
        screen.blit(controls_surface, controls_rect)
