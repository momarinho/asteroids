import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';

class BulletComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  double lifeTimer;

  BulletComponent({
    required Vector2 position,
    required this.radius,
    required this.velocity,
    required this.lifeTimer,
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
    position += velocity * dt;
    wrapAround();
    
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
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
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AsteroidComponent) {
      game.playSfx('asteroid_split.wav');
      game.score += (other.radius * 5).toInt();
      other.split();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.lineWidth;

    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
