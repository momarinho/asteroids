import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/asteroids_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asteroid Inverted Scoring Tests', () {
    test('Small asteroids score 300 pts, medium score 150 pts, large score 50 pts', () {
      final smallAsteroid = AsteroidComponent(
        radius: 20.0,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
      );
      final mediumAsteroid = AsteroidComponent(
        radius: 35.0,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
      );
      final largeAsteroid = AsteroidComponent(
        radius: 60.0,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
      );

      expect(smallAsteroid.scoreValue, equals(300), reason: 'Small asteroids must reward highest points (+300)');
      expect(mediumAsteroid.scoreValue, equals(150), reason: 'Medium asteroids reward intermediate points (+150)');
      expect(largeAsteroid.scoreValue, equals(50), reason: 'Large asteroids reward opening points (+50)');
    });
  });

  group('Weapon Balance and Evolution Tests', () {
    test('All 4 weapons start at level 1 and upgrade properly to level 3', () {
      final blaster = Blaster();
      final spread = SpreadShot();
      final rapid = RapidFire();
      final bomb = BombLauncher();

      // Check initial level 1 stats
      expect(blaster.level, equals(1));
      expect(blaster.damage, equals(55.0));
      expect(blaster.cooldown, equals(0.26));

      expect(spread.level, equals(1));
      expect(spread.damage, equals(26.0));
      expect(spread.cooldown, equals(0.30));
      expect(spread.recoil, equals(16.0)); // Reduced recoil

      expect(rapid.level, equals(1));
      expect(rapid.cooldown, equals(0.11));
      expect(rapid.damage, equals(16.0));

      expect(bomb.level, equals(1));
      expect(bomb.cooldown, equals(0.65)); // Balanced from 1.45s
      expect(bomb.recoil, equals(28.0)); // Balanced from 135.0

      // Test Upgrade to Level 2
      expect(blaster.upgrade(), isTrue);
      expect(spread.upgrade(), isTrue);
      expect(rapid.upgrade(), isTrue);
      expect(bomb.upgrade(), isTrue);

      expect(blaster.level, equals(2));
      expect(blaster.damage, equals(70.0));
      expect(spread.level, equals(2));
      expect(spread.damage, equals(32.0));
      expect(rapid.level, equals(2));
      expect(rapid.damage, equals(20.0));
      expect(bomb.level, equals(2));
      expect(bomb.damage, equals(165.0));

      // Test Upgrade to Level 3 (Max)
      expect(blaster.upgrade(), isTrue);
      expect(spread.upgrade(), isTrue);
      expect(rapid.upgrade(), isTrue);
      expect(bomb.upgrade(), isTrue);

      expect(blaster.level, equals(3));
      expect(spread.level, equals(3));
      expect(rapid.level, equals(3));
      expect(bomb.level, equals(3));

      // Cannot upgrade beyond max
      expect(blaster.upgrade(), isFalse);
    });

    test('AsteroidsGame initializes in-run evolution level and halftime recharge', () {
      final game = AsteroidsGame();
      expect(game.fairRunEvolutionLevel, equals(1));
      expect(game.halfTimeRechargeTriggered, isFalse);
    });
  });
}
