# F-3.1 AI 多模態 Vision 菜單翻譯與食材過敏原拆解
# (AI Multimodal Menu Vision — Dish Lens)

> **狀態**：STAGE 0a 功能規格 (Feature Spec)
> **來源**：`docs/brainstorm/2026-09-12-features-brainstorm.md` §2.3 F-3.1 + Ch.7 情境 2
> **日期**：2026-09-09

---

## 1. 問題定義 (Problem Statement)

使用者到異國餐廳、特色小吃店或文字密集的紙本菜單前，面臨三個真實痛點：

1. **語言障礙**：外文菜名無法理解，翻譯 App 逐字翻譯失去料理語境。
2. **過敏原隱患**：食材組成不明，過敏體質者（花生、麩質、甲殼類等）無法安心點餐。
3. **選擇困難**：密密麻麻的菜單缺乏視覺引導，不知道哪些是招牌必點。

**核心價值主張**：拍照即翻譯 + 食材拆解 + 過敏原標示 + 分類瀏覽，一張照片解決外食焦慮。

---

## 2. 使用者故事 (User Stories)

### US-1：拍照翻譯菜單
> 身為一位**到日本旅遊的台灣使用者**，
> 我想要**拍下日文菜單照片，立刻看到繁體中文翻譯與食材說明**，
> 以便我能**快速理解每道菜並做出點餐決策**。

### US-2：過敏原警示
> 身為一位**對花生過敏的使用者**，
> 我想要**系統自動標註含有花生或可能含有花生的菜色**，
> 以便我能**安全避開致敏菜品，不必逐項詢問店員**。

### US-3：分類瀏覽與辣度標示
> 身為一位**怕辣的使用者**，
> 我想要**菜單依前菜/主食/湯品/甜點自動分類，並標示辣度等級**，
> 以便我能**快速定位適合自己的菜色區塊**。

### US-4：安全降級
> 身為一位**網路訊號不佳環境下的使用者**，
> 我想要**系統在 AI 服務不可用時提供友善提示與重試選項**，
> 以便我能**不會遇到白屏或閃退，隨時可切回手動瀏覽餐廳資訊**。

---

## 3. 解決方案概述 (Solution Overview)

在餐廳詳情頁 (`RestaurantDetailPage`) 新增「📸 拍菜單 AI 拆解」入口，觸發以下流程：

```
使用者拍照 → 本地壓縮 (≤1500px/85%) → Firebase AI Logic (Gemini 3.5 Flash-Lite)
→ Structured JSON → Dart Sealed Class 解析 → 互動式菜單看板 UI
```

### 技術選型決策

| 決策項 | 選擇 | 理由 |
|:---|:---|:---|
| AI SDK | `firebase_ai: ^4.0.0` (Firebase AI Logic) | `google_generative_ai` 已被 Google 官方標記為 Deprecated。`firebase_ai` 為現行唯一主力 SDK，原生支援 App Check 安全防護與 Remote Config 動態模型控制，且專案已有 `firebase_core: ^4.12.1` |
| 相機 | `image_picker`（已在 pubspec.yaml） | 已宣告未使用，直接啟用；內建 `maxWidth`/`maxHeight`/`imageQuality` 參數，無需額外影像處理庫 |
| 輸出格式 | Gemini Structured Output (`responseMimeType: 'application/json'` + `responseSchema`) | 保證 100% 回傳合法 JSON，消除 Regex 解析邊界情況 |
| 型別安全 | Dart 3 `sealed class` 窮盡式 `switch` | 編譯期強制處理所有分支（含 Fallback），新增元件類型時編譯器報錯 |
| 架構隔離 | 獨立模組 `lib/features/ai_assistant/` + GetIt 注入 | 即使 AI 服務離線或被停用，核心餐廳瀏覽/搜尋/最愛功能 100% 正常運作 |

---

## 4. 功能範圍 (Scope)

### ✅ In Scope (本次實作)

1. **相機拍照 / 相簿選取菜單圖片**
   - 喚起系統相機或相簿（`ImagePicker`）
   - 本地自動壓縮：長邊 ≤1500px、品質 85%

2. **Gemini 多模態菜單分析**
   - 傳送壓縮圖片至 Firebase AI Logic (Gemini 3.5 Flash-Lite)
   - 使用 Structured Output Schema 強制回傳結構化 JSON
   - System Instruction 定位為「資深餐飲專家與食品安全顧問」

3. **結構化輸出欄位**
   - 菜名（原文 + 繁體中文翻譯）
   - 分類（appetizer / main / soup / dessert / beverage / other）
   - 價格
   - 食材列表
   - 過敏原標示（`contains` / `may_contain` / `none`，涵蓋 7 大過敏原）
   - 辣度（0-3 級）
   - 飲食標籤（vegan / vegetarian / gluten-free / halal）

4. **互動式菜單看板 UI**
   - 分頁 Tab 切換菜色分類
   - 過敏原 Badge 警示（⚠️ 醒目標記）
   - 辣度等級視覺指示（🌶️）
   - 飲食標籤 Chip

5. **錯誤處理與安全降級**
   - 網路離線 / API 429 / JSON 破損 → 降級為 `FallbackMarkdownComponent`
   - 使用者取消拍攝 → 靜默返回
   - 圖片辨識失敗 → 友善提示 + 重試按鈕

6. **Clean Architecture 整合**
   - Domain Layer：`MenuVisionRepository` 抽象介面、`DishEntity` / `AllergenInfo` / `A2UIComponent` sealed class
   - Data Layer：`MenuVisionRepositoryImpl`（`firebase_ai` + `image_picker`）
   - Presentation Layer：`MenuVisionBloc` + `MenuVisionPage`（BottomSheet 或 Dialog）
   - DI：GetIt `registerLazySingleton`

### ❌ Out of Scope (本次不做)

1. **虛擬點餐試算與金額加總** — 需後端支援，屬 Phase 3 後段
2. **AI 推薦指數與 Yelp 評論交叉比對** — 需額外 Yelp API 呼叫與評論向量分析
3. **A2UI 通用 Widget Registry** — 本次僅實作 `DishCatalogComponent`，通用 Registry 待 M2 里程碑
4. **Firebase App Check 整合** — 安全防護為獨立基礎設施任務，本次先以 API Key 直接驗證
5. **Firebase Remote Config 動態模型控制** — 屬 M1 後續優化
6. **對話式 AI 助手 BottomSheet (F-3.3 情境 1)** — 獨立功能，非本次範圍
7. **多語言 System Instruction 切換** — 初版固定繁體中文輸出
8. **離線快取分析結果** — 初版每次拍照即送雲端

---

## 5. 驗收條件 (Acceptance Criteria)

### AC-1：端到端拍照分析
- [ ] 使用者在餐廳詳情頁點擊「📸 拍菜單」按鈕
- [ ] 系統喚起相機（或相簿），使用者拍攝/選取菜單圖片
- [ ] 圖片自動壓縮後送至 Gemini 3.5 Flash-Lite
- [ ] 結果以互動式菜單看板呈現（< 5 秒完成分析，一般菜單）

### AC-2：過敏原正確標示
- [ ] 7 大過敏原（堅果、花生、蛋、奶、麩質、甲殼類、大豆）正確辨識
- [ ] 區分 `contains`（確認含有）與 `may_contain`（可能含有）
- [ ] UI 以醒目 Badge（⚠️ 圖示 + 文字）標示高風險過敏原

### AC-3：分類與辣度
- [ ] 菜色自動歸類至 Tab 頁籤（前菜/主食/湯品/甜點/飲品/其他）
- [ ] 辣度 0-3 級以 🌶️ 圖示數量直觀呈現

### AC-4：安全降級
- [ ] 網路離線時顯示「目前無法連線，請稍後重試」+ 重試按鈕
- [ ] JSON 解析異常時降級為 Markdown 文字卡，不崩潰
- [ ] 使用者取消拍攝時無任何 side effect

### AC-5：架構隔離
- [ ] 移除或停用 AI 模組後，App 核心功能（搜尋/地圖/最愛/詳情）100% 正常
- [ ] `flutter analyze` 零警告
- [ ] 新增模組的單元測試覆蓋率 ≥ 85%

---

## 6. 非功能需求 (Non-Functional Requirements)

| 指標 | 目標值 |
|:---|:---|
| 分析回應時間 | ≤ 5 秒（一般菜單，10-30 道菜） |
| 圖片壓縮上限 | 長邊 ≤ 1500px、品質 85%、< 500KB |
| 結構化 JSON 解析錯誤率 | < 0.1%（透過 Gemini responseSchema 保證） |
| 異常安全降級率 | 100%（任何異常均不得白屏或 unhandled exception） |
| 程式碼品質 | `flutter analyze` 零警告 |

---

## 7. 資料流架構 (Data Flow)

```
┌─────────────────────────────────────────────────────────────────┐
│  Presentation Layer                                             │
│  ┌─────────────────┐    ┌──────────────────────────────────┐   │
│  │ RestaurantDetail │───▶│ MenuVisionBloc                   │   │
│  │ Page (入口按鈕)  │    │ Event: CaptureAndAnalyze         │   │
│  └─────────────────┘    │ State: Initial/Loading/Success/  │   │
│                          │        Failure                    │   │
│                          └──────────┬───────────────────────┘   │
│                                     │                           │
│  ┌──────────────────────────────────▼───────────────────────┐  │
│  │ MenuVisionResultSheet (BottomSheet)                       │  │
│  │ ├─ TabBar: 前菜 | 主食 | 湯品 | 甜點 | 飲品 | 其他      │  │
│  │ ├─ DishCard: 菜名 + 翻譯 + 價格 + 🌶️辣度              │  │
│  │ │   └─ AllergenBadge: ⚠️ 含花生 | 🌱 純素               │  │
│  │ └─ FallbackCard: (降級時顯示 Markdown)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Domain Layer                                                   │
│  ┌─────────────────────────┐    ┌───────────────────────────┐  │
│  │ MenuVisionRepository    │    │ sealed A2UIComponent      │  │
│  │ (abstract interface)    │    │ ├─ DishCatalogComponent   │  │
│  │ captureAndAnalyzeMenu() │    │ └─ FallbackMarkdown...    │  │
│  └─────────────────────────┘    └───────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ DishEntity / AllergenInfo / DietaryTag                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Data Layer                                                     │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ MenuVisionRepositoryImpl                                   │ │
│  │ 1. ImagePicker → 拍照/選取 + 本地壓縮                     │ │
│  │ 2. FirebaseAI.generativeModel('gemini-3.5-flash-lite')    │ │
│  │    + systemInstruction + responseSchema                    │ │
│  │ 3. generateContent([text prompt, InlineDataPart])         │ │
│  │ 4. jsonDecode → A2UIComponent.fromJson → DishCatalog      │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. 入口點設計 (Entry Point)

在 `RestaurantDetailPage` 的 `AppBar` 新增 action 按鈕：

```dart
AppBar(
  // ...existing leading & title...
  actions: [
    IconButton(
      icon: const Icon(Icons.document_scanner_outlined),
      tooltip: '拍菜單 AI 拆解',
      onPressed: () => _showMenuVisionSheet(context),
    ),
  ],
)
```

點擊後以 `showModalBottomSheet` 彈出 `MenuVisionResultSheet`，內含 BLoC 驅動的分析流程。

---

## 9. 風險與緩解 (Risks & Mitigations)

| 風險 | 影響 | 緩解措施 |
|:---|:---|:---|
| Gemini API 回應慢或超時 | 使用者等待體驗差 | 設定 30 秒 timeout、顯示 loading skeleton、支援取消 |
| 菜單圖片品質差（模糊/反光） | 辨識準確度下降 | System Instruction 指示在不確定時標註 `uncertain: true`；UI 提示「請確保照片清晰」 |
| API Key 洩漏 | 配額被盜刷 | 初版以 `--dart-define` 注入，不硬編碼；後續以 Firebase App Check 取代 |
| 過敏原誤標 | 食安風險 | 明確標示「AI 分析結果僅供參考，實際食材請洽店家確認」免責聲明 |
| firebase_ai 套件 breaking change | 升級成本 | Data Layer 隔離，僅 `MenuVisionRepositoryImpl` 觸及 SDK |

---

## 10. iOS / Android 權限需求

| 平台 | 權限 | 用途 |
|:---|:---|:---|
| iOS | `NSCameraUsageDescription` | 拍攝菜單照片 |
| iOS | `NSPhotoLibraryUsageDescription` | 從相簿選取菜單照片 |
| Android | `android.permission.CAMERA` | 拍攝菜單照片（`image_picker` 自動處理） |
