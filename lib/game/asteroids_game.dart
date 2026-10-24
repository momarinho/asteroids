import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/constants.dart';
import 'components/player.dart';
import 'components/asteroid_field.dart';
import 'components/particle.dart';
import 'components/asteroid.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';
import 'components/starfield.dart';
import 'components/joystick.dart';
import 'components/drop.dart';
import 'weapons.dart';
import 'level_manager.dart';
import 'scientist.dart';
import 'package:asteroids/services/api_service.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

enum GameState {
  menu,
  settings,
  scienceIntro,
  scientistSelection,
  playing,
  gameOver,
  stageClear,
  shop,
  leaderboard,
}

class AsteroidsGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late final PlayerComponent player;
  AsteroidField? asteroidField;
  LevelManager? levelManager;
  late final GameJoystick joystick;

  FocusNode? gameFocusNode;

  final Set<LogicalKeyboardKey> keysPressed = {};

  bool get isMobile => !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  bool mobileShootPressed = false;
  bool mobileDashPressed = false;

  GameState state = GameState.scienceIntro;
  String activeMode = 'arcade'; // 'arcade', 'classic' or 'campaign'
  
  // Science Fair mode properties
  Scientist selectedScientist = Scientist.defaultScientist;
  static const double fairRoundDuration = 150.0; // 2 minutes and 30 seconds
  double timeRemaining = fairRoundDuration;
  bool missionSurvived = false;
  String? participantName;

  // Settings selections
  int selectedMovementPresetIndex = 1; // 1 = Balanced
  int selectedWeaponIndex = 0; // 0 = Blaster

  int score = 0;
  int lives = GameConstants.playerLives;
  int currentLevel = 1;
  int credits = 0;

  double shakeTimer = 0.0;
  double shakeDuration = 0.0;
  double shakeIntensity = 0.0;
  
  double lowHealthWarnTimer = 0.0;

  String? playerId;
  String? playerUsername;

  // Preset definitions
  final List<MovementPreset> movementPresets = [
    MovementPreset("Arcade Tight", 700.0, 220.0, 5.0),
    MovementPreset("Balanced", 650.0, 250.0, 4.0),
    MovementPreset("Floaty Classic", 450.0, 320.0, 2.0),
  ];

  final List<String> weaponOptions = [
    "Laser Fotônico",
    "Tiro Dispersor",
    "Laser Veloz",
    "Lança-Bombas",
  ];

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Lock camera resolution to 1280x720 (matching Pygame coordinates)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Setup FlameAudio asset folder configuration and silence native warning spam on Linux
    AudioLogger.logLevel = AudioLogLevel.none;
    FlameAudio.updatePrefix('assets/sounds/');
    try {
      FlameAudio.bgm.initialize();
    } catch (_) {}

    // Add StarfieldComponent first so it is rendered behind the player
    world.add(StarfieldComponent());

    // Add PlayerComponent (starts off-screen or invisible in menu)
    player = PlayerComponent(
      position: Vector2(1280 / 2, 720 / 2),
    );
    world.add(player);

    // Add Joystick for mobile/touch/mouse controls
    joystick = GameJoystick();
    add(joystick);

    // Load local player profile
    final profile = await ApiService.getLocalProfile();
    if (profile != null) {
      playerId = profile['id'];
      playerUsername = profile['username'];
    }

    // Initial state set for Science Fair
    changeState(GameState.scienceIntro);
  }

  void changeState(GameState newState) {
    state = newState;
    keysPressed.clear();

    if (newState == GameState.playing) {
      gameFocusNode?.requestFocus();
    } else {
      gameFocusNode?.unfocus();
    }

    // Clear active overlays first
    try {
      overlays.clear();
    } catch (_) {}

    switch (newState) {
      case GameState.scienceIntro:
        _safeAddOverlay('scienceIntro');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.scientistSelection:
        _safeAddOverlay('scientistSelection');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.menu:
        _safeAddOverlay('menu');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        // Cleanup game entities
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.settings:
        _safeAddOverlay('settings');
        break;
      case GameState.playing:
        _safeAddOverlay('hud');
        // Play loop background music
        try {
          FlameAudio.bgm.play('music.wav');
        } catch (_) {}
        gameFocusNode?.requestFocus();
        break;
      case GameState.shop:
        _safeAddOverlay('shop');
        break;
      case GameState.stageClear:
        _safeAddOverlay('stageClear');
        break;
      case GameState.gameOver:
        _safeAddOverlay('gameOver');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        break;
      case GameState.leaderboard:
        _safeAddOverlay('leaderboard');
        break;
    }
  }

  void _safeAddOverlay(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (state != GameState.playing) {
      this.keysPressed.clear();
      return KeyEventResult.ignored;
    }
    this.keysPressed.clear();
    this.keysPressed.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  void startGame() {
    score = 0;
    lives = GameConstants.playerLives;
    currentLevel = 1;
    credits = 0;

    // Remove any running level manager or asteroid field
    if (levelManager != null) {
      levelManager = null;
    }
    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }

    // Reset player states, stats, and unlocked weapons
    player.respawn(GameConstants.screenWidth / 2, GameConstants.screenHeight / 2);
    player.unlockedWeapons.clear();
    
    // Set starting weapon
    Weapon startingWeapon;
    if (activeMode == 'campaign') {
      player.unlockedWeapons['blaster'] = Blaster();
      if (selectedWeaponIndex == 1) {
        startingWeapon = SpreadShot();
      } else if (selectedWeaponIndex == 2) {
        startingWeapon = RapidFire();
      } else if (selectedWeaponIndex == 3) {
        startingWeapon = BombLauncher();
      } else {
        startingWeapon = player.unlockedWeapons['blaster']!;
      }
      final key = startingWeapon.name.toLowerCase().replaceAll(' ', '_');
      player.unlockedWeapons[key] = startingWeapon;
    } else {
      // Classic Mode: Unlock ALL weapons by default so they can switch at will!
      player.unlockedWeapons['blaster'] = Blaster();
      player.unlockedWeapons['spread_shot'] = SpreadShot();
      player.unlockedWeapons['rapid_fire'] = RapidFire();
      player.unlockedWeapons['bomb_launcher'] = BombLauncher();

      if (selectedWeaponIndex == 1) {
        startingWeapon = player.unlockedWeapons['spread_shot']!;
      } else if (selectedWeaponIndex == 2) {
        startingWeapon = player.unlockedWeapons['rapid_fire']!;
      } else if (selectedWeaponIndex == 3) {
        startingWeapon = player.unlockedWeapons['bomb_launcher']!;
      } else {
        startingWeapon = player.unlockedWeapons['blaster']!;
      }
    }
    player.setWeapon(startingWeapon);

    // Apply movement preset
    final preset = movementPresets[selectedMovementPresetIndex];
    player.movementAcceleration = preset.acceleration;
    player.movementMaxSpeed = preset.maxSpeed;
    player.movementFriction = preset.friction;

    // Setup Spawning Mode
    if (activeMode == 'campaign') {
      levelManager = LevelManager(this);
    } else {
      asteroidField = AsteroidField();
      world.add(asteroidField!);
    }

    changeState(GameState.playing);
  }

  void _removeAllAsteroidsAndProjectiles() {
    final childrenToRemove = world.children.where((child) =>
        child is AsteroidComponent ||
        child is BulletComponent ||
        child is BombComponent ||
        child is BombExplosionComponent ||
        child is ParticleComponent ||
        child is DropComponent);
    for (final child in List.from(childrenToRemove)) {
      child.removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (shakeTimer > 0) {
      shakeTimer = math.max(0.0, shakeTimer - dt);
    }

    // Science Fair 120-second countdown timer
    if (state == GameState.playing) {
      timeRemaining -= dt;
      if (timeRemaining <= 0) {
        timeRemaining = 0;
        completeMission(survived: true);
      }
    }

    // If campaign is active, run the level manager update
    if (state == GameState.playing && activeMode == 'campaign' && levelManager != null) {
      levelManager!.update(dt);
    }

    // Low health sound warning loop (every 3.5 seconds when on 1 life)
    if (state == GameState.playing && lives == 1) {
      lowHealthWarnTimer -= dt;
      if (lowHealthWarnTimer <= 0) {
        lowHealthWarnTimer = 3.5;
        playSfx('low_health.wav');
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (shakeTimer > 0) {
      final random = math.Random();
      final progress = shakeTimer / shakeDuration;
      final currentIntensity = shakeIntensity * progress;
      final dx = -currentIntensity + random.nextDouble() * currentIntensity * 2;
      final dy = -currentIntensity + random.nextDouble() * currentIntensity * 2;
      
      canvas.save();
      canvas.translate(dx, dy);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  final Map<String, int> _lastPlayedSfxTime = {};

  void playSfx(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minInterval = (name == 'shoot.wav') ? 60 : 75;
    final lastTime = _lastPlayedSfxTime[name] ?? 0;
    if (now - lastTime < minInterval) {
      return;
    }
    _lastPlayedSfxTime[name] = now;

    try {
      final player = await FlameAudio.play(name);
      player.onPlayerComplete.first.then((_) {
        try {
          player.dispose();
        } catch (_) {}
      }).catchError((_) {});
    } catch (_) {}
  }

  void triggerScreenShake({required double duration, required double intensity}) {
    shakeTimer = duration;
    shakeDuration = duration;
    shakeIntensity = intensity;
  }

  void spawnExplosionParticles({
    required Vector2 position,
    required List<Color> colorChoices,
    required int count,
    required double minSize,
    required double maxSize,
    required double minSpeed,
    required double maxSpeed,
  }) {
    final random = math.Random();
    for (var i = 0; i < count; i++) {
      final color = colorChoices[random.nextInt(colorChoices.length)];
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = minSpeed + random.nextDouble() * (maxSpeed - minSpeed);
      
      final velocity = Vector2(math.cos(angle), math.sin(angle))..scale(speed);
      final size = minSize + random.nextDouble() * (maxSize - minSize);
      final lifetime = 0.3 + random.nextDouble() * 0.5; // 0.3 to 0.8 seconds

      world.add(
        ParticleComponent(
          position: position,
          velocity: velocity,
          color: color,
          initialSize: size,
          initialLifetime: lifetime,
        ),
      );
    }
  }

  void buyItem(String itemId) {
    final isWeapon = const ['blaster', 'spread_shot', 'rapid_fire', 'bomb_launcher'].contains(itemId);

    if (isWeapon) {
      if (player.unlockedWeapons.containsKey(itemId)) {
        final weapon = player.unlockedWeapons[itemId]!;
        if (weapon.level >= weapon.maxLevel) return;

        final upgradeCost = 200 * weapon.level;
        if (credits < upgradeCost) return;

        credits -= upgradeCost;
        weapon.upgrade();
        playSfx('purchase.wav');
      } else {
        int cost = 0;
        Weapon newWeapon;
        if (itemId == 'spread_shot') {
          cost = 500;
          newWeapon = SpreadShot();
        } else if (itemId == 'rapid_fire') {
          cost = 600;
          newWeapon = RapidFire();
        } else if (itemId == 'bomb_launcher') {
          cost = 800;
          newWeapon = BombLauncher();
        } else {
          return;
        }

        if (credits < cost) return;
        credits -= cost;
        player.unlockedWeapons[itemId] = newWeapon;
        player.setWeapon(newWeapon);
        playSfx('purchase.wav');
      }
    } else if (itemId == 'speed_boost') {
      if (credits < 300) return;
      credits -= 300;
      player.movementAcceleration += 150.0;
      player.movementMaxSpeed += 50.0;
      playSfx('powerup.wav');
    } else if (itemId == 'extra_life') {
      if (lives >= 5) return;
      if (credits < 400) return;
      credits -= 400;
      lives += 1;
      playSfx('powerup.wav');
    }
  }

  void gameOver() {
    completeMission(survived: false);
  }

  void startFairGame(Scientist scientist) {
    selectedScientist = scientist;
    score = 0;
    lives = GameConstants.playerLives;
    currentLevel = 1;
    timeRemaining = fairRoundDuration;
    missionSurvived = false;

    if (levelManager != null) {
      levelManager = null;
    }
    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }

    _removeAllAsteroidsAndProjectiles();

    player.respawn(GameConstants.screenWidth / 2, GameConstants.screenHeight / 2);
    player.configureScientist(scientist);

    final preset = movementPresets[selectedMovementPresetIndex];
    player.movementAcceleration = preset.acceleration;
    player.movementMaxSpeed = preset.maxSpeed;
    player.movementFriction = preset.friction;

    asteroidField = AsteroidField();
    world.add(asteroidField!);

    changeState(GameState.playing);
  }

  void completeMission({required bool survived}) {
    if (state != GameState.playing) return;

    missionSurvived = survived;
    if (survived) {
      score += 500; // Survival bonus
      playSfx('powerup.wav');
    } else {
      playSfx('player_hit.wav');
    }

    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }
    _removeAllAsteroidsAndProjectiles();

    player.invulnerableTimer = 999999.0;
    player.velocity.setZero();

    changeState(GameState.gameOver);
  }
}

class MovementPreset {
  final String label;
  final double acceleration;
  final double maxSpeed;
  final double friction;

  MovementPreset(this.label, this.acceleration, this.maxSpeed, this.friction);
}
