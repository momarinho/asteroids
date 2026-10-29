import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';

class BombComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final Vector2 velocity;
  final double damage;
  double fuseTimer = 1.1; // Max flight time if no asteroid is hit
  final double explosionRadius = 90.0; // Balanced: wide impact without trivializing the whole screen
  final double radius = 10.0;
  bool _hasExploded = false;

  BombComponent({
    required Vector2 position,
    required this.velocity,
    this.damage = 120.0,
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
        damage: damage,
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

    // Bomba incandescente: orbe vermelha com núcleo quente e pulso rápido
    final pulse = 0.85 + 0.15 * math.sin(fuseTimer * 30.0);
    Glow.orb(canvas, Offset.zero, radius * pulse, Colors.redAccent, intensity: 1.2);
    Glow.strokeCircle(canvas, Offset.zero, radius, Colors.amberAccent, width: GameConstants.lineWidth, intensity: 0.8);
  }
}

class BombExplosionComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double maxRadius;
  final double damage;
  final double duration = 0.5;
  double timer = 0.0;
  double radius = 1.0;

  BombExplosionComponent({
    required Vector2 position,
    required this.maxRadius,
    this.damage = 120.0,
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

    // Damage / destroy asteroids in radius & track multi-kill
    int destroyedCount = 0;
    final asteroids = game.world.children.whereType<AsteroidComponent>();
    for (final asteroid in List<AsteroidComponent>.from(asteroids)) {
      final distance = position.distanceTo(asteroid.position);
      if (distance <= maxRadius + asteroid.radius) {
        final destroyed = asteroid.takeDamage(damage, asteroid.position);
        if (destroyed) {
          destroyedCount++;
          game.onAsteroidDestroyed(asteroid.position, (asteroid.radius * 5).toInt());
        }
      }
    }

    if (destroyedCount >= 2) {
      game.spawnFloatingText(
        position + Vector2(0, -32),
        '💥 IMPACTO MÚLTIPLO! (x$destroyedCount)',
        color: Colors.amberAccent,
        fontSize: 16.0,
        velocity: Vector2(0, -30),
      );
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

    // Outer ring (red-orange) com halo neon
    Glow.strokeCircle(
      canvas,
      Offset.zero,
      radius,
      Color.fromARGB(alpha, 255, (255 * 0.4).toInt(), 0),
      width: math.max(1.0, GameConstants.lineWidth * (1.0 - progress) * 3),
      intensity: 1.0 - progress,
    );

    // Inner ring (yellow)
    if (radius > 10.0) {
      Glow.strokeCircle(
        canvas,
        Offset.zero,
        radius * 0.6,
        Color.fromARGB(alpha, 255, 255, 0),
        width: math.max(1.0, GameConstants.lineWidth * (1.0 - progress) * 2),
        intensity: 1.0 - progress,
      );
    }
  }
}
