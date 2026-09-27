# Implementation Plan：Firebase Remote Config 動態模型控制（AI 參數遠端化）

> 關聯規格：[`docs/features/2026-09-27-remote-config-ai-model-control.md`](../features/2026-09-27-remote-config-ai-model-control.md)（v1，使用者已確認）
> 建立日期：2026-09-28
> 狀態：草稿（待確認）
> 基準：`main` @ `e307b5c`
> 預估：0.5d 以內（4 個實作任務 + 1 個收尾驗證）

規格 §8 待決事項的定案（使用者採預設建議）：

| # | 項目 | 定案 |
|---|------|------|
| 1 | fetch 間隔 | release `12h`；`kDebugMode` 時 `Duration.zero`；`fetchTimeout` 10 秒 |
| 2 | 生效時機 | 啟動時 `fetchAndActivate()`（fetch 完立即 activate）；`GenerativeModel` 維持每次呼叫才建立 |
| 3 | Console 參數 | 使用者手動建立，清單見 §7 |
| 4 | 模型 key | 分開 `ai_foodie_model`／`menu_vision_model`，預設值引用同一個 Dart 常數 |
| 8 | `setDefaults` | **不呼叫**（理由見 §1.3） |

---

## 0. 已查證的事實（計畫依據）

| 事實 | 來源 | 對計畫的影響 |
|------|------|--------------|
| `firebase_remote_config 6.7.0` 依賴 `firebase_core ^4.14.0`；lock 目前 `firebase_core 4.15.0` | pub.dev archive 的 `pubspec.yaml`、`pubspec.lock` | `flutter pub add` 不應讓 `firebase_core` 升降級（T1 驗收） |
| `FirebaseRemoteConfig` 是一般 `class`（非 `final`/`sealed`），建構式私有；`instance` getter 呼叫 `Firebase.app()` | `firebase_remote_config-6.7.0/lib/src/firebase_remote_config.dart:12,33-35` | 可用 mocktail `implements`；**只有讀 `instance` 那一刻**才碰 Firebase |
| `getString(key)`：key 不存在回傳 `''`；`getDouble(key)`：key 不存在回傳 `0.0` | 同檔 `:135-145` 的 doc comment | 只用 `getString`，temperature 自己 `double.tryParse`，就能避開「`0.0` 究竟是合法值還是解析失敗」的歧義 |
| `setConfigSettings(RemoteConfigSettings(fetchTimeout:, minimumFetchInterval:))`，兩個參數皆 `required` | `firebase_remote_config_platform_interface-3.0.7/lib/src/remote_config_settings.dart` | T2 程式碼直接照用 |
| Firebase 未初始化時 `Firebase.app()` 丟 `FirebaseException(plugin: 'core', code: 'no-app')`，是 `Exception` | `firebase_core_platform_interface-8.1.1/lib/src/method_channel/method_channel_firebase.dart:186-191`、`firebase_core_exceptions.dart:10-15` | 存取點以 `on Exception` 接住後回傳預設值，不需要額外判斷「Firebase 有沒有初始化」 |
| `FirebaseAI` 是一般 `class`，可 mock；但 `GenerativeModel` 是 `final class`，無法 mock 或 `implements` | `firebase_ai-4.0.0/lib/src/firebase_ai.dart:30`、`generative_model.dart:22` | repo 測試讓 mock 的 `ai.generativeModel(...)` 直接 `thenThrow(Exception)`，再用 `verify(...).captured` 取出傳入參數；不需要產生 `GenerativeModel` 實例 |
| `Content.system(s)` = `Content('system', [TextPart(s)])`；`GenerationConfig.temperature` 為公開欄位 | `firebase_ai-4.0.0/lib/src/content.dart:65-66`、`api.dart:1232` | 測試可斷言 `(sys.parts.single as TextPart).text` 與 `cfg.temperature` |
| `AiFoodieRepo.askAssistant` 在 `on Exception` 內降級；`MenuVisionRepo._analyze` 不捕捉，例外往上拋 | `ai_foodie_repo.dart:181-187`、`menu_vision_repo.dart:135-147` | AI 覓食測試呼叫後直接 `verify`；拍菜單測試要 `expectLater(..., throwsException)` |
| 測試全域**沒有**初始化 Firebase；`test/` 沒有任何 `setupFirebaseCoreMocks`／`initializeApp` | `rtk proxy grep -rln "setupFirebase\|initializeApp" test` 無結果 | 建構 repo、建構存取點都不能碰 Firebase |
| `di_test.dart:95-98` 會從 GetIt 解析 `MenuVisionRepository`（即執行 `MenuVisionRepo()`） | 讀檔 | repo 預設建立存取點時不得碰 Firebase |
| `'gemini-3.5-flash-lite'` 在 lib/test 只有兩處；`systemInstruction` 在 lib/test 除了兩個 repo 以外沒有其他引用 | `rtk proxy grep -rn "gemini-3.5\|systemInstruction" lib test` | 刪掉 `MenuVisionRepo.systemInstruction`（public）不會打斷任何呼叫端 |
| `ai_foodie_repo.dart` 的 `_systemInstruction` 內文在 L29–L98（L28 開頭、L99 `''';` 結尾）；`menu_vision_repo.dart` 在 L29–L32 | `awk` 實查 | T2 逐字搬移、T3 刪除，T3 驗收用 `diff` 比對原文 |
| `main.dart` 的初始化 `try` 使用裸 `catch (e, st)`（既有程式） | `lib/main.dart:58` | 本計畫不改動它，新的 fetch 自己處理例外（`on Exception`） |

---

## 1. 實作方向與 trade-off

### 1.1 存取點如何交給 repo（本次最重要的設計判斷）

| 方案 | 做法 | 對既有測試 | 結論 |
|------|------|-----------|------|
| **A（採用）repo 可選參數 + 預設 `AiModelConfig()`** | `AiFoodieRepo({..., AiModelConfig? modelConfig})`，初始化列 `_modelConfig = modelConfig ?? AiModelConfig()`；`AiModelConfig()` 只存一個可為 null 的 `FirebaseRemoteConfig?`，**每次讀取時**才解析 `FirebaseRemoteConfig.instance` | `AiFoodieRepo()`、`MenuVisionRepo(...)` 照常可用，建構時零 Firebase 存取 | 跟 repo 既有的 `_firebaseAI ?? FirebaseAI.googleAI()` 寫法一致；測試可注入 mock；零破壞 |
| B repo 預設從 `getIt<AiModelConfig>()` 取 | `injection.dart` 註冊，repo 建構時 `modelConfig ?? getIt<AiModelConfig>()` | `ai_foodie_repo_test.dart:252,268` 的 `AiFoodieRepo()` 沒呼叫 `setupInjection()`，建構時就會丟 `StateError` | 否決：repo 反向依賴 service locator，還會弄壞既有測試 |
| C 在 `injection.dart` 建好後以 required 參數傳入 | `AiFoodieRepo(modelConfig: ...)` 必填 | 所有 `AiFoodieRepo(...)`／`MenuVisionRepo(...)` 呼叫點都要改 | 否決：違反驗收條件 8 |

**不註冊到 GetIt，也不改 `injection.dart`**（與規格 §4.3「`injection.dart` 註冊存取點」不同，請確認）。原因：`AiModelConfig` 本身沒有狀態，真正的狀態在 SDK 的 `FirebaseRemoteConfig.instance` singleton 裡。repo 預設建立的實例和 `main.dart` 用來觸發 fetch 的實例，讀寫的都是同一份資料。註冊到 GetIt 只會多一行儀式碼，還會多出「repo 用 GetIt 的實例，還是用預設建的實例」這種不必要的選擇。

### 1.2 非法值判斷：只用 `getString`

| 方案 | temperature 的判斷 | 缺點 |
|------|--------------------|------|
| **A（採用）`getString` + `double.tryParse`** | 原始字串 `trim` 後為空 → 預設；`tryParse` 回傳 null、NaN 或超出 `[0, 2]` → 預設並記 `Logger().w` | 無法分辨「key 不存在」和「Console 設成空字串」，兩者都會安靜地回到預設值（見下方規則） |
| B `getValue(key).source` + `getDouble` | `source == ValueSource.valueRemote` 才相信 `getDouble` | `getDouble` 對非數字仍回傳 `0.0`，還是得解析原始字串，等於做兩次；mock 要多 stub `RemoteConfigValue` |
| C `setDefaults` + `getDouble` | 依賴 SDK 預設值 | `0.0` 的歧義完全沒解決 |

**統一規則**（5 個 getter 共用兩個私有 helper，沒有個別特例）：

| 原始字串 `raw`（來自 `getString`） | String 參數（model／instruction） | temperature |
|---|---|---|
| 讀取時丟 `Exception`（例如 Firebase 未初始化） | `Logger().w` + 預設值 | `Logger().w` + 預設值 |
| `''`（key 不存在、尚未 fetch、Console 值為空） | 預設值，**不記 log** | 預設值，**不記 log** |
| 非空但 `trim()` 後為空（全空白） | `Logger().w` + 預設值 | `Logger().w` + 預設值 |
| 無法解析為數字、NaN、`< 0.0` 或 `> 2.0` | — | `Logger().w` + 預設值 |
| 其他 | **逐字**回傳 `raw`（不 trim，符合規格 §8-6） | 解析後的數值（`0.0`、`2.0` 是合法邊界值） |

`''` 不記 log：這是首次啟動、Console 沒建參數時的正常狀態。如果每次 AI 請求都記 warning，log 只會變成噪音。

### 1.3 `setDefaults`：不呼叫

getter 已經會在 `''` 時退回 Dart 常數，`setDefaults` 在功能上完全多餘。它唯一的好處是「debug 工具看得到預設值」，代價則是多一個非同步呼叫，以及第二條預設值路徑（驗收條件 2 要求預設值只有一個來源）。不呼叫的話，預設值自然只存在於 `AiModelConfig` 的 `static const`。

### 1.4 fetch 不阻塞啟動

`AiModelConfig.fetchAndActivate()` 自己用 `on Exception catch (e, st)` 接住錯誤並呼叫 `Logger().e`，因此永遠不會以 Exception 失敗結束。`main.dart` 只加一行 `unawaited(AiModelConfig().fetchAndActivate());`，位置在 **App Check `activate` 之後、`FcmManager().init()` 之前**，並且放在既有的 `try` 內：

- 在 `Future.wait`（含 `Firebase.initializeApp`）成功之後 → 只有 Firebase 已初始化時才會觸發（規格風險 5）。
- 在 App Check 之後 → 日後如果在 Console 對 Remote Config 開啟 App Check enforcement，fetch 請求也會帶上 token。
- `unawaited` → `runApp` 不必等待；和 `FcmManager().init()` 並行。
- 捕捉 `on Exception`，不捕捉 `Error`（flutter-styles §6.1）。

---

## 2. 資料結構：`AiModelConfig`

檔案：`lib/data_layer/datasources/ai_model_config.dart`（新增，並由 `datasources_barrel.dart` export）

- 單一具體類別，不設計 interface，也不做通用 config 框架。
- 對外：5 個型別化 getter、1 個 `fetchAndActivate()`、4 個 `static const` 預設值（測試會引用）。
- Remote Config key 全部是 `static const` private，`lib/` 其他地方看不到 key 字串（驗收條件 5）。
- 不快取任何值：每次 getter 都呼叫 `getString`（SDK 從記憶體讀取，成本可以忽略）。這樣 activate 後的**下一次讀取**就會拿到新值（驗收條件 4）。

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Gemini 模型參數的唯一來源。
///
/// Remote Config 有合法值時使用遠端值，否則使用本類別的預設常數。
/// 每次讀取都即時查詢、不快取；建構時不觸碰 Firebase（可在未初始化 Firebase 的測試中建構）。
class AiModelConfig {
  AiModelConfig({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _remoteConfig;

  static const String defaultModel = 'gemini-3.5-flash-lite';
  static const double defaultAiFoodieTemperature = 0.2;
  static const String defaultAiFoodieSystemInstruction = '''
<逐字搬移 ai_foodie_repo.dart L29–L98>
''';
  static const String defaultMenuVisionSystemInstruction = '''
你是一位資深星級主廚與食品安全檢驗專家。請仔細審視傳入的菜單照片：
1. 辨識所有可識別菜色名稱與價格。
2. 進行成分拆解，明確標註是否有致敏成分 (包含堅果、花生、蛋、牛奶、小麥麩質、甲殼類海鮮、大豆)。
3. 一律依據定義的 JSON Schema 輸出純 JSON，不可有任何額外的對話或說明。
''';

  static const String _aiFoodieModelKey = 'ai_foodie_model';
  static const String _aiFoodieTemperatureKey = 'ai_foodie_temperature';
  static const String _aiFoodieSystemInstructionKey =
      'ai_foodie_system_instruction';
  static const String _menuVisionModelKey = 'menu_vision_model';
  static const String _menuVisionSystemInstructionKey =
      'menu_vision_system_instruction';

  static const double _minTemperature = 0.0;
  static const double _maxTemperature = 2.0;
  static const Duration _fetchTimeout = Duration(seconds: 10);
  static const Duration _releaseFetchInterval = Duration(hours: 12);

  String get aiFoodieModel => _string(_aiFoodieModelKey, defaultModel);

  double get aiFoodieTemperature => _temperature(
    _aiFoodieTemperatureKey,
    defaultAiFoodieTemperature,
  );

  String get aiFoodieSystemInstruction => _string(
    _aiFoodieSystemInstructionKey,
    defaultAiFoodieSystemInstruction,
  );

  String get menuVisionModel => _string(_menuVisionModelKey, defaultModel);

  String get menuVisionSystemInstruction => _string(
    _menuVisionSystemInstructionKey,
    defaultMenuVisionSystemInstruction,
  );

  /// 啟動時呼叫一次：套用 fetch 設定後 fetch 並立即 activate。
  ///
  /// 失敗只記錄、不外拋，AI 參數沿用目前已 activate 的值或預設值。
  Future<void> fetchAndActivate() async {
    try {
      final rc = _remoteConfig ?? FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : _releaseFetchInterval,
        ),
      );
      await rc.fetchAndActivate();
    } on Exception catch (e, st) {
      Logger().e(
        'Remote config fetch failed, AI parameters keep current values',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _read(String key) {
    try {
      return (_remoteConfig ?? FirebaseRemoteConfig.instance).getString(key);
    } on Exception catch (e, st) {
      Logger().w(
        'Remote config unavailable for $key, using default',
        error: e,
        stackTrace: st,
      );
      return '';
    }
  }

  String _string(String key, String fallback) {
    final raw = _read(key);
    if (raw.trim().isNotEmpty) return raw;
    if (raw.isNotEmpty) Logger().w('Blank remote value for $key, using default');
    return fallback;
  }

  double _temperature(String key, double fallback) {
    final raw = _read(key).trim();
    if (raw.isEmpty) return fallback;
    final value = double.tryParse(raw);
    // NaN 的任何比較都是 false，會自然落到預設值。
    if (value != null && value >= _minTemperature && value <= _maxTemperature) {
      return value;
    }
    Logger().w('Invalid remote value for $key: "$raw", using default');
    return fallback;
  }
}
```

注意：`_temperature` 的全空白字串在 `trim()` 後變成 `''`，會安靜地回到預設值，**不記 log**。這和 §1.2 表格第 3 列（全空白要記 `Logger().w`）有一點出入。temperature 在 Console 是 Number 型別，實務上填不出全空白，因此不為了這個情況多寫一個分支；T2 的測試也只斷言回傳值，不斷言 log。

---

## 3. 異動檔案

| 檔案 | 動作 | 任務 |
|------|------|------|
| `pubspec.yaml`、`pubspec.lock` | 新增 `firebase_remote_config: ^6.7.0` | T1 |
| `ios/Podfile.lock` | `pod install` 後更新（如果有變動） | T1 |
| `lib/data_layer/datasources/ai_model_config.dart` | 新增 | T2 |
| `lib/data_layer/datasources/datasources_barrel.dart` | 新增一行 export | T2 |
| `test/data_layer/datasources/ai_model_config_test.dart` | 新增 | T2 |
| `lib/data_layer/repositories/ai_foodie_repo.dart` | 修改：新增 `modelConfig` 參數，刪除 `_systemInstruction`，model 參數改讀 getter | T3 |
| `lib/data_layer/repositories/menu_vision_repo.dart` | 修改：同上，刪除 `systemInstruction` | T3 |
| `test/data_layer/ai_foodie_repo_test.dart` | 修改：只**新增** group，既有案例零修改 | T3 |
| `test/data_layer/menu_vision_repo_test.dart` | 修改：只**新增** group，既有案例零修改 | T3 |
| `lib/main.dart` | 修改：新增 1 行 `unawaited(...)` 與 1 行 import | T4 |

`lib/di/injection.dart` **不修改**（§1.1）。

---

## 4. 任務總覽與並行判斷

| # | 標題 | 寫入路徑 | 依賴 | 可並行 | 難度 |
|---|------|----------|------|--------|------|
| T1 | 新增 `firebase_remote_config` 依賴 | `pubspec.yaml`、`pubspec.lock`、`ios/Podfile.lock` | — | 否（所有任務的前提） | 機械性 |
| T2 | `AiModelConfig` 存取點與非法值回退（TDD） | `lib/data_layer/datasources/ai_model_config.dart`（新）、`lib/data_layer/datasources/datasources_barrel.dart`、`test/data_layer/datasources/ai_model_config_test.dart`（新） | T1 | 否 | 設計判斷 |
| T3 | 兩個 repo 改從 `AiModelConfig` 取值（TDD） | `lib/data_layer/repositories/ai_foodie_repo.dart`、`lib/data_layer/repositories/menu_vision_repo.dart`、`test/data_layer/ai_foodie_repo_test.dart`、`test/data_layer/menu_vision_repo_test.dart` | T2 | 可與 T4 並行 | 整合 |
| T4 | 啟動時非阻塞 fetch | `lib/main.dart` | T2 | 可與 T3 並行 | 整合 |
| T5 | 收尾驗證 | 不寫入 | T1–T4 | 否 | 機械性 |

關鍵路徑：T1 → T2 → T3 → T5。T3 與 T4 的寫入路徑不重疊，也沒有互相引用（T4 只用到 T2 的 `AiModelConfig`）。

**鐵律**：
1. 既有測試的斷言一條都不改；`test/data_layer/*_repo_test.dart` 只能新增 group，不能修改既有案例。
2. 每個任務結束時，`flutter analyze` 零 issue，並且跑過該任務列出的驗收指令。
3. 開工前先跑一次 `flutter test`，記下基準通過數 N（T5 用來比對）。
4. 每個任務可以單獨 commit；要 commit 需經使用者授權。

---

## 5. 任務細節

### T1：新增 `firebase_remote_config` 依賴

**步驟 1**：
```bash
rtk flutter pub add firebase_remote_config
```

**步驟 2**：確認 `pubspec.yaml` 新增的那一行是 `firebase_remote_config: ^6.7.0`，並且放在 `firebase_app_check` 下一行、比照鄰近行加上註解：
```yaml
  firebase_remote_config: ^6.7.0 # Firebase Remote Config 遠端參數（AI 模型設定）
```

**步驟 3（iOS）**：
```bash
cd ios && pod install && cd ..
```

**驗收**：
```bash
rtk proxy grep -n "firebase_remote_config" pubspec.yaml     # 1 行，^6.7.0
rtk git diff pubspec.lock | rtk proxy grep -n "firebase_core:" # 期望：沒有輸出（firebase_core 維持 4.15.0）
rtk flutter analyze                                          # No issues found
```
如果 resolver 選出的版本會讓 `firebase_core` 升降級，就停下來回報，不要強行指定版本（規格 §7）。

---

### T2：`AiModelConfig` 存取點與非法值回退（依賴 T1）

**步驟 1（先寫測試，紅燈）**：新增 `test/data_layer/datasources/ai_model_config_test.dart`

```dart
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
```

說明：
- mocktail 以最後定義的 stub 優先，所以 `setUp` 裡的 `any()` 兜底 stub 會被各案例的 `stub(key, ...)` 蓋掉。
- 測試直接寫出 key 字串（`'ai_foodie_model'` 等）是刻意的：這組字串就是 §7 Console 清單。之後有人改了 lib 裡的 key 常數，測試會失敗，避免 key 和 Console 無聲地脫鉤（規格風險 4）。
- `flutter test` 在 debug 模式下執行，`kDebugMode == true`，所以斷言 `Duration.zero`。release 的 12h 分支不寫測試（`kDebugMode` 是編譯期常數，測試環境改不動）。
- 「未注入且 Firebase 未初始化」這個案例走的是真實路徑：`FirebaseRemoteConfig.instance` → `Firebase.app()` → `FirebaseException('no-app')`（§0 已查證）。如果在測試環境因為 platform channel 丟出非 `Exception` 的錯誤，就刪掉這個案例、只保留前一個 mock 丟例外的案例，並回報實際錯誤。不要為了讓它通過而改成捕捉 `Error`。

```bash
rtk flutter test test/data_layer/datasources/ai_model_config_test.dart   # 紅燈：AiModelConfig 不存在
```

**步驟 2（綠燈）**：依 §2 新增 `lib/data_layer/datasources/ai_model_config.dart`。`defaultAiFoodieSystemInstruction` 的內文**逐字複製** `lib/data_layer/repositories/ai_foodie_repo.dart` 的 L29–L98（不含 L28 的宣告行與 L99 的 `''';`）。這一步只複製、不刪除 repo 裡的原文，刪除交給 T3。

**步驟 3**：在 `lib/data_layer/datasources/datasources_barrel.dart` 加上：
```dart
export 'ai_model_config.dart';
```

**驗收**：
```bash
dart format lib/data_layer/datasources/ test/data_layer/datasources/ai_model_config_test.dart
rtk flutter analyze                                                        # No issues found
rtk flutter test test/data_layer/datasources/ai_model_config_test.dart    # 全綠（13 個案例）
diff <(git show HEAD:lib/data_layer/repositories/ai_foodie_repo.dart | sed -n '29,98p') \
     <(awk "/defaultAiFoodieSystemInstruction = '''/{f=1;next} f&&/^''';/{exit} f" lib/data_layer/datasources/ai_model_config.dart)
# 期望：沒有輸出（逐字一致）
```

---

### T3：兩個 repo 改從 `AiModelConfig` 取值（依賴 T2，可與 T4 並行）

**步驟 1（先寫測試，紅燈）**

`test/data_layer/ai_foodie_repo_test.dart`：
- import 區（`package:` 區塊）加上：
  ```dart
  import 'package:firebase_remote_config/firebase_remote_config.dart';
  import 'package:mocktail/mocktail.dart';
  ```
- `void main()` 之前加上：
  ```dart
  class _MockFirebaseAI extends Mock implements FirebaseAI {}

  class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}
  ```
- 在 `main()` 最後新增一個 group：
  ```dart
  group('AiFoodieRepo 讀取 AiModelConfig', () {
    late _MockFirebaseAI ai;
    late _MockRemoteConfig rc;
    late AiFoodieRepo repo;

    setUpAll(() {
      registerFallbackValue(Content.system(''));
      registerFallbackValue(GenerationConfig());
    });

    setUp(() {
      ai = _MockFirebaseAI();
      rc = _MockRemoteConfig();
      when(() => rc.getString(any())).thenReturn('');
      // GenerativeModel 是 final class 無法 mock：在建立 model 時中止，只檢查傳入參數。
      when(
        () => ai.generativeModel(
          model: any(named: 'model'),
          systemInstruction: any(named: 'systemInstruction'),
          generationConfig: any(named: 'generationConfig'),
        ),
      ).thenThrow(Exception('stop before network'));
      repo = AiFoodieRepo(
        firebaseAI: ai,
        modelConfig: AiModelConfig(remoteConfig: rc),
      );
    });

    List<dynamic> captureModelArgs() => verify(
      () => ai.generativeModel(
        model: captureAny(named: 'model'),
        systemInstruction: captureAny(named: 'systemInstruction'),
        generationConfig: captureAny(named: 'generationConfig'),
      ),
    ).captured;

    test('沒有遠端值時送出與現況一致的 model／instruction／temperature', () async {
      await repo.askAssistant('任意');

      final args = captureModelArgs();
      expect(args[0], 'gemini-3.5-flash-lite');
      expect(
        ((args[1] as Content).parts.single as TextPart).text,
        AiModelConfig.defaultAiFoodieSystemInstruction,
      );
      expect((args[2] as GenerationConfig).temperature, 0.2);
    });

    test('同一個 repo 實例，遠端值改變後下一次請求就使用新值', () async {
      when(() => rc.getString('ai_foodie_model')).thenReturn('model-a');
      await repo.askAssistant('第一次');
      when(() => rc.getString('ai_foodie_model')).thenReturn('model-b');
      when(() => rc.getString('ai_foodie_temperature')).thenReturn('0.9');
      await repo.askAssistant('第二次');

      final args = captureModelArgs();
      expect([args[0], args[3]], ['model-a', 'model-b']);
      expect((args[5] as GenerationConfig).temperature, 0.9);
    });
  });
  ```
  `captured` 會把每次呼叫的 3 個參數依序攤平，所以兩次呼叫得到 `[model1, sys1, cfg1, model2, sys2, cfg2]`。

`test/data_layer/menu_vision_repo_test.dart`：
- import 區加上 `package:firebase_ai/firebase_ai.dart`、`package:firebase_remote_config/firebase_remote_config.dart`、`package:mocktail/mocktail.dart`。
- 加上相同的兩個 mock 類別。
- 在 `main()` 最後新增一個 group：
  ```dart
  group('MenuVisionRepo 讀取 AiModelConfig', () {
    late _MockFirebaseAI ai;
    late _MockRemoteConfig rc;
    late MenuVisionRepo repo;
    final bytes = Uint8List.fromList([1, 2, 3]);

    setUpAll(() {
      registerFallbackValue(Content.system(''));
      registerFallbackValue(GenerationConfig());
    });

    setUp(() {
      ai = _MockFirebaseAI();
      rc = _MockRemoteConfig();
      when(() => rc.getString(any())).thenReturn('');
      when(
        () => ai.generativeModel(
          model: any(named: 'model'),
          systemInstruction: any(named: 'systemInstruction'),
          generationConfig: any(named: 'generationConfig'),
        ),
      ).thenThrow(Exception('stop before network'));
      repo = MenuVisionRepo(
        firebaseAI: ai,
        modelConfig: AiModelConfig(remoteConfig: rc),
      );
    });

    List<dynamic> captureModelArgs() => verify(
      () => ai.generativeModel(
        model: captureAny(named: 'model'),
        systemInstruction: captureAny(named: 'systemInstruction'),
        generationConfig: captureAny(named: 'generationConfig'),
      ),
    ).captured;

    test('沒有遠端值時送出與現況一致的參數，且不設定 temperature', () async {
      await expectLater(repo.analyzeMenuImageBytes(bytes), throwsException);

      final args = captureModelArgs();
      expect(args[0], 'gemini-3.5-flash-lite');
      expect(
        ((args[1] as Content).parts.single as TextPart).text,
        AiModelConfig.defaultMenuVisionSystemInstruction,
      );
      expect((args[2] as GenerationConfig).temperature, isNull);
    });

    test('同一個 repo 實例，遠端值改變後下一次請求就使用新值', () async {
      when(() => rc.getString('menu_vision_model')).thenReturn('model-a');
      await expectLater(repo.analyzeMenuImageBytes(bytes), throwsException);
      when(() => rc.getString('menu_vision_model')).thenReturn('model-b');
      await expectLater(repo.analyzeMenuImageBytes(bytes), throwsException);

      final args = captureModelArgs();
      expect([args[0], args[3]], ['model-a', 'model-b']);
    });
  });
  ```

```bash
rtk flutter test test/data_layer/   # 紅燈：modelConfig 參數不存在（編譯錯誤）
```

**步驟 2（綠燈）**：修改 `lib/data_layer/repositories/ai_foodie_repo.dart`
- 在 import 區（相對路徑區塊）加上 `import '../datasources/ai_model_config.dart';`。
- 建構式改成：
  ```dart
  AiFoodieRepo({
    FirebaseAI? firebaseAI,
    AiPromptFunction? promptExecutor,
    AiModelConfig? modelConfig,
  }) : _firebaseAI = firebaseAI,
       _promptExecutor = promptExecutor,
       _modelConfig = modelConfig ?? AiModelConfig();

  final FirebaseAI? _firebaseAI;
  final AiPromptFunction? _promptExecutor;
  final AiModelConfig _modelConfig;
  ```
- 刪除 `static const String _systemInstruction = '''...''';`（原 L28–L99）。
- `askAssistant` 裡的 `ai.generativeModel(...)` 改成：
  ```dart
      final model = ai.generativeModel(
        model: _modelConfig.aiFoodieModel,
        systemInstruction: Content.system(
          _modelConfig.aiFoodieSystemInstruction,
        ),
        generationConfig: GenerationConfig(
          temperature: _modelConfig.aiFoodieTemperature,
          responseMimeType: 'application/json',
          responseSchema: aiFoodieResponseSchema,
        ),
      );
  ```
  model 仍然在 `try` 內、每次呼叫時建立（驗收條件 6），**不可**提到建構式或 field。

**步驟 3（綠燈）**：修改 `lib/data_layer/repositories/menu_vision_repo.dart`
- 加上 `import '../datasources/ai_model_config.dart';`。
- 建構式新增 `AiModelConfig? modelConfig,`（放在 `analyzer` 之後），初始化列加上 `_modelConfig = modelConfig ?? AiModelConfig()`，並新增欄位 `final AiModelConfig _modelConfig;`。
- 刪除 `static const String systemInstruction = '''...''';`（原 L28–L33）。
- `_getModel()` 改成：
  ```dart
  GenerativeModel _getModel() {
    final ai = _firebaseAI ?? FirebaseAI.googleAI();
    return ai.generativeModel(
      model: _modelConfig.menuVisionModel,
      systemInstruction: Content.system(
        _modelConfig.menuVisionSystemInstruction,
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: menuAnalysisSchema,
      ),
    );
  }
  ```
  `GenerationConfig` **不加** temperature（規格 §4.1）。

**驗收**：
```bash
dart format lib/data_layer/repositories/ test/data_layer/
rtk flutter analyze                                   # No issues found
rtk flutter test test/data_layer/ test/di_test.dart   # 全綠
rtk git diff -U0 test/data_layer/ai_foodie_repo_test.dart test/data_layer/menu_vision_repo_test.dart | rtk proxy grep -n "^-[^-]"
# 期望：沒有輸出（既有測試只有新增、沒有刪改）
rtk proxy grep -rn "gemini-3.5-flash-lite" lib        # 期望：只有 ai_model_config.dart 一處
rtk proxy grep -rn "'ai_foodie_\|'menu_vision_model\|'menu_vision_system" lib   # 期望：只出現在 ai_model_config.dart
```

---

### T4：啟動時非阻塞 fetch（依賴 T2，可與 T3 並行）

**TDD 說明**：`main()` 不是單元測試的對象；「fetch 失敗不外拋」已在 T2 的 `fetchAndActivate` 測試中鎖住。這裡只做一行接線，驗收靠 `analyze` 加上手動啟動。

**步驟 1**：修改 `lib/main.dart`
- 在 import 區（相對路徑區塊）的 `import 'component/ad/ad_barrel.dart';` 後面加上：
  ```dart
  import 'data_layer/datasources/datasources_barrel.dart';
  ```
- 在 App Check 的 `if (kDebugMode) {...} else {...}` 之後、`await FcmManager().init();` 之前插入：
  ```dart

    // 不阻塞 runApp：失敗在 fetchAndActivate 內記錄，AI 參數沿用預設值。
    unawaited(AiModelConfig().fetchAndActivate());

  ```
  `dart:async` 已經 import（`unawaited` 來自這裡）。

**驗收**：
```bash
dart format lib/main.dart
rtk flutter analyze                          # No issues found
```
手動（debug build，擇一平台）：`flutter run` 後首頁照常出現；log 沒有 `Remote config fetch failed`（Console 還沒建參數時 fetch 仍然會成功，只是拿不到值）。切成飛航模式再冷啟動：首頁照常出現，log 出現一次 `Remote config fetch failed ...`，AI 覓食助理照常可用。

---

### T5：收尾驗證

```bash
rtk flutter analyze                                # No issues found
dart format --output=none --set-exit-if-changed lib test   # exit 0
rtk flutter test                                   # N + 17 個全綠（T2 13 個 + T3 4 個）
rtk proxy grep -rn "gemini-3.5-flash-lite" lib     # 只有 ai_model_config.dart 一處
rtk proxy grep -rn "firebase_remote_config" lib    # 只有 ai_model_config.dart 一處
rtk git diff main --stat                           # 只有 §3 列出的檔案
```

Console 手動驗證（debug build，`minimumFetchInterval = 0`）：在 Console 把 `ai_foodie_model` 改成一個不存在的名稱並發布 → 冷啟動 → 送出一次 AI 覓食請求，應該降級為本地推薦，log 出現 `AI assistant request failed`。改回來、發布、冷啟動後恢復正常。這個流程同時驗證了 key 拼字、fetch 與生效時機。

---

## 6. 風險與回滾

| 風險 | 偵測點 | 緩解／回滾 |
|------|--------|------------|
| `pub add` 帶動 `firebase_core` 或其他 FlutterFire 套件升降級 | T1 驗收的 `pubspec.lock` diff | 停下來回報；不手動釘版本 |
| iOS pod 版本與其他 FlutterFire pod 不一致 | T1 `pod install` | 同屬 FlutterFire BoM，正常情況下一致；有衝突就回報 |
| instruction 搬移時漏字或多了空白 | T2 驗收的 `diff` | 必須沒有輸出才能進入 T3 |
| 有人日後把 `GenerativeModel` 改成建構時快取 | T3 的「遠端值改變後下一次請求就使用新值」兩個案例 | 測試鎖住 |
| Console key 拼錯，無聲地一直用預設值 | T5 的 Console 手動驗證；T2 測試寫死了 key 字串 | §7 清單逐字比對 |
| 遠端填了「格式正確但不存在」的模型名 | 執行期 | 沿用既有路徑：AI 覓食降級為本地推薦，拍菜單由 BLoC 顯示失敗；在 Console 改回來即可止血 |
| 「未注入且 Firebase 未初始化」測試案例在測試環境丟出非 Exception 的錯誤 | T2 | 刪除該案例並回報（見 T2 說明），不改成捕捉 `Error` |

**回滾**：
- 執行期（不發版）：刪除 Console 上的參數，或把值改回預設值並發布 → 裝置下一次 fetch（release 最長 12h）後就回到預設值。
- 程式碼：T4 → T3 → T2 → T1 依序 revert。T3、T4 各自獨立，可以只 revert 其中一個（只 revert T4：不再 fetch，永遠使用預設值；只 revert T3：repo 回到寫死值，`AiModelConfig` 閒置）。

---

## 7. Firebase Console 需建立的 5 個參數

Remote Config → 新增參數。值一律等於程式預設值（不建也不會壞，只是維運時沒有東西可改）。key 必須和下表逐字相同：

| Parameter key | Data type | Default value |
|---|---|---|
| `ai_foodie_model` | String | `gemini-3.5-flash-lite` |
| `ai_foodie_temperature` | Number | `0.2`（合法範圍 `0`–`2`，超出範圍時 client 會退回 `0.2`） |
| `ai_foodie_system_instruction` | String | `AiModelConfig.defaultAiFoodieSystemInstruction` 全文（從 `lib/data_layer/datasources/ai_model_config.dart` 複製，保留換行） |
| `menu_vision_model` | String | `gemini-3.5-flash-lite` |
| `menu_vision_system_instruction` | String | `AiModelConfig.defaultMenuVisionSystemInstruction` 全文（同上） |

注意：
- 貼上 instruction 時，Console 可能會吞掉結尾的換行。client 端逐字使用、不做正規化；少一個結尾換行對模型沒有影響，但建議在 debug build 驗證一次（規格風險 6）。
- 空字串或全空白的值會被 client 視為「沒有設定」，退回預設值。
- Remote Config 的值會下發到 client，不是機密儲存；經它下發的金鑰須視同公開值（規格 §5）。
- 建議把這張表貼進 PR 描述，當作上線前的維運檢查項。

---

## 8. 執行方式選項

- **Subagent-driven（推薦）**：一個 subagent 依序做 T1 → T2 → T3 → T4 → T5，主 session 在 T2 結束後重點 review `AiModelConfig`（唯一需要設計判斷的地方），其餘任務檢查驗收輸出即可。
- **Parallel session**：T1、T2 在主線完成後，開 2 個 worktree 分別做 T3、T4（寫入路徑不重疊），合併後做 T5。T4 只有兩行，並行省下的時間不到協調成本，不建議。

---

## 9. 與規格不同之處（請確認）

1. **不修改 `lib/di/injection.dart`**：規格 §4.3 寫「`injection.dart` 註冊存取點」。本計畫改成 repo 可選注入並預設 `AiModelConfig()`，`main.dart` 直接 `AiModelConfig().fetchAndActivate()`。理由見 §1.1：這個類別沒有狀態，註冊到 GetIt 沒有任何好處。如果堅持要註冊，就在 T4 加一行 `getIt.registerLazySingleton<AiModelConfig>(() => AiModelConfig());`，並把 `main.dart` 改成 `getIt<AiModelConfig>()`；repo 預設值維持不變（不可以改成從 GetIt 取，否則 `ai_foodie_repo_test.dart:252,268` 會壞）。
2. **刪除 `MenuVisionRepo.systemInstruction`（public static const）**：lib 與 test 內沒有任何引用（§0）。保留會讓預設值出現兩份，違反驗收條件 2。
3. **不呼叫 `setDefaults`**（規格 §8-8 交由計畫決定）：理由見 §1.3。
4. **空字串不記 `Logger().w`**：規格驗收條件 7 寫「空字串或全空白 → 預設值（並記 `Logger().w`）」。但 `getString` 無法分辨「key 不存在」和「值是空字串」，前者是 Console 還沒建參數時的正常狀態，每次 AI 請求都記 warning 只會製造噪音。因此只有「非空但全空白」與「temperature 非法」會記 warning（§1.2）。
