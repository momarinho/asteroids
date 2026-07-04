import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class WeaponSelectionOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const WeaponSelectionOverlay({super.key, required this.game});

  @override
  State<WeaponSelectionOverlay> createState() => _WeaponSelectionOverlayState();
}

class _WeaponSelectionOverlayState extends State<WeaponSelectionOverlay> {
  int _selectedIndex = 0; // Default to Blaster

  final List<Map<String, dynamic>> _weapons = [
    {
      'name': 'BLASTER',
      'icon': Icons.flash_on,
      'color': Colors.cyanAccent,
      'cooldown': '0.3s',
      'recoil': 'Low',
      'damage': 'Medium',
      'description': 'Standard energy cannon. Highly reliable with minimal recoil.',
    },
    {
      'name': 'SPREAD SHOT',
      'icon': Icons.grain,
      'color': Colors.orangeAccent,
      'cooldown': '0.5s',
      'recoil': 'High',
      'damage': 'High (Close)',
      'description': 'Fires a 3-way shotgun spread. Excellent for close-up crowd control.',
    },
    {
      'name': 'RAPID FIRE',
      'icon': Icons.multiline_chart,
      'color': Colors.yellowAccent,
      'cooldown': '0.15s',
      'recoil': 'Low',
      'damage': 'Low (High DPS)',
      'description': 'Rapid automatic plasma bolts. Shreds asteroids at the cost of precision.',
    },
    {
      'name': 'BOMB LAUNCHER',
      'icon': Icons.adjust,
      'color': Colors.redAccent,
      'cooldown': '1.5s',
      'recoil': 'Extreme',
      'damage': 'Massive (Area)',
      'description': 'Launches slow-moving fusion charges that detonate in a large shockwave.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              width: 750,
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.1),
                    blurRadius: 30.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.cyanAccent, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'SELECT STARTING WEAPON',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      'Mission: ${widget.game.activeMode.toUpperCase()} MODE',
                      style: const TextStyle(
                        color: Colors.grey,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 35),

                  // Cards Layout
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.85,
                    ),
                    itemCount: _weapons.length,
                    itemBuilder: (context, index) {
                      final weapon = _weapons[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(15.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? weapon['color'].withOpacity(0.15)
                                : Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? weapon['color']
                                  : Colors.white24,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: weapon['color'].withOpacity(0.2),
                                      blurRadius: 12.0,
                                      spreadRadius: 1.0,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    weapon['icon'],
                                    color: isSelected ? weapon['color'] : Colors.white60,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    weapon['name'],
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  weapon['description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Specs Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSpec(
                                    label: 'Rate',
                                    value: weapon['cooldown'],
                                    color: weapon['color'],
                                    isSelected: isSelected,
                                  ),
                                  _buildSpec(
                                    label: 'Recoil',
                                    value: weapon['recoil'],
                                    color: weapon['color'],
                                    isSelected: isSelected,
                                  ),
                                  _buildSpec(
                                    label: 'Damage',
                                    value: weapon['damage'].split(' ').first,
                                    color: weapon['color'],
                                    isSelected: isSelected,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Launch & Back Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.game.overlays.remove('weaponSelection');
                            widget.game.overlays.add('menu');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'BACK TO MENU',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.game.selectedWeaponIndex = _selectedIndex;
                            widget.game.overlays.remove('weaponSelection');
                            widget.game.startGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _weapons[_selectedIndex]['color'],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            elevation: 10,
                            shadowColor: _weapons[_selectedIndex]['color'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LAUNCH SYSTEM',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildSpec({
    required String label,
    required String value,
    required Color color,
    required bool isSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? color : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
