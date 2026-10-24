import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/scientist.dart';

class ScientistSelectionOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const ScientistSelectionOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scientists = Scientist.scientists;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    // Top Bar with Back Button and Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            game.changeState(GameState.scienceIntro);
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          tooltip: 'Voltar',
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'ESCOLHA SUA CIENTISTA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Cada cientista comanda uma nave e armamento exclusivo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48), // Balance back button
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Cards Layout (Grid of 4 or Row of 4)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: scientists.map((s) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: _buildScientistCard(context, s),
                              ),
                            )).toList(),
                          );
                        } else {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: scientists.map((s) => SizedBox(
                              width: (constraints.maxWidth - 20) / 2 > 300
                                  ? (constraints.maxWidth - 20) / 2
                                  : constraints.maxWidth,
                              child: _buildScientistCard(context, s),
                            )).toList(),
                          );
                        }
                      },
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

  Widget _buildScientistCard(BuildContext context, Scientist scientist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scientist.primaryColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scientist.primaryColor.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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

          const SizedBox(height: 12),

          // Ship & Weapon Info
          Container(
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

          const SizedBox(height: 14),

          // Select & Launch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                game.playSfx('powerup.wav');
                game.startFairGame(scientist);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scientist.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 6,
                shadowColor: scientist.primaryColor.withOpacity(0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'DECOLAR',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
