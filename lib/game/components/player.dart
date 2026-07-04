import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/weapons.dart';
import 'asteroid.dart';

class PlayerComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  
  double movementAcceleration = GameConstants.playerAcceleration;
  double movementMaxSpeed = GameConstants.playerMaxSpeed;
  double movementFriction = GameConstants.playerFriction;
  
  double radius = GameConstants.playerRadius;
  double shootTimer = 0.0;
  double invulnerableTimer = GameConstants.playerInvulnerableSeconds;
  double dashCooldownTimer = 0.0;
  double dashActiveTimer = 0.0;
  Vector2 dashDirection = Vector2.zero();
  double muzzleFlashTimer = 0.0;
  double muzzleFlashSize = 0.0;

  late Weapon weapon;
  late final Map<String, Weapon> unlockedWeapons;

  PlayerComponent({required Vector2 position}) {
    this.position = position;
    angle = 0.0;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    weapon = Blaster();
    unlockedWeapons = {'blaster': weapon};
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AsteroidComponent) {
      if (!isInvulnerable()) {
        game.playSfx('player_hit.wav');
        game.triggerScreenShake(duration: 0.4, intensity: 12.0);

        game.spawnExplosionParticles(
          position: position,
          colorChoices: [Colors.cyan, Colors.white, Colors.blue, Colors.grey],
          count: 30,
          minSize: 2.5,
          maxSize: 5.0,
          minSpeed: 80.0,
          maxSpeed: 250.0,
        );

        game.lives -= 1;
        if (game.lives <= 0) {
          game.gameOver();
        } else {
          respawn(game.size.x / 2, game.size.y / 2);
        }
      }
    }
  }

  Vector2 get forward => Vector2(
        math.cos(angle - math.pi / 2),
        math.sin(angle - math.pi / 2),
      );

  void rotate(double dt, double direction) {
    angle += (GameConstants.playerTurnSpeed * math.pi / 180.0) * direction * dt;
  }

  void accelerate(double dt, double directionMultiplier) {
    velocity += forward * movementAcceleration * directionMultiplier * dt;
  }

  void clampSpeed() {
    if (velocity.length > movementMaxSpeed) {
      velocity.normalize();
      velocity.scale(movementMaxSpeed);
    }
  }

  void applyFriction(double dt) {
    velocity.scale(math.exp(-movementFriction * dt));
  }

  void dash() {
    if (dashCooldownTimer > 0) return;

    dashActiveTimer = GameConstants.playerDashDurationSeconds;
    dashCooldownTimer = GameConstants.playerDashCooldownSeconds;
    dashDirection = forward.normalized();
    invulnerableTimer = math.max(invulnerableTimer, GameConstants.playerDashDurationSeconds);
  }

  void respawn(double x, double y) {
    position.setValues(x, y);
    angle = 0.0;
    velocity.setZero();
    invulnerableTimer = GameConstants.playerInvulnerableSeconds;
  }

  bool isInvulnerable() => invulnerableTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);

    shootTimer = math.max(0.0, shootTimer - dt);
    invulnerableTimer = math.max(0.0, invulnerableTimer - dt);
    dashCooldownTimer = math.max(0.0, dashCooldownTimer - dt);
    muzzleFlashTimer = math.max(0.0, muzzleFlashTimer - dt);

    final keys = game.keysPressed;

    // Handle active dash
    if (dashActiveTimer > 0) {
      dashActiveTimer = math.max(0.0, dashActiveTimer - dt);
      velocity = dashDirection * GameConstants.playerDashSpeed;
      position += velocity * dt;
      wrapAround();

      // Spawn dash ghost trail
      game.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
        ),
      );
      return;
    }

    // Input Handling
    final stick = game.joystick.stickInput;
    if (stick.length > 0.15 && game.joystick.isDragging) {
      // Joystick drag steering & thrust
      final targetAngle = math.atan2(stick.y, stick.x) + math.pi / 2;
      double diff = targetAngle - angle;
      while (diff < -math.pi) diff += 2 * math.pi;
      while (diff > math.pi) diff -= 2 * math.pi;

      final turnAmount = (GameConstants.playerTurnSpeed * math.pi / 180.0) * dt;
      if (diff.abs() < turnAmount) {
        angle = targetAngle;
      } else {
        angle += turnAmount * diff.sign;
      }

      accelerate(dt, stick.length);
    } else {
      // Standard Keyboard Input Handling
      double rotateDirection = 0.0;
      if (keys.contains(LogicalKeyboardKey.arrowLeft) || keys.contains(LogicalKeyboardKey.keyA)) {
        rotateDirection -= 1.0;
      }
      if (keys.contains(LogicalKeyboardKey.arrowRight) || keys.contains(LogicalKeyboardKey.keyD)) {
        rotateDirection += 1.0;
      }
      if (rotateDirection != 0.0) {
        rotate(dt, rotateDirection);
      }

      if (keys.contains(LogicalKeyboardKey.arrowUp) || keys.contains(LogicalKeyboardKey.keyW)) {
        accelerate(dt, 1.0);
      }
      if (keys.contains(LogicalKeyboardKey.arrowDown) || keys.contains(LogicalKeyboardKey.keyS)) {
        accelerate(dt, -1.0);
      }
    }

    if (keys.contains(LogicalKeyboardKey.shiftLeft) || keys.contains(LogicalKeyboardKey.shiftRight)) {
      dash();
    }

    clampSpeed();
    applyFriction(dt);
    position += velocity * dt;
    wrapAround();

    if (keys.contains(LogicalKeyboardKey.space)) {
      shoot();
    }

    // Weapon switching controls
    if (keys.contains(LogicalKeyboardKey.digit1) && unlockedWeapons.containsKey('blaster')) {
      setWeapon(unlockedWeapons['blaster']!);
    }
    if (keys.contains(LogicalKeyboardKey.digit2) && unlockedWeapons.containsKey('spread_shot')) {
      setWeapon(unlockedWeapons['spread_shot']!);
    }
    if (keys.contains(LogicalKeyboardKey.digit3) && unlockedWeapons.containsKey('rapid_fire')) {
      setWeapon(unlockedWeapons['rapid_fire']!);
    }
    if (keys.contains(LogicalKeyboardKey.digit4) && unlockedWeapons.containsKey('bomb_launcher')) {
      setWeapon(unlockedWeapons['bomb_launcher']!);
    }
  }

  void shoot() {
    if (shootTimer > 0) return;

    if (weapon.fire(this)) {
      shootTimer = weapon.cooldown;
      // Apply physical recoil pushing the player backwards
      velocity -= forward * weapon.recoil;

      // Set muzzle flash visual effect
      muzzleFlashTimer = 0.08;
      muzzleFlashSize = weapon.muzzleFlashSize;

      game.playSfx('shoot.wav');
    }
  }

  void setWeapon(Weapon newWeapon) {
    weapon = newWeapon;
    final key = newWeapon.name.toLowerCase().replaceAll(' ', '_');
    unlockedWeapons[key] = newWeapon;
  }

  void wrapAround() {
    final sizeX = game.size.x;
    final sizeY = game.size.y;

    if (position.x < -radius) {
      position.x = sizeX + radius;
    } else if (position.x > sizeX + radius) {
      position.x = -radius;
    }

    if (position.y < -radius) {
      position.y = sizeY + radius;
    } else if (position.y > sizeY + radius) {
      position.y = -radius;
    }
  }

  @override
  void render(Canvas canvas) {
    // Blinking effect when invulnerable
    if (isInvulnerable()) {
      final milliseconds = DateTime.now().millisecondsSinceEpoch;
      if (milliseconds % 200 < 100) {
        return; // Skip rendering
      }
    }

    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.lineWidth;

    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(-radius / 1.5, radius)
      ..lineTo(radius / 1.5, radius)
      ..close();

    canvas.drawPath(path, paint);

    // Muzzle flash rendering
    if (muzzleFlashTimer > 0) {
      final flashPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(Offset(0, -radius), muzzleFlashSize, flashPaint);
      
      final innerFlashPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(0, -radius), muzzleFlashSize * 0.5, innerFlashPaint);
    }
  }
}

class DashGhost extends PositionComponent {
  final double maxLifespan = 0.15;
  double lifespan = 0.15;
  final double radius;

  DashGhost({
    required Vector2 position,
    required double initialAngle,
    required this.radius,
  }) {
    this.position = position.clone();
    angle = initialAngle;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (lifespan / maxLifespan * 80).clamp(0.0, 255.0).toInt();
    if (alpha <= 0) return;

    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = Color.fromARGB(alpha, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(-radius / 1.5, radius)
      ..lineTo(radius / 1.5, radius)
      ..close();

    canvas.drawPath(path, paint);
  }
}
