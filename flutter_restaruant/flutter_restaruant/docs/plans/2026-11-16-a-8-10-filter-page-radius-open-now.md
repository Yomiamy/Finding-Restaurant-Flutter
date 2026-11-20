# 實作計畫：[A-8.10] 補齊 FilterPage 的搜尋半徑 (`radius`) 與目前營業中 (`open_now`) UI 控制項

> 項目編號：**[A-8.10]**（UI 補完）  
> 建立日期：2026-11-16  
> 關聯規格：[`docs/features/2026-11-16-a-8-10-filter-page-radius-open-now.md`](../features/2026-11-16-a-8-10-filter-page-radius-open-now.md)  
> 實查基線：`main` @ `f8fe7adf`  
> 狀態：🟡 修訂版 1 (STAGE 0b，依 `plan-verifier` 初審意見修正後送複審)

---

## 1. 目標

補齊 `FilterPage` 的搜尋半徑 (`radius`) 與目前營業中 (`open_now`) UI 控制項、預選回填與套用回傳，並在 `FilterConfigs.fromUI` 模型邊界直接強制執行 `openNow` / `openAt` 互斥與 `radius` 值域不變量，將既有 PR #174 打通的進階篩選管線安全交付給使用者。

資料流維持單向傳遞：
`FilterPage` (`_selectedRadius`, `_openNow`) → `FilterConfigs.fromUI(...)`（模型層不變量正規化） → `MainPage._openFilterPage` → `Reset` / `ResetSuccess` → `FetchSearchInfo` → `MainBloc` → `MainRepo.fetchYelpSearchInfo` → `APIClz.businessesSearch`

---

## 2. 實作方向與 Trade-off

### 2.1 UI 與模型設計選擇

1. **模型層不變量正規化（`FilterConfigs.fromUI`）**：
   - **理由**：把「`openNow: false` 轉為 `null`」、「`openNow == true` 時清除 `openAt`」、「`radius <= 0` 轉 `null`、`> 40,000` clamp 至 `40,000`」收斂在 `FilterConfigs.fromUI` 單一入口，從資料結構根除非法狀態組合，不依賴 UI caller 手寫補丁。
   - **向後相容**：所有參數型別與具名參數名稱完全不變；合法非預設半徑（如 `2500`）原樣保留；未傳入 `openNow`/`radius` 時與原行為完全相同。
2. **`open_now` 採用 `SwitchListTile` 置於「營業時間」卡片內並與 `CupertinoDatePicker` 互斥收合**：
   - **理由**：`open_now` 與 `open_at` 在 Yelp API 上為互斥參數（`MainRepo:82` 亦以 `openNow == true` 覆寫 `openAt`）。將「僅看營業中」開關放在「營業時間」`SectionCardWidget` 最上方，開啟時以 `if (!_openNow)` 收合下方的 `CupertinoDatePicker`，關閉時恢復顯示並保留既有 `_openAtDateTime`。
   - **替代方案**：另開獨立卡片並用半透明禁用 `CupertinoDatePicker` — 會增加頁面高度並留下 180px 無效轉盤，且與 `flutter-styles.md` 建議少用 `Opacity` 離屏緩衝的原則不符。
3. **`radius` 採用 `RadiusChipsWidget`（`ChoiceChip` 預設距離級距）**：
   - **理由**：Yelp API `radius` 上限為 `40,000` 公尺。採用與 `CuisineCategoryChipsWidget` 一致的 `ChoiceChip` + `Wrap` 互動（選項：不限 `null`、`500 m`、`1 km`、`3 km`、`5 km`、`10 km`、`20 km`、`40 km`），點擊已選取距離 Chip 可取消回到「不限」，值域天然合法且一鍵可達；相較 `Slider`（0～40,000 需定義 0 代表 null 的魔術值且 500m 步進難以精確點擊），更簡潔且視覺一致。
   - **元件位置**：抽成獨立 StatelessWidget `lib/flow/filter/view/radius_chips_widget.dart`（遵守 `flutter-styles.md` 禁止 `_buildX()` 輔助方法規範），並將 `SectionCardWidget` 置於「餐飲料理分類」之後、「排序依據」之前，維持既有測試畫面中菜系 Chip 可見不偏移。

### 2.2 任務切分、複雜度分級與依賴關係

| 任務編號 | 負責範圍 | 複雜度 / 委派等級 | 異動檔案 | 執行方式 |
|:---|:---|:---|:---|:---:|
| **T1** | `FilterConfigs.fromUI` 模型不變量正規化與單元測試 | 機械性 / 快 | `lib/models/filter_configs.dart`<br>`test/models/filter_configs_test.dart` | 序列第一步 |
| **T2** | 多語系 ARB 更新、l10n 生成、`RadiusChipsWidget` 元件與 Widget 測試 | 快 / 標準 | `lib/l10n/intl_en.arb`<br>`lib/l10n/intl_zh_TW.arb`<br>`lib/generated/l10n.dart`<br>`lib/generated/intl/messages_*.dart`<br>`lib/flow/filter/view/radius_chips_widget.dart`<br>`lib/flow/filter/view/view_barrel.dart`<br>`test/flow/filter/radius_chips_widget_test.dart` | 序列第二步（依賴 T1 模型上限常數/語意一致性） |
| **T3** | `FilterPage` 整合 `open_now` 開關、`RadiusChipsWidget` 與完整 Widget 測試 | 標準 | `lib/flow/filter/view/filter_page.dart`<br>`test/flow/filter/filter_page_test.dart` | 序列第三步（依賴 T1 行為與 T2 元件及 l10n key） |

> 說明：
> - **T1**：觸及 `lib/models/filter_configs.dart` 與 `test/models/filter_configs_test.dart` 共 2 檔，不命中單檔派發煞車。
> - **T2** 與 **T3** 皆須共用 `S.current` l10n key，嚴格採 T1 → T2 → T3 序列執行，確保每個任務獨立可測與可驗收。

---

## 3. 詳細設計與具體實作步驟（TDD-first）

### 3.1 T1：`FilterConfigs.fromUI` 模型不變量正規化

#### 步驟 1：先補單元測試（TDD Red）
在 `test/models/filter_configs_test.dart` 新增測試案例：
1. `FilterConfigs.fromUI` 傳入 `radius: 5000, openNow: true` 時，`configs.radius == 5000`、`configs.openNow == true` 且 `configs.openAt == isNull`。
2. `FilterConfigs.fromUI` 傳入 `openNow: false` 時，正規化為 `configs.openNow == isNull` 且 `configs.openAt == openAtDate.millisecondsSinceEpoch`（消滅 `open_now=false` 與 `open_at` 並發衝突）。
3. `FilterConfigs.fromUI` 未傳入 `openNow`（`null`）時，`configs.openAt == openAtDate.millisecondsSinceEpoch`。
4. `FilterConfigs.fromUI` 對 `radius` 值域正規化：
   - 合法非預設值 `radius: 2500` → 原樣保留 `2500`。
   - 越界下限 `radius: 0` 與 `radius: -100` → 正規化為 `null`。
   - 越界上限 `radius: 50000` → clamp 至 `40000`。
5. `clearConfig(FilterConfigType.radius)` 與 `clearConfig(FilterConfigType.openNow)` 分別將 `radius` 與 `openNow` 清回 `null` 且不影響其他欄位。

#### 步驟 2：實作修改（TDD Green）
修改 `lib/models/filter_configs.dart`：
```dart
  /// Yelp Fusion API `/v3/businesses/search` 支援的最大搜尋半徑（公尺）。
  static const int maxRadiusMeters = 40000;
```
並調整 `FilterConfigs.fromUI` 參數為區域參數並於建構子內完成正規化：
```dart
  FilterConfigs.fromUI({
    required int priceIndex,
    required DateTime openAtDate,
    required int sortingRuleIndex,
    this.categories,
    int? radius,
    bool? openNow,
  }) {
    price = '${priceIndex + 1}';
    this.openNow = (openNow == true) ? true : null;
    openAt = (this.openNow == true) ? null : openAtDate.millisecondsSinceEpoch;
    sortBy = mapSortingRuleByIndex(sortingRuleIndex);
    this.radius = _normalizeRadius(radius);
  }

  static int? _normalizeRadius(int? radius) {
    if (radius == null || radius <= 0) {
      return null;
    }
    return radius > maxRadiusMeters ? maxRadiusMeters : radius;
  }
```
> 註：`analysis_options.yaml` 啟用了 `unnecessary_this: true`，實作時僅在區域參數同名遮蔽（`this.openNow`、`this.radius`）處保留 `this.`（屬於 Dart 合法且必要的消歧義，不觸發 `unnecessary_this`）。

#### 步驟 3：驗證
```bash
flutter test test/models/filter_configs_test.dart
```

---

### 3.2 T2：多語系鍵值、`RadiusChipsWidget` 元件與測試

#### 步驟 1：補齊多語系與重新生成
在 `lib/l10n/intl_en.arb` 新增：
```json
  "filter_open_now": "Open Now",
  "filter_open_now_subtitle": "Show only restaurants open right now (ignores specific time)",
  "filter_search_radius": "Search Radius",
  "filter_radius_unlimited": "Unlimited"
```
在 `lib/l10n/intl_zh_TW.arb` 新增：
```json
  "filter_open_now": "僅看營業中",
  "filter_open_now_subtitle": "只搜尋現在營業中的餐廳（將忽略指定時間）",
  "filter_search_radius": "搜尋半徑",
  "filter_radius_unlimited": "不限"
```
執行生成器：
```bash
dart run intl_utils:generate
```

#### 步驟 2：先寫元件測試（TDD Red）
建立 `test/flow/filter/radius_chips_widget_test.dart`（**必須**比照 `cuisine_category_chips_widget_test.dart:15-17` 於 `MaterialApp` 掛載 `localizationsDelegates: const [S.delegate]` 與 `theme: AppThemeData.materialLight`，確保不吃 `flutter_test_config.dart` 的全域 `zh_TW` 而穩定以英文 `'Unlimited'` 斷言）：
1. 驗證預設 `selectedRadius: null` 時，「Unlimited」`ChoiceChip` 處於選取狀態，並完整渲染 `Unlimited`、`500 m`、`1 km`、`3 km`、`5 km`、`10 km`、`20 km`、`40 km` 共 8 個 `ChoiceChip`。
2. 驗證傳入 `selectedRadius: 5000` 時，「5 km」`ChoiceChip` 處於選取狀態、「Unlimited」未選取。
3. 驗證點擊未選中的距離 Chip（如 `3 km`）回呼 `3000`。
4. 驗證再次點擊已選中的距離 Chip（如 `3 km`）回呼 `null`（取消選取回到不限）。
5. 驗證從非 `null` 初始值（如 `selectedRadius: 5000`）點擊「Unlimited」Chip 回呼 `null`；且在 `selectedRadius: null` 時點擊「Unlimited」Chip 維持 `null`（不會意外反選為其他值）。

#### 步驟 3：實作 `RadiusChipsWidget`（TDD Green）
建立 `lib/flow/filter/view/radius_chips_widget.dart` 並於 `lib/flow/filter/view/view_barrel.dart` 新增 `export 'radius_chips_widget.dart';`：
```dart
import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 搜尋半徑選項 Chip 元件，涵蓋「不限」與 Yelp API 上限 40 km 內的預設級距。
class RadiusChipsWidget extends StatelessWidget {
  /// Yelp Fusion API 允許的預設半徑選項（單位：公尺，上限 40,000）。
  static const List<int> presetRadiiMeters = [
    500,
    1000,
    3000,
    5000,
    10000,
    20000,
    40000,
  ];

  const RadiusChipsWidget({
    super.key,
    required this.selectedRadius,
    required this.onRadiusSelected,
  });

  final int? selectedRadius;
  final ValueChanged<int?> onRadiusSelected;

  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    return '${meters ~/ 1000} km';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ThemeSize.space8,
      runSpacing: ThemeSize.space8,
      children: [
        ChoiceChip(
          label: Text(S.current.filter_radius_unlimited),
          selected: selectedRadius == null,
          onSelected: (selected) {
            if (selected) {
              onRadiusSelected(null);
            }
          },
        ),
        for (final meters in presetRadiiMeters)
          ChoiceChip(
            label: Text(_formatRadius(meters)),
            selected: selectedRadius == meters,
            onSelected: (selected) {
              onRadiusSelected(selected ? meters : null);
            },
          ),
      ],
    );
  }
}
```

#### 步驟 4：驗證
```bash
flutter test test/flow/filter/radius_chips_widget_test.dart
```

---

### 3.3 T3：`FilterPage` 整合 `open_now` 與 `radius` 控制項與測試

#### 步驟 1：先寫/擴充 Widget 測試（TDD Red）
在 `test/flow/filter/filter_page_test.dart` 擴充測試案例（**所有新增測試均須比照既有測試設定 `tester.view.physicalSize = const Size(800, 1200)`、`devicePixelRatio = 1.0` 與 `addTearDown` 重設，且任何點擊螢幕下半部元件如 `'3 km'`、`'Unlimited'`、`'10 km'` 前皆須呼叫 `tester.scrollUntilVisible(..., 100, scrollable: find.byType(Scrollable).first)`**）：
1. **渲染新區塊**：驗證「Open Now」`SwitchListTile`（初始 `value == false`）、「Search Radius」標題與「Unlimited」、`500 m`～`40 km` Chips 正確渲染。
2. **互斥切換與時間保留**：傳入固定時間 `initialOpenAt = DateTime(2026, 11, 16, 18, 30)` 之 `FilterConfigs(openAt: initialOpenAt.millisecondsSinceEpoch)`：
   - 驗證初始 `CupertinoDatePicker.initialDateTime == initialOpenAt`。
   - 點擊「Open Now」`SwitchListTile` 開啟後，`CupertinoDatePicker` 消失（`findsNothing`）。
   - 再次點擊關閉「Open Now」後，`CupertinoDatePicker` 重新出現（`findsOneWidget`）且其 `initialDateTime` 仍等於 `initialOpenAt`。
3. **選取並套用回傳**：開啟「Open Now」並先 `scrollUntilVisible` 再點擊 `'3 km'` Chip，最後點擊「Apply」，驗證返回的 `FilterConfigs` 具備 `openNow == true`、`openAt == isNull`、`radius == 3000`。
4. **預選回填與關閉還原**：傳入 `FilterConfigs(radius: 10000, openNow: true)` 開啟 `FilterPage`：
   - 驗證「Open Now」`SwitchListTile` 初始為 `true` 且 `CupertinoDatePicker` 不渲染。
   - 先 `scrollUntilVisible` 定位 `'10 km'`，驗證其 `ChoiceChip.selected == true`。
   - 先 `scrollUntilVisible` 定位「Open Now」`SwitchListTile` 並點擊關閉；`scrollUntilVisible` 定位 `'Unlimited'` 並點擊；點擊「Apply」，驗證回傳 `openNow == isNull`（非 `false`）、`openAt != null`、`radius == isNull`。
5. **非預設半徑值保留**：傳入 `FilterConfigs(radius: 2500)` 開啟 `FilterPage`，未點擊任何半徑選項直接點擊「Apply」，驗證回傳 `radius == 2500` 不被靜默清空。

#### 步驟 2：實作 `FilterPage` 修改（TDD Green）
修改 `lib/flow/filter/view/filter_page.dart`：
1. 引入 `import 'radius_chips_widget.dart';`。
2. 在 `_FilterPageState` 新增狀態欄位：
   - `int? _selectedRadius;`
   - `bool _openNow = false;`
3. 於 `didChangeDependencies()` 的 `if (!_isInit)` 區塊新增回填：
   - `_selectedRadius = configs.radius;`
   - `_openNow = configs.openNow == true;`
4. 更新「營業時間 (`S.current.filter_business_hour`)」`SectionCardWidget` 的 `child`：
   ```dart
   Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       SwitchListTile(
         contentPadding: EdgeInsets.zero,
         title: Text(S.current.filter_open_now),
         subtitle: Text(S.current.filter_open_now_subtitle),
         value: _openNow,
         onChanged: (value) {
           setState(() {
             _openNow = value;
           });
         },
       ),
       if (!_openNow) ...[
         const SizedBox(height: ThemeSize.space8),
         Container(
           height: ThemeSize.size180,
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(
               ThemeSize.radius8,
             ),
           ),
           child: CupertinoDatePicker(
             initialDateTime: _openAtDateTime,
             use24hFormat: true,
             mode: CupertinoDatePickerMode.dateAndTime,
             onDateTimeChanged: (dateTime) {
               _openAtDateTime = dateTime;
             },
           ),
         ),
       ],
     ],
   )
   ```
5. 在「餐飲料理分類」`SectionCardWidget` 之後、「排序依據」之前，新增「搜尋半徑」卡片：
   ```dart
   const SizedBox(height: ThemeSize.space16),
   SectionCardWidget(
     icon: Icons.location_searching,
     title: S.current.filter_search_radius,
     child: RadiusChipsWidget(
       selectedRadius: _selectedRadius,
       onRadiusSelected: (radius) {
         setState(() {
           _selectedRadius = radius;
         });
       },
     ),
   ),
   ```
6. 更新底部 `FilledButton.onPressed` 呼叫 `FilterConfigs.fromUI`（直接傳入 `_openNow`，由 T1 模型建構子統一正規化）：
   ```dart
   FilterConfigs configs = FilterConfigs.fromUI(
     priceIndex: _priceIndex,
     openAtDate: _openAtDateTime,
     sortingRuleIndex: _sortByIndex,
     categories: _selectedCategory,
     radius: _selectedRadius,
     openNow: _openNow,
   );
   ```

#### 步驟 3：驗證
```bash
flutter test test/flow/filter/filter_page_test.dart
```

---

## 4. 驗證標準與退場條件

1. **靜態分析**：`flutter analyze lib/ test/` 無新增 warning / error / info（維持專案既有基準）。
2. **程式碼格式**：`dart format --output=none --set-exit-if-changed lib/ test/` 通過（零格式差異）。
3. **單元與 Widget 測試**：`flutter test` 全套測試 100% 通過，包含：
   - `test/models/filter_configs_test.dart`
   - `test/flow/filter/radius_chips_widget_test.dart`
   - `test/flow/filter/filter_page_test.dart`
4. **向後相容**：未設定 `radius` 與 `openNow`（或傳入 `openNow: false`）時，`FilterConfigs` 預設輸出（`radius: null`、`openNow: null`、`openAt != null`）與既有介面完全維持原樣。

---

## 5. 執行方式選擇

- **Subagent-Driven Development**（目前批次採 `--pause-level balanced`：STAGE 0b 計畫確認後，經 STAGE 1 建立 Issue + Worktree，進入 STAGE 2 序列執行 T1 → T2 → T3 並逐任務由獨立 `verifier` 驗收）。
