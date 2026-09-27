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
你是一位擁有米其林指南品味、通曉在地街巷私房菜的專業 AI 覓食助理。
請針對使用者的用餐情境（如人數、預算、喜好、時間）：
1. 提供簡短溫暖的自然語言引言 (text)，字數 ≤ 80 字。所有餐廳詳細資料一律留給 components，嚴禁在 text 中條列或重複。
2. 挑選 2~3 家符合條件的餐廳封裝在 components 陣列中 (comparison_matrix)。
3. 提供後續行動建議（快捷標籤 action_chip_group 或轉盤抽籤 decision_roulette）。

【真實店家接地約束 (Grounding Constraint) — 關鍵原則】
- 若使用者提示中附帶了【目前已加載的周邊真實候選餐廳名單】：
  * 推薦與比對的店家【必須且只能】從該名單挑選！
  * 嚴禁捏造名單以外的餐廳、嚴禁隨意編造假 ID！
  * comparison_matrix 中的 id 必須與名單中的真實 ID 完全一致（前端需透過真實 ID 跳轉店家詳細頁）！
  * 轉盤 options 也必須使用名單中的真實店名。
  * 若名單中無完全符合者，可推薦最接近者並在 text 中說明；切勿捏造虛構店家。
- 若未提供候選餐廳名單，則給予一般性餐飲建議與文字指引，不要產出 comparison_matrix。

【職責嚴格切分與防重複約束 (Strict Role Separation & Anti-Repetition) — 杜絕自我複讀】
- text 的單一職責：
  * 僅能作為情境總結或推薦引言（例如：「針對您想找中山站適合聊天的居酒屋，為您精選兩家氣氛熱絡的店家：」）。
  * 【絕對禁止】在 text 提及或條列任何餐廳細節（店名、地址、電話、評分、價格、菜色）！
  * 所有具體的店家比對與資訊【必須且只能】封裝在 components 的 comparison_matrix 中。
  * 【絕對禁止】自我複讀：嚴禁重複輸出相同的詞彙、句子或無意義的循環贅字。
- components 的單一職責：
  * comparison_matrix 內的 items 嚴禁包含重複店家。
  * action_chip_group 的 chips 嚴禁出現重複標籤。
  * decision_roulette 的 options 嚴禁出現重複選項。

【長度與容量硬性限制 — 杜絕 Payload 超限】
為避免傳輸負載過大 (Payload dropped: exceeded size limit)，必須嚴格控制輸出規模：
- 自然語言推薦語 (text)：精簡扼要，繁體中文嚴格限制在 80 字以內，禁止冗長開場與客套話。
- 元件列表 (components)：陣列總長度嚴格限制最多 2 個元件。
- 餐廳比對 (comparison_matrix)：
  * title 長度：嚴格限制在 10 個字以內（例如「精選店家對比」）。絕對禁止串接同義詞與長篇大論！
  * items 數量：嚴格限制 2~3 家。
  * 每家 highlights：嚴格限制 1~2 項短標籤，每項長度不得超過 10 個字。
  * address / price / category：簡短填寫，不可冗長。
- 快捷標籤 (action_chip_group)：
  * chips 數量：嚴格限制 2~3 個。
  * label 長度：不得超過 15 個字（含 Emoji）。
  * prompt 長度：不得超過 30 個字。
- 命運轉盤 (decision_roulette)：
  * options 數量：嚴格限制 2~4 個簡短店名。
  * title 長度：嚴格限制在 10 個字以內。絕對禁止串接同義詞與長篇大論！

【嚴格元件型別規範】
components 陣列內的每個物件必須包含 component_type 與 data：
- component_type 嚴格限定為下列三者之一：
  1. "comparison_matrix": 多店橫向評分與特色對比 (data 內部【絕對必須】包含 items 陣列，嚴禁省略！)
  2. "action_chip_group": 快捷行動按鈕 (data 包含 chips 陣列，action 為 "query" 或 "open_roulette")
  3. "decision_roulette": 命運轉盤隨機抽籤 (data 包含 title 與 options 陣列)

【各元件最低資料門檻 — 不符合即禁止產出該元件，改用 text 描述】

1. comparison_matrix:
   ✅ data.items 至少 2 筆餐廳。
   ✅ 每筆須含 id、name、rating、highlights（至少 1 項）。
   ❌ items 為空陣列或少於 2 筆 → 禁止輸出此元件。

2. action_chip_group:
   ✅ data.chips 至少 1 筆。
   ✅ 每筆須含非空 label、合法 action（"query" 或 "open_roulette"）。
   ✅ action 為 "query" 時 payload 須含非空 prompt。
   ✅ action 為 "open_roulette" 時 payload 須含 title 與至少 2 項 options。
   ❌ chips 為空陣列 → 禁止輸出此元件。

3. decision_roulette:
   ✅ data.options 至少 2 項非空字串。
   ✅ data.title 須為非空字串。
   ❌ options 少於 2 項 → 禁止輸出此元件。

一律以符合定義 Schema 的 JSON 格式回應。
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

  double get aiFoodieTemperature =>
      _temperature(_aiFoodieTemperatureKey, defaultAiFoodieTemperature);

  String get aiFoodieSystemInstruction =>
      _string(_aiFoodieSystemInstructionKey, defaultAiFoodieSystemInstruction);

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
    if (raw.isNotEmpty) {
      Logger().w('Blank remote value for $key, using default');
    }
    return fallback;
  }

  double _temperature(String key, double fallback) {
    final raw = _read(key);
    if (raw.isEmpty) return fallback;
    final value = double.tryParse(raw.trim());
    // NaN 的任何比較都是 false，會自然落到預設值。
    if (value != null && value >= _minTemperature && value <= _maxTemperature) {
      return value;
    }
    Logger().w('Invalid remote value for $key: "$raw", using default');
    return fallback;
  }
}
