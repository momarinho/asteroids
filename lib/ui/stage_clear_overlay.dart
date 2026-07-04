import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class StageClearOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const StageClearOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final levelManager = game.levelManager;
    if (levelManager == null) {
      return const SizedBox.shrink();
    }

    final level = levelManager.currentLevel;
    final score = game.score;
    final clearBonus = levelManager.stageClearBonus;
    final livesBonus = levelManager.livesBonus;
    final totalEarned = levelManager.bonusCredits;
    final totalCredits = game.credits;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 20.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'STAGE $level CLEAR!',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.greenAccent,
                      shadows: [
                        Shadow(
                          color: Colors.green,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 40),

                  // Bonus Table
                  _buildStatRow('CURRENT SCORE', '$score'),
                  const SizedBox(height: 12),
                  _buildStatRow('STAGE CLEAR BONUS', '+$clearBonus credits', color: Colors.greenAccent),
                  const SizedBox(height: 12),
                  _buildStatRow('LIVES REMAINING BONUS', '+$livesBonus credits', color: Colors.greenAccent),
                  const SizedBox(height: 12),
                  _buildStatRow('CREDITS EARNED', '+$totalEarned credits', color: Colors.amberAccent),
                  const SizedBox(height: 12),
                  _buildStatRow('TOTAL CREDITS', '$totalCredits credits', color: Colors.amber, isBold: true),

                  const SizedBox(height: 40),

                  // Shop Button
                  ElevatedButton(
                    onPressed: () {
                      game.changeState(GameState.shop);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 50.0),
                      elevation: 8,
                      shadowColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ENTER UPGRADE SHOP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
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

  Widget _buildStatRow(String label, String value, {Color color = Colors.white, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
