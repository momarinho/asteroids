import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.game.changeState(GameState.scienceIntro);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _submitAndShowLeaderboard();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAndShowLeaderboard() async {
    if (_isSaving) return;
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

    return GestureDetector(
      onTap: () => _nameFocusNode.requestFocus(),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                width: 580,
                padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 26.0),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        survived ? '🎉 MISSÃO CONCLUÍDA! 🚀' : 'MISSÃO FINALIZADA',
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      survived
                          ? 'Parabéns! Você sobreviveu aos 3 minutos completos no espaço!'
                          : 'Sua nave foi abatida pelos asteroides.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: survived ? FontWeight.bold : FontWeight.normal,
                        color: survived ? Colors.greenAccent.shade100 : Colors.white70,
                      ),
                    ),

                    if (survived) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.25),
                              Colors.greenAccent.withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 20),
                              SizedBox(width: 8),
                              Text(
                                '🏅 MEDALHA DE HONRA: SOBREVIVENTE ESPACIAL (+1000 PTS BÔNUS!)',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

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
                                  fontSize: 12,
                                  color: Colors.white54,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 36, color: Colors.white24),
                          Column(
                            children: [
                              const Text(
                                'AMOSTRAS',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  color: Colors.white54,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${game.samplesCollected}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 36, color: Colors.white24),
                          Column(
                            children: [
                              const Text(
                                'CIENTISTA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  color: Colors.white54,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scientist.name,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 15,
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

                    // Educational Fun Fact Card with Prominent Hero Portrait
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scientist.primaryColor.withOpacity(0.18),
                            scientist.accentColor.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: scientist.primaryColor.withOpacity(0.6),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scientist.primaryColor.withOpacity(0.2),
                            blurRadius: 18.0,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Prominent Hero Portrait Frame (115x115)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scientist.primaryColor,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scientist.primaryColor.withOpacity(0.45),
                                  blurRadius: 16.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                scientist.imagePath,
                                width: 115,
                                height: 115,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 115,
                                  height: 115,
                                  decoration: BoxDecoration(
                                    color: scientist.primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.school, color: scientist.primaryColor, size: 48),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Curiosity Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: scientist.accentColor, size: 20),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'LEGADO • ${scientist.name.toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: scientist.accentColor,
                                          letterSpacing: 1.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  scientist.funFact,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 14,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'SEU NOME / APELIDO',
                        hintStyle: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 15,
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
                          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2.0),
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
                            focusNode: FocusNode(canRequestFocus: false),
                            onPressed: _isSaving ? null : _submitAndShowLeaderboard,
                            icon: const Icon(Icons.emoji_events, size: 20),
                            label: Text(
                              _isSaving ? 'SALVANDO...' : 'SALVAR NO RANKING [ENTER]',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                            focusNode: FocusNode(canRequestFocus: false),
                            onPressed: () {
                              game.changeState(GameState.scienceIntro);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'PULAR [ESC]',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Keyboard prompt
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.keyboard, color: Colors.cyanAccent, size: 16),
                            SizedBox(width: 8),
                            Text(
                              '[DIGITE SEU NOME]   •   [ENTER]: SALVAR NO RANKING   •   [ESC]: PULAR',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
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
