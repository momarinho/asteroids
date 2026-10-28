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
import 'components/comet.dart';
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
  static const double fairRoundDuration = 180.0; // 3 minutes
  double timeRemaining = fairRoundDuration;
  bool missionSurvived = false;
  String? participantName;

  // Feature 1: One-time Special Ability per run
  bool specialAvailable = true;

  // Feature 2: Scientific Samples Collected
  int samplesCollected = 0;

  // Feature 3: Target Leader Record
  String? topLeaderName;
  int topLeaderScore = 0;
  bool topRecordBeaten = false;

  // Feature 4: Surprise Celestial Event (Comet Halley Flyby)
  bool cometWarningTriggered = false;
  bool cometSpawned = false;
  double cometAlertTimer = 0.0;
  String? cometAlertMessage;

  // Feature 5: Launch Transmission Dialogue Box
  bool showLaunchTransmission = false;
  double launchTransmissionTimer = 0.0;

  void dismissLaunchTransmission() {
    showLaunchTransmission = false;
  }

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

    // Register global hardware keyboard handler for instant pause detection
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);

    // Initial state set for Science Fair
    changeState(GameState.scienceIntro);
  }

  DateTime? _lastPauseToggleTime;

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (state == GameState.playing && showLaunchTransmission) {
      showLaunchTransmission = false;
    }

    final key = event.logicalKey;
    final isPauseKey = key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP;

    if (state == GameState.playing && isPauseKey) {
      togglePause();
      return true;
    }
    return false;
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
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.settings:
        _safeAddOverlay('settings');
        _removeAllAsteroidsAndProjectiles();
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
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.gameOver:
        _safeAddOverlay('gameOver');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.leaderboard:
        _safeAddOverlay('leaderboard');
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.6);
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
    }
  }

  void _safeAddOverlay(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  bool isGamePaused = false;

  void togglePause() {
    if (state != GameState.playing) return;
    final now = DateTime.now();
    if (_lastPauseToggleTime != null && now.difference(_lastPauseToggleTime!).inMilliseconds < 300) {
      return;
    }
    _lastPauseToggleTime = now;

    if (isGamePaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void pauseGame() {
    if (state != GameState.playing || isGamePaused) return;
    _lastPauseToggleTime = DateTime.now();
    isGamePaused = true;
    keysPressed.clear();
    pauseEngine();
    _safeAddOverlay('pause');
  }

  void resumeGame() {
    if (!isGamePaused) return;
    _lastPauseToggleTime = DateTime.now();
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

    if (showLaunchTransmission && keysPressed.isNotEmpty) {
      showLaunchTransmission = false;
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
    samplesCollected = 0;
    topRecordBeaten = false;
    cometWarningTriggered = false;
    cometSpawned = false;
    cometAlertTimer = 0.0;
    cometAlertMessage = null;
    showLaunchTransmission = true;
    launchTransmissionTimer = 5.0;
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
    // 1. Remove qualquer gerador de meteoros (AsteroidField / LevelManager)
    final fieldsToRemove = world.children.whereType<AsteroidField>();
    for (final f in List<AsteroidField>.from(fieldsToRemove)) {
      f.removeFromParent();
    }
    asteroidField = null;

    if (levelManager != null) {
      levelManager = null;
    }

    // 2. Remove todas as entidades dinâmicas de jogo
    final childrenToRemove = world.children.where((child) =>
        child is AsteroidComponent ||
        child is BulletComponent ||
        child is BombComponent ||
        child is BombExplosionComponent ||
        child is ParticleComponent ||
        child is FloatingTextComponent ||
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

    // Science Fair 180-second (3-minute) countdown timer & Celestial Events
    if (state == GameState.playing) {
      timeRemaining -= dt;
      if (showLaunchTransmission) {
        launchTransmissionTimer -= dt;
        if (launchTransmissionTimer <= 0) {
          showLaunchTransmission = false;
        }
      }
      if (cometAlertTimer > 0) {
        cometAlertTimer = math.max(0.0, cometAlertTimer - dt);
      }

      // Mid-game surprise event: Comet Halley warning at 105s remaining (75s played)
      if (!cometWarningTriggered && timeRemaining <= 105.0 && timeRemaining > 101.0) {
        cometWarningTriggered = true;
        cometAlertTimer = 4.0;
        cometAlertMessage = '☄️ ALERTA CIENTÍFICO: Cometa Halley se aproximando!';
        playSfx('low_health.wav');
      }

      // Spawn Comet at 101s remaining (79s played)
      if (cometWarningTriggered && !cometSpawned && timeRemaining <= 101.0) {
        cometSpawned = true;
        spawnComet();
      }

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
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
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

    score += basePoints;
    spawnFloatingText(pos, '+$basePoints', color: Colors.white, fontSize: 13.5);

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

  void spawnComet() {
    if (state != GameState.playing) return;
    final random = math.Random();

    // Pick an edge to spawn from: 0 = Left, 1 = Right, 2 = Top, 3 = Bottom
    final edge = random.nextInt(4);
    Vector2 spawnPos;
    switch (edge) {
      case 0: // Left
        spawnPos = Vector2(-35.0, 100.0 + random.nextDouble() * (GameConstants.screenHeight - 200.0));
        break;
      case 1: // Right
        spawnPos = Vector2(GameConstants.screenWidth + 35.0, 100.0 + random.nextDouble() * (GameConstants.screenHeight - 200.0));
        break;
      case 2: // Top
        spawnPos = Vector2(100.0 + random.nextDouble() * (GameConstants.screenWidth - 200.0), -35.0);
        break;
      default: // Bottom
        spawnPos = Vector2(100.0 + random.nextDouble() * (GameConstants.screenWidth - 200.0), GameConstants.screenHeight + 35.0);
        break;
    }

    // Direct trajectory across the central play area (near player zone)
    final targetX = (GameConstants.screenWidth / 2) + (random.nextDouble() - 0.5) * 400.0;
    final targetY = (GameConstants.screenHeight / 2) + (random.nextDouble() - 0.5) * 260.0;
    final targetPoint = Vector2(targetX, targetY);

    final dir = (targetPoint - spawnPos).normalized();
    final velocity = dir * 105.0; // Calibrated speed (105 px/s): approachable and pursuable

    final comet = CometComponent(
      position: spawnPos,
      velocity: velocity,
    );

    world.add(comet);
    playSfx('powerup.wav');
    triggerScreenShake(duration: 0.3, intensity: 6.0);
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
        // Super Dispersor 360°: 3 ondas concêntricas de projéteis (12 por onda = 36 projéteis) + 3.0s de escudo
        player.invulnerableTimer = 3.0;

        // Configuração das 3 fileiras/anéis concêntricos (rápida, média e curta)
        final waves = [
          (speed: 560.0, angleOffset: 0.0, color: const Color(0xFF00E676)),
          (speed: 480.0, angleOffset: math.pi / 12, color: const Color(0xFF00E5FF)),
          (speed: 400.0, angleOffset: 0.0, color: Colors.greenAccent),
        ];

        const bulletsPerWave = 12;
        const step = (2 * math.pi) / bulletsPerWave;

        for (final wave in waves) {
          for (int i = 0; i < bulletsPerWave; i++) {
            final ang = (i * step) + wave.angleOffset;
            final dir = Vector2(math.cos(ang), math.sin(ang));
            final bullet = BulletComponent(
              position: player.position + dir * (player.radius + 2.0),
              radius: 3.2,
              velocity: dir * wave.speed,
              lifeTimer: 0.75,
              damage: 18.0,
              color: wave.color,
            );
            world.add(bullet);
          }
        }

        // Explosão de partículas temáticas nas cores da Dra. Mae Jemison
        spawnExplosionParticles(
          position: player.position,
          colorChoices: [
            const Color(0xFF00E676),
            const Color(0xFF00E5FF),
            Colors.white,
          ],
          count: 36,
          minSize: 3.0,
          maxSize: 6.0,
          minSpeed: 80.0,
          maxSpeed: 240.0,
        );
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
              onAsteroidDestroyed(ast.position, (ast.radius * 16).toInt());
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
    samplesCollected = 0;
    topRecordBeaten = false;
    cometWarningTriggered = false;
    cometSpawned = false;
    cometAlertTimer = 0.0;
    cometAlertMessage = null;
    showLaunchTransmission = true;
    launchTransmissionTimer = 5.0;
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
      score += 3000; // Full 3-minute survival bonus (calibrated for fair play)
      if (!topRecordBeaten && topLeaderScore > 0 && score > topLeaderScore) {
        topRecordBeaten = true;
      }
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
