import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/asteroid_field.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/scientist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Asteroid Lifecycle and Resource Protection Tests', () {
    test('AsteroidField does NOT spawn asteroids when state is not playing', () {
      final game = AsteroidsGame();
      final field = AsteroidField();
      game.world.add(field);

      game.state = GameState.gameOver;
      // Advance by 100 seconds
      field.update(100.0);

      final asteroids = game.world.children.whereType<AsteroidComponent>();
      expect(asteroids.isEmpty, isTrue);
    });

    test('AsteroidField caps active asteroids to preserve 60 FPS performance without stalling gameplay', () {
      final game = AsteroidsGame();
      final field = AsteroidField();
      game.world.add(field);
      game.state = GameState.playing;

      // Advance through the most extreme storm phase for a long time
      field.difficultyTimer = 175.0;
      for (int i = 0; i < 200; i++) {
        field.update(0.5);
      }

      final asteroids = game.world.children.whereType<AsteroidComponent>();
      expect(asteroids.length <= 38, isTrue);
    });

    test('changeState to non-playing states cleans up all asteroids and spawners', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(1280 / 2, 720 / 2));
      final mae = Scientist.scientists.first;
      game.startFairGame(mae);

      expect(game.state, GameState.playing);
      expect(game.asteroidField, isNotNull);

      // Add a couple asteroids
      game.world.add(AsteroidComponent(radius: 20, position: Vector2.zero(), velocity: Vector2.zero()));
      expect(game.world.children.whereType<AsteroidComponent>().isNotEmpty, isTrue);

      // Transition to gameOver or scienceIntro
      game.changeState(GameState.gameOver);

      expect(game.world.children.whereType<AsteroidComponent>().isEmpty, isTrue);
      expect(game.world.children.whereType<AsteroidField>().isEmpty, isTrue);
      expect(game.asteroidField, isNull);
    });
  });
}
