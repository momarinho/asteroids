import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';

class AsteroidField extends Component with HasGameReference<AsteroidsGame> {
  final String mode;
  double spawnTimer = 0.0;
  double difficultyTimer = 0.0;
  double spawnRateMultiplier = 1.0;
  double speedMultiplier = 1.0;

  AsteroidField({this.mode = 'classic'});

  @override
  void update(double dt) {
    super.update(dt);
    
    if (mode == 'campaign') {
      return;
    }

    spawnTimer += dt;
    difficultyTimer += dt;

    spawnRateMultiplier = math.min(
      GameConstants.asteroidMaxSpawnRateMultiplier,
      1.0 + difficultyTimer * GameConstants.asteroidSpawnRateGrowth,
    );
    speedMultiplier = math.min(
      GameConstants.asteroidMaxSpeedMultiplier,
      1.0 + difficultyTimer * GameConstants.asteroidSpeedGrowth,
    );

    final spawnInterval = GameConstants.asteroidSpawnRateSeconds / spawnRateMultiplier;
    if (spawnTimer > spawnInterval) {
      spawnTimer = 0.0;
      _spawnAsteroid();
    }
  }

  void _spawnAsteroid() {
    final random = math.Random();
    final screenWidth = GameConstants.screenWidth;
    final screenHeight = GameConstants.screenHeight;
    final maxRadius = GameConstants.asteroidMaxRadius;

    // Pick a random edge: 0 = Left, 1 = Right, 2 = Top, 3 = Bottom
    final edgeIndex = random.nextInt(4);
    Vector2 direction;
    Vector2 position;

    final t = random.nextDouble(); // relative position along the edge (0 to 1)

    switch (edgeIndex) {
      case 0: // Left edge spawning, moving right
        direction = Vector2(1, 0);
        position = Vector2(-maxRadius, t * screenHeight);
        break;
      case 1: // Right edge spawning, moving left
        direction = Vector2(-1, 0);
        position = Vector2(screenWidth + maxRadius, t * screenHeight);
        break;
      case 2: // Top edge spawning, moving down
        direction = Vector2(0, 1);
        position = Vector2(t * screenWidth, -maxRadius);
        break;
      case 3: // Bottom edge spawning, moving up
      default:
        direction = Vector2(0, -1);
        position = Vector2(t * screenWidth, screenHeight + maxRadius);
        break;
    }

    // Speed: 40 to 100, scaled by speedMultiplier
    final speed = (40.0 + random.nextDouble() * 60.0) * speedMultiplier;
    
    // Rotate direction randomly by -30 to +30 degrees
    final deviationAngle = (-30.0 + random.nextDouble() * 60.0) * math.pi / 180.0;
    final velocity = direction.clone()..rotate(deviationAngle);
    velocity.scale(speed);

    // Kind/Size: 1 to 3
    final kind = random.nextInt(GameConstants.asteroidKinds) + 1;
    final radius = GameConstants.asteroidMinRadius * kind;

    final asteroid = AsteroidComponent(
      radius: radius,
      position: position,
      velocity: velocity,
    );
    game.world.add(asteroid);
  }

  String dangerLevel() {
    if (spawnRateMultiplier >= 2.0 || speedMultiplier >= 1.7) {
      return "High";
    }
    if (spawnRateMultiplier >= 1.5 || speedMultiplier >= 1.35) {
      return "Medium";
    }
    return "Low";
  }
}
