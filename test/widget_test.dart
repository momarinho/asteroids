import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/scientist.dart';
import 'package:asteroids/ui/science_intro_overlay.dart';
import 'package:asteroids/ui/game_over_overlay.dart';
import 'package:asteroids/ui/leaderboard_overlay.dart';

import 'package:asteroids/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Scientist Model Tests', () {
    test('Scientists list has 4 historical pioneers', () {
      expect(Scientist.scientists.length, 4);

      final ids = Scientist.scientists.map((s) => s.id).toSet();
      expect(ids.contains('mae_jemison'), isTrue);
      expect(ids.contains('margaret_hamilton'), isTrue);
      expect(ids.contains('nancy_roman'), isTrue);
      expect(ids.contains('peggy_whitson'), isTrue);
    });

    test('Each scientist has unique weapon and ship design', () {
      final weaponIds = Scientist.scientists.map((s) => s.weaponId).toSet();
      expect(weaponIds.length, 4);

      final shipDesigns = Scientist.scientists.map((s) => s.shipDesign).toSet();
      expect(shipDesigns.length, 4);

      for (final scientist in Scientist.scientists) {
        final weapon = scientist.createWeapon();
        expect(weapon, isNotNull);
        expect(scientist.name.isNotEmpty, isTrue);
        expect(scientist.funFact.isNotEmpty, isTrue);
      }
    });

    test('Scientist findById returns correct scientist or default', () {
      final mae = Scientist.findById('mae_jemison');
      expect(mae.name, 'Mae Jemison');

      final unknown = Scientist.findById('unknown_id');
      expect(unknown.id, Scientist.defaultScientist.id);
    });
  });

  group('Science Fair Keyboard Navigation Tests', () {
    testWidgets('ScienceIntroOverlay changes selection with ArrowRight key', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScienceIntroOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Initially "► INICIAR MISSÃO" should be selected
      expect(find.text('► INICIAR MISSÃO'), findsOneWidget);
      expect(find.text('► RANKING DA FEIRA'), findsNothing);

      // Press ArrowRight
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Now "► RANKING DA FEIRA" should be selected
      expect(find.text('► RANKING DA FEIRA'), findsOneWidget);
      expect(find.text('► INICIAR MISSÃO'), findsNothing);

      // Press ArrowLeft
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Should return to "► INICIAR MISSÃO"
      expect(find.text('► INICIAR MISSÃO'), findsOneWidget);
      expect(find.text('► RANKING DA FEIRA'), findsNothing);
    });

    testWidgets('GameOverOverlay accepts text typing and Enter submits', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedScientist = Scientist.scientists[0];
      game.score = 420;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // The TextField should be present
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter text
      await tester.enterText(textFieldFinder, 'MARIA');
      await tester.pump();

      expect(find.text('MARIA'), findsOneWidget);

      // Press Enter key on keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // State should transition to leaderboard and participantName should be set
      expect(game.participantName, 'MARIA');
      expect(game.state, GameState.leaderboard);
    });

    testWidgets('LeaderboardOverlay responds to keyboard navigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Initially "► PRÓXIMO PILOTO 🚀" is selected
      expect(find.text('► PRÓXIMO PILOTO 🚀'), findsOneWidget);

      // Press ArrowRight to switch to CIENTISTAS
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.text('► CIENTISTAS'), findsOneWidget);

      // Press Escape to return to scienceIntro
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(game.state, GameState.scienceIntro);
    });
  });

  group('Fair Score Persistence and Leaderboard Tests', () {
    test('saveFairScore and getFairLeaderboard saves and retrieves scores including score 0', () async {
      SharedPreferences.setMockInitialValues({});

      await ApiService.saveFairScore(
        playerName: 'test3',
        scientistName: 'Mae Jemison',
        score: 0,
      );

      await ApiService.saveFairScore(
        playerName: 'PILOT_ACE',
        scientistName: 'Nancy Grace Roman',
        score: 5500,
      );

      final leaderboard = await ApiService.getFairLeaderboard(period: 'all');
      expect(leaderboard.length, 2);
      expect(leaderboard[0]['username'], 'PILOT_ACE');
      expect(leaderboard[0]['score'], 5500);
      expect(leaderboard[1]['username'], 'test3');
      expect(leaderboard[1]['score'], 0);
      expect(leaderboard[1]['scientist'], 'Mae Jemison');
    });

    test('FlameAudio updatePrefix sets correct asset folder for both SFX and BGM', () {
      FlameAudio.updatePrefix('assets/sounds/');
      expect(FlameAudio.audioCache.prefix, 'assets/sounds/');
      expect(FlameAudio.bgm.audioPlayer.audioCache.prefix, 'assets/sounds/');
    });
  });
}
