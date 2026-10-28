import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';
import 'drop.dart';
import 'particle.dart';

class CometComponent extends AsteroidComponent {
  int wrapsLeft = 4; // Allows up to 4 screen crossings so players have ample time to engage
  double tailParticleTimer = 0.0;
  double auraTimer = 0.0;
  bool isEscaping = false;

  CometComponent({
    required super.position,
    required super.velocity,
  }) : super(radius: 25.0) { // Increased to 25px (medium size) for a fair and reachable hitbox
    maxHp = 140.0; // Sturdy HP
    hp = maxHp;
  }

  @override
  void update(double dt) {
    if (game.state != GameState.playing) return;

    auraTimer += dt * 6.0;
    tailParticleTimer += dt;

    // Emit brilliant cyan and golden stardust particles along the tail
    if (tailParticleTimer >= 0.025) {
      tailParticleTimer = 0.0;
      final random = math.Random();
      final speed = velocity.length;
      final dir = speed > 0 ? velocity.normalized() : Vector2(1, 0);

      // Tail emits backwards from velocity
      final offsetDist = radius * 0.75;
      final spread = (random.nextDouble() - 0.5) * 8.0;
      final normal = Vector2(-dir.y, dir.x);
      final emitPos = position - (dir * offsetDist) + (normal * spread);

      // Particle velocity has a small backwards kick with subtle expansion
      final particleVel = (-dir * (speed * 0.22)) + (normal * (random.nextDouble() - 0.5) * 40.0);

      final colorChoices = [
        const Color(0xFF00E5FF), // Electric Cyan
        Colors.cyanAccent,
        Colors.white,
        Colors.amberAccent,
        const Color(0xFF80D8FF),
      ];
      final color = colorChoices[random.nextInt(colorChoices.length)];

      game.world.add(
        ParticleComponent(
          position: emitPos,
          velocity: particleVel,
          color: color,
          initialSize: 2.2 + random.nextDouble() * 2.8,
          initialLifetime: 0.35 + random.nextDouble() * 0.25,
        ),
      );
    }

    super.update(dt);
  }

  @override
  void wrapAround() {
    final sizeX = GameConstants.screenWidth;
    final sizeY = GameConstants.screenHeight;

    bool didWrap = false;
    if (position.x < -radius * 2) {
      if (wrapsLeft > 0) {
        position.x = sizeX + radius;
        didWrap = true;
      } else {
        _escape();
      }
    } else if (position.x > sizeX + radius * 2) {
      if (wrapsLeft > 0) {
        position.x = -radius;
        didWrap = true;
      } else {
        _escape();
      }
    }

    if (position.y < -radius * 2) {
      if (wrapsLeft > 0) {
        position.y = sizeY + radius;
        didWrap = true;
      } else {
        _escape();
      }
    } else if (position.y > sizeY + radius * 2) {
      if (wrapsLeft > 0) {
        position.y = -radius;
        didWrap = true;
      } else {
        _escape();
      }
    }

    if (didWrap) {
      wrapsLeft--;
      if (wrapsLeft == 1) {
        game.spawnFloatingText(
          Vector2(GameConstants.screenWidth / 2, 180),
          '⚠️ ÚLTIMA PASSAGEM DO COMETA!',
          color: Colors.amberAccent,
          fontSize: 16.0,
        );
      }
    }
  }

  void _escape() {
    if (isEscaping) return;
    isEscaping = true;
    game.spawnFloatingText(
      Vector2(GameConstants.screenWidth / 2, 280),
      '☄️ O COMETA PASSOU PELO SETOR!',
      color: Colors.cyanAccent,
      fontSize: 16.0,
    );
    removeFromParent();
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    // Glowing ice crystal sparks on hit
    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [Colors.cyanAccent, Colors.white, Colors.lightBlueAccent],
      count: 6,
      minSize: 2.0,
      maxSize: 3.8,
      minSpeed: 40.0,
      maxSpeed: 120.0,
    );

    if (hp <= 0) {
      split();
      return true; // Destroyed
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: Colors.cyanAccent,
        fontSize: 12.0,
      );
      return false; // Still alive
    }
  }

  @override
  void split() {
    removeFromParent();

    // Epic celebration sound & screen shake
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 0.45, intensity: 14.0);

    // Stardust explosion
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [
        const Color(0xFF00E5FF),
        Colors.cyanAccent,
        Colors.amberAccent,
        Colors.white,
      ],
      count: 45,
      minSize: 3.0,
      maxSize: 6.5,
      minSpeed: 70.0,
      maxSpeed: 280.0,
    );

    // Guaranteed Legendary Drop
    game.world.add(
      DropComponent(
        position: position.clone(),
        type: DropType.cometDust,
        initialVelocity: Vector2.zero(),
      ),
    );

    // Celebration indicator
    game.spawnFloatingText(
      position + Vector2(0, -35),
      '☄️ COMETA HALLEY INTERCEPTADO!',
      color: const Color(0xFF00E5FF),
      fontSize: 18.0,
      velocity: Vector2(0, -40),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final isFlashing = hitFlashTimer > 0;
    final pulse = (math.sin(auraTimer) + 1.0) / 2.0;

    // 1. Outer glowing cosmic aura (pulsing neon ring + soft additive bloom)
    final auraColor = isFlashing ? Colors.redAccent : const Color(0xFF00E5FF);
    Glow.orb(canvas, Offset.zero, radius * 0.9, auraColor, intensity: 0.8 + pulse * 0.5);
    Glow.strokeCircle(
      canvas,
      Offset.zero,
      radius + 3.0 + pulse * 2.5,
      auraColor,
      width: 2.0 + pulse * 1.5,
      intensity: 1.2,
    );

    // 2. Faceted crystalline ice nucleus
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

    // Fill inner nucleus
    final nucleusPaint = Paint()
      ..color = isFlashing ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, nucleusPaint);

    // Outline border
    Glow.heroStrokePath(
      canvas,
      path,
      isFlashing ? Colors.white : const Color(0xFF00E5FF),
      width: 2.2,
      intensity: 1.3,
    );

    // 3. Mini Sci-Fi HP Bar floating directly above the comet
    final barWidth = 42.0;
    final barHeight = 4.5;
    final barY = -radius - 14.0;

    // HP background
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, barY), width: barWidth + 2, height: barHeight + 2),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // HP border
    final barBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, barY), width: barWidth + 2, height: barHeight + 2),
        const Radius.circular(2),
      ),
      barBorderPaint,
    );

    // HP fill
    final fillRatio = (hp / maxHp).clamp(0.0, 1.0);
    final fillPaint = Paint()
      ..color = fillRatio > 0.4 ? const Color(0xFF00E5FF) : Colors.amberAccent
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, barY - barHeight / 2, barWidth * fillRatio, barHeight),
        const Radius.circular(2),
      ),
      fillPaint,
    );
  }
}
