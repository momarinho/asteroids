import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/api_service.dart';

class LeaderboardOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const LeaderboardOverlay({super.key, required this.game});

  @override
  State<LeaderboardOverlay> createState() => _LeaderboardOverlayState();
}

class _LeaderboardOverlayState extends State<LeaderboardOverlay> {
  String _selectedMode = 'classic'; // 'classic' or 'campaign'

  @override
  Widget build(BuildContext context) {
    final title = _selectedMode == 'campaign' ? 'CAMPAIGN LEADERBOARD' : 'CLASSIC LEADERBOARD';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              width: 600,
              height: 500,
              padding: const EdgeInsets.all(25.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.1),
                    blurRadius: 20.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title
                  const Row(
                    children: [
                      Icon(Icons.leaderboard, color: Colors.cyanAccent, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'GLOBAL RANKINGS',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Mode Tabs
                  Row(
                    children: [
                      _buildTabButton('CLASSIC', 'classic'),
                      const SizedBox(width: 10),
                      _buildTabButton('CAMPAIGN', 'campaign'),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 25),

                  // High scores table
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ApiService.getLeaderboard(_selectedMode),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Center(
                            child: Text(
                              'Failed to load rankings. Check server connection.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          );
                        }

                        final entries = snapshot.data!;
                        if (entries.isEmpty) {
                          return const Center(
                            child: Text(
                              'No scores submitted yet. Be the first!',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final username = entry['username'] as String;
                            final score = entry['score'] as int;
                            final level = entry['level'] as int;
                            final isMe = username.toUpperCase() == widget.game.playerUsername?.toUpperCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.cyan.withOpacity(0.08) : Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMe ? Colors.cyan : Colors.white12,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank number
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                        color: index == 0
                                            ? Colors.amber
                                            : (index == 1 ? Colors.grey : (index == 2 ? Colors.brown : Colors.white60)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Username
                                  Expanded(
                                    child: Text(
                                      username.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                        color: isMe ? Colors.cyanAccent : Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Level reached
                                  Text(
                                    'LVL $level',
                                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                                  ),
                                  const SizedBox(width: 25),
                                  // Score
                                  Text(
                                    '$score',
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 25),

                  // Return Button
                  ElevatedButton(
                    onPressed: () {
                      widget.game.changeState(GameState.menu);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'BACK TO MENU',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String mode) {
    final isActive = _selectedMode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isActive ? Colors.cyanAccent : Colors.white60,
          backgroundColor: isActive ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
          side: BorderSide(
            color: isActive ? Colors.cyan : Colors.white24,
            width: isActive ? 1.5 : 1.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
