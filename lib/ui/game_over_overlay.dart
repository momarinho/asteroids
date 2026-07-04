import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class GameOverOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final modeLabel = game.activeMode == 'campaign' ? 'CAMPAIGN MODE' : 'CLASSIC MODE';
    final score = game.score;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              width: 450,
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 30.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15),
                    blurRadius: 20.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.redAccent,
                      shadows: [
                        Shadow(
                          color: Colors.red,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    modeLabel,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Colors.white60,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 45),

                  // Stats
                  const Text(
                    'FINAL SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Restart Button
                  ElevatedButton(
                    onPressed: () {
                      game.startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 45.0),
                      elevation: 8,
                      shadowColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'TRY AGAIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Menu Button
                  TextButton(
                    onPressed: () {
                      game.changeState(GameState.menu);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.white24, width: 1),
                      ),
                    ),
                    child: const Text(
                      'BACK TO MENU',
                      style: TextStyle(
                        fontSize: 13,
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
}
