import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/components/comet.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/game/asteroids_game.dart';

void main() {
  group('Celestial Event - Comet Halley Tests', () {
    test('DropType enum contains cometDust with highest score value', () {
      expect(DropType.values.contains(DropType.cometDust), isTrue);
    });

    test('CometComponent has small hitbox and sturdy HP', () {
      final comet = CometComponent(
        position: Vector2(100, 100),
        velocity: Vector2(150, 80),
      );

      // Hitbox is small (radius 16.0)
      expect(comet.radius, equals(16.0));
      // Sturdy HP (140.0) higher than a large asteroid (90.0)
      expect(comet.maxHp, equals(140.0));
      expect(comet.hp, equals(140.0));
      expect(comet.wrapsLeft, equals(3));
    });

    test('AsteroidsGame has comet tracking fields configured', () {
      final game = AsteroidsGame();
      expect(game.cometWarningTriggered, isFalse);
      expect(game.cometSpawned, isFalse);
      expect(game.cometAlertTimer, equals(0.0));
      expect(game.cometAlertMessage, isNull);
    });
  });
}
