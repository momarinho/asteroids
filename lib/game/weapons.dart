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
          cooldown: 0.26,
          recoil: 14.0,
          muzzleFlashSize: 8.0,
          damage: 55.0,
        );

  @override
  bool fire(PlayerComponent player) {
    if (level >= 3) {
      // Nível 3: Disparo duplo paralelo com alta potência telescópica
      final right = Vector2(-player.forward.y, player.forward.x);
      for (final offset in [-6.0, 6.0]) {
        final spawnPos = player.position + player.forward * player.radius + right * offset;
        final bullet = BulletComponent(
          position: spawnPos,
          radius: GameConstants.shotRadius,
          velocity: player.forward * (GameConstants.playerShootSpeed + 40.0),
          lifeTimer: GameConstants.shotLifetimeSeconds,
          damage: damage,
        );
        player.game.world.add(bullet);
      }
      return true;
    }

    final velocity = player.forward * (GameConstants.playerShootSpeed + (level == 2 ? 30.0 : 0.0));
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: GameConstants.shotRadius + (level == 2 ? 1.0 : 0.0),
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
      cooldown = 0.19;
      recoil = 9.0;
      damage = 70.0;
      muzzleFlashSize = 10.0;
    } else if (level >= 3) {
      cooldown = 0.14;
      recoil = 5.0;
      damage = 95.0;
      muzzleFlashSize = 12.0;
    }
  }
}

class SpreadShot extends Weapon {
  SpreadShot()
      : super(
          name: "Tiro Dispersor",
          cooldown: 0.30,
          recoil: 16.0,
          muzzleFlashSize: 11.0,
          damage: 26.0,
        );

  @override
  bool fire(PlayerComponent player) {
    // Nível 3 dispara 5 projéteis em arco amplo; Nível 1 e 2 disparam 3
    final List<double> angles = level >= 3
        ? [-24.0, -12.0, 0.0, 12.0, 24.0]
        : [-14.0, 0.0, 14.0];

    final speedMultiplier = 1.0 + (level - 1) * 0.12;
    final baseSpeed = GameConstants.playerShootSpeed * 0.95 * speedMultiplier;
    final lifeTime = 0.75 + (level - 1) * 0.06;

    for (final angleDeg in angles) {
      final angleRad = angleDeg * math.pi / 180.0;
      final shootAngle = player.angle + angleRad;
      
      final direction = Vector2(
        math.cos(shootAngle - math.pi / 2),
        math.sin(shootAngle - math.pi / 2),
      );

      final bullet = BulletComponent(
        position: player.position + player.forward * player.radius,
        radius: 3.5 + (level >= 3 ? 0.8 : 0.0),
        velocity: direction * baseSpeed,
        lifeTimer: lifeTime,
        damage: damage,
      );
      player.game.world.add(bullet);
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.24;
      recoil = 11.0;
      damage = 32.0;
      muzzleFlashSize = 13.0;
    } else if (level >= 3) {
      cooldown = 0.18;
      recoil = 7.0;
      damage = 38.0;
      muzzleFlashSize = 15.0;
    }
  }
}

class RapidFire extends Weapon {
  RapidFire()
      : super(
          name: "Laser Veloz",
          cooldown: 0.11,
          recoil: 5.0,
          muzzleFlashSize: 6.0,
          damage: 16.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final velocity = player.forward * (GameConstants.playerShootSpeed + 50.0);
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: 3.2 + (level >= 3 ? 0.8 : 0.0),
      velocity: velocity,
      lifeTimer: 0.88,
      damage: damage,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.08;
      recoil = 3.0;
      damage = 20.0;
      muzzleFlashSize = 8.0;
    } else if (level >= 3) {
      cooldown = 0.055;
      recoil = 1.5;
      damage = 25.0;
      muzzleFlashSize = 9.0;
    }
  }
}

class BombLauncher extends Weapon {
  BombLauncher()
      : super(
          name: "Lança-Bombas",
          cooldown: 0.65,
          recoil: 28.0,
          muzzleFlashSize: 18.0,
          damage: 130.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final speed = 280.0 + (level - 1) * 40.0;
    final velocity = player.forward * speed;
    final explosionRadius = 95.0 + (level - 1) * 20.0;

    final bomb = BombComponent(
      position: player.position + player.forward * player.radius,
      velocity: velocity,
      damage: damage,
      explosionRadius: explosionRadius,
    );
    player.game.world.add(bomb);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.50;
      recoil = 18.0;
      damage = 165.0;
      muzzleFlashSize = 22.0;
    } else if (level >= 3) {
      cooldown = 0.38;
      recoil = 10.0;
      damage = 200.0;
      muzzleFlashSize = 26.0;
    }
  }
}
