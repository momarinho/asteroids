import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;
  final double duration;
  double timer = 0.0;
  final Vector2 velocity;

  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 14.0,
    this.duration = 0.8,
    Vector2? velocity,
  }) : velocity = velocity ?? Vector2(0, -50) {
    this.position = position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    timer += dt;
    if (timer >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = timer / duration;
    final alpha = (255 * (1.0 - progress)).clamp(0, 255).toInt();
    if (alpha <= 0) return;

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color.withAlpha(alpha),
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(alpha),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
          Shadow(
            color: color.withAlpha((alpha * 0.5).toInt()),
            blurRadius: 8,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}
