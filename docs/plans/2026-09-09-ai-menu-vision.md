# F-3.1 AI 多模態 Vision 菜單翻譯與食材過敏原拆解 實作計畫
# (Implementation Plan: AI Multimodal Menu Vision — Dish Lens)

> **狀態**：STAGE 0b 實作計畫 (Implementation Plan)
> **規格對應**：`docs/features/2026-09-09-ai-menu-vision.md`
> **日期**：2026-09-09

---

## 1. 架構審查與 Linus 式五層分解 (Architecture Assessment)

### 🐧 第 1 層：資料結構優先 (Data-First)
核心資料結構集中於 `lib/features/ai_assistant/domain/entities/`：
- **`AllergenInfo`**：不可變模型，包含 `name` (過敏原名稱)、`riskLevel` (`contains` | `may_contain` | `none`)、`note`。
- **`DishItemEntity`**：單道菜品模型，包含 `id`、`name` (繁中名)、`originalName` (原文名)、`price`、`category` (分類代碼)、`allergens` (`List<AllergenInfo>`)、`dietaryTags` (`List<String>`)、`spiceLevel` (`int 0-3`)。
- **`A2UIComponent`**：Dart 3 `sealed class`：
  - `DishCatalogComponent`：包含 `restaurantTitle`、`dishes` (`List<DishItemEntity>`)。
  - `FallbackMarkdownComponent`：包含降級文字 `text`。

### 🐧 第 2 層：消除邊界情況 (Eliminating Edge Cases)
1. **JSON 破損/幻覺防護**：
   - 透過 Gemini `responseSchema` 在模型端強制輸出符合定義之 JSON 結構。
   - 資料解析層遇未知或破損格式一律回退至 `FallbackMarkdownComponent`，絕不讓任何未預期的結構導致執行期崩潰。
2. **大型圖片上傳導致 OOM 或 HTTP 413**：
   - 利用 `image_picker` 原生參數於客戶端本機完成等比例縮圖（`maxWidth: 1500, maxHeight: 1500, imageQuality: 85`），檔案大小約束在 500KB 內。
3. **使用者取消拍攝 / 拒絕權限**：
   - 取消選取時回傳靜默狀態，不觸發錯誤流程，不汙染狀態機。
4. **網路斷線或 API 速率限制 (HTTP 429)**：
   - BLoC 捕捉具體例外，發布 `MenuVisionStateFailure` 並提供重試操作。

### 🐧 第 3 層：簡潔與 YAGNI (Simplicity)
- 不引入肥大的自製影像處理或腳本解析庫。
- 善用 Material 3 現成元件（`TabBar`、`Card`、`FilterChip`、`DraggableScrollableSheet`），單一元件行數 < 120 行。

### 🐧 第 4 層：絕不破壞用戶空間 (Never Break Userspace)
- 新功能全部高內聚於 `lib/features/ai_assistant/` 獨立模組。
- 既有 `RestaurantDetailPage` 僅在 `AppBar` 新增一個 action 按鈕，不更動既有 BLoC、Repository 與資料模型。
- 即使 AI 服務中斷，App 既有餐廳瀏覽、地圖與收藏功能 100% 正常。

### 🐧 第 5 層：實用主義 (Pragmatism)
- 直接命中外國菜單與過敏原痛點，提供端到端可執行的閉環。

---

## 2. 檔案異動清單 (File Changes)

### 依賴更新 (Dependencies)
- `pubspec.yaml`：新增 `firebase_ai: ^4.0.0`

### 新增檔案 (New Files)
```text
lib/features/ai_assistant/
├── domain/
│   ├── entities/
│   │   ├── allergen_info.dart           # 過敏原實體模型
│   │   ├── dish_item_entity.dart        # 菜色資料實體模型
│   │   ├── a2ui_component.dart          # Sealed class GenUI 元件協定
│   │   └── ai_entities_barrel.dart      # Barrel 檔案
│   └── repositories/
│       └── menu_vision_repository.dart  # 抽象 Repository 契約
├── data/
│   └── repositories/
│       ├── menu_analysis_schema.dart    # Gemini responseSchema 定義
│       └── menu_vision_repo.dart        # Repository 實作 (FirebaseAI + ImagePicker)
└── presentation/
    ├── bloc/
    │   ├── menu_vision_bloc.dart        # BLoC 狀態管理
    │   ├── menu_vision_event.dart       # Event 定義 (Equatable)
    │   └── menu_vision_state.dart       # State 定義 (Equatable)
    └── view/
        ├── allergen_badge.dart          # 過敏原與飲食標籤 Badge 元件
        ├── dish_card.dart               # 單道菜品展示卡片
        └── menu_vision_sheet.dart       # 拍菜單分析 BottomSheet 彈窗
```

### 修改檔案 (Modified Files)
- `lib/di/injection.dart`：註冊 `MenuVisionRepository`
- `lib/flow/restaurant/view/restaurant_detail_page.dart`：`AppBar` 新增拍菜單掃描按鈕

### 測試檔案 (Test Files)
- `test/features/ai_assistant/domain_entity_test.dart`：實體解析與 sealed class 模式匹配單元測試
- `test/features/ai_assistant/menu_vision_repo_test.dart`：Data Layer JSON 映射與降級機制測試
- `test/features/ai_assistant/menu_vision_bloc_test.dart`：BLoC 狀態轉換測試
- `test/features/ai_assistant/menu_vision_sheet_test.dart`：BottomSheet 與卡片 UI 元件測試

---

## 3. 實作任務拆分 (Task Breakdown)

本計畫拆分為 **4 個循序驗證任務**：

### Task 1: Domain 實體與 A2UI 協定定義
* **目標**：建立型別安全的領域層實體與 sealed class 元件階層。
* **變更檔案**：
  - `lib/features/ai_assistant/domain/entities/allergen_info.dart`
  - `lib/features/ai_assistant/domain/entities/dish_item_entity.dart`
  - `lib/features/ai_assistant/domain/entities/a2ui_component.dart`
  - `lib/features/ai_assistant/domain/entities/ai_entities_barrel.dart`
  - `lib/features/ai_assistant/domain/repositories/menu_vision_repository.dart`
  - `test/features/ai_assistant/domain_entity_test.dart`
* **驗收標準**：
  - `A2UIComponent` 為 sealed class，支援 `DishCatalogComponent` 與 `FallbackMarkdownComponent`。
  - `DishItemEntity` 與 `AllergenInfo` 完整實作 `Equatable` 與 `fromJson`。
  - 單元測試通過，覆蓋合法 JSON、空值與未知元件 fallback 分支。

### Task 2: Data 層 Gemini 結構化分析與 Repository 實作
* **目標**：引入 `firebase_ai`，定義結構化 Schema，實作拍照壓縮與 Gemini 呼叫。
* **變更檔案**：
  - `pubspec.yaml`
  - `lib/features/ai_assistant/data/repositories/menu_analysis_schema.dart`
  - `lib/features/ai_assistant/data/repositories/menu_vision_repo.dart`
  - `lib/di/injection.dart`
  - `test/features/ai_assistant/menu_vision_repo_test.dart`
* **驗收標準**：
  - `firebase_ai: ^4.0.0` 成功加入且 `flutter pub get` 通過。
  - `menuAnalysisSchema` 嚴格定義菜色、過敏原與分類結構。
  - `MenuVisionRepo` 支援注入 `ImagePicker` 與 `FirebaseAI`，便於單元測試 mock。
  - 拍照壓縮尺寸約束為 `maxWidth: 1500, maxHeight: 1500, imageQuality: 85`。
  - 測試覆蓋：成功解析 JSON、模型異常回退、使用者取消拍照。

### Task 3: Presentation 層 BLoC 狀態管理實作
* **目標**：建立單向資料流狀態機，處理拍照分析、載入、成功與失敗狀態。
* **變更檔案**：
  - `lib/features/ai_assistant/presentation/bloc/menu_vision_event.dart`
  - `lib/features/ai_assistant/presentation/bloc/menu_vision_state.dart`
  - `lib/features/ai_assistant/presentation/bloc/menu_vision_bloc.dart`
  - `test/features/ai_assistant/menu_vision_bloc_test.dart`
* **驗收標準**：
  - Event：`CaptureAndAnalyzeMenu`、`RetryMenuAnalysis`、`ResetMenuVision`。
  - State：`MenuVisionInitial`、`MenuVisionLoading`、`MenuVisionSuccess` (持 `DishCatalogComponent`)、`MenuVisionFailure` (持錯誤訊息)、`MenuVisionCancelled`。
  - 單元測試覆蓋狀態推進歷程與例外捕捉。

### Task 4: UI 元件實作與餐廳詳情頁入口接線
* **目標**：實作互動式菜單看板 BottomSheet，並於餐廳詳情頁掛載入口。
* **變更檔案**：
  - `lib/features/ai_assistant/presentation/view/allergen_badge.dart`
  - `lib/features/ai_assistant/presentation/view/dish_card.dart`
  - `lib/features/ai_assistant/presentation/view/menu_vision_sheet.dart`
  - `lib/flow/restaurant/view/restaurant_detail_page.dart`
  - `test/features/ai_assistant/menu_vision_sheet_test.dart`
* **驗收標準**：
  - `MenuVisionSheet` 提供分類 `TabBar`（前菜/主食/湯品/甜點/飲品/其他）。
  - 過敏原以醒目 Badge 標註（`contains` 標紅、`may_contain` 標黃）。
  - 辣度以 🌶️ 數量直觀呈現。
  - `RestaurantDetailPage` AppBar 右上角新增相機圖示按鈕，點擊彈出 Sheet。
  - `flutter analyze` 零警告，全套測試綠燈。

---

## 4. 驗證與交付標準 (Verification Standards)

1. **靜態程式碼分析**：
   ```bash
   flutter analyze
   ```
   標準：`No issues found!` 零警告、零提示。
2. **測試驗證**：
   ```bash
   flutter test test/features/ai_assistant/
   ```
   標準：單元測試與 Widget 測試 100% 通過，覆蓋率 ≥ 85%。
3. **無破壞性保證**：
   ```bash
   flutter test
   ```
   標準：專案既有全量測試維持全綠。
