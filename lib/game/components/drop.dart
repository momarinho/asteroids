import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'player.dart';

enum DropType {
  lunarSample, // Fragmento Lunar (+100 pts)
  rareHelium,  // Hélio-3 Raro (+250 pts)
  darkMatter,  // Matéria Escura (+500 pts)
  shield,      // Escudo Fotônico (4s Invulnerabilidade)
  health,      // Cápsula de Reparo (+1 Vida)
}

class DropComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final DropType type;
  Vector2 velocity;
  double lifespan = 8.0;
  final double maxLifespan = 8.0;
  double pulseTimer = 0.0;
  final double radius = 12.0;

  DropComponent({
    required Vector2 position,
    required this.type,
    Vector2? initialVelocity,
  }) : velocity = initialVelocity ?? Vector2.zero() {
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
    if (game.state != GameState.playing) return;

    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    pulseTimer += dt * 4.0;

    // Gentle magnetic tractor pull towards player if within 160 pixels
    final player = game.player;
    final distToPlayer = (player.position - position).length;
    if (distToPlayer < 160.0 && distToPlayer > 0.1) {
      final pullDir = (player.position - position).normalized();
      velocity += pullDir * 240.0 * dt;
    }

    // Apply friction to drift velocity
    velocity.scale(math.exp(-1.5 * dt));
    position += velocity * dt;

    // Wrap around screen edges
    _wrapAround();
  }

  void _wrapAround() {
    const sizeX = 1280.0;
    const sizeY = 720.0;
    if (position.x < -radius) position.x = sizeX + radius;
    if (position.x > sizeX + radius) position.x = -radius;
    if (position.y < -radius) position.y = sizeY + radius;
    if (position.y > sizeY + radius) position.y = -radius;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;

    if (other is PlayerComponent) {
      _collect();
    }
  }

  void _collect() {
    game.playSfx('powerup.wav');

    Color particleColor;
    switch (type) {
      case DropType.lunarSample:
        game.score += 100;
        game.samplesCollected++;
        game.spawnFloatingText(
          position,
          "+100 AMOSTRA LUNAR!",
          color: Colors.cyanAccent,
          fontSize: 15.0,
        );
        particleColor = Colors.cyanAccent;
        break;

      case DropType.rareHelium:
        game.score += 250;
        game.samplesCollected++;
        game.spawnFloatingText(
          position,
          "+250 HÉLIO-3 RARO!",
          color: Colors.amberAccent,
          fontSize: 16.0,
        );
        particleColor = Colors.amberAccent;
        break;

      case DropType.darkMatter:
        game.score += 500;
        game.samplesCollected++;
        game.triggerScreenShake(duration: 0.2, intensity: 5.0);
        game.spawnFloatingText(
          position,
          "+500 MATÉRIA ESCURA! 🌌",
          color: const Color(0xFFE040FB),
          fontSize: 17.5,
          velocity: Vector2(0, -35),
        );
        particleColor = const Color(0xFFE040FB);
        break;

      case DropType.shield:
        game.player.invulnerableTimer = 4.0;
        game.spawnFloatingText(
          position,
          "ESCUDO 4s!",
          color: Colors.lightBlueAccent,
          fontSize: 15.0,
        );
        particleColor = Colors.lightBlueAccent;
        break;

      case DropType.health:
        if (game.lives < 3) {
          game.lives += 1;
          game.spawnFloatingText(
            position,
            "+1 VIDA!",
            color: const Color(0xFF00E676),
            fontSize: 15.0,
          );
        } else {
          game.score += 100;
          game.spawnFloatingText(
            position,
            "+100 REPARO!",
            color: const Color(0xFF00E676),
            fontSize: 15.0,
          );
        }
        particleColor = const Color(0xFF00E676);
        break;
    }

    // Explosion particles upon pickup
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [particleColor, Colors.white],
      count: 18,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 60.0,
      maxSpeed: 160.0,
    );

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Blinking effect in the last 2.5 seconds of lifespan
    if (lifespan < 2.5 && (DateTime.now().millisecondsSinceEpoch % 200 < 100)) {
      return;
    }

    canvas.translate(radius, radius);

    final pulseScale = 1.0 + math.sin(pulseTimer) * 0.18;
    Color mainColor;

    switch (type) {
      case DropType.lunarSample:
        mainColor = Colors.cyanAccent;
        break;
      case DropType.rareHelium:
        mainColor = Colors.amberAccent;
        break;
      case DropType.darkMatter:
        mainColor = const Color(0xFFE040FB);
        break;
      case DropType.shield:
        mainColor = Colors.lightBlueAccent;
        break;
      case DropType.health:
        mainColor = const Color(0xFF00E676);
        break;
    }

    // Outer glowing ring
    final glowPaint = Paint()
      ..color = mainColor.withOpacity(type == DropType.darkMatter ? 0.45 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = type == DropType.darkMatter ? 4.5 : 3.0;
    canvas.drawCircle(Offset.zero, radius * pulseScale, glowPaint);

    if (type == DropType.darkMatter) {
      // Secondary outer orbital halo for Dark Matter
      final orbitPaint = Paint()
        ..color = mainColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, radius * (pulseScale + 0.3), orbitPaint);
    }

    // Inner filled circle
    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.85, innerPaint);

    final borderPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset.zero, radius * 0.85, borderPaint);

    // Draw vector symbol inside
    final symbolPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    if (type == DropType.health) {
      // Cross
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 3, height: 10), symbolPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10, height: 3), symbolPaint);
    } else if (type == DropType.lunarSample) {
      // Diamond Crystal
      final path = Path()
        ..moveTo(0, -6)
        ..lineTo(5, 0)
        ..lineTo(0, 6)
        ..lineTo(-5, 0)
        ..close();
      canvas.drawPath(path, symbolPaint);
    } else if (type == DropType.rareHelium) {
      // Star / Hexagon
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final a = (i * math.pi) / 3;
        final r = (i % 2 == 0) ? 6.0 : 3.0;
        final x = r * math.cos(a);
        final y = r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, symbolPaint);
    } else if (type == DropType.darkMatter) {
      // Cosmic core: circle + cross flares
      canvas.drawCircle(Offset.zero, 3.5, symbolPaint);
      final flarePaint = Paint()
        ..color = mainColor
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), flarePaint);
      canvas.drawLine(const Offset(0, -6), const Offset(0, 6), flarePaint);
    } else if (type == DropType.shield) {
      // Shield circle outline
      final sPaint = Paint()
        ..color = mainColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, 4.5, sPaint);
    }
  }
}
