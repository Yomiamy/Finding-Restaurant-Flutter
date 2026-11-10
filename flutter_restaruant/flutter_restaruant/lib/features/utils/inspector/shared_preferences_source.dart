import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [KeyValueBrowserSource] 的 SharedPreferences 實作。
class SharedPreferencesSource implements KeyValueBrowserSource {
  SharedPreferencesSource(this._prefs);

  final SharedPreferences _prefs;

  @override
  String get name => 'SharedPreferences';

  @override
  Future<List<KeyValueEntry>> listAll() async {
    try {
      await _prefs.reload();
    } catch (_) {}

    final keys = _prefs.getKeys();
    final entries = <KeyValueEntry>[];
    for (final key in keys) {
      final value = _prefs.get(key);
      final KeyValueType type = switch (value) {
        bool _ => KeyValueType.bool,
        int _ => KeyValueType.int,
        double _ => KeyValueType.double,
        List<String> _ || List<dynamic> _ => KeyValueType.stringList,
        _ => KeyValueType.string,
      };
      entries.add(KeyValueEntry(key: key, value: value, type: type));
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  @override
  Future<void> setValue(String key, Object? value) async {
    switch (value) {
      case final String v:
        await _prefs.setString(key, v);
      case final bool v:
        await _prefs.setBool(key, v);
      case final int v:
        await _prefs.setInt(key, v);
      case final double v:
        await _prefs.setDouble(key, v);
      case final List<String> v:
        await _prefs.setStringList(key, v);
      case final List<dynamic> v:
        await _prefs.setStringList(key, v.map((e) => e.toString()).toList());
      case null:
        await _prefs.remove(key);
      default:
        await _prefs.setString(key, value.toString());
    }
  }

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}
