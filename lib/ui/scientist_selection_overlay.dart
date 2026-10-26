import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/scientist.dart';

class ScientistSelectionOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ScientistSelectionOverlay({super.key, required this.game});

  @override
  State<ScientistSelectionOverlay> createState() => _ScientistSelectionOverlayState();
}

class _ScientistSelectionOverlayState extends State<ScientistSelectionOverlay> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  int _countdownSeconds = 25;
  Timer? _countdownTimer;

  // Live Inline Weapon Simulation
  late final AnimationController _animController;
  final List<_InlineBullet> _bullets = [];
  final List<_InlineSpark> _sparks = [];
  Offset _dummyAsteroidPos = const Offset(120, 22);
  double _asteroidFlashTimer = 0.0;
  double _fireTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateInlineSimulation)..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
          if (_countdownSeconds <= 5) {
            widget.game.playSfx('menu_select.wav');
          }
        } else {
          _countdownTimer?.cancel();
          _launchScientist(Scientist.scientists[_selectedIndex]);
        }
      });
    });
  }

  void _updateInlineSimulation() {
    const dt = 0.016;
    _fireTimer += dt;
    if (_asteroidFlashTimer > 0) {
      _asteroidFlashTimer = math.max(0.0, _asteroidFlashTimer - dt);
    }

    final scientist = Scientist.scientists[_selectedIndex];
    double fireCooldown;
    switch (scientist.weaponId) {
      case 'rapid_fire':
        fireCooldown = 0.13;
        break;
      case 'spread_shot':
        fireCooldown = 0.45;
        break;
      case 'bomb_launcher':
        fireCooldown = 0.85;
        break;
      case 'blaster':
      default:
        fireCooldown = 0.32;
        break;
    }

    if (_fireTimer >= fireCooldown) {
      _fireTimer = 0.0;
      _spawnBulletsForSelected(scientist);
    }

    // Update simulation bullets
    for (int i = _bullets.length - 1; i >= 0; i--) {
      final b = _bullets[i];
      b.pos += b.vel * dt;
      b.life -= dt;

      // Check hit with dummy asteroid
      final dist = (b.pos - _dummyAsteroidPos).distance;
      if (dist <= (12.0 + b.radius)) {
        _asteroidFlashTimer = 0.12;
        final sparkCount = b.isBomb ? 14 : 5;
        for (int s = 0; s < sparkCount; s++) {
          final ang = math.Random().nextDouble() * 2 * math.pi;
          final spd = 30.0 + math.Random().nextDouble() * 60.0;
          _sparks.add(_InlineSpark(
            pos: b.pos,
            vel: Offset(math.cos(ang) * spd, math.sin(ang) * spd),
            color: b.color,
            life: 0.3,
          ));
        }
        _bullets.removeAt(i);
        continue;
      }

      if (b.life <= 0 || b.pos.dy < -5) {
        _bullets.removeAt(i);
      }
    }

    // Update sparks
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.pos += s.vel * dt;
      s.life -= dt;
      if (s.life <= 0) {
        _sparks.removeAt(i);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _spawnBulletsForSelected(Scientist scientist) {
    const muzzle = Offset(120, 68);
    if (scientist.weaponId == 'spread_shot') {
      final angles = [-14.0, 0.0, 14.0];
      for (final a in angles) {
        final rad = (a - 90.0) * math.pi / 180.0;
        const spd = 160.0;
        _bullets.add(_InlineBullet(
          pos: muzzle,
          vel: Offset(math.cos(rad) * spd, math.sin(rad) * spd),
          color: scientist.primaryColor,
          radius: 2.6,
          life: 0.6,
        ));
      }
    } else if (scientist.weaponId == 'rapid_fire') {
      _bullets.add(_InlineBullet(
        pos: muzzle,
        vel: const Offset(0, -200),
        color: scientist.primaryColor,
        radius: 2.2,
        life: 0.5,
      ));
    } else if (scientist.weaponId == 'bomb_launcher') {
      _bullets.add(_InlineBullet(
        pos: muzzle,
        vel: const Offset(0, -120),
        color: scientist.primaryColor,
        radius: 5.0,
        life: 0.7,
        isBomb: true,
      ));
    } else {
      _bullets.add(_InlineBullet(
        pos: muzzle,
        vel: const Offset(0, -210),
        color: scientist.primaryColor,
        radius: 3.0,
        life: 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _launchScientist(Scientist scientist) {
    _countdownTimer?.cancel();
    widget.game.playSfx('powerup.wav');
    widget.game.startFairGame(scientist);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final scientists = Scientist.scientists;
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + scientists.length) % scientists.length;
          _bullets.clear();
          _sparks.clear();
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % scientists.length;
          _bullets.clear();
          _sparks.clear();
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
        _launchScientist(scientists[_selectedIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _countdownTimer?.cancel();
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  width: size.width > 1500
                      ? 1440
                      : (size.width > 1100 ? size.width * 0.96 : size.width * 0.98),
                  padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header & Arcade Timer
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _countdownTimer?.cancel();
                              widget.game.changeState(GameState.scienceIntro);
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 26),
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
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Use as setas ◄ / ► para navegar • Pressione ESPAÇO para decolar',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Colors.cyanAccent.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arcade Countdown Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_countdownSeconds}s',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 16,
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

                      // 4 Cards Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1050;
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
                              spacing: 14,
                              runSpacing: 14,
                              alignment: WrapAlignment.center,
                              children: List.generate(scientists.length, (index) {
                                final isSelected = index == _selectedIndex;
                                return SizedBox(
                                  width: (constraints.maxWidth - 20) / 2 > 320
                                      ? (constraints.maxWidth - 20) / 2
                                      : constraints.maxWidth,
                                  child: _buildScientistCard(context, scientists[index], index, isSelected),
                                );
                              }),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // Bottom Arcade Navigation Guide
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard, color: Colors.cyanAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '◄ / ► (A/D): NAVEGAR  •  [ESPAÇO / ENTER]: DECOLAR  •  [ESC]: VOLTAR',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12.5,
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

  Widget _buildScientistCard(BuildContext context, Scientist scientist, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _bullets.clear();
          _sparks.clear();
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
            color: isSelected ? scientist.primaryColor : scientist.primaryColor.withOpacity(0.35),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? scientist.primaryColor.withOpacity(0.35)
                  : scientist.primaryColor.withOpacity(0.06),
              blurRadius: isSelected ? 18 : 8,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top: Live Hologram Weapon Viewport (Height: 96px)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF090D18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? scientist.primaryColor.withOpacity(0.7)
                        : Colors.white10,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 96),
                      painter: _InlineViewportPainter(
                        scientist: scientist,
                        isSelected: isSelected,
                        bullets: isSelected ? _bullets : const [],
                        sparks: isSelected ? _sparks : const [],
                        asteroidPos: _dummyAsteroidPos,
                        asteroidFlash: isSelected && _asteroidFlashTimer > 0,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? Colors.redAccent.withOpacity(0.6) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: isSelected ? Colors.redAccent : Colors.white38,
                              size: 6,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSelected ? 'AO VIVO' : 'STANDBY',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white54,
                                letterSpacing: 0.8,
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

            const SizedBox(height: 12),

            // Scientist Portrait + Name & Role
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scientist.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scientist.primaryColor, width: 2.0),
                    ),
                    child: Image.asset(
                      scientist.imagePath,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.person, color: scientist.primaryColor, size: 28),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scientist.role,
                        style: TextStyle(
                          fontSize: 12.5,
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

            // Weapon Title & Compact Attribute Bars
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
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
                      const Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          scientist.weaponName,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('CAD', scientist.cadenceRating, Colors.cyanAccent),
                      _buildMiniStat('ÁREA', scientist.areaRating, Colors.greenAccent),
                      _buildMiniStat('DANO', scientist.powerRating, Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Special Power Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: scientist.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scientist.primaryColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: scientist.primaryColor, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ESPECIAL: ${scientist.specialAbilityName}',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: scientist.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Short Bio
            SizedBox(
              height: 44,
              child: Text(
                scientist.shortBio,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Select / Launch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchScientist(scientist),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? scientist.primaryColor : Colors.white.withOpacity(0.08),
                  foregroundColor: isSelected ? Colors.black : Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isSelected ? 8 : 0,
                  shadowColor: isSelected ? scientist.primaryColor.withOpacity(0.6) : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.play_arrow : Icons.sports_esports,
                      size: 18,
                      color: isSelected ? Colors.black : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSelected ? 'DECOLAR (ESPAÇO)' : 'SELECIONAR',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: isSelected ? Colors.black : Colors.white70,
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

  Widget _buildMiniStat(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final active = index < value;
            return Container(
              width: 5,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: active ? color : Colors.white12,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InlineBullet {
  Offset pos;
  Offset vel;
  Color color;
  double radius;
  double life;
  bool isBomb;

  _InlineBullet({
    required this.pos,
    required this.vel,
    required this.color,
    required this.radius,
    required this.life,
    this.isBomb = false,
  });
}

class _InlineSpark {
  Offset pos;
  Offset vel;
  Color color;
  double life;

  _InlineSpark({
    required this.pos,
    required this.vel,
    required this.color,
    required this.life,
  });
}

class _InlineViewportPainter extends CustomPainter {
  final Scientist scientist;
  final bool isSelected;
  final List<_InlineBullet> bullets;
  final List<_InlineSpark> sparks;
  final Offset asteroidPos;
  final bool asteroidFlash;

  _InlineViewportPainter({
    required this.scientist,
    required this.isSelected,
    required this.bullets,
    required this.sparks,
    required this.asteroidPos,
    required this.asteroidFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 240.0;
    final scaleY = size.height / 82.0;

    // Draw Subtle Space Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Target Rock if active
    if (isSelected) {
      final mappedAsteroid = Offset(asteroidPos.dx * scaleX, asteroidPos.dy * scaleY);
      final rockFill = Paint()
        ..color = asteroidFlash ? Colors.white : Colors.grey[800]!
        ..style = PaintingStyle.fill;
      final rockBorder = Paint()
        ..color = asteroidFlash ? Colors.yellowAccent : Colors.grey[500]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(mappedAsteroid, 10.0 * scaleX, rockFill);
      canvas.drawCircle(mappedAsteroid, 10.0 * scaleX, rockBorder);
    }

    // Draw Ship Silhouette at center bottom
    final shipCenter = Offset(size.width / 2, size.height - 14);
    final shipPaint = Paint()
      ..color = scientist.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final fillPaint = Paint()
      ..color = scientist.primaryColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final path = Path();
    switch (scientist.shipDesign) {
      case ShipDesign.deltaJet:
        path.moveTo(shipCenter.dx, shipCenter.dy - 12);
        path.lineTo(shipCenter.dx - 10, shipCenter.dy + 8);
        path.lineTo(shipCenter.dx - 4, shipCenter.dy + 4);
        path.lineTo(shipCenter.dx + 4, shipCenter.dy + 4);
        path.lineTo(shipCenter.dx + 10, shipCenter.dy + 8);
        path.close();
        break;
      case ShipDesign.codeApollo:
        path.moveTo(shipCenter.dx, shipCenter.dy - 14);
        path.lineTo(shipCenter.dx - 8, shipCenter.dy + 8);
        path.lineTo(shipCenter.dx, shipCenter.dy + 4);
        path.lineTo(shipCenter.dx + 8, shipCenter.dy + 8);
        path.close();
        break;
      case ShipDesign.hubbleScout:
        path.addRect(Rect.fromCenter(center: shipCenter, width: 8, height: 18));
        path.addRect(Rect.fromCenter(center: Offset(shipCenter.dx - 10, shipCenter.dy), width: 8, height: 6));
        path.addRect(Rect.fromCenter(center: Offset(shipCenter.dx + 10, shipCenter.dy), width: 8, height: 6));
        break;
      case ShipDesign.orbitalTitan:
        path.moveTo(shipCenter.dx - 6, shipCenter.dy - 10);
        path.lineTo(shipCenter.dx + 6, shipCenter.dy - 10);
        path.lineTo(shipCenter.dx + 12, shipCenter.dy + 6);
        path.lineTo(shipCenter.dx - 12, shipCenter.dy + 6);
        path.close();
        break;
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, shipPaint);

    // If selected, draw thruster flame
    if (isSelected) {
      final flamePaint = Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.fill;
      final flamePath = Path()
        ..moveTo(shipCenter.dx - 3, shipCenter.dy + 6)
        ..lineTo(shipCenter.dx + 3, shipCenter.dy + 6)
        ..lineTo(shipCenter.dx, shipCenter.dy + 12)
        ..close();
      canvas.drawPath(flamePath, flamePaint);
    }

    // Draw active simulation bullets
    for (final b in bullets) {
      final bPos = Offset(b.pos.dx * scaleX, b.pos.dy * scaleY);
      final bulletPaint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bPos, b.radius, bulletPaint);

      if (b.isBomb) {
        final glow = Paint()
          ..color = b.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(bPos, b.radius + 3.0, glow);
      }
    }

    // Draw sparks
    for (final s in sparks) {
      final sPos = Offset(s.pos.dx * scaleX, s.pos.dy * scaleY);
      final sparkPaint = Paint()
        ..color = s.color.withOpacity((s.life / 0.3).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sPos, 1.5, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InlineViewportPainter oldDelegate) => true;
}
