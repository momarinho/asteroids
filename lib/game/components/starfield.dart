import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/constants.dart';

class Star {
  Vector2 position;
  final int layer;

  Star({required this.position, required this.layer});
}

class StarfieldComponent extends Component with HasGameReference<AsteroidsGame> {
  final int numStars;
  final List<Star> stars = [];
  final Vector2 drift = Vector2(-8.0, -4.0);

  StarfieldComponent({this.numStars = 80});

  @override
  void onMount() {
    super.onMount();
    _initializeStars();
  }

  void _initializeStars() {
    final random = math.Random();
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    stars.clear();
    for (var i = 0; i < numStars; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final layer = random.nextInt(3) + 1; // 1, 2, or 3
      stars.add(
        Star(
          position: Vector2(x, y),
          layer: layer,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (stars.isEmpty) return;

    final playerVelocity = game.player.velocity;
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    for (final star in stars) {
      final multiplier = star.layer * 0.05;
      
      // Star position translation: base drift plus opposite player velocity
      star.position.x += (drift.x - playerVelocity.x * multiplier) * dt;
      star.position.y += (drift.y - playerVelocity.y * multiplier) * dt;

      // Wrap around edges
      if (star.position.x < 0) {
        star.position.x = width;
      } else if (star.position.x > width) {
        star.position.x = 0;
      }

      if (star.position.y < 0) {
        star.position.y = height;
      } else if (star.position.y > height) {
        star.position.y = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final star in stars) {
      Color color;
      double size;

      switch (star.layer) {
        case 1:
          color = const Color(0xFF4B4B4B); // (75, 75, 75)
          size = 1.0;
          break;
        case 2:
          color = const Color(0xFF878787); // (135, 135, 135)
          size = 1.5;
          break;
        case 3:
        default:
          color = const Color(0xFFDCDCDC); // (220, 220, 220)
          size = 2.0;
          break;
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(star.position.x, star.position.y), size, paint);
    }
  }
}
