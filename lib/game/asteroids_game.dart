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
import 'components/floating_text.dart';
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

  // Feature 1: One-time Special Ability per run
  bool specialAvailable = true;

  // Feature 2: Combo System
  int comboCount = 0;
  double comboTimer = 0.0;
  static const double comboWindow = 2.0;

  // Feature 3: Target Leader Record
  String? topLeaderName;
  int topLeaderScore = 0;
  bool topRecordBeaten = false;

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
      await FlameAudio.bgm.initialize();
    } catch (_) {}

    initSfxPlayers();

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
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65);
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.scientistSelection:
        _safeAddOverlay('scientistSelection');
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65);
          }
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
          FlameAudio.bgm.play('music.wav', volume: 0.85);
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
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.6);
          }
        } catch (_) {}
        break;
    }
  }

  void _safeAddOverlay(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  bool isGamePaused = false;

  double get currentComboWindow {
    switch (player.weapon.name) {
      case 'Laser Veloz':
        return 2.0;
      case 'Tiro Dispersor':
        return 2.3;
      case 'Laser Fotônico':
        return 2.8;
      case 'Lança-Bombas':
        return 3.8;
      default:
        return 2.5;
    }
  }

  void togglePause() {
    if (state != GameState.playing) return;
    if (isGamePaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void pauseGame() {
    if (state != GameState.playing || isGamePaused) return;
    isGamePaused = true;
    keysPressed.clear();
    pauseEngine();
    _safeAddOverlay('pause');
  }

  void resumeGame() {
    if (!isGamePaused) return;
    isGamePaused = false;
    keysPressed.clear();
    overlays.remove('pause');
    resumeEngine();
    gameFocusNode?.requestFocus();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (state != GameState.playing) {
      this.keysPressed.clear();
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        togglePause();
        return KeyEventResult.handled;
      }
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
    specialAvailable = true;
    comboCount = 0;
    comboTimer = 0.0;
    topRecordBeaten = false;
    fetchTopLeaderRecord();

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

    // Update combo timer
    if (comboTimer > 0) {
      comboTimer = math.max(0.0, comboTimer - dt);
      if (comboTimer <= 0) {
        comboCount = 0;
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
  final List<AudioPlayer> _sfxPlayers = [];
  List<AudioPlayer> get sfxPlayers => _sfxPlayers;
  int _currentSfxIndex = 0;

  void initSfxPlayers() {
    for (int i = 0; i < 3; i++) {
      final p = AudioPlayer();
      p.audioCache.prefix = 'assets/sounds/';
      _sfxPlayers.add(p);
    }
  }

  void playSfx(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minInterval = (name == 'shoot.wav') ? 50 : 65;
    final lastTime = _lastPlayedSfxTime[name] ?? 0;
    if (now - lastTime < minInterval) {
      return;
    }
    _lastPlayedSfxTime[name] = now;

    if (_sfxPlayers.isEmpty) return;

    _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPlayers.length;
    final player = _sfxPlayers[_currentSfxIndex];

    try {
      await player.play(AssetSource(name), volume: 1.0);
    } catch (_) {}
  }

  @override
  void onRemove() {
    for (final p in _sfxPlayers) {
      try {
        p.dispose();
      } catch (_) {}
    }
    _sfxPlayers.clear();
    try {
      FlameAudio.bgm.dispose();
    } catch (_) {}
    super.onRemove();
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

  void spawnFloatingText(Vector2 position, String text, {Color color = Colors.white, double fontSize = 14.0, Vector2? velocity}) {
    world.add(
      FloatingTextComponent(
        position: position.clone(),
        text: text,
        color: color,
        fontSize: fontSize,
        velocity: velocity,
      ),
    );
  }

  void onAsteroidDestroyed(Vector2 pos, int basePoints) {
    if (state != GameState.playing) return;

    comboTimer = currentComboWindow;
    comboCount++;

    int earned = basePoints;
    if (comboCount >= 2) {
      final multiplier = 1.0 + (comboCount - 1) * 0.15;
      earned = (basePoints * multiplier).toInt();
      score += earned;

      spawnFloatingText(
        pos,
        '+$earned',
        color: comboCount >= 4 ? Colors.amberAccent : Colors.cyanAccent,
        fontSize: comboCount >= 4 ? 17.0 : 15.0,
      );

      final comboColor = comboCount >= 5
          ? Colors.redAccent
          : (comboCount >= 3 ? Colors.orangeAccent : Colors.yellowAccent);
      spawnFloatingText(
        pos + Vector2(0, -18),
        'COMBO x$comboCount! 🔥',
        color: comboColor,
        fontSize: 13.0,
      );
    } else {
      score += basePoints;
      spawnFloatingText(pos, '+$basePoints', color: Colors.white, fontSize: 13.5);
    }

    // Check if player just beat top leader score
    if (!topRecordBeaten && topLeaderScore > 0 && score > topLeaderScore) {
      topRecordBeaten = true;
      playSfx('powerup.wav');
      triggerScreenShake(duration: 0.5, intensity: 10.0);
      spawnFloatingText(
        player.position + Vector2(0, -40),
        '👑 NOVO RECORDE DA FEIRA!',
        color: Colors.amberAccent,
        fontSize: 20.0,
        velocity: Vector2(0, -40),
      );
    }
  }

  void onMultiKill(int count, Vector2 pos) {
    if (state != GameState.playing) return;

    int bonus = 0;
    String label = '';
    Color color = Colors.amberAccent;

    if (count == 2) {
      bonus = 150;
      label = '💥 DUPLO! +$bonus';
      color = Colors.amberAccent;
    } else if (count == 3) {
      bonus = 300;
      label = '💥 TRIPLO! +$bonus';
      color = Colors.orangeAccent;
    } else {
      bonus = 500;
      label = '💥 MULTI-KILL x$count! +$bonus';
      color = Colors.redAccent;
    }

    score += bonus;
    comboCount += (count - 1);
    comboTimer = currentComboWindow; // Fully recharge the combo bar!
    playSfx('powerup.wav');

    spawnFloatingText(
      pos + Vector2(0, -32),
      label,
      color: color,
      fontSize: 16.0,
      velocity: Vector2(0, -35),
    );
  }

  Future<void> fetchTopLeaderRecord() async {
    try {
      final list = await ApiService.getFairLeaderboard(period: 'all', limit: 1);
      if (list.isNotEmpty) {
        final top = list.first;
        topLeaderName = (top['username'] ?? 'Líder').toString().toUpperCase();
        topLeaderScore = (top['score'] ?? 0) as int;
      } else {
        topLeaderName = 'PIONEIRO';
        topLeaderScore = 10000;
      }
    } catch (_) {}
  }

  void triggerSpecial() {
    if (!specialAvailable || state != GameState.playing) return;
    specialAvailable = false;
    playSfx('powerup.wav');
    triggerScreenShake(duration: 0.6, intensity: 16.0);

    // Visual shockwave particles
    spawnExplosionParticles(
      position: player.position,
      colorChoices: [
        selectedScientist.primaryColor,
        selectedScientist.accentColor,
        Colors.white,
        Colors.amberAccent,
      ],
      count: 45,
      minSize: 3.0,
      maxSize: 6.0,
      minSpeed: 100.0,
      maxSpeed: 350.0,
    );

    // Floating text indicator
    spawnFloatingText(
      player.position + Vector2(0, -35),
      '★ ESPECIAL ATIVADO! ★',
      color: selectedScientist.primaryColor,
      fontSize: 18,
    );

    switch (selectedScientist.id) {
      case 'mae_jemison':
        // Gravidade Zero: Empurra todos os meteoros para longe e concede 3.5s de invulnerabilidade
        player.invulnerableTimer = 3.5;
        final asteroids = List<AsteroidComponent>.from(world.children.whereType<AsteroidComponent>());
        for (final ast in asteroids) {
          final diff = ast.position - player.position;
          final dist = diff.length;
          final pushDir = dist > 0 ? diff.normalized() : Vector2(1, 0);
          ast.velocity.setFrom(pushDir * 350.0);
          if (dist < 140.0) {
            final destroyed = ast.takeDamage(50.0, ast.position);
            if (destroyed) {
              onAsteroidDestroyed(ast.position, (ast.radius * 5).toInt());
            }
          }
        }
        break;

      case 'margaret_hamilton':
        // Overclock Quântico: 16 disparos de laser em círculo 360° ao redor da nave + 3.0s de escudo
        player.invulnerableTimer = 3.0;
        final step = (2 * math.pi) / 16;
        for (int i = 0; i < 16; i++) {
          final ang = i * step;
          final dir = Vector2(math.cos(ang), math.sin(ang));
          final bullet = BulletComponent(
            position: player.position + dir * player.radius,
            radius: 3.5,
            velocity: dir * 550.0,
            lifeTimer: 0.8,
            damage: 25.0,
          );
          world.add(bullet);
        }
        break;

      case 'nancy_roman':
        // Varredura do Hubble: Destrói meteoros na linha de visada frontal e traseira + 3.0s de escudo
        player.invulnerableTimer = 3.0;
        final fwd = player.forward.normalized();
        final asteroidsNancy = List<AsteroidComponent>.from(world.children.whereType<AsteroidComponent>());
        for (final ast in asteroidsNancy) {
          final toAst = ast.position - player.position;
          final proj = toAst.dot(fwd);
          // Distance from line: length of projection perpendicular
          final perpDist = (toAst - (fwd * proj)).length;
          if (perpDist <= ast.radius + 45.0) {
            final destroyed = ast.takeDamage(100.0, ast.position);
            if (destroyed) {
              onAsteroidDestroyed(ast.position, (ast.radius * 5).toInt());
            }
          }
        }
        break;

      case 'peggy_whitson':
        // Pulso de Plasma Orbital: Super explosão de 160px de raio ao redor da nave + 3.0s de escudo
        player.invulnerableTimer = 3.0;
        world.add(
          BombExplosionComponent(
            position: player.position.clone(),
            maxRadius: 160.0,
            damage: 150.0,
          ),
        );
        break;
    }
  }

  void startFairGame(Scientist scientist) {
    selectedScientist = scientist;
    score = 0;
    lives = GameConstants.playerLives;
    currentLevel = 1;
    timeRemaining = fairRoundDuration;
    missionSurvived = false;
    specialAvailable = true;
    comboCount = 0;
    comboTimer = 0.0;
    topRecordBeaten = false;
    fetchTopLeaderRecord();

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
