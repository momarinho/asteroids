import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/glow.dart';

class ParticleComponent extends PositionComponent {
  final Vector2 velocity;
  final Color color;
  final double initialSize;
  final double initialLifetime;
  double lifetime;

  ParticleComponent({
    required Vector2 position,
    required this.velocity,
    required this.color,
    required this.initialSize,
    required this.initialLifetime,
  }) : lifetime = initialLifetime {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(initialSize * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final ratio = (lifetime / initialLifetime).clamp(0.0, 1.0);
    final currentRadius = math.max(1.0, initialSize * ratio);

    // Brilho aditivo: as faíscas "queimam" mais forte no começo e esvaem suave.
    Glow.spark(canvas, Offset.zero, currentRadius, color, math.sqrt(ratio));
  }
}
