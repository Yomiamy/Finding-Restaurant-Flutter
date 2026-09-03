import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeColor Constants Tests', () {
    test('brand primary matches #D84A20', () {
      expect(ThemeColor.colord84a20, const Color(0xFFD84A20));
      expect(ThemeColor.appPrimary, ThemeColor.colord84a20);
    });

    test('surface background matches #FFFBF7', () {
      expect(ThemeColor.colorfffbf7, const Color(0xFFFFFBF7));
    });

    test('white matches #FFFFFF', () {
      expect(ThemeColor.colorffffff, const Color(0xFFFFFFFF));
    });

    test('transparent matches #00000000', () {
      expect(ThemeColor.color00000000, const Color(0x00000000));
    });

    test('grey matches #9E9E9E', () {
      expect(ThemeColor.color9e9e9e, const Color(0xFF9E9E9E));
    });

    test('red matches #F44336', () {
      expect(ThemeColor.colorf44336, const Color(0xFFF44336));
    });

    test('black54 matches #8A000000', () {
      expect(ThemeColor.color8a000000, const Color(0x8A000000));
    });
  });
}
