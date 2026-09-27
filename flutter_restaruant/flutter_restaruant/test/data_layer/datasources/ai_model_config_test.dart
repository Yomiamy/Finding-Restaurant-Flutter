import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_restaruant/data_layer/datasources/ai_model_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late _MockRemoteConfig rc;
  late AiModelConfig config;

  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    );
  });

  setUp(() {
    rc = _MockRemoteConfig();
    when(() => rc.getString(any())).thenReturn('');
    config = AiModelConfig(remoteConfig: rc);
  });

  void stub(String key, String value) =>
      when(() => rc.getString(key)).thenReturn(value);

  group('AiModelConfig 預設值', () {
    void expectAllDefaults(AiModelConfig c) {
      expect(c.aiFoodieModel, 'gemini-3.5-flash-lite');
      expect(c.menuVisionModel, 'gemini-3.5-flash-lite');
      expect(c.aiFoodieTemperature, 0.2);
      expect(
        c.aiFoodieSystemInstruction,
        AiModelConfig.defaultAiFoodieSystemInstruction,
      );
      expect(
        c.menuVisionSystemInstruction,
        AiModelConfig.defaultMenuVisionSystemInstruction,
      );
    }

    test('沒有遠端值（getString 回傳空字串）時全部回傳預設值', () {
      expectAllDefaults(config);
    });

    test('讀取時丟 Exception 時全部回傳預設值、不外拋', () {
      when(
        () => rc.getString(any()),
      ).thenThrow(FirebaseException(plugin: 'remote_config'));
      expectAllDefaults(config);
    });

    test('未注入且 Firebase 未初始化時全部回傳預設值、不外拋', () {
      expectAllDefaults(AiModelConfig());
    });
  });

  group('AiModelConfig 遠端值', () {
    test('合法遠端值逐字回傳', () {
      stub('ai_foodie_model', 'gemini-x');
      stub('menu_vision_model', 'gemini-y');
      stub('ai_foodie_system_instruction', ' A \n');
      stub('menu_vision_system_instruction', 'B');
      stub('ai_foodie_temperature', '0.7');

      expect(config.aiFoodieModel, 'gemini-x');
      expect(config.menuVisionModel, 'gemini-y');
      expect(config.aiFoodieSystemInstruction, ' A \n');
      expect(config.menuVisionSystemInstruction, 'B');
      expect(config.aiFoodieTemperature, 0.7);
    });

    test('temperature 邊界 0 與 2 是合法值', () {
      stub('ai_foodie_temperature', '0');
      expect(config.aiFoodieTemperature, 0.0);
      stub('ai_foodie_temperature', '2');
      expect(config.aiFoodieTemperature, 2.0);
    });

    test('字串參數全空白時回退預設值', () {
      stub('ai_foodie_model', '   ');
      stub('menu_vision_system_instruction', '\n\t');
      expect(config.aiFoodieModel, AiModelConfig.defaultModel);
      expect(
        config.menuVisionSystemInstruction,
        AiModelConfig.defaultMenuVisionSystemInstruction,
      );
    });

    test('temperature 全空白記 warning，空字串不記', () {
      final logs = <String>[];
      double read(String raw) {
        stub('ai_foodie_temperature', raw);
        return runZoned(
          () => config.aiFoodieTemperature,
          zoneSpecification: ZoneSpecification(
            print: (_, _, _, line) => logs.add(line),
          ),
        );
      }

      expect(read(''), 0.2);
      expect(logs.where((l) => l.contains('ai_foodie_temperature')), isEmpty);
      expect(read('  '), 0.2);
      expect(
        logs.where((l) => l.contains('ai_foodie_temperature')),
        isNotEmpty,
      );
    });

    for (final raw in ['abc', '-0.1', '2.1', 'NaN', 'Infinity']) {
      test('temperature 非法值 "$raw" 回退 0.2', () {
        stub('ai_foodie_temperature', raw);
        expect(config.aiFoodieTemperature, 0.2);
      });
    }
  });

  group('AiModelConfig.fetchAndActivate', () {
    setUp(() {
      when(() => rc.setConfigSettings(any())).thenAnswer((_) async {});
    });

    test('debug 模式使用 0 間隔與 10 秒逾時，並呼叫 fetchAndActivate', () async {
      when(() => rc.fetchAndActivate()).thenAnswer((_) async => true);

      await config.fetchAndActivate();

      final settings =
          verify(() => rc.setConfigSettings(captureAny())).captured.single
              as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, Duration.zero);
      expect(settings.fetchTimeout, const Duration(seconds: 10));
      verify(() => rc.fetchAndActivate()).called(1);
    });

    test('fetch 丟 Exception 時正常完成、不外拋', () async {
      when(
        () => rc.fetchAndActivate(),
      ).thenThrow(FirebaseException(plugin: 'remote_config'));

      await expectLater(config.fetchAndActivate(), completes);
    });
  });
}
