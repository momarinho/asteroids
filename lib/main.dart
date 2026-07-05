import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/asteroids_game.dart';
import 'ui/menu_overlay.dart';
import 'ui/settings_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/shop_overlay.dart';
import 'ui/stage_clear_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/leaderboard_overlay.dart';
import 'ui/weapon_selection_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteroids Multiplatform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AsteroidsGame _game;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _game = AsteroidsGame();
    _focusNode = FocusNode();
    _game.gameFocusNode = _focusNode;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<AsteroidsGame>(
        game: _game,
        focusNode: _focusNode,
        overlayBuilderMap: {
          'menu': (context, game) => MenuOverlay(game: game),
          'settings': (context, game) => SettingsOverlay(game: game),
          'hud': (context, game) => HudOverlay(game: game),
          'shop': (context, game) => ShopOverlay(game: game),
          'stageClear': (context, game) => StageClearOverlay(game: game),
          'gameOver': (context, game) => GameOverOverlay(game: game),
          'leaderboard': (context, game) => LeaderboardOverlay(game: game),
          'weaponSelection': (context, game) => WeaponSelectionOverlay(game: game),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }
}
