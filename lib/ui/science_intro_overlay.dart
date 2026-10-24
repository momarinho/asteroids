import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class ScienceIntroOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const ScienceIntroOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 700 ? 680.0 : size.width * 0.94;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 32.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.4),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.18),
                      blurRadius: 28.0,
                      spreadRadius: 3.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge: Tema da Feira
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purpleAccent.withOpacity(0.3), Colors.cyanAccent.withOpacity(0.3)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'FEIRA DE CIÊNCIAS • MULHERES NA CIÊNCIA',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Main Title
                    const Text(
                      'MISSÃO COSMOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent,
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'PIONEIRAS DA EXPLORAÇÃO ESPACIAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 18),

                    // Lore Narrative Box
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Text(
                        'O cinturão de asteroides entrou em rota de colisão com nossos telescópios e satélites orbitais! '
                        'As maiores cientistas e astronautas da história foram convocadas para defender nossa pesquisa.\n\n'
                        'Escolha sua pioneira, pilote sua nave científica e mostre a força da ciência no espaço!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Mission Highlights
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBadge(Icons.timer, 'TEMPO', '2 MINUTOS', Colors.amberAccent),
                        _buildBadge(Icons.favorite, 'VIDAS', '3 CHANCES', Colors.redAccent),
                        _buildBadge(Icons.emoji_events, 'DESAFIO', 'RANKING AO VIVO', Colors.cyanAccent),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Start Button
                        ElevatedButton.icon(
                          onPressed: () {
                            game.playSfx('powerup.wav');
                            game.changeState(GameState.scientistSelection);
                          },
                          icon: const Icon(Icons.rocket_launch, size: 20),
                          label: const Text(
                            'ESCOLHER CIENTISTA',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 10,
                            shadowColor: Colors.cyanAccent.withOpacity(0.6),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Leaderboard Button
                        OutlinedButton.icon(
                          onPressed: () {
                            game.changeState(GameState.leaderboard);
                          },
                          icon: const Icon(Icons.leaderboard, size: 18),
                          label: const Text(
                            'RANKING',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBadge(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
