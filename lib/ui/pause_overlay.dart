import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';

class PauseOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        widget.game.resumeGame();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final scientist = game.selectedScientist;
    final score = game.score;
    final timeRemaining = game.timeRemaining;

    final minutes = (timeRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeRemaining.toInt() % 60).toString().padLeft(2, '0');

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  width: 440,
                  padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 28.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scientist.primaryColor.withOpacity(0.6),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scientist.primaryColor.withOpacity(0.2),
                        blurRadius: 24.0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle_filled, color: scientist.primaryColor, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'JOGO PAUSADO',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pressione ESC ou Espaço para continuar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Round Summary Box
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            // Scientist info
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    scientist.imagePath,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: scientist.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scientist.name,
                                        style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: scientist.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NAVE: ${scientist.shipName}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 22, color: Colors.white12),

                            // Stats: Score, Samples & Time Remaining
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'PONTOS',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11,
                                        color: Colors.white54,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$score',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: Colors.white12),
                                Column(
                                  children: [
                                    const Text(
                                      'AMOSTRAS',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11,
                                        color: Colors.white54,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${game.samplesCollected}',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 32, color: Colors.white12),
                                Column(
                                  children: [
                                    const Text(
                                      'TEMPO RESTANTE',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11,
                                        color: Colors.white54,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$minutes:$seconds',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: timeRemaining <= 30 ? Colors.redAccent : Colors.cyanAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Button 1: Continuar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            game.resumeGame();
                          },
                          icon: const Icon(Icons.play_arrow, size: 22),
                          label: const Text(
                            'CONTINUAR PARTIDA',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scientist.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            shadowColor: scientist.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Button 2: Voltar ao Menu
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            game.resumeGame();
                            game.changeState(GameState.scientistSelection);
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text(
                            'VOLTAR AO MENU',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      ),
    );
  }
}
