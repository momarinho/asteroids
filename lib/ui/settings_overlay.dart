import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class SettingsOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              width: MediaQuery.of(context).size.width > 550 ? 550 : MediaQuery.of(context).size.width * 0.92,
              padding: const EdgeInsets.all(20.0),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Title
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Colors.cyanAccent, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 30),

                  // Section 1: Movement Presets
                  const Text(
                    'SHIP MOVEMENT STYLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(game.movementPresets.length, (index) {
                    final preset = game.movementPresets[index];
                    final isSelected = game.selectedMovementPresetIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          game.selectedMovementPresetIndex = index;
                          (context as Element).markNeedsBuild();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.cyan : Colors.white12,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.cyanAccent : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Acc: ${preset.acceleration.toInt()}  |  Max Speed: ${preset.maxSpeed.toInt()}  |  Friction: ${preset.friction.toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.cyan, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 35),

                  // Save Button
                  ElevatedButton(
                    onPressed: () {
                      game.changeState(GameState.menu);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SAVE & BACK TO MENU',
                      style: TextStyle(
                        fontSize: 14,
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
    ),
  );
}
}
