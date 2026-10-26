import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'components/player.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';

abstract class Weapon {
  final String name;
  double cooldown;
  double recoil;
  double muzzleFlashSize;
  double damage;
  int level = 1;
  final int maxLevel = 3;

  Weapon({
    required this.name,
    required this.cooldown,
    required this.recoil,
    required this.muzzleFlashSize,
    required this.damage,
  });

  bool fire(PlayerComponent player);

  bool upgrade() {
    if (level >= maxLevel) {
      return false;
    }
    level++;
    applyUpgradeStats();
    return true;
  }

  void applyUpgradeStats();
}

class Blaster extends Weapon {
  Blaster()
      : super(
          name: "Laser Fotônico",
          cooldown: GameConstants.playerShootCooldownSeconds,
          recoil: 25.0,
          muzzleFlashSize: 8.0,
          damage: 50.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final velocity = player.forward * GameConstants.playerShootSpeed;
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: GameConstants.shotRadius,
      velocity: velocity,
      lifeTimer: GameConstants.shotLifetimeSeconds,
      damage: damage,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = GameConstants.playerShootCooldownSeconds * 0.75;
      recoil = 18.0;
      damage = 60.0;
    } else if (level == 3) {
      cooldown = GameConstants.playerShootCooldownSeconds * 0.5;
      recoil = 10.0;
      damage = 75.0;
    }
  }
}

class SpreadShot extends Weapon {
  SpreadShot()
      : super(
          name: "Tiro Dispersor",
          cooldown: 0.5,
          recoil: 55.0,
          muzzleFlashSize: 12.0,
          damage: 25.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final angles = [-15.0, 0.0, 15.0];
    final speedMultiplier = 1.0 + (level - 1) * 0.1;
    final baseSpeed = GameConstants.playerShootSpeed * 0.9 * speedMultiplier;

    for (final angleDeg in angles) {
      final angleRad = angleDeg * math.pi / 180.0;
      final shootAngle = player.angle + angleRad;
      
      final direction = Vector2(
        math.cos(shootAngle - math.pi / 2),
        math.sin(shootAngle - math.pi / 2),
      );

      final bullet = BulletComponent(
        position: player.position + player.forward * player.radius,
        radius: 4.0,
        velocity: direction * baseSpeed,
        lifeTimer: 0.6,
        damage: damage,
      );
      player.game.world.add(bullet);
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.4;
      recoil = 40.0;
      damage = 32.0;
    } else if (level == 3) {
      cooldown = 0.3;
      recoil = 25.0;
      damage = 40.0;
    }
  }
}

class RapidFire extends Weapon {
  RapidFire()
      : super(
          name: "Laser Veloz",
          cooldown: 0.15,
          recoil: 12.0,
          muzzleFlashSize: 6.0,
          damage: 18.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final velocity = player.forward * GameConstants.playerShootSpeed;
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: 3.0,
      velocity: velocity,
      lifeTimer: 0.8,
      damage: damage,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.10;
      recoil = 8.0;
      damage = 22.0;
    } else if (level == 3) {
      cooldown = 0.06;
      recoil = 4.0;
      damage = 28.0;
    }
  }
}

class BombLauncher extends Weapon {
  BombLauncher()
      : super(
          name: "Lança-Bombas",
          cooldown: 1.45,
          recoil: 135.0,
          muzzleFlashSize: 18.0,
          damage: 120.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final velocity = player.forward * 220.0;
    final bomb = BombComponent(
      position: player.position + player.forward * player.radius,
      velocity: velocity,
      damage: damage,
    );
    player.game.world.add(bomb);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 1.05;
      recoil = 80.0;
      damage = 150.0;
    } else if (level == 3) {
      cooldown = 0.75;
      recoil = 45.0;
      damage = 180.0;
    }
  }
}
