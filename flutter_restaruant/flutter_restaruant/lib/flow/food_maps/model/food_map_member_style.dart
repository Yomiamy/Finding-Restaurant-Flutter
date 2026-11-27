import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 依據成員 UID 決定性產生一致的頭像色票、GoogleMap Marker 色相與首字母標記。
abstract final class FoodMapMemberStyle {
  static const List<({Color color, double markerHue})> _palette = [
    (color: Color(0xFFE65100), markerHue: BitmapDescriptor.hueOrange),
    (color: Color(0xFF1565C0), markerHue: BitmapDescriptor.hueAzure),
    (color: Color(0xFF6A1B9A), markerHue: BitmapDescriptor.hueViolet),
    (color: Color(0xFF2E7D32), markerHue: BitmapDescriptor.hueGreen),
    (color: Color(0xFFC2185B), markerHue: BitmapDescriptor.hueRose),
    (color: Color(0xFF00838F), markerHue: BitmapDescriptor.hueCyan),
    (color: Color(0xFFAD1457), markerHue: BitmapDescriptor.hueMagenta),
    (color: Color(0xFFF9A825), markerHue: BitmapDescriptor.hueYellow),
  ];

  static int _stableHash(String uid) =>
      uid.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);

  static Color colorForUid(String uid) =>
      _palette[_stableHash(uid) % _palette.length].color;

  static double markerHueForUid(String uid) =>
      _palette[_stableHash(uid) % _palette.length].markerHue;

  static String initialForName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
