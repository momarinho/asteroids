import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';

class BombComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final Vector2 velocity;
  double fuseTimer = 1.1; // Max flight time if no asteroid is hit
  final double explosionRadius = 90.0; // Balanced: wide impact without trivializing the whole screen
  final double radius = 10.0;
  bool _hasExploded = false;

  BombComponent({
    required Vector2 position,
    required this.velocity,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hasExploded) return;

    position += velocity * dt;
    wrapAround();

    fuseTimer -= dt;
    if (fuseTimer <= 0) {
      explode();
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

  void explode() {
    if (_hasExploded) return;
    _hasExploded = true;

    game.world.add(
      BombExplosionComponent(
        position: position.clone(),
        maxRadius: explosionRadius,
      ),
    );
    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_hasExploded) return;

    if (other is AsteroidComponent) {
      explode();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    // Filled red body
    final fillPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, fillPaint);

    // Orange outline
    final strokePaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.lineWidth;
    canvas.drawCircle(Offset.zero, radius, strokePaint);
  }
}

class BombExplosionComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double maxRadius;
  final double duration = 0.5;
  double timer = 0.0;
  double radius = 1.0;

  BombExplosionComponent({
    required Vector2 position,
    required this.maxRadius,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(maxRadius * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Trigger screen shake
    game.triggerScreenShake(duration: duration, intensity: 15.0);

    // Play explosion sound (placeholder/loaded in game)
    game.playSfx('player_hit.wav');

    // Spawn fire particles
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [Colors.red, Colors.orange, Colors.yellow, Colors.grey],
      count: 40,
      minSize: 3.0,
      maxSize: 6.0,
      minSpeed: 50.0,
      maxSpeed: 300.0,
    );

    // Instantly destroy/split asteroids in radius
    final asteroids = game.world.children.whereType<AsteroidComponent>();
    for (final asteroid in List<AsteroidComponent>.from(asteroids)) {
      final distance = position.distanceTo(asteroid.position);
      if (distance <= maxRadius + asteroid.radius) {
        game.score += (asteroid.radius * 5).toInt();
        asteroid.split();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;
    if (timer >= duration) {
      removeFromParent();
      return;
    }

    final progress = timer / duration;
    // Quadratic ease-out expansion
    radius = maxRadius * (1.0 - math.pow(1.0 - progress, 2));
  }

  @override
  void render(Canvas canvas) {
    final progress = timer / duration;
    final alpha = (255 * (1.0 - progress)).clamp(0.0, 255.0).toInt();
    if (alpha <= 0) return;

    canvas.translate(maxRadius, maxRadius);

    // Outer ring (red-orange)
    final outerPaint = Paint()
      ..color = Color.fromARGB(alpha, 255, (255 * 0.4).toInt(), 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, GameConstants.lineWidth * (1.0 - progress) * 3);
    canvas.drawCircle(Offset.zero, radius, outerPaint);

    // Inner ring (yellow)
    if (radius > 10.0) {
      final innerPaint = Paint()
        ..color = Color.fromARGB(alpha, 255, 255, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, GameConstants.lineWidth * (1.0 - progress) * 2);
      canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);
    }
  }
}
