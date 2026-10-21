# Feature: 餐廳評論智慧摘要 (Review Intelligence & Highlights)

> 項目編號：**M5-Review**  
> 優先級別：**P1（AI 差異化體驗 / Phase 3）**  
> 建立日期：2026-10-19  
> 參考文檔：`docs/brainstorm/2026-10-18-features-brainstorm.md` §7.4 情境 3, §7.6 M5  
> 狀態：草稿（待使用者確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **評論破碎且資訊零散**：
   - 目前 Yelp Fusion API (`/v3/businesses/{id}/reviews`) 僅回傳 **3 則短評，每則長度強制截斷至 160 字**。
   - 評論正負評雜陳、資訊片面，且可能混雜外文。使用者需要花費心力閱讀與過濾，難以快速掌握餐廳的核心價值與潛在雷點。
2. **缺乏即時決策摘要**：
   - 使用者在決定是否到店用餐時，最在乎三個關鍵問題：「這家店招牌必點是什麼？」、「有什麼值得一試的優勢？」、「排隊久嗎或環境有何注意事項？」。
   - 目前詳情頁僅直接以 `RestaurantCommentCell` 展示 3 張原始短評卡片，無法提供結構化的決策情報。

### 1.2 改造目標 (Linus 實用主義模式)
- **AI 評論情報卡 (Review Intelligence Card)**：
  - 在餐廳詳情頁 (`RestaurantDetailPage`) 的顧客評論區塊頂部，注入由 Google AI Studio (Gemini 3.5 Flash Lite) 萃取的「AI 評價情報卡」。
  - **自動非同步載入**：詳情頁取得 Yelp 評論後，AI 卡片以 Shimmer 骨架屏自動在背景非同步生成並平滑顯示，使用者體驗流暢無打斷。
- **結構化決策三要素**：
  - 🟢 **值得一試 (Pros)**：條列 1~3 項核心優勢（如：海鮮新鮮、出餐快速、醬汁道地）。
  - 🔴 **注意事項 (Cons)**：條列 1~2 項避雷提醒（如：尖峰排隊 30 分鐘、店內座位較狹窄）。
  - ⭐ **招牌必點 (Highlights)**：條列 1~3 項顧客最推薦的招牌菜品或特色。
  - 📝 **一句話短評 (Summary)**：客觀提煉總結。
- **好品味與零破壞防護 (Never break userspace)**：
  - **零評論短路**：若 Yelp 短評為 0 則，直接不渲染卡片 (`SizedBox.shrink()`)，零 API 呼叫浪費。
  - **優雅降級**：若遇網路中斷、JSON 解析失敗或 Gemini 配額耗盡 (429)，AI 卡片安全隱藏或提供重試按鈕，**絕不阻擋詳情頁其餘重要資訊（菜色、地圖、電話）的渲染**。
  - **多語系自動收斂**：在 Prompt 系統指令規範「無論原始短評語言為何，一律以繁體中文 (zh-TW) 輸出」，在編譯期消除多語系分支。

---

## 2. 規格需求 (What)

### 2.1 領域層資料結構 (Domain Entities)

新增 `ReviewSummaryEntity`（支援 `@JsonSerializable` 與 `Equatable`）：
```dart
class ReviewSummaryEntity extends Equatable {
  final List<String> pros;        // 值得一試（核心優勢）
  final List<String> cons;        // 注意事項（避雷點）
  final List<String> highlights;  // 招牌必點與特色
  final String summary;           // 一句話總評

  const ReviewSummaryEntity({
    required this.pros,
    required this.cons,
    required this.highlights,
    required this.summary,
  });

  @override
  List<Object?> get props => [pros, cons, highlights, summary];
}
```

### 2.2 倉儲契約與資料層 (Repository & Data Layer)

1. **契約介面 (`lib/domain/repositories/review_summary_repository.dart`)**：
   ```dart
   abstract interface class ReviewSummaryRepository {
     Future<ReviewSummaryEntity> generateReviewSummary({
       required RestaurantDetailEntity detail,
       required List<ReviewDetailEntity> reviews,
     });
   }
   ```
2. **強型別 JSON Schema (`lib/data_layer/models/review_summary_schema.dart`)**：
   - 遵循 `firebase_ai` 的 `Schema.object` 規範：
     - `pros`: `Schema.array(items: Schema.string())`
     - `cons`: `Schema.array(items: Schema.string())`
     - `highlights`: `Schema.array(items: Schema.string())`
     - `summary`: `Schema.string()`
3. **實作類別 (`lib/data_layer/repositories/review_summary_repo.dart`)**：
   - 注入 `FirebaseAI` 與 `AiModelConfig`（由 Remote Config 動態控制模型 `gemini-3.5-flash-lite` 與溫度）。
   - 傳入結構化 Prompt：包含餐廳名稱、分類標籤、價格等級與 3 則短評內容。

### 2.3 表現層 (BLoC & UI)

1. **`ReviewSummaryBloc` (`lib/flow/restaurant/bloc/review_summary_bloc.dart`)**：
   - 保持獨立職責，不污染主詳情頁的 `RestaurantDetailBloc`。
   - **事件 (Events)**：
     - `GenerateReviewSummaryEvent(detail, reviews)`
     - `RetryReviewSummaryEvent`
   - **狀態 (States)**：
     - `ReviewSummaryInitial`
     - `ReviewSummaryLoading`
     - `ReviewSummarySuccess(ReviewSummaryEntity summary)`
     - `ReviewSummaryFailure(String errorMessage, bool canRetry)`
2. **UI 元件 (`lib/features/component/card/review_summary_card.dart`)**：
   - 採用 Material 3 卡片風格（`Card` / `Container` + 品牌色邊框與圓角）。
   - **加載狀態**：展示 `ReviewSummarySkeleton`（輕量 Shimmer 動畫）。
   - **成功狀態**：
     - 頂部：✨ AI 評論情報（帶小巧晶片標籤與一句話總評）。
     - 左側/上欄：🟢 值得一試（帶綠色勾勾或圓點）。
     - 右側/下欄：🔴 注意事項（帶警示或提醒圖示）。
     - 底部：招牌推薦 Action Chips。
   - **掛載位置**：置於 `RestaurantDetailPage` 的評論區塊頂部（`RestaurantCommentCell` 之上）。

---

## 3. 邊界與非目標 (Out of Scope)

1. ❌ **個人口味偏好設定與 0-100% 相性雷達**：專案目前欠缺個人偏好資料庫與設定頁，不為單一功能發明複雜前置依賴，第一版堅決砍除（YAGNI）。
2. ❌ **一日美食巡禮與行程生成**：屬 M5-Crawl 範疇，為最愛名單頁 (`flow/favor`) 之多店編排功能，獨立開案處理。
3. ❌ **修改 Yelp 原始短評邏輯**：維持既有 3 則短評之渲染與「前往 Yelp」導外連結，不破壞既有功能。
4. ❌ **無效的 UseCase 轉發層**：遵照專案架構規範，BLoC 直連 Repository 介面，不引進單純轉發的 `GenerateReviewSummaryUseCase`。

---

## 4. 驗收條件 (Verification)

1. **功能行為**：
   - 進入餐廳詳情頁且 Yelp 成功回傳評論時，AI 評論情報卡自動顯示 Shimmer 並於背景載入。
   - 載入完成後順暢切換為結構化卡片（展示 pros, cons, highlights, summary）。
   - 當評論數量為 0 時，情報卡自動隱藏 (`SizedBox.shrink()`)，無多餘 UI 留白，且不發送 AI 請求。
   - 當網路斷線、JSON 格式異常或 API 429 配額耗盡時，卡片顯示友善提示與重試按鈕，詳情頁其他內容完整不受影響。
2. **品質與測試**：
   - 單元測試：包含 `ReviewSummaryRepo`（Schema 解析與 Mock 注入）、`ReviewSummaryBloc`（狀態流轉驗證，使用 `blocTest` 與 `mocktail`）。
   - 元件測試：驗證 `ReviewSummaryCard` 在加載中、成功、失敗與空資料狀態下的正確渲染。
3. **程式碼規範**：
   - `flutter analyze .` 維持零警告 (`No issues found!`)。
   - `flutter test` 所有既有與新增測試全數通過。
