import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/api_service.dart';

class LeaderboardOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const LeaderboardOverlay({super.key, required this.game});

  @override
  State<LeaderboardOverlay> createState() => _LeaderboardOverlayState();
}

class _LeaderboardOverlayState extends State<LeaderboardOverlay> {
  String _selectedPeriod = 'today'; // 'today' or 'all'
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
            game.participantName = null;
            game.changeState(GameState.scienceIntro);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            game.changeState(GameState.scienceIntro);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
            game.changeState(GameState.scientistSelection);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.tab ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.keyA ||
              event.logicalKey == LogicalKeyboardKey.keyD) {
            setState(() {
              _selectedPeriod = _selectedPeriod == 'today' ? 'all' : 'today';
            });
            game.playSfx('menu_select.wav');
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.offset + 90,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                math.max(0.0, _scrollController.offset - 90),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              width: MediaQuery.of(context).size.width > 680 ? 650 : MediaQuery.of(context).size.width * 0.94,
              height: MediaQuery.of(context).size.height > 520 ? 530 : MediaQuery.of(context).size.height * 0.92,
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.4),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.15),
                    blurRadius: 24.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amberAccent, size: 28),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RANKING DA FEIRA',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'MULHERES NA CIÊNCIA • TOP PILOTOS',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          game.changeState(GameState.scienceIntro);
                        },
                        icon: const Icon(Icons.close, color: Colors.white60),
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Filter Tabs: Hoje vs Todos os Dias
                  Row(
                    children: [
                      _buildTabButton('HOJE', 'today'),
                      const SizedBox(width: 10),
                      _buildTabButton('TODOS OS DIAS (GERAL)', 'all'),
                    ],
                  ),

                  const Divider(color: Colors.white24, height: 20),

                  // Table Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Text(
                            'POS',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'PILOTO',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'CIENTISTA',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'PONTOS',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // High scores table
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ApiService.getFairLeaderboard(period: _selectedPeriod, limit: 10),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                        }

                        final entries = snapshot.data ?? [];
                        if (entries.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhum recorde ainda.\nSeja a primeira a jogar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final username = (entry['username'] ?? 'Astronauta').toString();
                            final scientist = (entry['scientist'] ?? 'Pioneira').toString();
                            final score = (entry['score'] ?? 0) as int;
                            final isCurrent = game.participantName != null &&
                                username.toUpperCase() == game.participantName!.toUpperCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.cyanAccent.withOpacity(0.12)
                                    : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent ? Colors.cyanAccent : Colors.white12,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank number
                                  SizedBox(
                                    width: 38,
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: index == 0
                                            ? Colors.amberAccent
                                            : (index == 1
                                                ? const Color(0xFFCFD8DC)
                                                : (index == 2
                                                    ? const Color(0xFFBCAAA4)
                                                    : Colors.white60)),
                                      ),
                                    ),
                                  ),

                                  // Pilot Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      username.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                        color: isCurrent ? Colors.cyanAccent : Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Scientist Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      scientist,
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Score
                                  Text(
                                    '$score',
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Action Buttons for the Booth Loop
                  Row(
                    children: [
                      // Next Participant Button (Returns to Intro for the next kid in line)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            game.participantName = null;
                            game.changeState(GameState.scienceIntro);
                          },
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text(
                            'PRÓXIMO PARTICIPANTE 🚀',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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

                      // Select another scientist / retry
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            game.changeState(GameState.scientistSelection);
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
                            'CIENTISTAS',
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

                  const SizedBox(height: 12),

                  // Keyboard arcade guide
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard, color: Colors.cyanAccent, size: 14),
                        SizedBox(width: 8),
                        Text(
                          '◄ / ►: MUDAR ABA  •  ▲ / ▼: ROLAR  •  [ESPAÇO / ENTER]: PRÓXIMO PILOTO  •  [ESC]: VOLTAR',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
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
  );
}

  Widget _buildTabButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.cyanAccent : Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
