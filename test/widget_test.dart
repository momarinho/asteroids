import 'package:flutter_test/flutter_test.dart';
import 'package:asteroids/game/scientist.dart';

void main() {
  group('Scientist Model Tests', () {
    test('Scientists list has 4 historical pioneers', () {
      expect(Scientist.scientists.length, 4);

      final ids = Scientist.scientists.map((s) => s.id).toSet();
      expect(ids.contains('mae_jemison'), isTrue);
      expect(ids.contains('margaret_hamilton'), isTrue);
      expect(ids.contains('nancy_roman'), isTrue);
      expect(ids.contains('peggy_whitson'), isTrue);
    });

    test('Each scientist has unique weapon and ship design', () {
      final weaponIds = Scientist.scientists.map((s) => s.weaponId).toSet();
      expect(weaponIds.length, 4);

      final shipDesigns = Scientist.scientists.map((s) => s.shipDesign).toSet();
      expect(shipDesigns.length, 4);

      for (final scientist in Scientist.scientists) {
        final weapon = scientist.createWeapon();
        expect(weapon, isNotNull);
        expect(scientist.name.isNotEmpty, isTrue);
        expect(scientist.funFact.isNotEmpty, isTrue);
      }
    });

    test('Scientist findById returns correct scientist or default', () {
      final mae = Scientist.findById('mae_jemison');
      expect(mae.name, 'Mae Jemison');

      final unknown = Scientist.findById('unknown_id');
      expect(unknown.id, Scientist.defaultScientist.id);
    });
  });
}
