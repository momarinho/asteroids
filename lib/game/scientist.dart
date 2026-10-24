import 'package:flutter/material.dart';
import 'weapons.dart';

enum ShipDesign {
  deltaJet,     // Mae Jemison: Endeavour Bio-Jet (Aerodynamic delta wings, dual engine lines)
  codeApollo,   // Margaret Hamilton: Apollo Code-1 (Precision angular wedge with shield pylons)
  hubbleScout,  // Nancy Grace Roman: Hubble Scout (Telescope body with solar panel wings)
  orbitalTitan, // Peggy Whitson: Orbital Station-X (Heavy module with reinforced outer hull)
}

class Scientist {
  final String id;
  final String name;
  final String role;
  final String shortBio;
  final String funFact;
  final String shipName;
  final ShipDesign shipDesign;
  final String weaponId;
  final String weaponName;
  final String weaponDescription;
  final Color primaryColor;
  final Color accentColor;
  final Weapon Function() createWeapon;

  const Scientist({
    required this.id,
    required this.name,
    required this.role,
    required this.shortBio,
    required this.funFact,
    required this.shipName,
    required this.shipDesign,
    required this.weaponId,
    required this.weaponName,
    required this.weaponDescription,
    required this.primaryColor,
    required this.accentColor,
    required this.createWeapon,
  });

  static final List<Scientist> scientists = [
    Scientist(
      id: 'mae_jemison',
      name: 'Mae Jemison',
      role: 'Médica & Engenheira Química',
      shortBio: 'Primeira mulher negra no espaço. Pesquisou células e materiais em gravidade zero no ônibus espacial Endeavour.',
      funFact: 'Além de médica e astronauta da NASA, Mae Jemison é dançarina e foi a primeira astronauta real a atuar em Star Trek!',
      shipName: 'Endeavour Bio-Jet',
      shipDesign: ShipDesign.deltaJet,
      weaponId: 'spread_shot',
      weaponName: 'Spread Shot (Dispersor)',
      weaponDescription: 'Disparo em leque de 3 projéteis para cobrir amplas áreas do espaço.',
      primaryColor: const Color(0xFF00E676), // Emerald Green
      accentColor: const Color(0xFF00E5FF), // Light Cyan
      createWeapon: () => SpreadShot(),
    ),
    Scientist(
      id: 'margaret_hamilton',
      name: 'Margaret Hamilton',
      role: 'Cientista da Computação',
      shortBio: 'Liderou a equipe do MIT que criou o software de voo da Apollo 11. Cunhou o termo "Engenharia de Software".',
      funFact: 'Minutos antes do pouso na Lua, o código dela priorizou os processos vitais do radar e salvou a Apollo 11 de abortar!',
      shipName: 'Apollo Code-1',
      shipDesign: ShipDesign.codeApollo,
      weaponId: 'rapid_fire',
      weaponName: 'Rapid Fire (Pulso Veloz)',
      weaponDescription: 'Rajadas rápidas e contínuas de laser, como ciclos de processamento de código.',
      primaryColor: const Color(0xFF2979FF), // Electric Blue
      accentColor: const Color(0xFFFFFFFF), // Pure White
      createWeapon: () => RapidFire(),
    ),
    Scientist(
      id: 'nancy_roman',
      name: 'Nancy Grace Roman',
      role: 'Astrônoma (Mãe do Hubble)',
      shortBio: 'Primeira executiva da NASA e astrônoma pioneira que idealizou e viabilizou o Telescópio Espacial Hubble.',
      funFact: 'Fascinada pelo céu desde a infância, ela montou clubes de astronomia aos 11 anos e abriu as portas do universo com o Hubble!',
      shipName: 'Hubble Scout',
      shipDesign: ShipDesign.hubbleScout,
      weaponId: 'blaster',
      weaponName: 'Blaster Fotônico',
      weaponDescription: 'Laser concentrado de longo alcance com mira de precisão telescópica.',
      primaryColor: const Color(0xFFE040FB), // Cosmic Magenta/Purple
      accentColor: const Color(0xFFFFD700), // Gold
      createWeapon: () => Blaster(),
    ),
    Scientist(
      id: 'peggy_whitson',
      name: 'Peggy Whitson',
      role: 'Bioquímica & Comandante da ISS',
      shortBio: 'Bioquímica recordista com 665 dias no espaço e 10 caminhadas espaciais, conduzindo centenas de testes científicos.',
      funFact: 'Peggy foi a primeira mulher a comandar a Estação Espacial Internacional (ISS) duas vezes e liderou estudos cruciais de genética em órbita!',
      shipName: 'Orbital Station-X',
      shipDesign: ShipDesign.orbitalTitan,
      weaponId: 'bomb_launcher',
      weaponName: 'Bomb Launcher (Pulso de Plasma)',
      weaponDescription: 'Lança cargas explosivas de alta energia que pulverizam aglomerados de asteroides.',
      primaryColor: const Color(0xFFFF6D00), // Solar Orange
      accentColor: const Color(0xFFECEFF1), // Silver
      createWeapon: () => BombLauncher(),
    ),
  ];

  static Scientist get defaultScientist => scientists.first;

  static Scientist findById(String id) {
    return scientists.firstWhere(
      (s) => s.id == id,
      orElse: () => defaultScientist,
    );
  }
}
