# S2 — 共用元件重塑 (RestaurantItemCell & EmptyDataWidget) 功能規格

> **文件狀態**：STAGE 0a 功能規格 (What & Why)  
> **關聯需求**：§S2 共用元件重塑 (ItemCell / EmptyDataWidget)  
> **撰寫日期**：2026-08-26  
> **目標元件**：`lib/component/cell/main_page/restaurant_item_cell.dart`、`lib/component/empty_data_widget.dart`

---

## 1. 問題陳述與現況盤點 (Problem Statement)

### 1.1 根因與現況分析

本專案在完成 S1 (Design System Foundation) 後，已具備 `AppThemeData` (M3)、`ThemeColor`、`ThemeSize` 與 `ThemeTextStyle` 基礎 Token。
在 S2 階段中，`RatingStars` (取代 11 張 PNG) 與 `Skeleton` (Shimmer 骨架屏) 已先行完成，目前剩餘 **`RestaurantItemCell`** 與 **`EmptyDataWidget`** 尚未完成視覺與結構重塑：

1. **`RestaurantItemCell` (`lib/component/cell/main_page/restaurant_item_cell.dart`)**：
   - **圖片變形與無圓角**：採用 `BoxFit.fill` 導致不同比例餐廳縮圖被拉伸變形；且未套用 Design System 圓角 (`ThemeSize.radius8`)。
   - **硬編碼色值未除**：內部仍存在 4 處裸 `Colors.grey`（距離、評論數、價格、分類），未走 `Theme.of(context).colorScheme.outline` 或 `Theme.of(context).textTheme`。
   - **距離格式 Bug**：使用 `sprintf('%.2fm', [_summaryInfo.distance])`，當距離為 1523 公尺時顯示「`1523.47m`」而非「`1.5 km`」，可讀性差。
   - **資訊層級平鋪混亂**：店名、評分、價格、地址、分類缺乏清晰的字級與字重層次。
   - **窄卡片極限相容性**：需維持 Issue #72 / PR #73 修復之成果，在 298px 窄卡片（地圖 Carousel 模式）下絕對不可發生 `RenderFlex` 溢出。

2. **`EmptyDataWidget` (`lib/component/empty_data_widget.dart`)**：
   - **中文文案硬編碼**：預設字串 `'目前無任何資料'` 未透過 i18n (`S.current` / ARB) 管理。
   - **缺乏輔助提示與操作**：僅單純顯示大圖示與單行文字，未提供輔助說明（如建議調整篩選）或重試按鈕 (`onRetry` 回呼)。
   - **視覺對齊 M3**：圖示與文字需對齊 `colorScheme.outline` / `colorScheme.onSurfaceVariant` 及 `textTheme.titleMedium`。

---

## 2. 使用者故事 (User Stories)

### 2.1 終端使用者
- **身為** 探索餐廳的使用者，
- **我希望** 餐廳列表卡片中的圖片比例正常不失真、資訊層級清晰、距離顯示直覺（如 1.2 km），
- **以便** 我能快速掃描並找到心儀的餐廳。

- **身為** 搜尋無結果或最愛清單為空的使用者，
- **我希望** 看到友善的空狀態圖示與引導說明（甚至一鍵重試），
- **以便** 我知道下一步該如何操作（例如調整篩選條件）。

### 2.2 開發者
- **身為** 維護 UI 的工程師，
- **我希望** 共用元件完全使用統一的 Design System Tokens (`ThemeSize`, `ThemeTextStyle`, `ColorScheme`)，
- **以便** 全 App 維持一致的視覺語言且無散落的裸顏色常數。

---

## 3. 驗收條件 (Acceptance Criteria)

### 3.1 靜態品質（硬性）
- **AC-1**：`flutter analyze` 維持 **`No issues found!`**（零警告、零錯誤）。
- **AC-2**：`dart format --set-exit-if-changed .` 完全通過。
- **AC-3**：遵守 Style Guide 規範（嚴禁裸 `Colors.xxx`、函式簡潔、無深層巢狀）。

### 3.2 功能與視覺回歸（硬性）
- **AC-4**：`RestaurantItemCell` 圖片改用 `BoxFit.cover` 並加上 `ClipRRect(borderRadius: BorderRadius.circular(ThemeSize.radius8))`，確保縮圖不變形且有精緻圓角。
- **AC-5**：`RestaurantItemCell` 距離顯示重構：
  - `< 1000m`：顯示整數公尺（例：`583 m`）。
  - `>= 1000m`：顯示一位小數公里（例：`1.5 km`）。
- **AC-6**：`RestaurantItemCell` 徹底消除 4 處 `Colors.grey`，文字樣式與色彩全部由 `Theme.of(context).textTheme` 與 `colorScheme` 派生。
- **AC-7**：維持窄卡片佈局安全：在 298px 地圖卡片（`testWidgets('窄卡片下評分列不得溢出')`）與 `imageErrorBuilder` 測試中維持 100% 通過。
- **AC-8**：`EmptyDataWidget` 支援 i18n 多語系，預設文案走 `S.current`，並提供可選的 `subtitle` (輔助說明) 與 `onRetry` (重試按鈕回呼)。
- **AC-9**：既有全部測試檔（`flutter test`）全數通過，並補充/更新單元測試。

---

## 4. 範圍邊界 (Scope & Boundaries)

### 4.1 In-Scope (本階段要做)
1. **重構 `RestaurantItemCell`**：
   - 圖片圓角 (`ClipRRect`) 與 `BoxFit.cover`。
   - 距離格式化邏輯（消除 `sprintf` 原始公尺 bug）。
   - 分類分隔字元改為 `·` 或標準間隔。
   - 替換所有裸 `Colors.grey` 為語意化 Token。
2. **重構 `EmptyDataWidget`**：
   - 升級為支援 `title`、`subtitle`、`icon`、`onRetry`。
   - 消除硬編碼中文，對接 `intl_*.arb` 多語系。
   - 視覺樣式對齊 M3 `colorScheme` 與 `textTheme`。
3. **多語系 ARB 更新**：
   - 在 `intl_en.arb` 與 `intl_zh_TW.arb` 補齊空狀態相關翻譯。
4. **測試更新與回歸**：
   - 更新 `restaurant_item_cell_test.dart` 與新增/更新 `empty_data_widget_test.dart`。

### 4.2 Out-of-Scope (明確排除)
- ❌ **不更動資料層與 Entity**（`RestaurantEntity` 保持原樣）。
- ❌ **不改動頁面級大型佈局**（如詳情頁分區重構、登入頁表單重整，留給 S3）。
- ❌ **不新增重型第三方套件**。

---

## 5. 🐧 Linus 模式五層問題分解

### 5.1 第 1 層：資料結構分析
- 核心資料流：`RestaurantEntity` 傳入 `RestaurantItemCell` 進行純聲明式渲染；空狀態以純屬性（`icon`, `title`, `subtitle`, `onRetry`）傳入 `EmptyDataWidget`。
- 無冗餘狀態轉換，純屬 Presentation 層的 StatelessWidget。

### 5.2 第 2 層：邊界情況識別
- **圖片載入失敗 / URL 為 null**：`FadeInImage.assetNetwork` 的 `imageErrorBuilder` 必須保持自帶寬高約束（`110x110`），防止原始圖撐爆 Row。
- **長文字店名 / 地址**：維持 `TextOverflow.ellipsis` 與合理的 `maxLines`。
- **極窄螢幕 / 298px Carousel**：評分星等寬度不可壓縮（固定 5 顆星 80px），文字自適應伸縮。
- **空狀態無重試或無副標題**：`subtitle` 與 `onRetry` 設為可選，當為 `null` 時短路不渲染對應 Widget。

### 5.3 第 3 層：複雜度審查
- 移除深層無用嵌套，保持層級扁平。
- 距離格式化以簡短 pure function / extension 處理，行數 ≤ 5 行。

### 5.4 第 4 層：破壞性分析
- 影響畫面：`main_page` (餐廳列表/地圖 Carousel)、`favor_page` (收藏清單)、`restaurant_detail_page` (若有引用)。
- 驗證方式：執行既有 `restaurant_item_cell_test.dart` 與全套 widget tests，確保零破壞。

### 5.5 第 5 層：實用性驗證
- 解決真實視覺變形、距離可讀性差、硬編碼色值及無 i18n 問題，改動精準、高槓桿。
