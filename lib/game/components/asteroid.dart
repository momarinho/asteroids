import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';

class AsteroidComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  
  late final int numPoints;
  late final List<double> pointsOffsets;
  late final double rotationSpeed;

  AsteroidComponent({
    required this.radius,
    required Vector2 position,
    required this.velocity,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    
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
    position += velocity * dt;
    angle += rotationSpeed * dt;
    wrapAround();
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
    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.lineWidth;

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

    if (radius <= GameConstants.asteroidMinRadius) {
      return;
    }

    // Split into two smaller asteroids
    final random = math.Random();
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

    game.add(asteroidA);
    game.add(asteroidB);
  }
}
