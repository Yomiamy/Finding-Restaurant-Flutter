# 功能規格：UI-8.7 採用專屬靜態地圖佔位圖 (icon_static_map_plachold.png) 替換通用 Empty 圖示

- **建立日期**：2026-10-22
- **負責角色**：Flutter & UI 元件專家
- **狀態**：規劃中 (Draft)
- **關聯**：
  - 需求來源：`docs/brainstorm/2026-10-21-features-brainstorm.md` §8.3.3 `[UI-8.7]`
  - 關聯元件：`lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart`
  - 關聯資產：`images/icon_static_map_plachold.png`
  - 效益：提升地圖載入中與錯誤回退狀態的語意傳達與視覺品質

---

## 1. 需求與背景 (Problem & Background)

### 1.1 現況與痛點
1. **地圖語意缺失**：目前餐廳詳情頁基本資訊卡片（`RestaurantInfoCell`）中的 Google 靜態地圖縮圖（`FadeInImage.assetNetwork`），在網路請求載入中（`placeholder`）或載入失敗（`imageErrorBuilder`）時，皆回退至通用的空碗盤圖示 `Assets.images.empty`。
2. **視覺體驗突兀**：空碗盤圖示為無資料/無餐廳時的通用佔位符，放在靜態地圖的縮圖矩形框中，無法讓使用者預期「此處是一張地圖」或清楚知道「地圖預覽載入失敗」，與右下角的導航懸浮按鈕（`Icons.navigation_rounded`）語意產生斷層。
3. **資產已就位但未接線**：專案資產目錄已有專屬的地圖佔位圖檔 `images/icon_static_map_plachold.png`，但尚未在 `pubspec.yaml` 宣告，亦未透過 `fluttergen` 產生型別安全存取子。

### 1.2 目標 (Goals)
1. **註冊專屬資產**：在 `pubspec.yaml` 的 `flutter: assets:` 新增 `images/icon_static_map_plachold.png`，並透過 `make fluttergen` 生成 `Assets.images.iconStaticMapPlachold`。
2. **替換靜態地圖佔位與錯誤圖示**：
   - 將 `lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart` 中的 `FadeInImage.assetNetwork`：
     - `placeholder` 替換為 `Assets.images.iconStaticMapPlachold.path`。
     - `imageErrorBuilder` 替換為 `Assets.images.iconStaticMapPlachold.image(fit: BoxFit.cover)`。
3. **單元與元件測試覆蓋**：
   - 擴充 `test/component/restaurant_info_cell_test.dart`，驗證 `RestaurantInfoCell` 在靜態地圖渲染時正確使用專屬地圖佔位圖。
4. **維持既有規格與零迴歸**：
   - 尺寸（140×140）、圓角（`ThemeSize.radius8`）、`BoxFit.cover` 與點擊開啟導航選單行為保持不變。
   - `flutter analyze` 零警告，既有測試全數通過。

---

## 2. 需求 Brief (gen-grill 審核)

- **Q1 問題定義**：`RestaurantInfoCell` 的靜態地圖使用通用的 `empty.png` 作為 placeholder 與 error fallback，缺乏地圖位置預覽語意。
- **Q2 觸發場景**：使用者進入餐廳詳情頁，地圖縮圖正在載入中、或在離線/無有效 API 金鑰導致圖片載入失敗時。
- **Q3 成功標準**：
  1. `pubspec.yaml` 宣告該資產，`Assets.images.iconStaticMapPlachold` 正確生成。
  2. `RestaurantInfoCell` 採用 `Assets.images.iconStaticMapPlachold`。
  3. 元件測試驗證通過。
  4. `flutter analyze` 零警告。
- **Q4 範圍邊界**：
  - 不修改靜態地圖 URL 產生邏輯。
  - 不修改外部地圖跳轉選單（Apple Maps / Google Maps）。
  - 不影響其他使用 `Assets.images.empty` 的列表或無資料佔位畫面。
- **Q5 既有覆蓋實查**：
  - `restaurant_info_cell.dart:72,74` 目前使用 `Assets.images.empty.path` 與 `Assets.images.empty.image(fit: BoxFit.cover)`。
  - `images/icon_static_map_plachold.png` 實體檔案已存在，但未納入 `pubspec.yaml`。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1**：資產宣告與程式碼生成
  - `pubspec.yaml` 包含 `images/icon_static_map_plachold.png`。
  - `lib/gen/assets.gen.dart` 包含 `AssetGenImage get iconStaticMapPlachold`。
- **AC-2**：地圖佔位與錯誤回退替換
  - `RestaurantInfoCell` 的 `FadeInImage.assetNetwork` 之 `placeholder` 指向 `Assets.images.iconStaticMapPlachold.path`。
  - `imageErrorBuilder` 回傳 `Assets.images.iconStaticMapPlachold.image(fit: BoxFit.cover)`。
- **AC-3**：測試覆蓋與品質檢驗
  - `test/component/restaurant_info_cell_test.dart` 補齊靜態地圖佔位圖渲染驗證。
  - `flutter analyze` 零錯誤與零警告。
