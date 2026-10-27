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
  final String weaponStyle;
  final String specialAbilityName;
  final String specialAbilityDesc;
  final int cadenceRating; // 1 to 5
  final int areaRating; // 1 to 5
  final int powerRating; // 1 to 5
  final String kidTip;
  final String launchQuote;
  final String imagePath;
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
    required this.weaponStyle,
    required this.specialAbilityName,
    required this.specialAbilityDesc,
    required this.cadenceRating,
    required this.areaRating,
    required this.powerRating,
    required this.kidTip,
    required this.launchQuote,
    required this.imagePath,
    required this.primaryColor,
    required this.accentColor,
    required this.createWeapon,
  });

  static final List<Scientist> scientists = [
    Scientist(
      id: 'mae_jemison',
      name: 'Mae Jemison',
      role: 'Médica & Astronauta',
      shortBio: '1ª mulher negra no espaço. Pesquisou gravidade zero.',
      funFact: 'Além de médica e astronauta, Mae é dançarina e atuou em Star Trek como oficial da Frota Estelar!',
      shipName: 'Endeavour Bio-Jet',
      shipDesign: ShipDesign.deltaJet,
      weaponId: 'spread_shot',
      weaponName: 'Tiro Dispersor',
      weaponDescription: 'Disparo em leque de 3 projéteis para cobrir amplas áreas do espaço.',
      weaponStyle: 'Disparo Triplo em Leque',
      specialAbilityName: 'Super Dispersor 360°',
      specialAbilityDesc: 'Dispara 3 ondas concêntricas de projéteis cobrindo 360° ao redor da nave + 3s de escudo!',
      cadenceRating: 3,
      areaRating: 5,
      powerRating: 3,
      kidTip: 'Dispara 3 tiros de uma vez só! Ótima para cobrir a tela e acertar sem precisar mirar com precisão.',
      launchQuote: 'Sistemas de propulsão e pesquisa ativos! O espaço pertence a quem ousa explorar. Vamos catalogar essas amostras!',
      imagePath: 'assets/images/scientists/mae_jemison.png',
      primaryColor: const Color(0xFF00E676), // Emerald Green
      accentColor: const Color(0xFF00E5FF), // Light Cyan
      createWeapon: () => SpreadShot(),
    ),
    Scientist(
      id: 'margaret_hamilton',
      name: 'Margaret Hamilton',
      role: 'Cientista da Computação',
      shortBio: 'Criou o software da Apollo 11 que pousou na Lua.',
      funFact: 'Seu software evitou o cancelamento do pouso na Lua ao priorizar tarefas vitais no momento crítico!',
      shipName: 'Apollo Code-1',
      shipDesign: ShipDesign.codeApollo,
      weaponId: 'rapid_fire',
      weaponName: 'Laser Veloz',
      weaponDescription: 'Rajadas rápidas e contínuas de laser, como ciclos de processamento de código.',
      weaponStyle: 'Metralhadora de Laser',
      specialAbilityName: 'Overclock Quântico',
      specialAbilityDesc: 'Disparo radial de 16 lasers em círculo 360° e ativa escudo de 3s!',
      cadenceRating: 5,
      areaRating: 2,
      powerRating: 3,
      kidTip: 'Disparos contínuos e ultrarrápidos! Ideal para quem tem dedo ágil e adora atirar sem parar.',
      launchQuote: 'Sistemas de navegação Apollo online! Cada linha de código foi testada para essa missão. Mantenha o foco, piloto!',
      imagePath: 'assets/images/scientists/margaret_hamilton.png',
      primaryColor: const Color(0xFF2979FF), // Electric Blue
      accentColor: const Color(0xFFFFFFFF), // Pure White
      createWeapon: () => RapidFire(),
    ),
    Scientist(
      id: 'nancy_roman',
      name: 'Nancy Roman',
      role: 'Astrônoma do Hubble',
      shortBio: 'Astrônoma da NASA que liderou a criação do Hubble.',
      funFact: 'Criou clubes de astronomia aos 11 anos e abriu as portas do cosmos ao viabilizar o Telescópio Hubble!',
      shipName: 'Hubble Scout',
      shipDesign: ShipDesign.hubbleScout,
      weaponId: 'blaster',
      weaponName: 'Laser Fotônico',
      weaponDescription: 'Laser concentrado de longo alcance com mira de precisão telescópica.',
      weaponStyle: 'Laser Concentrado',
      specialAbilityName: 'Varredura do Hubble',
      specialAbilityDesc: 'Feixe cósmico frontal e traseiro que limpa os meteoros + escudo de 3s!',
      cadenceRating: 3,
      areaRating: 2,
      powerRating: 4,
      kidTip: 'Tiro rápido e de longo alcance! Destrói meteoros distantes antes que cheguem perto da nave.',
      launchQuote: 'Sensores ópticos e lentes calibradas! Há segredos fantásticos nos esperando entre esses asteroides.',
      imagePath: 'assets/images/scientists/nancy_roman.png',
      primaryColor: const Color(0xFFE040FB), // Cosmic Magenta/Purple
      accentColor: const Color(0xFFFFD700), // Gold
      createWeapon: () => Blaster(),
    ),
    Scientist(
      id: 'peggy_whitson',
      name: 'Peggy Whitson',
      role: 'Comandante da ISS',
      shortBio: 'Comandante da ISS com 665 dias de pesquisas no espaço.',
      funFact: 'Comandou a ISS duas vezes e conduziu pesquisas pioneiras de genética e biologia em órbita!',
      shipName: 'Orbital Station-X',
      shipDesign: ShipDesign.orbitalTitan,
      weaponId: 'bomb_launcher',
      weaponName: 'Lança-Bombas',
      weaponDescription: 'Lança cargas explosivas de alta energia que pulverizam aglomerados de asteroides.',
      weaponStyle: 'Bombas de Plasma Explosivo',
      specialAbilityName: 'Pulso de Plasma Orbital',
      specialAbilityDesc: 'Super explosão em área circular massiva de 160px + escudo de 3s!',
      cadenceRating: 2,
      areaRating: 5,
      powerRating: 5,
      kidTip: 'Lança bombas pesadas que causam uma super explosão, destruindo vários meteoros juntos!',
      launchQuote: 'Comandante pronta na ponte! Já estive mais de 600 dias em órbita: calma nas manobras e cumpra a missão!',
      imagePath: 'assets/images/scientists/peggy_whitson.png',
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
