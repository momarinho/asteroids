import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/api_service.dart';

class GameOverOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitAndShowLeaderboard() async {
    final name = _nameController.text.trim().isEmpty ? 'Astronauta' : _nameController.text.trim();
    setState(() {
      _isSaving = true;
    });

    widget.game.participantName = name;
    await ApiService.saveFairScore(
      playerName: name,
      scientistName: widget.game.selectedScientist.name,
      score: widget.game.score,
    );

    if (mounted) {
      widget.game.changeState(GameState.leaderboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final scientist = game.selectedScientist;
    final score = game.score;
    final survived = game.missionSurvived;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                width: 540,
                padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 28.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: survived ? Colors.greenAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (survived ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15),
                      blurRadius: 24.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Header
                    Text(
                      survived ? 'MISSÃO CONCLUÍDA! 🚀' : 'MISSÃO FINALIZADA',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: survived ? Colors.greenAccent : Colors.orangeAccent,
                        shadows: [
                          Shadow(
                            color: survived ? Colors.green : Colors.orange,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      survived
                          ? 'Parabéns! Você sobreviveu aos 2:30 min no espaço!'
                          : 'Sua nave foi abatida pelos asteroides.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Score Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'PONTUAÇÃO',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  color: Colors.white54,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          Column(
                            children: [
                              const Text(
                                'CIENTISTA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  color: Colors.white54,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scientist.name,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: scientist.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Educational Fun Fact Card with Portrait
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scientist.primaryColor.withOpacity(0.12),
                            scientist.accentColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scientist.primaryColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              scientist.imagePath,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: scientist.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(Icons.school, color: scientist.primaryColor, size: 28),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb, color: scientist.accentColor, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'VOCÊ SABIA? • ${scientist.name.toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: scientist.accentColor,
                                          letterSpacing: 1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  scientist.funFact,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name Input Field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DIGITE SEU NOME PARA O RANKING DA FEIRA:',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'SEU NOME / APELIDO',
                        hintStyle: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                          color: Colors.white24,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.8),
                        ),
                      ),
                      onSubmitted: (_) => _submitAndShowLeaderboard(),
                    ),

                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        // Leaderboard submit button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _submitAndShowLeaderboard,
                            icon: const Icon(Icons.emoji_events, size: 18),
                            label: Text(
                              _isSaving ? 'SALVANDO...' : 'SALVAR NO RANKING',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 6,
                              shadowColor: Colors.cyanAccent.withOpacity(0.5),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Skip / Retry button
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              game.changeState(GameState.scienceIntro);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'PULAR',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
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
}
