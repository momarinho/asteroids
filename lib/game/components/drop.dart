import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'player.dart';

enum DropType {
  sample,     // Amostra de Minerais/Pesquisa (+150 pontos)
  health,     // Fragmento de Vida (+1 Vida)
  speedBoost, // Turbo Propulsor (+Velocidade)
  shield,     // Escudo Protetor (+4s Invulnerabilidade)
}

class DropComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final DropType type;
  Vector2 velocity;
  double lifespan = 12.0;
  final double maxLifespan = 12.0;
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

    // Gentle magnetic pull towards player if within 140 pixels
    final player = game.player;
    final distToPlayer = (player.position - position).length;
    if (distToPlayer < 140.0 && distToPlayer > 0.1) {
      final pullDir = (player.position - position).normalized();
      velocity += pullDir * 180.0 * dt;
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
      case DropType.sample:
        game.score += 150;
        particleColor = Colors.amberAccent;
        break;
      case DropType.health:
        if (game.lives < 3) {
          game.lives += 1;
        } else {
          game.score += 100;
        }
        particleColor = Colors.greenAccent;
        break;
      case DropType.speedBoost:
        game.player.movementMaxSpeed = math.min(420.0, game.player.movementMaxSpeed + 60.0);
        game.player.movementAcceleration = math.min(900.0, game.player.movementAcceleration + 120.0);
        particleColor = Colors.orangeAccent;
        break;
      case DropType.shield:
        game.player.invulnerableTimer = 4.0;
        particleColor = Colors.cyanAccent;
        break;
    }

    // Explosion particles upon pickup
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [particleColor, Colors.white],
      count: 16,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 60.0,
      maxSpeed: 160.0,
    );

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Blinking effect in the last 3 seconds of lifespan
    if (lifespan < 3.0 && (DateTime.now().millisecondsSinceEpoch % 200 < 100)) {
      return;
    }

    canvas.translate(radius, radius);

    final pulseScale = 1.0 + math.sin(pulseTimer) * 0.15;
    Color mainColor;
    IconData icon;

    switch (type) {
      case DropType.sample:
        mainColor = Colors.amberAccent;
        icon = Icons.science;
        break;
      case DropType.health:
        mainColor = const Color(0xFF00E676);
        icon = Icons.favorite;
        break;
      case DropType.speedBoost:
        mainColor = Colors.orangeAccent;
        icon = Icons.bolt;
        break;
      case DropType.shield:
        mainColor = Colors.cyanAccent;
        icon = Icons.shield;
        break;
    }

    // Outer glowing ring
    final glowPaint = Paint()
      ..color = mainColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset.zero, radius * pulseScale, glowPaint);

    // Inner filled circle
    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.85, innerPaint);

    final borderPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset.zero, radius * 0.85, borderPaint);

    // Draw simple vector symbol inside
    final symbolPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    if (type == DropType.health) {
      // Cross / Heart
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 3, height: 10), symbolPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10, height: 3), symbolPaint);
    } else if (type == DropType.sample) {
      // Diamond
      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(5, 0)
        ..lineTo(0, 5)
        ..lineTo(-5, 0)
        ..close();
      canvas.drawPath(path, symbolPaint);
    } else if (type == DropType.speedBoost) {
      // Lightning bolt / Double chevron
      final path = Path()
        ..moveTo(1, -6)
        ..lineTo(-4, 0)
        ..lineTo(0, 0)
        ..lineTo(-1, 6)
        ..lineTo(4, 0)
        ..lineTo(0, 0)
        ..close();
      canvas.drawPath(path, symbolPaint);
    } else if (type == DropType.shield) {
      // Shield circle outline
      final sPaint = Paint()
        ..color = mainColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, 4.0, sPaint);
    }
  }
}
