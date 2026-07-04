class GameConstants {
  static const double lineWidth = 2.0;
  static const double screenWidth = 1280.0;
  static const double screenHeight = 720.0;

  static const double playerRadius = 20.0;
  static const double playerSpeed = 200.0;
  static const double playerAcceleration = 400.0;
  static const double playerMaxSpeed = 300.0;
  static const double playerFriction = 1.5;
  static const double playerShootSpeed = 500.0;
  static const double playerShootCooldownSeconds = 0.3;
  static const double playerTurnSpeed = 300.0; // degrees per second
  static const double playerInvulnerableSeconds = 1.5;
  static const int playerLives = 3;
  static const double playerDashSpeed = 700.0;
  static const double playerDashDurationSeconds = 0.15;
  static const double playerDashCooldownSeconds = 2.0;

  static const double asteroidMinRadius = 20.0;
  static const int asteroidKinds = 3;
  static const double asteroidSpawnRateSeconds = 1.2;
  static const double asteroidMaxRadius = asteroidMinRadius * asteroidKinds;
  
  static const double asteroidSpawnRateGrowth = 0.02;
  static const double asteroidSpeedGrowth = 0.03;
  static const double asteroidMaxSpawnRateMultiplier = 1.5;
  static const double asteroidMaxSpeedMultiplier = 2.0;

  static const double shotRadius = 5.0;
  static const double shotLifetimeSeconds = 1.2;
}
