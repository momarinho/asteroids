import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/services/api_service.dart';

void main() {
  group('Database & Backend Integration Verification', () {
    test('Backend is accessible and returns healthy status', () async {
      final scores = await ApiService.getLeaderboard('arcade', limit: 3);
      expect(scores, isA<List<Map<String, dynamic>>>());
      // The database has scores seeded/saved
      expect(scores.isNotEmpty, isTrue);
    });

    test('ApiService saves and queries dual-persistence leaderboard', () async {
      SharedPreferences.setMockInitialValues({});

      // Register and submit via fair score API
      await ApiService.saveFairScore(
        playerName: 'PILOTO_TESTE',
        scientistName: 'Margaret Hamilton',
        score: 7770,
      );

      final fairScores = await ApiService.getFairLeaderboard(period: 'all');
      expect(fairScores.any((s) => s['username'] == 'PILOTO_TESTE' && s['score'] == 7770), isTrue);
    });
  });
}
