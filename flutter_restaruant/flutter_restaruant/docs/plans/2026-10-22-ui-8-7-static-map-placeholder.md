# 實作計畫：UI-8.7 採用專屬靜態地圖佔位圖 (icon_static_map_plachold.png) 替換通用 Empty 圖示

- **建立日期**：2026-10-22
- **對應規格**：`docs/features/2026-10-22-ui-8-7-static-map-placeholder.md`
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 簡介與目標 (Overview & Goals)

落實功能項目 `UI-8.7`：
1. **宣告與生成專屬資產**：於 `pubspec.yaml` 的 `flutter: assets:` 區段宣告 `images/icon_static_map_plachold.png`，並透過 `make fluttergen` 生成型別安全的 `Assets.images.iconStaticMapPlachold`。
2. **替換靜態地圖佔位與錯誤回退圖示**：將 `lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart` 中的 `FadeInImage.assetNetwork` 之 `placeholder` 與 `imageErrorBuilder` 由通用的空碗盤圖示（`Assets.images.empty`）改為專屬地圖佔位圖示（`Assets.images.iconStaticMapPlachold`）。
3. **驗證與品質保證**：在 `test/component/restaurant_info_cell_test.dart` 增加靜態地圖佔位圖渲染之 Widget 測試，確保靜態分析零警告且所有測試通過。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 修改檔案
- `pubspec.yaml`：於 `assets:` 清單新增 `- images/icon_static_map_plachold.png`。
- `lib/gen/assets.gen.dart`：由 `flutter_gen` 自動重新生成，包含 `AssetGenImage get iconStaticMapPlachold`。
- `lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart`：
  - 第 72 行 `placeholder: Assets.images.empty.path` 替換為 `Assets.images.iconStaticMapPlachold.path`。
  - 第 74 行 `Assets.images.empty.image(fit: BoxFit.cover)` 替換為 `Assets.images.iconStaticMapPlachold.image(fit: BoxFit.cover)`。
- `test/component/restaurant_info_cell_test.dart`：新增 Widget 測試，驗證 `RestaurantInfoCell` 在網路圖片載入中與錯誤時，能正確渲染專屬地圖佔位圖資產。

---

## 3. 實作任務拆分 (Tasks)

### 任務 1：pubspec.yaml 資產宣告與程式碼生成
- **內容**：
  - 在 `pubspec.yaml` 的 `assets:` 下方加入 `- images/icon_static_map_plachold.png`。
  - 執行 `make fluttergen`（或 `dart run flutter_gen`），重新產出 `lib/gen/assets.gen.dart`。
- **驗證**：檢查 `lib/gen/assets.gen.dart` 存在 `iconStaticMapPlachold` getter。

### 任務 2：RestaurantInfoCell 替換佔位圖與錯誤圖示
- **內容**：
  - 修改 `lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart`：
    ```dart
    FadeInImage.assetNetwork(
      placeholder: Assets.images.iconStaticMapPlachold.path,
      imageErrorBuilder: (context, error, trace) =>
          Assets.images.iconStaticMapPlachold.image(fit: BoxFit.cover),
      image: staticMapUrl,
      imageCacheHeight: RestaurantInfoCell._mapImageH,
      imageCacheWidth: RestaurantInfoCell._mapImageW,
      placeholderCacheHeight: RestaurantInfoCell._mapImageH,
      placeholderCacheWidth: RestaurantInfoCell._mapImageW,
      fit: BoxFit.cover,
    ),
    ```
- **驗證**：`dart analyze lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart` 零警告。

### 任務 3：擴充元件測試與全案回歸驗證
- **內容**：
  - 在 `test/component/restaurant_info_cell_test.dart` 新增測試案例：
    - 驗證 `FadeInImage` 內的 `placeholder` 正確指定為 `Assets.images.iconStaticMapPlachold.path`。
    - 驗證載入失敗時呼叫 `imageErrorBuilder` 產生之 Image 包含 `icon_static_map_plachold` 資產。
  - 執行 `flutter test test/component/restaurant_info_cell_test.dart`。
  - 執行 `flutter test` 與 `flutter analyze .`。
- **驗證**：既有測試與新增測試 100% 全綠，靜態分析 0 警告。

---

## 4. 驗收標準 (Acceptance Criteria)

1. `Assets.images.iconStaticMapPlachold` 型別安全常數就位。
2. `RestaurantInfoCell` 徹底移除對 `Assets.images.empty` 的靜態地圖佔位依賴。
3. 單元與元件測試全數通過，無任何編譯或分析警告。
