# S2 — 共用元件重塑 (RestaurantItemCell & EmptyDataWidget) 實作計畫

> **文件狀態**：STAGE 0b 實作計畫 (How)  
> **依據規格**：[`docs/features/2026-08-26-remodel-shared-components.md`](../features/2026-08-26-remodel-shared-components.md)  
> **撰寫日期**：2026-08-26  

---

## 1. 架構與資料流分析 (Architecture & Data Flow)

本計畫聚焦於 Presentation 層共用元件的重塑，無資料層或狀態機（BLoC）模型之結構異動。

```text
[RestaurantEntity / UI Attributes]
              │
              ▼
 ┌──────────────────────────┐      ┌──────────────────────────┐
 │    RestaurantItemCell    │      │     EmptyDataWidget      │
 │  - ClipRRect + Cover 圖  │      │  - i18n 多語系文案        │
 │  - M3 TextTheme & Color  │      │  - 輔助說明 subtitle     │
 │  - 距離格式化 (m / km)   │      │  - 可選 onRetry 回呼     │
 │  - 298px 窄卡片自適應    │      │  - M3 Outline / Variant  │
 └──────────────────────────┘      └──────────────────────────┘
```

---

## 2. 檔案異動清單 (File Changes)

| 檔案路徑 | 異動類型 | 說明 |
| :--- | :---: | :--- |
| `lib/l10n/intl_en.arb` | 修改 | 新增 `empty_data_title`、`empty_data_subtitle`、`empty_data_retry` 英文語系字串 |
| `lib/l10n/intl_zh_TW.arb` | 修改 | 新增 `empty_data_title`、`empty_data_subtitle`、`empty_data_retry` 繁中語系字串 |
| `lib/component/empty_data_widget.dart` | 重構 | 支援 i18n 預設值、`subtitle`、`icon`、`onRetry`、套用 M3 ColorScheme 與 TextTheme |
| `lib/component/cell/main_page/restaurant_item_cell.dart` | 重構 | 圖片 `BoxFit.cover` + `ClipRRect(radius8)`、距離格式化、消除 4 處 `Colors.grey`、排版分層 |
| `test/component/empty_data_widget_test.dart` | 新增 | 測試 `EmptyDataWidget` 標題、副標題、圖示與 `onRetry` 點擊回呼 |
| `test/component/cell/main_page/restaurant_item_cell_test.dart` | 修改 | 更新距離格式斷言，確保 298px 窄卡片與 `imageErrorBuilder` 測試持續全綠 |

---

## 3. 任務拆分與執行順序 (Task Breakdown)

### 🔹 Task 1: 多語系與字串資源擴充 (i18n)
- **目標**：在 ARB 檔案中定義空狀態所需的標準文案，並生成相應 localization 程式碼。
- **異動檔案**：
  - `lib/l10n/intl_en.arb`
  - `lib/l10n/intl_zh_TW.arb`
- **驗證**：執行 `flutter gen-l10n` 或建置確認 `S.current.empty_data_title` 可被正確引用。

### 🔹 Task 2: 重構 `EmptyDataWidget`
- **目標**：提升空狀態元件的靈活性與視覺質感。
- **規格要點**：
  - 建構子參數：
    ```dart
    const EmptyDataWidget({
      super.key,
      this.title,
      this.subtitle,
      this.icon = Icons.restaurant_outlined,
      this.onRetry,
      this.retryText,
    });
    ```
  - 樣式：
    - 圖示使用 `Theme.of(context).colorScheme.outline`
    - 主標題使用 `Theme.of(context).textTheme.titleMedium`（預設取 `S.current.empty_data_title`）
    - 輔助說明使用 `Theme.of(context).textTheme.bodyMedium` 與 `colorScheme.outline`
    - 若傳入 `onRetry`，渲染 `OutlinedButton.icon` 或 `FilledButton.tonalIcon`。
- **異動檔案**：`lib/component/empty_data_widget.dart`

### 🔹 Task 3: 重構 `RestaurantItemCell`
- **目標**：修復圖片變形、距離顯示與硬編碼色值，重塑視覺層級。
- **規格要點**：
  - **縮圖**：`FadeInImage` 外層包覆 `ClipRRect(borderRadius: BorderRadius.circular(ThemeSize.radius8))`，`fit: BoxFit.cover`。
  - **`imageErrorBuilder`**：保持顯式寬高 `width: ThemeSize.size110, height: ThemeSize.size110, fit: BoxFit.cover` 確保不撐爆佈局。
  - **距離格式化函式**：
    ```dart
    String _formatDistance(double? distance) {
      if (distance == null) return '';
      if (distance < 1000) {
        return '${distance.toInt()} m';
      }
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    ```
  - **色彩與文字**：
    - 店名：`textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)`
    - 距離：`textTheme.bodySmall?.copyWith(color: colorScheme.outline)`
    - 評分與價格：`textTheme.bodySmall?.copyWith(color: colorScheme.outline)`
    - 地址：`textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)`
    - 分類：`textTheme.bodySmall?.copyWith(color: colorScheme.outline)`
  - **防溢出約束**：`RatingStars` 保持外層無 `Expanded`，評論數與價格文字包 `Expanded` 並設定 `TextOverflow.ellipsis`。
- **異動檔案**：`lib/component/cell/main_page/restaurant_item_cell.dart`

### 🔹 Task 4: 測試覆蓋與全量回歸驗證 (Verification)
- **目標**：編寫單元/Widget 測試驗證新行為，確保既有功能零回歸。
- **異動檔案**：
  - `test/component/empty_data_widget_test.dart`
  - `test/component/cell/main_page/restaurant_item_cell_test.dart`
- **驗證步驟**：
  1. `flutter test test/component/empty_data_widget_test.dart`
  2. `flutter test test/component/cell/main_page/restaurant_item_cell_test.dart`
  3. `flutter test` (全量測試全綠)
  4. `flutter analyze` (維持零警告)
  5. `dart format --set-exit-if-changed .`

---

## 4. 破壞性與風險控制 (Risk & Rollback)

1. **窄卡片 Carousel 佈局風險**：
   - 控管：嚴格維持 `RatingStars` 獨立佈局（不包 `Expanded`），僅讓字串進行 flex 縮放，在 `restaurant_item_cell_test.dart` 298px 測試中驗證。
2. **`imageErrorBuilder` 撐爆 Row 風險**：
   - 控管：測試 `test/component/cell/error_builder_constraint_test.dart` 與 `restaurant_item_cell_test.dart` 確保載圖失敗時寬高不溢出。
3. **i18n 兼容性**：
   - 控管：當 `title` 未傳入時，若 i18n 未初始化提供安全 fallback，防止測試環境報錯。
