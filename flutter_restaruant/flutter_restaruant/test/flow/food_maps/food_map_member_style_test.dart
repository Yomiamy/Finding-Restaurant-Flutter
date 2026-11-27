import 'package:flutter_restaruant/flow/food_maps/model/food_map_member_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodMapMemberStyle', () {
    test('returns deterministic color and markerHue for identical uid', () {
      final color1 = FoodMapMemberStyle.colorForUid('uid-alice');
      final color2 = FoodMapMemberStyle.colorForUid('uid-alice');
      final hue1 = FoodMapMemberStyle.markerHueForUid('uid-alice');
      final hue2 = FoodMapMemberStyle.markerHueForUid('uid-alice');

      expect(color1, color2);
      expect(hue1, hue2);
    });

    test('distinguishes multiple members across palette', () {
      final hues = {
        FoodMapMemberStyle.markerHueForUid('user-1'),
        FoodMapMemberStyle.markerHueForUid('user-2'),
        FoodMapMemberStyle.markerHueForUid('user-3'),
        FoodMapMemberStyle.markerHueForUid('user-4'),
      };
      expect(hues.length, greaterThan(1));
    });

    test('initialForName uppercases first rune and falls back to ?', () {
      expect(FoodMapMemberStyle.initialForName('  alice  '), 'A');
      expect(FoodMapMemberStyle.initialForName('小明'), '小');
      expect(FoodMapMemberStyle.initialForName('   '), '?');
    });
  });
}
