import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';

class ScienceIntroOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ScienceIntroOverlay({super.key, required this.game});

  @override
  State<ScienceIntroOverlay> createState() => _ScienceIntroOverlayState();
}

class _ScienceIntroOverlayState extends State<ScienceIntroOverlay> {
  final FocusNode _focusNode = FocusNode();
  int _selectedMenuIndex = 0; // 0 = INICIAR MISSÃO, 1 = RANKING DA FEIRA

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activateOption() {
    if (_selectedMenuIndex == 0) {
      widget.game.playSfx('powerup.wav');
      widget.game.changeState(GameState.scientistSelection);
    } else {
      widget.game.playSfx('menu_select.wav');
      widget.game.changeState(GameState.leaderboard);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        setState(() {
          _selectedMenuIndex = 1 - _selectedMenuIndex;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _activateOption();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyR ||
          event.logicalKey == LogicalKeyboardKey.digit2) {
        setState(() {
          _selectedMenuIndex = 1;
        });
        widget.game.playSfx('menu_select.wav');
        widget.game.changeState(GameState.leaderboard);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        setState(() {
          _selectedMenuIndex = 0;
        });
        widget.game.playSfx('powerup.wav');
        widget.game.changeState(GameState.scientistSelection);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 700 ? 680.0 : size.width * 0.94;

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
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 32.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'FEIRA DE CIÊNCIAS • MULHERES NA CIÊNCIA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
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
                          fontSize: 15,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Story Narrative / Mission Briefing
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.08),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.satellite_alt, color: Colors.cyanAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'COMUNICADO DA BASE ESPACIAL • OPERAÇÃO PIONEIRAS 2026',
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Colors.cyanAccent.shade100,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'A Terra detectou um cinturão de asteroides repleto de minerais raros e do lendário Cometa Halley!\n'
                              'Assuma o comando de naves inspiradas em 4 cientistas pioneiras, colete dados vitais para a ciência '
                              'e sobreviva aos 3 minutos de tempestade estelar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Mission Highlights
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBadge(Icons.timer, 'TEMPO', '3:00 MIN', Colors.amberAccent),
                          _buildBadge(Icons.favorite, 'VIDAS', '3 CHANCES', Colors.redAccent),
                          _buildBadge(Icons.emoji_events, 'DESAFIO', 'RANKING AO VIVO', Colors.cyanAccent),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Interactive Arcade Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Start Button (Index 0)
                          Expanded(
                            child: ElevatedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                setState(() {
                                  _selectedMenuIndex = 0;
                                });
                                _activateOption();
                              },
                              icon: Icon(
                                Icons.rocket_launch,
                                size: 20,
                                color: _selectedMenuIndex == 0 ? Colors.black : Colors.cyanAccent,
                              ),
                              label: Text(
                                _selectedMenuIndex == 0 ? '► INICIAR MISSÃO' : 'INICIAR MISSÃO',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: _selectedMenuIndex == 0 ? Colors.black : Colors.cyanAccent,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedMenuIndex == 0
                                    ? Colors.cyanAccent
                                    : Colors.cyan.withOpacity(0.12),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedMenuIndex == 0 ? Colors.white : Colors.cyanAccent.withOpacity(0.4),
                                    width: _selectedMenuIndex == 0 ? 2.0 : 1.0,
                                  ),
                                ),
                                elevation: _selectedMenuIndex == 0 ? 10 : 0,
                                shadowColor: Colors.cyanAccent.withOpacity(0.7),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Leaderboard Button (Index 1)
                          Expanded(
                            child: ElevatedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                setState(() {
                                  _selectedMenuIndex = 1;
                                });
                                _activateOption();
                              },
                              icon: Icon(
                                Icons.leaderboard,
                                size: 20,
                                color: _selectedMenuIndex == 1 ? Colors.black : Colors.amberAccent,
                              ),
                              label: Text(
                                _selectedMenuIndex == 1 ? '► RANKING DA FEIRA' : 'RANKING DA FEIRA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: _selectedMenuIndex == 1 ? Colors.black : Colors.amberAccent,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedMenuIndex == 1
                                    ? Colors.amberAccent
                                    : Colors.amber.withOpacity(0.12),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedMenuIndex == 1 ? Colors.white : Colors.amberAccent.withOpacity(0.4),
                                    width: _selectedMenuIndex == 1 ? 2.0 : 1.0,
                                  ),
                                ),
                                elevation: _selectedMenuIndex == 1 ? 10 : 0,
                                shadowColor: Colors.amberAccent.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Retro Arcade Keyboard Prompt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              Icon(Icons.keyboard, color: Colors.cyanAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '◄ / ►: ESCOLHER   •   [ESPAÇO / ENTER]: CONFIRMAR   •   [R]: RANKING',
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

  Widget _buildBadge(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 11.5,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
