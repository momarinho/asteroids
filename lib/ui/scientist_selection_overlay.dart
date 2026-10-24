import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/scientist.dart';
import 'package:asteroids/ui/weapon_preview_dialog.dart';

class ScientistSelectionOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ScientistSelectionOverlay({super.key, required this.game});

  @override
  State<ScientistSelectionOverlay> createState() => _ScientistSelectionOverlayState();
}

class _ScientistSelectionOverlayState extends State<ScientistSelectionOverlay> {
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  int _countdownSeconds = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus keyboard listener for instant arcade input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
          if (_countdownSeconds <= 5) {
            widget.game.playSfx('menu_select.wav');
          }
        } else {
          _timer?.cancel();
          _launchScientist(Scientist.scientists[_selectedIndex]);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _launchScientist(Scientist scientist) {
    _timer?.cancel();
    widget.game.playSfx('powerup.wav');
    widget.game.startFairGame(scientist);
  }

  void _openPreview(Scientist scientist) {
    widget.game.playSfx('menu_select.wav');
    WeaponPreviewDialog.show(context, scientist, widget.game);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final scientists = Scientist.scientists;
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + scientists.length) % scientists.length;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % scientists.length;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
        _launchScientist(scientists[_selectedIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyT || event.logicalKey == LogicalKeyboardKey.keyV) {
        _openPreview(scientists[_selectedIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _timer?.cancel();
        widget.game.changeState(GameState.scienceIntro);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scientists = Scientist.scientists;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  width: size.width > 1200 ? 1160 : size.width * 0.96,
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.12),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Bar with Back Button, Header and Arcade Countdown Timer
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _timer?.cancel();
                              widget.game.changeState(GameState.scienceIntro);
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white70),
                            tooltip: 'Voltar (ESC)',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'ESCOLHA SUA CIENTISTA',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Cada cientista comanda uma nave e armamento exclusivo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arcade Countdown Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _countdownSeconds <= 5
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _countdownSeconds <= 5 ? Colors.redAccent : Colors.cyanAccent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: _countdownSeconds <= 5 ? Colors.redAccent : Colors.cyanAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_countdownSeconds}s',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: _countdownSeconds <= 5 ? Colors.redAccent : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Cards Layout (Grid of 4 or Row of 4)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(scientists.length, (index) {
                                final isSelected = index == _selectedIndex;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: _buildScientistCard(context, scientists[index], index, isSelected),
                                  ),
                                );
                              }),
                            );
                          } else {
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: List.generate(scientists.length, (index) {
                                final isSelected = index == _selectedIndex;
                                return SizedBox(
                                  width: (constraints.maxWidth - 20) / 2 > 300
                                      ? (constraints.maxWidth - 20) / 2
                                      : constraints.maxWidth,
                                  child: _buildScientistCard(context, scientists[index], index, isSelected),
                                );
                              }),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Desktop Arcade Keyboard Guide Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard, color: Colors.cyanAccent, size: 16),
                            SizedBox(width: 8),
                            Text(
                              '◄ / ► (A/D): NAVEGAR  •  [ESPAÇO / ENTER]: DECOLAR  •  [T]: TESTAR ARMA  •  [ESC]: VOLTAR',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
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

  Widget _buildScientistCard(BuildContext context, Scientist scientist, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.game.playSfx('menu_select.wav');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? scientist.primaryColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? scientist.primaryColor : scientist.primaryColor.withOpacity(0.4),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? scientist.primaryColor.withOpacity(0.35)
                  : scientist.primaryColor.withOpacity(0.08),
              blurRadius: isSelected ? 18 : 10,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arcade Selection Indicator Banner
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scientist.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_esports, color: Colors.black, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'PILOTO EM FOCO',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 19),

            // Header Badge: Pixel-art Portrait + Name & Role
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scientist.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scientist.primaryColor, width: 1.5),
                    ),
                    child: Image.asset(
                      scientist.imagePath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.person, color: scientist.primaryColor, size: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scientist.name,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        scientist.role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scientist.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Ship & Weapon Info (Interactive with quick preview)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                _openPreview(scientist);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flight, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scientist.shipName,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scientist.accentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scientist.weaponName,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.amberAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_outline, color: Colors.amberAccent, size: 10),
                              SizedBox(width: 2),
                              Text(
                                'VER',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Short Bio (clean 2-line uniform display)
            SizedBox(
              height: 36,
              child: Text(
                scientist.shortBio,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // Test Weapon Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _openPreview(scientist);
                },
                icon: const Icon(Icons.play_circle_fill, size: 14, color: Colors.amberAccent),
                label: const Text(
                  'TESTAR ARMA (T)',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    letterSpacing: 1.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amberAccent.withOpacity(0.4), width: 1.2),
                  backgroundColor: Colors.amberAccent.withOpacity(0.06),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Select & Launch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchScientist(scientist),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scientist.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isSelected ? 8 : 4,
                  shadowColor: scientist.primaryColor.withOpacity(0.6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      isSelected ? 'DECOLAR (ESPAÇO)' : 'DECOLAR',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
