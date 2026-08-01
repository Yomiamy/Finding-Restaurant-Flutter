# S1 — Design System 地基 · 實作計畫

> STAGE 0b：How（資料結構、檔案異動、任務拆分）
> 規格來源：`docs/features/2026-07-31-design-system-foundation.md`（R-1 / R-2 / R-3 已由使用者拍板，本計畫不推翻）
> 背景報告：`docs/brainstorm/2026-07-30_features_brainstorm.md` §6.4、§6.7
> 撰寫日期：2026-07-31

## 重要變更 (Changelog)

| 日期 | 變更 |
| :--- | :--- |
| 2026-08-01 | **本文為實作前的計畫快照，內文的路徑與識別字已不等於現況。** 實作時目錄改為 features-first（`lib/theme/` → `lib/features/foundation/style/`）、識別字統一 `theme_` 前綴（`AppTheme` → `AppThemeData`、`Sizes` → `ThemeSize`、`AppTextTheme` → `ThemeTextStyle`），並移除 FlutterGen 的 colors 生成鏈。內文保留原樣以存證當時的推導；**現況以規格書的 AC 與程式碼為準**（見 `docs/features/2026-07-31-design-system-foundation.md` 文首 Changelog） |

## 重要變更 (Changelog)

| 日期 | 變更 |
| :--- | :--- |
| 2026-08-01 | `app_typography.dart` / `AppTypography` 更名為 `app_text_theme.dart` / `AppTextTheme`。本文內文已同步為新名 |

---

## 1. 實作策略總覽

**一句話**：先拍基準線截圖，再建 `lib/theme/` 的 **2 個新檔**（不是 4 個，理由見 §2.3），把 `ThemeData` 掛上 `PlatformApp.material:`，最後刪掉 `filter_tags_widget.dart` 那行取不到值的 `Theme.of(context).primaryColor`（掛了 theme 後它自動變橘，但更好的做法是連同 `selectedColor` 一起刪，讓 `FilterChip` 吃 M3 預設）。

**順序**（強制序列的部分只有 3 段）：

```
T0 截圖基準線 ──┐
                ├─→ T3 掛 main.dart ─→ T4 FilterChip ─→ T5 驗證
T1 typography ──┤        (唯一 owner)
T2 spacing   ───┤
T6 @Deprecated ─┘（可與 T1/T2 並行，與 T3 無相依）
```

T1 / T2 / T6 三個任務寫入路徑完全不重疊，**可完全並行**。T3 是 `main.dart` 的唯一 owner，必須等 T1 完成（T3 要 import `AppTextTheme`）；**T3 不依賴 T2** —— T2 的間距 token 不被 `main.dart` 引用，兩者可並行。T0 必須在 T3 之前完成（沒有基準線就無法驗 AC-7），但可與 T1/T2/T6 並行。

**這個計畫刻意比報告 §6.4 小**：報告建議 4 個檔案，實際只需要 2 個。詳見 §2.3、§2.4。

---

## 2. 設計判斷

### 2.1 `app_text_theme.dart`：舊 10 個字級 → M3 TextTheme 的映射策略

**結論：不做一對一映射，也不覆寫整個 TextTheme。只覆寫 `ThemeData.textTheme` 中「實際會被用到」的 5 個角色，其餘全部沿用 `ColorScheme` 推導出的 M3 預設。**

#### 實測依據

29 處使用點的分布（`rtk grep` 實測）：

| 舊常數 | 值 | 使用次數 |
| :--- | :---: | :---: |
| `xxxhFontSize` | 22 | 8 |
| `mFontSize` | 14 | 7 |
| `xhFontSize` | 18 | 6 |
| `hFontSize` | 16 | 2 |
| `xxxxhFontSize` | 24 | 3 |
| `lFontSize` | 12 | 1 |
| `xxhFontSize` | 20 | 1 |
| `xlFontSize` / `xxxxxhFontSize` / `xxxxxxhFontSize` | 10 / 26 / 28 | **0** |

**三個常數（10、26、28）根本沒人用。** 為它們設計 TextTheme 角色是純粹的過度工程。

#### 採用的映射

只定義 S2/S3 遷移時**真的會用到**的 5 個角色，數值取自實測高頻值，不發明新尺寸：

| M3 角色 | fontSize | 對應舊常數 | 用途（S2/S3 遷移目標） |
| :--- | :---: | :--- | :--- |
| `titleLarge` | 22 | `xxxhFontSize`(8×) | AppBar 標題、頁面主標 |
| `titleMedium` | 18 | `xhFontSize`(6×) | 卡片店名、區塊標題 |
| `bodyLarge` | 16 | `hFontSize`(2×) | 主要內文 |
| `bodyMedium` | 14 | `mFontSize`(7×) | 一般內文、說明文字 |
| `labelSmall` | 12 | `lFontSize`(1×) | 標籤、次要註記 |

**刻意不做的事**：

- 不定義 `displayLarge/Medium/Small`、`headlineLarge/Medium/Small` — 這個 App 沒有任何 Hero 大標，24 只出現在 `main_page` AppBar（歸 `titleLarge` 語意，但實測值 24 vs 22 的差異留給 S3 統一，S1 不動它）。
- 不定義 `fontFamily` — 專案沒有自訂字體資產，指定它只會踩到「字體不存在 fallback」的坑。
- 不定義 `fontWeight`、`letterSpacing`、`height` — M3 預設值是 Material Design 團隊調過的，沒有證據說我們的需求不同。**只覆寫 `fontSize`，其餘 `copyWith` 保留。**

實作形式（一個 `static const TextTheme`，不是 class + 一堆 getter）：

```dart
// lib/theme/app_text_theme.dart
import 'package:flutter/material.dart';

/// S1 只覆寫實測有使用的 5 個字級，其餘沿用 Material 3 預設。
/// 舊 `UIConstants` 字級常數對照見 docs/plans/2026-07-31-design-system-foundation.md §2.1
abstract final class AppTextTheme {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontSize: 22),
    titleMedium: TextStyle(fontSize: 18),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    labelSmall: TextStyle(fontSize: 12),
  );
}
```

> ⚠️ 實作注意：`ThemeData(textTheme:)` 的 partial `TextTheme` 會被 framework 與 `Typography` 預設 **merge**，未指定的角色不會變 null。這是 `ThemeData` 建構式的既有行為，不需要手動 merge。

---

### 2.2 `app_spacing.dart`：token 命名與數值

**結論：報告建議的數值合理，但命名要改，而且要放進 `Dimens`（見 §2.4），不建新檔。**

| 報告建議 | 採用 | 理由 |
| :--- | :--- | :--- |
| `space4/8/12/16/24` | ✅ 採用數值，命名為 `space4` … `space24` | 4 的倍數階梯是 Material 慣例，實測 `EdgeInsets.only(left: 10, right: 5, top: 10)` 這種手感值會在 S2/S3 被吸附到最近的階梯 |
| `radiusCard = 16` | ✅ | 卡片圓角 |
| `radiusChip = 20` | ✅ | `FilterChip` 高度約 32-40，20 是 stadium 效果 |
| `radiusImage = 12` | ✅ | 縮圖圓角 |

**只加這 8 個常數，一個不多。** 不加 `space2`、`space32`、`space48`、`radiusButton`、`radiusDialog` — 沒有任何現存程式碼需要它們，S2/S3 真的需要時再加是一行的事。

實作形式（`static const double`，不是 `EdgeInsets` 預組合）：

```dart
// lib/utils/dimens.dart（填實既有空殼，見 §2.4）
abstract final class Dimens {
  // Spacing
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;

  // Corner radius
  static const double radiusCard = 16;
  static const double radiusChip = 20;
  static const double radiusImage = 12;
}
```

> 刻意不預組 `EdgeInsets.all(space16)` 這種便利常數 — 呼叫端需要的組合太雜（`only` / `symmetric` / `fromLTRB`），預組會變成猜測遊戲。

---

### 2.3 `app_colors.dart`：**不需要，不建立**

**結論：❌ 不建立這個檔案。**

理由（誠實判斷）：

1. **R-1 定案零 `copyWith`**。所以整個色彩系統就是一行 `ColorScheme.fromSeed(seedColor: ColorName.appPrimaryColor)`。這一行放在 `app_theme.dart` 的 `ThemeData` 建構式裡，是它唯一合理的位置。
2. **品牌色已經有 owner**。`ColorName.appPrimaryColor` 在 `lib/gen/colors.gen.dart`（FlutterGen 生成，來源 `assets/colors.xml`）。再建一個 `AppColors.primary = ColorName.appPrimaryColor` 是**同一個值的第二個真相來源** — 這是 bug 的溫床，不是架構。
3. **它會是一個空殼**。除了 seed 色（已有 owner）與語意色（`ColorScheme` 自己就是語意色 API），這個檔案裡沒有任何東西可放。為了湊滿報告 §6.4 的四個檔案而造一個空 class，正是 `lib/utils/dimens.dart` 現在的狀態 —— 我們正要修掉的問題，不該再製造一個。

**對 AC-9 的影響**：AC-9 的原文是「`lib/theme/` 目錄存在，包含 `app_theme` / `app_colors` / `app_text_theme` / `app_spacing` **四個關注點**」。四個**關注點**都被覆蓋了：

| 關注點 | 落在哪 |
| :--- | :--- |
| ThemeData 組裝 | `lib/theme/app_theme.dart` |
| 色彩 | `ColorScheme.fromSeed(ColorName.appPrimaryColor)`，在 `app_theme.dart` 內一行 |
| 字級 | `lib/theme/app_text_theme.dart` |
| 間距/圓角 | `lib/utils/dimens.dart` |

**這需要使用者確認**：是否接受「四個關注點，兩個新檔 + 一個填實既有檔」而非「四個新檔」。若堅持四檔，我會建但明說那是為了對齊文件而非技術需要。

---

### 2.4 `lib/utils/dimens.dart`：**填實它，不建 `app_spacing.dart`**

**結論：填實既有的 `class Dimens {}`，不在 `lib/theme/` 下建 `app_spacing.dart`。**

實測依據：`rtk grep -rn "Dimens" lib/ test/` 的結果只有兩行 —— 檔案自身的 `class Dimens {}` 與 `ui_constants.dart:24` 的一句 `// Dimens` 註解。**零使用點**，所以「填實」與「新建」在破壞性上完全等價，純粹是命名與位置的選擇。

選填實的三個理由：

1. **AC-13 明文要求**：「`lib/utils/dimens.dart` 不再是空類別，含間距與圓角 token」。建 `app_spacing.dart` 而放著空 `Dimens` 不管，是直接違反驗收條件。
2. **零使用點意味著填實它沒有遷移成本**。這不是「維持爛設計」，是「這個檔案已經在正確的位置，只是沒有內容」。
3. **淨減少一個檔案**。若建新檔，就得同時把 `Dimens` 標 `@Deprecated` 或刪掉 —— 為了一個從未被使用的空 class 做遷移儀式，是純儀式。

> 反方意見（記錄在案）：`lib/theme/` 目錄的內聚性會被打破（間距 token 在 `lib/utils/`）。這個代價可接受 —— `Dimens` 是一個實作良好時**呼叫端會頻繁 import** 的檔案，`utils/` 是它慣常的家，且 AC-13 已認定這個位置。

---

### 2.5 驗證策略：**不新增任何測試檔**

**原結論：不新增測試。既有 13 個測試檔全數保留，一個都不改。**

> **實作時的偏離（2026-08-01）**：最終新增了 `test/app_theme_platform_test.dart`，並修改 `test/filter_tags_widget_test.dart`。
> 理由：`PlatformApp` 在 iOS 走 `CupertinoApp` 分支，`material:` 不生效，需靠 `builder:` 補一層 `Theme`——這是**跨平台的行為差異，不是資料宣告**，上面「測賦值運算子」的論證不適用。該測試直接掛載 `FindingRestaruantApp`，若 `main.dart` 的 `builder:` 層被移除，iOS case 會紅。

理由：

1. **S1 沒有新增任何邏輯分支**。新增的是一批 `static const double`（間距、圓角、圖片尺寸、字級）、5 個 `TextStyle`、一個 `ThemeData` 建構。這些是資料宣告，測 `ThemeSize.space10 == 10` 是在測 Dart 的賦值運算子。
2. **真正的風險是視覺 regression，測試抓不到**。M3 切換造成的內距、圓角、色彩變化，`flutter test` 完全看不見 —— 只有截圖比對能抓。把驗證力氣花在 T0/T5 的截圖上，比寫 golden test 划算得多（golden test 的基礎設施成本 > S1 本身）。
3. **既有測試已經是最好的 regression 網**。`filter_tags_widget_test.dart` 用 `MaterialApp` 包裝（**不是** `FindingRestaruantApp`），所以它驗證的是「widget 結構不變」，不受 theme 影響 —— 這正是我們要的：theme 掛上後結構必須不變。

**唯一例外（若 T4 選了方案 B）**：若 `FilterChip` 改為完全移除 `selectedColor`，`filter_tags_widget_test.dart` 的兩個既有測試仍會通過（它們只斷言 `FilterChip` 數量與文字）。無須改測試。

---

## 3. 檔案異動總表

### 新增（2 檔）

| 路徑 | 內容 | 行數估計 |
| :--- | :--- | :---: |
| `lib/theme/app_theme.dart` | `AppTheme.light` — `ThemeData(useMaterial3: true, colorScheme: fromSeed(...), textTheme: AppTextTheme.textTheme)` | ~15 |
| `lib/theme/app_text_theme.dart` | `AppTextTheme.textTheme` — 5 個 `TextStyle` | ~15 |

### 修改（4 檔）

| 路徑 | 異動 | 風險 |
| :--- | :--- | :---: |
| `lib/utils/dimens.dart` | 空 class → 8 個 `static const double` | 🟢 零使用點 |
| `lib/utils/ui_constants.dart` | 10 個字級常數各加一行 `@Deprecated('...')` | 🟢 已驗證 `deprecated_member_use: info` |
| `lib/main.dart` | `PlatformApp` 加 `material:` 參數 + import `theme/app_theme.dart` | 🔴 **最高風險，唯一 owner** |
| `lib/flow/main/view/filter_tags_widget.dart` | 修正 `selectedColor` | 🟡 AC-6 |

### 明確不動

| 路徑 | 理由 |
| :--- | :--- |
| `lib/gen/colors.gen.dart` | AC-15。FlutterGen 生成檔，`git diff` 必須為空 |
| `lib/flow/signinup/view/sign_in_page.dart` | R-2 / T-1，S3 處理 |
| 其餘 33 處裸 `Colors.xxx`（13 檔） | T-2，S2/S3/S4 處理 |
| `test/**`（13 檔） | §2.5，不新增不修改 |
| `analysis_options.yaml` | 現有規則已足夠 |
| `pubspec.yaml` | S1 零新依賴 |

**不建立**：`lib/theme/app_colors.dart`（§2.3）、`lib/theme/app_spacing.dart`（§2.4）

---

## 4. 任務拆分

### T0 — 建立視覺基準線截圖

- **目標**：在動任何程式碼前，把 8 個頁面的現況截圖存檔（M-1）
- **寫入檔案**：`docs/screenshots/s1-before/*.png`（純資產，不碰 `lib/`）
- **複雜度**：`快/便宜`（機械操作）
- **相依**：無
- **可並行**：✅ 與 T1 / T2 / T6 並行
- **步驟**：
  1. 啟動 iPhone SE 模擬器（375pt 寬，AC-8 指定）
  2. 逐頁截圖：`main`、`restaurant`（詳情）、`favor`、`filter`、`signinup`、`settings`、`splash`、`photo_viewer`
  3. 存為 `docs/screenshots/s1-before/<page>.png`
- **驗收**：8 個 `.png` 檔存在，且 `main.png` 中可見 `FilterChip`（需先套一個篩選條件），否則 AC-6 無對照組
- **⚠️ 這是唯一不可補做的任務**。程式碼一改，基準線就永遠拿不到了。

---

### T1 — 建立 `app_text_theme.dart`

- **目標**：定義 5 個字級的 `TextTheme`
- **寫入檔案**：`lib/theme/app_text_theme.dart`（新增）
- **複雜度**：`快/便宜`
- **相依**：無（§2.1 已定案數值）
- **可並行**：✅ 與 T0 / T2 / T6 並行
- **內容**：見 §2.1 的程式碼片段
- **實作注意**：
  - `abstract final class` + `static const`（Dart 3，避免可實例化的工具 class）
  - `TextStyle(fontSize: 22)` 必須是 `const`（`prefer_const_constructors`）
  - 單引號（`prefer_single_quotes`）
  - import 用 `package:flutter/material.dart`（絕對路徑套件，`prefer_relative_imports` 只管專案內部）
- **驗收**：`rtk flutter analyze lib/theme/app_text_theme.dart` → 無 issue

---

### T2 — 填實 `Dimens`

- **目標**：空 class → 5 個間距 + 3 個圓角常數
- **寫入檔案**：`lib/utils/dimens.dart`（修改，全檔重寫）
- **複雜度**：`快/便宜`
- **相依**：無
- **可並行**：✅ 與 T0 / T1 / T6 並行
- **內容**：見 §2.2 的程式碼片段
- **實作注意**：
  - `class Dimens {}` → `abstract final class Dimens { ... }`。**這是 breaking change 嗎？不是** —— 實測零使用點，且 `abstract final` 只禁止「實例化與繼承」，沒人在做這兩件事。
  - 不需要 import 任何東西（純 `double` 常數）。⚠️ 若手滑加了 `import 'package:flutter/material.dart';` 會觸發 `unused_import: warning`，**直接破壞 AC-1**。
- **驗收**：`rtk flutter analyze` 全專案仍 `No issues found!`

---

### T6 — 舊字級常數標 `@Deprecated`

- **目標**：10 個字級常數加上 deprecation 標記，指向新的 `TextTheme` 角色
- **寫入檔案**：`lib/utils/ui_constants.dart`（修改，只動 25-34 行區段）
- **複雜度**：`快/便宜`
- **相依**：無（訊息內容引用 `AppTextTheme` 但只是字串，不是 import）
- **可並行**：✅ 與 T0 / T1 / T2 並行
- **實作**：在 `// Dimens` 註解區塊的 10 個常數上各加一行。訊息採 §2.1 的映射表：

```dart
  // Dimens
  // ponytail: 保留不刪，29 處使用點待 S4 遷移（T-3）。移除是 S4 之後的獨立 PR。
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xlFontSize = 10;
  @Deprecated('改用 Theme.of(context).textTheme.labelSmall')
  static const double lFontSize = 12;
  @Deprecated('改用 Theme.of(context).textTheme.bodyMedium')
  static const double mFontSize = 14;
  @Deprecated('改用 Theme.of(context).textTheme.bodyLarge')
  static const double hFontSize = 16;
  @Deprecated('改用 Theme.of(context).textTheme.titleMedium')
  static const double xhFontSize = 18;
  @Deprecated('改用 Theme.of(context).textTheme.titleMedium（實測僅 1 處）')
  static const double xxhFontSize = 20;
  @Deprecated('改用 Theme.of(context).textTheme.titleLarge')
  static const double xxxhFontSize = 22;
  @Deprecated('改用 Theme.of(context).textTheme.titleLarge')
  static const double xxxxhFontSize = 24;
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xxxxxhFontSize = 26;
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xxxxxxhFontSize = 28;
```

- **實作注意**：`@Deprecated` 的訊息必須用**單引號**（`prefer_single_quotes`）
- **驗收**：
  1. `rtk flutter analyze` 仍為 `No issues found!`（R-3 已驗證 `deprecated_member_use: info` 不計入）
  2. **若 analyze 意外出現 29 個 warning**，代表 R-3 的前提有誤 → 立即停止，回報使用者，不要自行改 `analysis_options.yaml`
  3. 10 個常數**皆未被刪除**（AC-14）

---

### T3 — 建立 `app_theme.dart` 並掛上 `PlatformApp`

- **目標**：組裝 `ThemeData` 並接到 `main.dart`。**這是整個 S1 的核心，也是唯一的高風險任務。**
- **寫入檔案**：
  - `lib/theme/app_theme.dart`（新增）
  - `lib/main.dart`（修改）
- **複雜度**：`最強推論`（跨層整合 + 第三方套件 API + M3 破壞性風險）
- **相依**：**必須等 T1 完成**（要 import `AppTextTheme`）、**必須等 T0 完成**（沒基準線不准動 code）
- **可並行**：❌ **序列。`main.dart` 只有一個 owner，就是這個任務。**

#### T3-a：`lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

import '../gen/colors.gen.dart';
import 'app_text_theme.dart';

/// App 的 Material 3 主題。
///
/// S1 定案：色票只做 `ColorScheme.fromSeed`，零 `copyWith` 覆寫（規格 §4.4 / R-1）。
/// 奶油白 surface 延到 S2（債務 T-6）。深色模式不做（D-3），`darkTheme` 留空。
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorName.appPrimaryColor,
        ),
        textTheme: AppTextTheme.textTheme,
      );
}
```

- **實作注意**：
  - import 順序：`package:` → 相對路徑（Style Guide §3.1）
  - `../gen/colors.gen.dart` 與 `app_text_theme.dart` 皆用**相對路徑**（`prefer_relative_imports`）
  - `ColorScheme.fromSeed` 不是 const constructor，所以 `light` 用 `get` 而非 `static const`。⚠️ 不要硬加 `const` 觸發編譯錯誤。
  - **零 `copyWith`**（AC-11）。不要「順手」加 `surface`、`appBarTheme`、`scaffoldBackgroundColor` —— 任何一個都會破壞 AC-7。
  - **不宣告 `darkTheme`**（AC-12）。連 `static ThemeData? get dark => null;` 都不要寫，那是 scaffolding。

#### T3-b：`lib/main.dart` 掛載

在既有 `PlatformApp(...)` 加一個參數，並在檔頭 import：

```dart
import 'theme/app_theme.dart';   // 相對路徑，放在 routes/routes_table.dart 之後
```

```dart
      routes: routesTable,
      material: (_, __) => MaterialAppData(theme: AppTheme.light));
```

- **API 已實測驗證**（`~/.pub-cache/hosted/pub.dev/flutter_platform_widgets-10.0.1/`）：
  - `platform_app.dart:364` → `final PlatformBuilder<MaterialAppData>? material;`
  - `widget_base.dart:12` → `typedef PlatformBuilder<T> = T Function(BuildContext context, PlatformTarget platform);`
  - `platform_app.dart:550` → `final data = material?.call(context, platform(context));`
  - `MaterialAppData` 建構式（`platform_app.dart:168-207`）含 `this.theme` / `this.darkTheme` / `this.themeMode`，皆為具名選填
  - **關鍵**：`platform_app.dart:552+` 對每個欄位都做 `data?.X ?? X`。所以 `MaterialAppData(theme:)` **只覆蓋 theme**，既有的 `navigatorKey` / `locale` / `routes` / `title` 等外層參數**全部保留**，不需要在 `MaterialAppData` 裡重複一遍。
  - `darkTheme:` 不傳 → `data?.darkTheme ?? _getMaterialDarkThemeData(context)` → 專案無 `PlatformProvider` 設定，結果為 `null`。**AC-12 自動滿足，不需寫任何東西。**
  - ⚠️ 套件會對 theme 做 `.copyWith(platform: TargetPlatform.android)`（line 592）。這是套件行為，不算我們的 `copyWith` 額度。
- **`MaterialAppData` 是否需要額外 import？** `flutter_platform_widgets.dart` 已在 `main.dart:5` import，`MaterialAppData` 由該 barrel 匯出。**不需要新 import**。若 IDE 自動加了額外 import，刪掉 —— `unused_import: warning` 會破壞 AC-1。
- **驗收**：
  1. `rtk flutter analyze` → `No issues found!`
  2. `dart format --set-exit-if-changed lib/` → exit 0
  3. `rtk flutter test` → 13 檔全綠
  4. App 能在模擬器啟動，不 crash

---

### T4 — 修正 `FilterChip` 主色（AC-6）

- **目標**：讓選中態顯示品牌橘
- **寫入檔案**：`lib/flow/main/view/filter_tags_widget.dart`（修改，約 61-63 行）
- **複雜度**：`快/便宜`
- **相依**：**必須等 T3 完成**（沒有 theme 就無從驗證）
- **可並行**：❌ 序列（在 T3 之後）

#### 兩個方案，選 A

**方案 A（採用）— 保持最小 diff，只改一個 token 來源**：

```dart
selectedColor: Theme.of(context).colorScheme.primary,
```

`primaryColor` 是 M2 遺留 API，在 M3 下語意模糊；`colorScheme.primary` 是 M3 的正解。`checkmarkColor: Colors.white` 與 `labelStyle: TextStyle(color: Colors.white)` **保留不動** —— 它們是 T-2 債務的一部分，S2 才處理，S1 動它會污染 AC-7。

**方案 B（不採用）— 移除 `selectedColor`，讓 M3 預設接管**：
diff 更小（刪一行），但 M3 的 `FilterChip` 選中態預設是 `secondaryContainer`（淡橘），配上硬編碼的白色文字會**對比度不足**（可讀性事故）。修好它就得連 `labelStyle` 一起改，範圍溢出到 S2。**否決。**

- **驗收**：
  1. 模擬器套用篩選條件，`FilterChip` 選中態為品牌橘 `#D84A20`，白字白勾清晰可讀
  2. 與 T0 的 `main.png` 比對，**只有 chip 顏色變化**
  3. `rtk flutter test test/filter_tags_widget_test.dart` → 綠（該測試只斷言結構與文字，不受影響）

---

### T5 — 驗證與截圖比對

- **目標**：證明 AC-1～AC-16 全數成立
- **寫入檔案**：`docs/screenshots/s1-after/*.png` + 比對結論寫入 PR description（**不產生額外 .md 報告檔**）
- **複雜度**：`標準`（機械但需判斷）
- **相依**：T0、T3、T4 全部完成
- **可並行**：❌ 序列（最後一步）
- **步驟**：見 §5

---

### 並行分組總結

| 波次 | 任務 | 說明 |
| :---: | :--- | :--- |
| **波 1（4 個並行）** | T0（截圖）、T1（typography）、T2（Dimens）、T6（@Deprecated） | 寫入路徑互不重疊：`docs/screenshots/` ／ `lib/theme/app_text_theme.dart` ／ `lib/utils/dimens.dart` ／ `lib/utils/ui_constants.dart` |
| **波 2（序列）** | T3（app_theme + main.dart） | `main.dart` 唯一 owner。需 T0（基準線）+ T1（AppTextTheme） |
| **波 3（序列）** | T4（FilterChip） | 需 T3 |
| **波 4（序列）** | T5（驗證） | 需 T0 + T3 + T4 |

**共 7 個任務（T0–T6），最大並行度 4。**

> 若採 subagent-driven：波 1 開 4 個 subagent 平行執行（T0 需模擬器，實務上可能得由主 session 做）。
> 若採 parallel session：波 1 的 T1 / T2 / T6 三個純程式碼任務適合分給 3 個 session，T0 由主 session 操作模擬器。
> **成本評估**：T1/T2/T6 各約 15 行改動，並行的協調成本可能高於直接依序做完。**建議：波 1 由單一 session 依序完成（總計約 45 行），把力氣留給 T3。**

---

## 5. 驗證計畫

### 5.1 靜態（每個任務後都跑）

```bash
rtk flutter analyze                       # 必須是 No issues found!  (AC-1, AC-3)
dart format --set-exit-if-changed lib/    # exit 0                   (AC-2)
```

**AC-1 的兩個地雷**（`analysis_options.yaml:14-16`）：

1. `unused_import: warning` — 新增 4 個檔案的 import 時，任何殘留未使用 import 都會讓 analyze 失守。`dimens.dart` 不需要任何 import；`main.dart` 不需要為 `MaterialAppData` 加 import。
2. `deprecated_member_use: info` — T6 的前提。若 T6 後 analyze 冒出 29 個 warning，**停止並回報**，不自行改 `analysis_options.yaml`。

### 5.2 功能回歸

```bash
rtk flutter test        # 13 個測試檔全綠 (AC-4)
```

**原則上不新增測試**（§2.5）。既有測試的價值在於「theme 掛上後 widget 結構不變」，這正是 S1 要證明的事。唯一例外是跨平台 theme 解析（`app_theme_platform_test.dart`），理由見 §2.5 的偏離註記。

手動主流程（AC-5）：列表滾動載入 → 收藏切換 → 篩選套用 → 訪客模式。

### 5.3 視覺（本階段核心）

**基準線比對**（AC-7）：T0 的 `s1-before/` 對 T5 的 `s1-after/`，逐頁檢查。

**必驗頁面 8 個**，每頁記錄判定：

| 頁面 | 預期 | 重點檢查 |
| :--- | :--- | :--- |
| `main` | ✅ FilterChip 變橘（AC-6，唯一預期變化） | Drawer 6 個 `ListTile` 文字色/間距、AppBar 標題**位置**（M3 Android `centerTitle` 行為）、2 個 `TextButton` 文字色（藍→橘）、`PlatformTextField` 游標色 |
| `restaurant` | 無變化 | `Scaffold` 底色（純白 → M3 中性色）、字級 |
| `favor` | 無變化 | 同上 |
| `filter` | 無變化 | 1 個 `PlatformElevatedButton`（未明寫 color → 會變橘 + M3 圓角/內距 → **可能改變版面高度**） |
| `signinup` | 無變化 | 藍色主按鈕**必須維持藍**（R-2 / T-1，明寫顏色故不受影響）、2 個 `TextButton`、2 個 `PlatformTextField` iOS/Android 雙平台 |
| `settings` | 無變化 | 2 個 `PlatformElevatedButton` |
| `splash` | 無變化 | — |
| `photo_viewer` | 無變化 | `AppBar` |

**必驗小螢幕**（AC-8）：iPhone SE / 375pt 寬，重點是 `filter` 與 `settings` 的 `PlatformElevatedButton` —— M3 按鈕內距變大最可能在窄螢幕撐破版面。

**判定規則**：AC-6 以外的每一處差異都必須明確標記為「可接受」或「需修正」。**「沒注意到」不是判定。**

**已知會變、預期可接受**：
- `CircularProgressIndicator`（`component/loading_widget.dart`）藍 → 橘。屬修正。
- 6 個 `AppBar` 背景色**不變**（全部明寫 `ColorName.appPrimaryColor`）、標題文字色與字級**不變**（全部明寫 `Colors.white` + `UIConstants.xxxFontSize`）。實測確認。

---

## 6. 風險與回滾

### 6.1 最可能出錯的一步：**T3**

| # | 風險 | 徵兆 | 對策 |
| :---: | :--- | :--- | :--- |
| R1 | **M3 元件版面破裂**（最高機率）。`PlatformElevatedButton` 的 M3 內距/圓角比 M2 大，可能撐破 `filter` / `settings` 的版面 | AC-8 小螢幕截圖出現溢出或按鈕變形 | **不要**用 `copyWith` 補 `elevatedButtonTheme`（違反 AC-11 精神且擴大範圍）。記為債務交給 S2（共用元件階段本來就要處理按鈕），或在該頁明寫尺寸。若嚴重到不可用 → 見 6.2 |
| R2 | **AppBar 標題對齊改變**。M3 的 `centerTitle` 預設行為與 M2 在 Android 上可能不同 | 截圖中標題從靠左變置中（或反之） | 若真的變了，在受影響的 `AppBar` 明寫 `centerTitle: false`。這是 4 個字的改動，範圍可控 |
| R3 | **`unused_import` 破壞 AC-1** | `flutter analyze` 出現 warning | 逐一刪除未使用 import。這是最容易犯也最容易修的錯 |
| R4 | **`flutter_platform_widgets` API 誤用** | 編譯失敗 | 已實測驗證簽名（§T3-b）。若仍失敗，直接讀 `~/.pub-cache/hosted/pub.dev/flutter_platform_widgets-10.0.1/lib/src/platform_app.dart:335-620` |
| R5 | **`Scaffold` 底色偏移**。`ColorScheme.fromSeed(#D84A20).surface` 是帶暖調的近白，非純白 | 8 頁底色全部略偏暖 | R-1 已預期此變化為「差異極小、可接受」。若截圖顯示差異明顯 → **這是 R-1 的前提失效，回報使用者重新決策**，不要自行加 `copyWith`（那是 T-6 / S2 的事） |

### 6.2 回滾

**S1 是單一 PR**。回滾成本是一行：

```bash
git revert <commit>
```

`flutter_platform_widgets` 原生支援 `material:` 參數，無套件更換、無依賴變動、無資料遷移（M-6）。最壞情況 App 完整回到現狀。

**分層回退**（若只想放棄一部分）：

| 想放棄 | 做法 | 剩餘價值 |
| :--- | :--- | :--- |
| 只放棄 M3（保留 token） | `ThemeData(useMaterial3: false, ...)` | token 仍在，`FilterChip` 仍變橘，M3 破壞性歸零。**這是 R1/R2 惡化時的第一道防線** |
| 只放棄 theme（保留 token） | 移除 `main.dart` 的 `material:` 一行 | `Dimens` / `AppTextTheme` 仍可被 S2 使用，但 AC-6 失效 |
| 全放棄 | `git revert` | 回到現狀 |

> `useMaterial3: false` 這個逃生口值得先知道，但**不要預先寫進程式碼**。預留 flag 是 scaffolding；真的需要時改一個 bool 是 5 秒的事。

### 6.3 承接債務（S1 交付時須帶出）

| # | 債務 | 承接 |
| :---: | :--- | :---: |
| T-1 | `sign_in_page.dart:180` 硬編碼藍 | S3 |
| T-2 | 33 處裸 `Colors.xxx`、13 檔（含 `filter_tags_widget` 的 `Colors.white` ×2） | S2/S3/S4 |
| T-3 | 10 個 `@Deprecated` 字級常數、29 處使用、14 檔待遷移 | S4，之後獨立 PR 移除 |
| T-6 | 奶油白 `surface` (`#FFFBF7`) 覆寫，3 個 `copyWith` 額度完整保留 | S2 |
| **T-7（新增）** | **`lib/theme/app_colors.dart` 不存在**（§2.3 判定不需要）。若 S2 引入 T-6 的 `surface` 覆寫後色彩定義開始分散，屆時再建立此檔 | S2 評估 |
| **T-8（新增）** | **`titleLarge` 語意重疊**：`main_page` AppBar 用 24，其餘標題用 22，S1 未統一 | S3 |

---

## 7. Commit

單一 commit（AC-16，Conventional Commits，英文祈使句帶 scope）：

```
feat(theme): add design system foundation with Material 3
```

---

## 8. 需要使用者確認的兩件事

1. **§2.3 — 不建立 `app_colors.dart`**。AC-9 字面要求四個檔案，本計畫交付**四個關注點但只有兩個新檔**（色彩就是 `fromSeed` 一行，另建檔案會是空殼 + 第二個真相來源）。若堅持四檔對齊文件，請明說。
2. **§2.5 — 不新增任何測試**。S1 沒有新增邏輯分支，真正的風險（視覺 regression）測試抓不到，驗證力氣全部押在 T0/T5 的截圖比對。若期待有測試產出，請明說。
