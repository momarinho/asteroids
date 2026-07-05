import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'components/asteroid.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';

class LevelManager {
  final AsteroidsGame game;
  int currentLevel = 1;
  String state = "playing"; // "playing", "stage_clear"
  
  int asteroidsRemainingToSpawn = 0;
  double speedMultiplier = 1.0;
  int waveSize = 3;
  int totalAsteroids = 3;
  int bonusCredits = 0;
  int stageClearBonus = 0;
  int livesBonus = 0;

  LevelManager(this.game) {
    startLevel(1);
  }

  void startLevel(int level) {
    currentLevel = level;
    game.currentLevel = level;
    state = "playing";

    // Clean up active asteroids, bullets, bombs, and explosions
    cleanUp();

    // Procedural difficulty scaling
    totalAsteroids = 3 + (level - 1) * 2;
    asteroidsRemainingToSpawn = totalAsteroids;

    // Wave size starts at 3, scaling by 1 every 3 levels, capped at 6
    waveSize = math.min(6, 3 + (level - 1) ~/ 3);

    // Baseline speed starts at 1.0 and increases by 0.12 per level, capped at 2.5
    speedMultiplier = math.min(2.5, 1.0 + (level - 1) * 0.12);

    // Spawn the initial wave
    spawnWave();
  }

  void cleanUp() {
    final asteroids = game.world.children.whereType<AsteroidComponent>();
    for (final asteroid in List<AsteroidComponent>.from(asteroids)) {
      asteroid.removeFromParent();
    }
    
    final bullets = game.world.children.whereType<BulletComponent>();
    for (final bullet in List<BulletComponent>.from(bullets)) {
      bullet.removeFromParent();
    }

    final bombs = game.world.children.whereType<BombComponent>();
    for (final bomb in List<BombComponent>.from(bombs)) {
      bomb.removeFromParent();
    }

    final explosions = game.world.children.whereType<BombExplosionComponent>();
    for (final explosion in List<BombExplosionComponent>.from(explosions)) {
      explosion.removeFromParent();
    }
  }

  void spawnWave() {
    final random = math.Random();
    final toSpawn = math.min(waveSize, asteroidsRemainingToSpawn);
    asteroidsRemainingToSpawn -= toSpawn;

    // Select asteroid kinds based on level
    List<int> kinds;
    if (currentLevel == 1) {
      kinds = [1, 2];
    } else if (currentLevel == 2) {
      kinds = [1, 2, 3];
    } else if (currentLevel == 3) {
      kinds = [2, 3];
    } else if (currentLevel == 4) {
      kinds = [2, 3, 4];
    } else {
      final maxKind = math.min<int>(5, 3 + (currentLevel - 5) ~/ 2);
      kinds = List.generate(
        maxKind - math.max<int>(1, maxKind - 2) + 1,
        (i) => math.max<int>(1, maxKind - 2) + i,
      );
    }

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;
    final maxRadius = GameConstants.asteroidMaxRadius;

    for (var i = 0; i < toSpawn; i++) {
      // Pick a random edge: 0 = Left, 1 = Right, 2 = Top, 3 = Bottom
      final edgeIndex = random.nextInt(4);
      Vector2 direction;
      Vector2 position;
      final t = random.nextDouble();

      switch (edgeIndex) {
        case 0:
          direction = Vector2(1, 0);
          position = Vector2(-maxRadius, t * screenHeight);
          break;
        case 1:
          direction = Vector2(-1, 0);
          position = Vector2(screenWidth + maxRadius, t * screenHeight);
          break;
        case 2:
          direction = Vector2(0, 1);
          position = Vector2(t * screenWidth, -maxRadius);
          break;
        case 3:
        default:
          direction = Vector2(0, -1);
          position = Vector2(t * screenWidth, screenHeight + maxRadius);
          break;
      }

      final speed = (40.0 + random.nextDouble() * 60.0) * speedMultiplier;
      final deviationAngle = (-30.0 + random.nextDouble() * 60.0) * math.pi / 180.0;
      final velocity = direction.clone()..rotate(deviationAngle);
      velocity.scale(speed);

      final kind = kinds[random.nextInt(kinds.length)];
      final radius = GameConstants.asteroidMinRadius * kind;

      final asteroid = AsteroidComponent(
        radius: radius,
        position: position,
        velocity: velocity,
      );
      game.world.add(asteroid);
    }
  }

  void update(double dt) {
    if (state == "playing") {
      final asteroidsCount = game.world.children.whereType<AsteroidComponent>().length;
      if (asteroidsCount == 0) {
        if (asteroidsRemainingToSpawn > 0) {
          spawnWave();
        } else {
          triggerStageClear();
        }
      }
    }
  }

  void triggerStageClear() {
    state = "stage_clear";
    stageClearBonus = currentLevel * 100;
    livesBonus = game.lives * 50;
    bonusCredits = stageClearBonus + livesBonus;
    game.credits += bonusCredits;
    
    // Stop playing loop and show clear screen
    game.changeState(GameState.stageClear);
  }

  void advanceLevel() {
    startLevel(currentLevel + 1);
    game.changeState(GameState.playing);
  }
}
