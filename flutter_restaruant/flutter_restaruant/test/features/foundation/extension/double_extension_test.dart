import 'package:flutter_restaruant/features/foundation/extension/extension_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoubleExtension.formatDistance', () {
    test('null 距離回傳空字串', () {
      const double? distance = null;
      expect(distance.formatDistance(), '');
    });

    test('< 1000m 回傳整數公尺字串', () {
      expect(0.0.formatDistance(), '0 m');
      expect(583.37.formatDistance(), '583 m');
      expect(999.9.formatDistance(), '999 m');
    });

    test('>= 1000m 回傳一位小數公里字串', () {
      expect(1000.0.formatDistance(), '1.0 km');
      expect(1523.47.formatDistance(), '1.5 km');
      expect(12500.0.formatDistance(), '12.5 km');
    });
  });
}
