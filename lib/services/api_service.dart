import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'dart:io' as io;

class ApiService {
  static String get baseUrl {
    if (!kIsWeb && io.Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
  static const String secretKey = 'asteroids-secret-token-key-2026';

  // Shared preferences keys
  static const String _keyPlayerId = 'player_id';
  static const String _keyPlayerUsername = 'player_username';

  // 1. Get saved player profile from local storage
  static Future<Map<String, String>?> getLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyPlayerId);
    final username = prefs.getString(_keyPlayerUsername);
    
    if (id != null && username != null) {
      return {'id': id, 'username': username};
    }
    return null;
  }

  // 2. Save player profile to local storage
  static Future<void> saveLocalProfile(String id, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerId, id);
    await prefs.setString(_keyPlayerUsername, username);
  }

  // 3. Register a new player with the Go API
  static Future<Map<String, String>?> registerPlayer(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final id = data['id'] as String;
        final name = data['username'] as String;
        
        await saveLocalProfile(id, name);
        return {'id': id, 'username': name};
      }
    } catch (e) {
      debugPrint('Error registering player: $e');
    }
    return null;
  }

  // 4. Submit score with anti-cheat signature
  static Future<bool> submitScore({
    required String playerId,
    required int score,
    required int level,
    required String mode,
  }) async {
    try {
      // Generate HMAC-SHA256 signature
      final payload = '$playerId:$score:$level:$mode';
      final keyBytes = utf8.encode(secretKey);
      final payloadBytes = utf8.encode(payload);
      final hmacSha256 = Hmac(sha256, keyBytes);
      final digest = hmacSha256.convert(payloadBytes);
      final signature = digest.toString();

      final response = await http.post(
        Uri.parse('$baseUrl/scores'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'player_id': playerId,
          'score': score,
          'level': level,
          'mode': mode,
          'signature': signature,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('Score submitted successfully to cloud leaderboard!');
        return true;
      } else {
        debugPrint('Failed to submit score. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error submitting score to backend: $e');
    }
    return false;
  }

  // 5. Get leaderboards list
  static Future<List<Map<String, dynamic>>> getLeaderboard(String mode, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scores?mode=$mode&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((entry) => entry as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
    }
    return [];
  }
}
