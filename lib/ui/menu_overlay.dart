import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/api_service.dart';

class MenuOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const MenuOverlay({super.key, required this.game});

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _registerPlayer() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 2 || username.length > 20) {
      setState(() {
        _errorMessage = 'Callsign must be 2 to 20 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profile = await ApiService.registerPlayer(username);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (profile != null) {
        widget.game.playerId = profile['id'];
        widget.game.playerUsername = profile['username'];
        widget.game.playSfx('powerup.wav');
        setState(() {}); // Rebuild to show main menu
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to backend server.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isRegistered = game.playerId != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              width: MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width * 0.92,
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.15),
                    blurRadius: 20.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Title
                  const Text(
                    'ASTEROIDS',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'MULTIPLATFORM EDITION',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      letterSpacing: 4,
                      color: Colors.cyanAccent.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 35),

                  if (!isRegistered) ...[
                    // REGISTRATION FORM (First Launch)
                    const Text(
                      'NEW PILOT REGISTRATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Register your callsign to unlock online global leaderboards and campaign achievements.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      decoration: InputDecoration(
                        hintText: 'ENTER PILOT CALLSIGN',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                        ),
                      ),
                      onSubmitted: (_) => _registerPlayer(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.cyan)
                    else
                      ElevatedButton(
                        onPressed: _registerPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'REGISTER PILOT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                  ] else ...[
                    // MAIN GAME MENU
                    Text(
                      'WELCOME BACK, PILOT ${game.playerUsername?.toUpperCase()}!',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mode Selection Card
                    _buildModeOption(
                      title: 'CLASSIC MODE',
                      description: 'Endless survival with scaling difficulty.',
                      isActive: game.activeMode == 'classic',
                      onTap: () {
                        setState(() {
                          game.activeMode = 'classic';
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildModeOption(
                      title: 'CAMPAIGN MODE',
                      description: 'Progressive levels with credits and an Upgrade Shop.',
                      isActive: game.activeMode == 'campaign',
                      onTap: () {
                        setState(() {
                          game.activeMode = 'campaign';
                        });
                      },
                    ),

                    const SizedBox(height: 35),

                    // Play Button
                    ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('menu');
                        game.overlays.add('weaponSelection');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 50.0),
                        elevation: 10,
                        shadowColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'START GAME',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Settings & Leaderboard Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            game.changeState(GameState.settings);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.white24, width: 1),
                            ),
                          ),
                          child: const Text(
                            'SETTINGS',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            game.changeState(GameState.leaderboard);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.cyanAccent.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1),
                            ),
                          ),
                          child: const Text(
                            'RANKING',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Profile reset button (log out)
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            game.playerId = null;
                            game.playerUsername = null;
                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1),
                            ),
                          ),
                          child: const Text(
                            'RESET PILOT',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildModeOption({
    required String title,
    required String description,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.cyan : Colors.white12,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isActive ? Colors.cyan : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isActive ? Colors.cyanAccent : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 26.0),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
