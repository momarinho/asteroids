import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'drop.dart';

class AsteroidComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  
  late final int numPoints;
  late final List<double> pointsOffsets;
  late final double rotationSpeed;

  late double maxHp;
  late double hp;
  double hitFlashTimer = 0.0;

  AsteroidComponent({
    required this.radius,
    required Vector2 position,
    required this.velocity,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    
    // Scale HP with asteroid size
    if (radius > GameConstants.asteroidMinRadius * 2.2) {
      maxHp = 90.0; // Large
    } else if (radius > GameConstants.asteroidMinRadius * 1.2) {
      maxHp = 50.0; // Medium
    } else {
      maxHp = 25.0; // Small
    }
    hp = maxHp;

    final random = math.Random();
    numPoints = random.nextInt(7) + 8; // 8 to 14 points
    pointsOffsets = List.generate(
      numPoints,
      (_) => 0.75 + random.nextDouble() * 0.5, // 0.75 to 1.25
    );
    
    // rotation speed in radians per second
    rotationSpeed = (-40.0 + random.nextDouble() * 80.0) * math.pi / 180.0;
    angle = random.nextDouble() * 2 * math.pi;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add circular hitbox for collision detection
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }
    position += velocity * dt;
    angle += rotationSpeed * dt;
    wrapAround();
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    // Small rock sparks on hit
    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [Colors.orangeAccent, Colors.white, Colors.grey],
      count: 4,
      minSize: 1.5,
      maxSize: 3.0,
      minSpeed: 30.0,
      maxSpeed: 90.0,
    );

    if (hp <= 0) {
      split();
      return true; // Destroyed
    } else {
      // Small damage number popup
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: Colors.orangeAccent,
        fontSize: 11.5,
      );
      return false; // Still alive
    }
  }

  void wrapAround() {
    final sizeX = GameConstants.screenWidth;
    final sizeY = GameConstants.screenHeight;

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
    canvas.translate(radius, radius);

    final isFlashing = hitFlashTimer > 0;
    final paint = Paint()
      ..color = isFlashing ? Colors.redAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFlashing ? GameConstants.lineWidth * 1.8 : GameConstants.lineWidth;

    if (isFlashing) {
      final fillPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      final fillPath = Path();
      for (var i = 0; i < numPoints; i++) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i];
        final x = r * math.cos(pointAngle);
        final y = r * math.sin(pointAngle);
        if (i == 0) {
          fillPath.moveTo(x, y);
        } else {
          fillPath.lineTo(x, y);
        }
      }
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    final path = Path();
    for (var i = 0; i < numPoints; i++) {
      final pointAngle = (2 * math.pi * i) / numPoints;
      final r = radius * pointsOffsets[i];
      final x = r * math.cos(pointAngle);
      final y = r * math.sin(pointAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void split() {
    removeFromParent();

    // Spawn explosion particles
    final numParticles = math.max(8, (radius * 0.8).toInt());
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [Colors.white, Colors.orange, Colors.yellow, Colors.grey],
      count: numParticles,
      minSize: 2.0,
      maxSize: 4.0,
      minSpeed: 40.0,
      maxSpeed: 180.0,
    );
    
    // Proportional screen shake
    final shakeIntensity = radius * 0.15;
    game.triggerScreenShake(duration: 0.15, intensity: shakeIntensity);

    final random = math.Random();

    // Science Fair: Chance to drop exploration samples or utility powerups based on asteroid size
    double dropChance = 0.25;
    if (radius >= 50.0) {
      dropChance = 0.60;
    } else if (radius >= 30.0) {
      dropChance = 0.40;
    }

    if (random.nextDouble() < dropChance) {
      final roll = random.nextDouble();
      DropType dropType;
      if (roll < 0.45) {
        dropType = DropType.lunarSample; // 45% Lunar Sample (+100 pts)
      } else if (roll < 0.70) {
        dropType = DropType.rareHelium;  // 25% Rare Helium-3 (+250 pts)
      } else if (roll < 0.80) {
        dropType = DropType.darkMatter;  // 10% Dark Matter (+500 pts)
      } else if (roll < 0.90) {
        dropType = DropType.shield;      // 10% Photonic Shield (4s)
      } else {
        dropType = DropType.health;      // 10% Life Repair Fragment
      }

      final driftAngle = random.nextDouble() * 2 * math.pi;
      final dropVel = Vector2(math.cos(driftAngle), math.sin(driftAngle)) * 30.0;

      game.world.add(
        DropComponent(
          position: position.clone(),
          type: dropType,
          initialVelocity: dropVel,
        ),
      );
    }

    if (radius <= GameConstants.asteroidMinRadius) {
      return;
    }

    // Split into two smaller asteroids
    final splitAngle = 20.0 + random.nextDouble() * 30.0; // 20 to 50 degrees
    final radAngle = splitAngle * math.pi / 180.0;

    final velocityA = velocity.clone()..rotate(radAngle);
    final velocityB = velocity.clone()..rotate(-radAngle);
    final newRadius = radius - GameConstants.asteroidMinRadius;

    final asteroidA = AsteroidComponent(
      radius: newRadius,
      position: position.clone(),
      velocity: velocityA * 1.2,
    );
    
    final asteroidB = AsteroidComponent(
      radius: newRadius,
      position: position.clone(),
      velocity: velocityB * 1.2,
    );

    game.world.add(asteroidA);
    game.world.add(asteroidB);
  }
}
