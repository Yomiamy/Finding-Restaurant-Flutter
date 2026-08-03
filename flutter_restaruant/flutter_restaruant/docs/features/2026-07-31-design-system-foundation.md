# S1 — Design System 地基 (Design System Foundation)

> 功能規格（STAGE 0a：What & Why）
> 出處：`docs/brainstorm/2026-07-30_features_brainstorm.md` §6（UI/UX 視覺重塑計畫）的 **S1 階段**
> 本文件**不含**實作細節、逐行異動與任務拆分——那是 STAGE 0b 實作計畫的內容。
> 撰寫日期：2026-07-31
> 定案更新：2026-07-31（§4.3、§4.4 兩項範圍決策經使用者拍板）

## 重要變更 (Changelog)

| 日期 | 變更 |
| :--- | :--- |
| 2026-08-01 | `app_typography` 關注點更名為 `app_text_theme`（實際檔案為 `lib/theme/app_text_theme.dart`、class `AppTextTheme`）。本文內文已同步為新名 |
| 2026-08-01 | **目錄改為 features-first**：`lib/theme/` → `lib/features/foundation/style/`，並統一 `theme_` 前綴：`theme_data.dart`（`AppThemeData`）／`theme_color.dart`（`ThemeColor`）／`theme_text_style.dart`（`ThemeTextStyle`、`ThemeFontSize`）／`theme_size.dart`（`ThemeSize`），對外走 `style_barrel.dart`。AC-9、AC-13 已同步 |
| 2026-08-01 | **移除 FlutterGen colors 生成鏈**：刪除 `assets/colors.xml`、`lib/gen/colors.gen.dart` 與 pubspec 的 `flutter_gen:` 區塊，品牌色改由手寫的 `ThemeColor` 管理。原 AC-15「不得手改生成檔」已失去對象，改寫為現況；M-4 同步 |

## 定案摘要 (Ratified Decisions)

| # | 決策 | 狀態 | 詳見 |
| :--- | :--- | :---: | :--- |
| R-1 | S1 的 `ColorScheme` **零 `copyWith` 覆寫**，只做 `fromSeed(#D84A20)`。奶油白 `surface` 延到 S2 | ✅ 已定案 | §4.4 |
| R-2 | `sign_in_page.dart:180` 硬編碼藍**不在 S1 修**，留給 S3，列為債務 T-1 | ✅ 已定案 | §4.3 |
| R-3 | 舊字級常數標 `@Deprecated` **不影響** AC-1，因 `analysis_options.yaml:16` 已設 `deprecated_member_use: info` | ✅ 已驗證 | §3.1 AC-1、§5.3 M-3 |

---

## 1. 問題陳述 (Problem Statement)

### 1.1 根因：整個 App 沒有 Theme

`lib/main.dart:52-64` 的 `PlatformApp` 只設定了 `navigatorKey`、`locale`、`localizationsDelegates`、`supportedLocales`、`debugShowCheckedModeBanner`、`title`、`routes`，**不存在 `material:` 或 `cupertino:` 參數**。

直接後果：

* 沒有 `ThemeData`
* 沒有 `ColorScheme`
* 沒有 `TextTheme`
* 沒有 Material 3

所有樣式皆由各 widget 自行硬編碼。**這不是樣式問題，是資料結構問題**——設計 token 是 UI 的資料結構，它現在不存在。

### 1.2 實測證據

| # | 症狀 | 證據位置（實測） |
| :--- | :--- | :--- |
| E-1 | **主題色取用失效（實錘）** | `lib/flow/main/view/filter_tags_widget.dart:61` 使用 `selectedColor: Theme.of(context).primaryColor`。因無 theme，取得的是 Material **預設藍**，與同畫面 AppBar 的品牌橘 `#D84A20` 衝突 |
| E-2 | 全 App 色票僅 2 個 token | `lib/gen/colors.gen.dart` 只有 `appPrimaryColor = Color(0xFFD84A20)` 與 `backBtnColor = Color(0xFFFFFFFF)`。此檔為 FlutterGen 生成檔（來源 `assets/colors.xml`），標明 DO NOT MODIFY BY HAND |
| E-3 | 顏色硬編碼散落 | 裸用 `Colors.xxx` 共 **33 處、13 個檔案**（`sign_in_page` 6、`settings_page` 5、`restaurant_info_cell` 5、`restaurant_item_cell` 4、`main_page` 3、`filter_tags_widget` 2、`filter_page` 2、其餘 7 檔各 1） |
| E-4 | 品牌識別錯誤 | `lib/flow/signinup/view/sign_in_page.dart:180` 主要登入按鈕為 `Color.fromARGB(255, 5, 97, 245)`（硬編碼藍），與品牌橘無關 |
| E-5 | 字級為無語意常數 | `lib/utils/ui_constants.dart:25-34` 共 **10 個**（`xlFontSize=10` ～ `xxxxxxhFontSize=28`），被使用 **29 次、跨 14 個檔案**。`xxxxxxhFontSize` 無法從命名判讀實際大小 |
| E-6 | `Dimens` 是空殼 | `lib/utils/dimens.dart` 全檔內容為 `class Dimens {}` |
| E-7 | 間距無系統 | `EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 0)` 等手感值散落各處 |
| E-8 | `lib/theme/` 目錄不存在 | — |

### 1.3 為何現在做 / 為何先做

* **E-1 是使用者當下就看得到的錯誤**：篩選標籤顯示藍色、AppBar 顯示橘色，同一畫面兩種主色。這不是設計選擇，是缺少 theme 的直接後果。
* **槓桿順序**：S2（共用元件）、S3（頁面改造）、S4（收尾）都要「套用 token」。沒有 S1，後續每個階段都退化成各頁貼膠帶，改一個顏色要動十幾個檔案。
* **阻擋其他 Roadmap 項目**：Phase 1.5 的地圖 Carousel、fluster 聚類、情境化標籤都需要 theme 才能正確著色（見報告 §6.9）。

---

## 2. 使用者故事 (User Stories)

### 2.1 對終端使用者

> **身為**使用餐廳列表的使用者，
> **我希望**篩選標籤的顏色與 App 主色一致，
> **以便**我不會誤以為藍色標籤是另一種功能或狀態。

**誠實說明：S1 對終端使用者幾乎無感。**
本階段唯一使用者可見的變化，就是 `filter_tags_widget.dart` 的 `FilterChip` 由 Material 預設藍轉為品牌橘。其餘所有畫面**應維持外觀不變**（見 §5 風險評估）。

報告 §6.7 已明確標示 S1 的「使用者可感知度：低」。若期待「App 變好看了」，那是 S2（共用元件，可感知度高）與 S3（頁面改造，可感知度高）的產出。**S1 的價值是使 S2/S3 成為可能，而非本身好看。**

§4.4 定案「零 `copyWith` 覆寫」後，此結論更為徹底：S1 連奶油白底色都不做，使用者可感知的變化**只剩 FilterChip 一處**。這是刻意的——地基階段的價值在於可被證明沒有破壞任何東西。

### 2.2 對開發者

> **身為**要改一個顏色的開發者，
> **我希望**只需修改一處 token，
> **以便**不用在 13 個檔案裡 grep `Colors.grey` 逐一比對。

> **身為**要新增畫面的開發者，
> **我希望**字級有語意命名（`titleLarge` 而非 `xxxxhFontSize`），
> **以便**我不用先數 x 的個數才知道字有多大。

> **身為**要實作 S2/S3 的開發者，
> **我希望**有一組已定義的 `ColorScheme` / `TextTheme` / 間距 token，
> **以便**共用元件與頁面改造是「套用」而不是「手刻」。

---

## 3. 驗收條件 (Acceptance Criteria)

### 3.1 靜態品質（硬性）

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| AC-1 | `flutter analyze` 維持 **`No issues found!`** | 目前為零警告，**不得回退**。<br>**已驗證無衝突**：`analysis_options.yaml:16` 的 `errors:` 區塊已設 `deprecated_member_use: info`，`info` 層級不計入 `flutter analyze` 的 issue 輸出。故 AC-14 對舊字級常數標 `@Deprecated` 後，29 處使用點**不會**破壞本條件（詳見 §5.3 M-3） |
| AC-2 | `dart format` 通過，無差異 | `dart format --set-exit-if-changed .` |
| AC-3 | 遵守 `analysis_options.yaml` 既有 10 條額外規則 | 含 `prefer_const_constructors`、`prefer_single_quotes`、`unnecessary_this`、`always_declare_return_types` |

### 3.2 功能回歸（硬性）

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| AC-4 | 既有 **13 個測試檔全綠** | `flutter test` |
| AC-5 | 手動驗證主流程無 regression | 列表滾動載入、收藏切換、篩選套用、訪客模式流程 |

### 3.3 視覺（本階段核心）

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| AC-6 | `filter_tags_widget.dart` 的 `FilterChip` 選中態顯示**品牌橘**，不再是 Material 預設藍 | 模擬器實跑截圖 |
| AC-7 | **既有畫面無非預期外觀變化** | 逐頁截圖比對改造前後。必驗頁面：`main`、`restaurant`、`favor`、`filter`、`signinup`、`settings`、`splash`、`photo_viewer`。任何 AC-6 以外的差異都必須被記錄並判定為「可接受」或「需修正」 |
| AC-8 | **必驗小螢幕**（iPhone SE / 375pt 寬）無版面破裂 | 模擬器實跑 |

### 3.4 架構產出（可檢查）

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| AC-9 | `lib/features/foundation/style/` 目錄存在，包含 `theme_data` / `theme_color` / `theme_text_style` / `theme_size` 四個關注點，並以 `style_barrel.dart` 對外 | 檔案存在。原訂路徑為 `lib/theme/`，實作時改採 features-first 結構（見文首 Changelog） |
| AC-10 | `PlatformApp` 已掛載 `material:` 參數 | `lib/main.dart` |
| AC-11 | 色票為 `ColorScheme.fromSeed(seedColor: #D84A20)`，**零 `copyWith` 覆寫**（已定案，見 §4.4） | Code review。D-4 的額度是「≤3 個」，S1 用 **0 個**，額度留給 S2 |
| AC-12 | `darkTheme` 留空（不交付深色色值） | Code review（D-3） |
| AC-13 | 間距與圓角 token 集中於 `theme_size.dart` 的 `ThemeSize` | 檔案內容。原訂放 `lib/utils/dimens.dart`，該空殼檔已刪除（見文首 Changelog） |
| AC-14 | `ui_constants.dart` 的 10 個字級常數標記 `@Deprecated`，**且未被移除** | 檔案內容。移除是 S4 之後的獨立 PR |
| AC-15 | 品牌色以手寫的 `ThemeColor` 管理，FlutterGen 的 colors 生成鏈已移除 | `assets/colors.xml`、`lib/gen/colors.gen.dart` 與 pubspec 的 `flutter_gen:` 區塊皆已刪除（見文首 Changelog）。原條件為「不得手改生成檔」，改為直接不再生成 |
| AC-16 | commit 遵循 Conventional Commits（英文祈使句，帶括號 scope） | 例如 `feat(theme): add design system foundation` |

---

## 4. 範圍邊界 (Scope)

### 4.1 S1 要做

| 項目 | 說明 |
| :--- | :--- |
| 建立 `lib/features/foundation/style/` | `theme_data`（ThemeData 組裝）、`theme_color`（品牌原始色）、`theme_text_style`（TextTheme 與字級原始值）、`theme_size`（間距/圓角 token）。原訂路徑 `lib/theme/`，見文首 Changelog |
| `PlatformApp` 掛上 `material:` | 整個改動的起點 |
| 建立 `ThemeSize` | 間距與圓角 token。階梯依實測既有值採 5 的倍數（非 4 的倍數），使既有使用點能一對一替換、零視覺變更。原訂填實 `lib/utils/dimens.dart`，該空殼檔已刪除 |
| 舊字級常數標 `@Deprecated` | 保留不刪，避免一次性編譯失敗 |
| 修正 `FilterChip` 的主色來源 | E-1 的直接修復，S1 唯一使用者可見成果 |

### 4.2 S1 不做（明確排除）

| 項目 | 所屬階段 | 理由 |
| :--- | :--- | :--- |
| 改共用元件（`RestaurantItemCell` / `RatingStars` / Skeleton / `EmptyDataWidget`） | **S2** | 需先有 token 才能套用 |
| 改頁面版面（詳情頁 / 登入頁 / 列表頁） | **S3** | 同上 |
| 掃除 33 處裸 `Colors.xxx` | **S2/S3/S4** | 各階段順手改，S4 做最後一次 grep 確認歸零。S1 若一次全掃，diff 會混入大量與 theme 無關的改動，讓 AC-7 的截圖比對失去意義 |
| 移除假延遲（過濾硬等 2 秒） | **S4** | D-7 決策項，非地基 |
| 刪除 11 張 PNG 資產 | **S4** | 與 D-5（星等改 Icon 繪製）連動 |
| 移除舊 `UIConstants` 字級常數 | **S4 之後的獨立 PR** | 全數遷移後才移除 |
| 深色模式 | **不做** | D-3。`darkTheme` 留空，但 token 架構不阻擋未來補做 |
| 頁面轉場動畫、收藏彈跳動效 | **不做** | 報告 §6.8：在還會硬等 2 秒的 App 上做轉場動畫，等於幫塞車的路口重鋪柏油 |
| 引入 `shimmer` 套件 | **S2 待決** | 專案目前**沒有**此依賴。S2 先自繪，超過 40 行才改用套件 |

### 4.3 已定案：`sign_in_page.dart:180` 的硬編碼藍**不在 S1 修**

> **狀態：✅ 已定案（2026-07-31 使用者拍板）**。原為待決範圍問題，現確認不納入 S1，留給 **S3 登入頁改造**。

**決定：❌ S1 不修。留給 S3。** 維持列為債務 **T-1**（見 §5.4）。

理由：

1. **它不是 theme 缺失造成的**。E-1 的 `FilterChip` 藍色是「取用 theme 但取不到」的直接後果——掛上 ThemeData 就自動修好，屬於 S1 的必然產出。而 `sign_in_page.dart:180` 是**明寫**的 `Color.fromARGB(255, 5, 97, 245)`，掛上 theme 對它零影響。修它需要一次獨立的、有意識的決定。

2. **它會污染 AC-7 的驗證**。S1 的核心驗收是「除了 FilterChip，其餘畫面外觀不變」。這個判準之所以有價值，正是因為它嚴格——只要多一處主動改色，「不變」就變成「不變，除了⋯⋯」，S1 就無法乾淨地證明掛上 ThemeData 沒有意外破壞既有畫面。**一個乾淨的地基驗證，比省下 S3 的一行改動更值錢。**

3. **改一行不等於改一處**。登入按鈕改成品牌橘後，它旁邊的次要按鈕、訪客模式入口（目前是灰色小字）、輸入框樣式的相對關係全部改變——報告 §6.3 已把登入頁列為「必做」正是因為這是整頁的視覺識別問題。單獨把主按鈕變橘，只會做出一個「橘按鈕配灰入口」的半成品。這是 S3 的整頁工作，不是順手一行。

4. **它不是緊急錯誤**。它醜、它錯，但它已經這樣好幾個版本，不會因為晚兩個 PR 修而造成任何損失。

**配套要求**：S1 交付時必須把它列入已知債務清單（§5.4 的 T-1），確保 S3 不會漏掉。

---

### 4.4 已定案：S1 的 `ColorScheme` **零 `copyWith` 覆寫**

> **狀態：✅ 已定案（2026-07-31 使用者拍板）**。原列於 §5.3 M-2 為「須明確評估」的待決事項，現確認。

**決定**：S1 的色票只做 `ColorScheme.fromSeed(seedColor: const Color(0xFFD84A20))`，**不加任何 `copyWith` 覆寫**。報告 §6.4 建議的奶油白 `surface = #FFFBF7`，**延到 S2 單獨驗證**（債務 T-6）。

#### 與報告 §6.4「≤3 個 `copyWith`」的關係

**這不是推翻 D-4，是在額度內選擇用 0 個。**

D-4 的原文是**上限**（「覆寫上限 3 個，超過代表種子色選錯」），不是**配額**——它從未要求必須用滿。S1 用 0 個完全符合 D-4，並且把 3 個額度**完整保留給 S2**。屆時 S2 若要引入奶油白 `surface`，仍有 3 個額度可用，且是在共用元件已套用 token 的脈絡下驗證色調，比在空白地基上盲調更準。

#### 理由

1. **保住 AC-7 的嚴格性**。S1 的核心驗收是「除了 FilterChip，其餘畫面外觀不變」。這條判準之所以有價值，正是因為它嚴格到能證明「掛上 ThemeData 沒有意外破壞任何東西」。而 `surface` 的覆寫會**一次波及全部 8 個 `Scaffold`**（見 §5.2），全 App 每一頁底色同時偏暖——AC-7 立刻退化成「不變，除了每一頁的底色」，S1 就失去了乾淨的地基證明。

2. **奶油白是「美化」，不是「地基」**。S1 的定義是建立 token 結構（§4.1），不是決定 App 長什麼樣。挑一個暖色底這件事屬於視覺設計決策，它的正確歸屬是 S2/S3，那裡本來就要做大量視覺變更、本來就要重新截圖比對，多一個底色變化的驗證成本趨近於零；放在 S1 卻要付出「唯一可見變化」這個判準的全部價值。

3. **風險與收益不對等**。S1 加上 `surface` 覆寫，收益是「早兩個 PR 看到暖色底」，成本是失去地基階段的乾淨驗證。這筆交易不划算。

4. **可逆**。S2 要加回來只是一行 `copyWith`，額度還在。反過來，S1 混入視覺變更後才發現破版，要拆開判斷「是 M3 預設造成的還是 surface 覆寫造成的」，成本高得多。

#### 對驗收的影響

* **AC-11** 由「至多 3 個 `copyWith`」收緊為「零 `copyWith`」
* **AC-12**（`darkTheme` 留空）不變
* §5.2 的 `Scaffold` 風險等級由 🟡 降為 🟢

---

## 5. 風險與破壞性評估 (Risk & Breakage Assessment)

### 5.1 核心風險：掛上 ThemeData 等於同時開啟 Material 3

目前 App 完全沒有 `ThemeData`，所有 Material 元件走的是 framework 兜底的預設值。一旦 `PlatformApp` 掛上 `material:`，Flutter 3.35 建立的 `ThemeData` 預設 `useMaterial3: true`——**所有吃預設樣式的元件會同時切換到 M3 的形狀、字級、色彩角色**。

這是 S1 唯一的真實破壞性風險，也是 AC-7（逐頁截圖比對）存在的理由。

### 5.2 受影響元件盤點（實測）

以下為專案中會受 theme 影響的 Material 元件實際分布：

| 元件 | 出現位置 | 風險 | 說明 |
| :--- | :--- | :---: | :--- |
| `FilterChip` ×1 | `main/view/filter_tags_widget.dart` | 🟢 | **這是預期中的變化**（藍→橘），即 AC-6。形狀可能同時由 M2 圓角切為 M3 樣式，需確認可接受 |
| `AppBar` ×6 | `main_page`、`filter_page`、`favor_page`、`settings_page`、`restaurant_detail_page`、`photo_viewer` | 🟡 | **好消息**：6 處全部明寫 `backgroundColor: ColorName.appPrimaryColor`，背景色不會變。**但**：M3 的 AppBar 預設 title 不置中（Android）、`foregroundColor`/圖示色與字級改走 `ColorScheme`，可能導致標題文字色或大小改變。`sign_in_page.dart:56` 亦明寫 `backgroundColor` |
| `Scaffold` ×8 | 幾乎每頁 | 🟢 | 背景色由 framework 預設白轉為 `ColorScheme.surface`。**因 §4.4 已定案 S1 零 `copyWith`**，`surface` 為 `fromSeed` 依 M3 演算法產生的近白中性色，與現況差異極小。原本「覆寫奶油白 `#FFFBF7` 導致全 App 底色偏暖」的最大風險已被移出 S1。仍須截圖確認 M3 中性色與純白的細微色差可接受 |
| `PlatformElevatedButton` ×4 | `settings_page` ×2、`filter_page` ×1、`sign_in_page` ×1 | 🟡 | 未明寫 `color` 者會吃 `ColorScheme.primary`（變橘）。M3 的按鈕圓角、內距、陰影與 M2 不同，可能改變版面高度。`sign_in_page.dart:180` 明寫顏色故不受影響（見 §4.3） |
| `TextButton` ×4 | `sign_in_page` ×2、`main_page` ×2 | 🟡 | 文字色由預設藍轉 `ColorScheme.primary`（橘）。屬修正而非破壞，但仍需截圖確認 |
| `PlatformTextField` ×3 | `sign_in_page` ×2、`main_page` ×1 | 🟡 | 游標色、選取色、underline 色改走 `ColorScheme`。`sign_in_page` 有一處明確沿用 Cupertino decoration，需確認 iOS/Android 兩邊都不破版 |
| `ListTile` ×6 | `main_page`（Drawer） | 🟡 | 文字色、圖示色、內距改走 theme。Drawer 內 6 個項目的 leading Icon 均明寫 `color: ColorName.appPrimaryColor`，圖示色不變；但文字色與間距可能變 |
| `CircularProgressIndicator` ×1 | `component/loading_widget.dart` | 🟢 | 由預設藍轉品牌橘。屬修正 |
| `Drawer` header | `main_page.dart:130` | 🟢 | 明寫 `BoxDecoration(color: ColorName.appPrimaryColor)`，不受影響 |

### 5.3 緩解方式

| # | 緩解措施 |
| :--- | :--- |
| M-1 | **改造前先建立截圖基準線**：在動任何程式碼之前，先於模擬器逐頁截圖存檔（含 iPhone SE 375pt）。沒有基準線，AC-7 無法驗證 |
| M-2 | **S1 零 `copyWith` 覆寫**（§4.4 已定案）。這是本階段最主要的風險緩解手段：`surface` 覆寫會一次波及全部 8 個 Scaffold，把它移出 S1，AC-7 的「除 FilterChip 外外觀不變」才站得住 |
| M-3 | **舊字級常數保留不刪**，避免一次性編譯失敗。**已驗證**：`analysis_options.yaml:16` 設有 `deprecated_member_use: info`，標記 `@Deprecated` 後 29 處使用點只會產生 `info` 層級提示，不計入 `flutter analyze` 的 issue 數，AC-1 不受影響。S1 可安全標記，無須額外處理 |
| M-4 | 新 token 一律放 `lib/features/foundation/style/`。原條件為「不動 FlutterGen 生成的 `colors.gen.dart`」，該生成鏈已整套移除，改由手寫的 `ThemeColor` 管理（AC-15） |
| M-5 | **S1 不順手改任何顏色**（§4.2）。維持「唯一預期變化是 FilterChip」的乾淨驗證條件 |
| M-6 | **可回退**：S1 是單一 PR，最壞情況直接 revert，App 回到現狀。`flutter_platform_widgets` 的 `PlatformApp` 原生支援 `material:`，不需更換套件，無依賴風險 |

### 5.4 已知債務（S1 交付時須帶出，供後續階段承接）

| # | 債務 | 承接階段 |
| :--- | :--- | :--- |
| T-1 | `sign_in_page.dart:180` 硬編碼藍 `Color.fromARGB(255, 5, 97, 245)`，品牌識別錯誤。**已定案不在 S1 修**（§4.3） | **S3** |
| T-2 | 33 處裸 `Colors.xxx`、13 個檔案 | S2 / S3 / S4 |
| T-3 | 10 個 `@Deprecated` 字級常數、29 處使用、14 個檔案待遷移 | S4 遷移，之後獨立 PR 移除 |
| T-4 | 過濾流程假延遲 2 秒 | S4 |
| T-5 | 訪客模式入口為灰色小字，功能價值被 UI 埋沒 | S3 |
| T-6 | `ColorScheme` 的奶油白 `surface` (`#FFFBF7`) 覆寫。S1 已定案不做（§4.4），D-4 的 3 個 `copyWith` 額度完整保留 | **S2** |

### 5.5 依賴與相容性

| 項目 | 狀態 |
| :--- | :---: |
| `flutter_platform_widgets: ^10.0.1` 支援 `material:` 參數 | 🟢 原生支援，無須更換套件 |
| Dart SDK `>=3.5.0 <4.0.0` | 🟢 無新語言特性需求 |
| `flutter_gen_runner: ^5.8.0` | 🟢 不動生成檔即無影響 |
| 新增第三方依賴 | 🟢 **S1 不需要任何新依賴**。`shimmer` 專案目前沒有，S1 也不需要 |

---

## 6. 事實訂正紀錄 (Fact Corrections)

以下三處，來源報告 `docs/brainstorm/2026-07-30_features_brainstorm.md` §6 的敘述與實測不符。**本規格一律採用實測值**。

| # | 報告原述（§6.1 缺陷證據表 / §6.4） | 實測結果 | 影響 |
| :--- | :--- | :--- | :--- |
| C-1 | `Colors.grey` **共 12 處、分佈於 5 個檔案** | 裸用 `Colors.xxx` 實際為 **33 處、13 個檔案**（`sign_in_page` 6、`settings_page` 5、`restaurant_info_cell` 5、`restaurant_item_cell` 4、`main_page` 3、`filter_tags_widget` 2、`filter_page` 2、`banner_ad` / `restaurant_head_cell` / `restaurant_business_hour_cell` / `restaurant_detail_page` / `favor_page` / `photo_viewer` 各 1） | **規模被低估近 3 倍**。強化了 §4.2 的判斷：這 33 處不該在 S1 一次掃除，否則 diff 過大且污染 AC-7 的視覺驗證 |
| C-2 | 字級為 **12 個** 無語意常數，位於 `constants.dart` | 實際為 **10 個**（`xlFontSize=10, lFontSize=12, mFontSize=14, hFontSize=16, xhFontSize=18, xxhFontSize=20, xxxhFontSize=22, xxxxhFontSize=24, xxxxxhFontSize=26, xxxxxxhFontSize=28`），位於 **`lib/utils/ui_constants.dart:25-34`**，被使用 **29 次、跨 14 個檔案** | 檔案路徑錯誤會導致實作階段找錯檔。數量差異不影響決策 |
| C-3 | `filter_tags_widget.dart` 位於 `lib/flow/filter/` | 實際位於 **`lib/flow/main/view/filter_tags_widget.dart`** | 這是 S1 唯一使用者可見變化的所在檔案，路徑錯誤會直接導致 AC-6 找不到驗證對象 |

**補充實測（報告未記載）**：

* `Theme.of(context)` 全專案**只有 1 處**：`lib/flow/main/view/filter_tags_widget.dart:61`。這佐證了「App 完全沒有 theme 意識」，也說明 S1 掛上 ThemeData 後，**主動取用 theme 的程式碼路徑只有這一條**——其餘變化全部來自元件的隱式預設值繼承（即 §5.2 的風險來源）。
* 6 個 `AppBar` 全部明寫 `backgroundColor: ColorName.appPrimaryColor`，故 AppBar 背景色不會因掛 theme 而改變。報告未提及此點，但它顯著降低了破壞性風險。

---

## 7. 參考

* 來源報告：`docs/brainstorm/2026-07-30_features_brainstorm.md` §6.1～§6.4、§6.7、§6.8
* 決策紀錄：D-1（範圍層級）、D-2（暖食慾派、種子色 `#D84A20`）、D-3（不做深色模式但走 ColorScheme）、D-4（`fromSeed` + ≤3 `copyWith`，S1 用 0 個)
* 本規格新增定案：§4.3（`sign_in_page` 藍色按鈕留給 S3）、§4.4（S1 零 `copyWith` 覆寫）——均已於 2026-07-31 由使用者拍板
* 後續階段：S2 共用元件 → S3 頁面改造 → S4 收尾
* 下一步：STAGE 0b 實作計畫 `docs/plans/YYYY-MM-DD-design-system-foundation.md`
