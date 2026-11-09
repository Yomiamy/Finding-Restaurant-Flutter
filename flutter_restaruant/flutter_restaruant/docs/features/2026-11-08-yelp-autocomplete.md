# 功能規格：[A-8.9] 串接 Yelp Autocomplete 實現搜尋即時補全與聯想 (UI / Debounce / BLoC)

- **日期**：2026-11-08
- **狀態**：🟢 已定案 (STAGE 0a)
- **實查基線**：`main` @ `44abb540`
- **需求來源**：`gen-grill` brief Q1–Q5
- **相關 brainstorm 項目**：`docs/brainstorm/2026-11-02-features-brainstorm.md` §8.3.2 [A-8.9]
- **底層基礎建設**：PR #160 (`APIClz.autocomplete`、`YelpAutocompleteDto`、`YelpAutocompleteRepository` / `YelpAutocompleteRepo`)

---

## 1. 背景與現況分析

### 1.1 現況（實查）

1. **底層端點與 DI 註冊已完工**：
   - PR #160（Issue #159）已於 `lib/api/api_clz.dart` 宣告 `GET /v3/autocomplete`。
   - `lib/api/dto/yelp_autocomplete_dto.dart` 定義了 `YelpAutocompleteDto`，包含 3 大聯想維度：
     - `terms`: `List<YelpAutocompleteTermDto>?`（熱門搜尋關鍵詞）
     - `businesses`: `List<YelpRestaurantSummaryDto>?`（精準推薦店家名稱與 ID）
     - `categories`: `List<YelpRestaurantCategoryDto>?`（菜系分類別名與標題）
   - `lib/domain/repositories/yelp_autocomplete_repository.dart` 定義抽象契約。
   - `lib/data_layer/repositories/yelp_autocomplete_repo.dart` 實作資料層。
   - `lib/app/di/injection.dart:59` 已註冊 `getIt.registerLazySingleton<YelpAutocompleteRepository>`。
2. **表現層完全零串接**：
   - 搜尋關鍵字目前僅存在於 `DrawerWidget` 的「關鍵字過濾」，點擊後彈出極為簡陋的 `PlatformTextField` 對話框 (`ViewUtils.showPromptDialog`)。
   - 使用者在打字時毫無即時聯想，必須完整拼寫完關鍵字並點擊「確定」，容易拼錯或盲目猜測。
   - `MainPage` 的 AppBar 目前僅有 AI 覓食小助手按鈕，缺乏 Material 3 標準的搜尋入口。

### 1.2 為什麼是問題

- **搜尋摩擦力過大**：使用者必須打開 Drawer 才能找到關鍵字過濾，而且輸入過程中無任何引導與提示。
- **高價值 API 閒置為技術債**：底層 API 與 Repository 已耗費 PR #160 完成，卻未在 UI 提供使用者價值。
- **未實作防抖 (Debounce) 的隱患**：若無防抖直接打 Autocomplete API，在輸入中文或快打時將引發大量無效請求與競態問題（Race Conditions）。

### 1.3 【核心判斷】（Linus 模式）

**好品味原則：消滅邊界情況，擁抱原生 Material 3 機制。**

1. **採用 Flutter 原生 `SearchDelegate`**：
   - 拒絕手寫脆弱且易被軟鍵盤推擠出錯的自訂 `OverlayEntry` 座標計算。
   - Flutter 內建 `SearchDelegate` (`showSearch`) 具備完整的路由轉場、頂部搜尋列、搜尋建議監聽 (`buildSuggestions`)、結果頁 (`buildResults`) 與無障礙支援。
2. **採用 RxDart 300ms Debounce + SwitchMap**：
   - 本專案已引入 `rxdart: ^0.28.0`。
   - 在 BLoC 中利用 `events.debounceTime(const Duration(milliseconds: 300)).switchMap(...)` 處理查詢字串變更事件。
   - 當新字元鍵入時，前一個尚未完成的 HTTP 請求自動被取消/拋棄，徹底消滅網路競態與亂序返回的邊界 Bug。
3. **分群清晰展示三大聯想維度**：
   - `terms`：點擊直接將字串填入搜尋並觸發主搜尋。
   - `businesses`：點擊直接以該店家 ID 跳轉至 `RestaurantDetailPage`。
   - `categories`：點擊以該分類標題發起搜尋。

---

## 2. 需求 Brief（gen-grill 產出）

- **Q1 問題定義**：使用者在搜尋餐廳時缺乏即時聯想引導，必須盲打完整店名或菜系，容易拼錯且流程繁瑣。
- **Q2 觸發場景**：使用者在 `MainPage` AppBar 點擊搜尋按鈕（或由側邊欄開啟搜尋），輸入 $\ge 1$ 個字元時，系統自動經由 300ms 防抖向 Yelp Autocomplete API 查詢，於畫面上即時分區展示「搜尋建議」、「推薦店家」與「相關分類」。
- **Q3 成功標準**：
  1. 建立 `AutocompleteBloc`（或於 `flow/autocomplete/` 下建立專屬 BLoC），整合 `rxdart` 300ms debounce。
  2. 建立 `RestaurantSearchDelegate`，在 `MainPage` AppBar 新增搜尋按鈕點擊觸發。
  3. 支援點擊關鍵詞直接回傳執行 `MainBloc.FilterListByKeyword`。
  4. 支援點擊店家直接導向 `RestaurantDetailPage`。
  5. 支援清空輸入、網路異常優雅降級（顯示提示而不崩潰）。
  6. 完整單元測試覆蓋 BLoC 與 Delegate 互動，`flutter analyze` 零警告。
- **Q4 範圍邊界**：
  - 不更動 `APIClz.autocomplete` 與 `YelpAutocompleteRepository` 既有介面。
  - 不引入全域持久化快取（專注於即時輸入聯想）。
- **Q5 既有覆蓋實查**：
  - 查驗符號：`YelpAutocompleteRepository`、`YelpAutocompleteDto`。
  - 實查結果：底層完備，UI 與 BLoC 完全未實作。

---

## 3. 使用者故事與驗收條件 (Acceptance Criteria)

### 3.1 使用者故事 (User Stories)

1. **即時補全聯想**：作為餐廳搜尋的使用者，我在搜尋框中輸入文字時，希望即時看到符合的熱門搜尋詞、店家與菜系，以便快速完成搜尋。
2. **店家直達跳轉**：作為目標明確的使用者，當搜尋聯想中出現我想找的具體店家時，我希望能一鍵點擊直接進入詳情頁，無需再經過列表層。
3. **優雅防抖與節流**：作為行動網路使用者，我不希望快速輸入時造成 App 卡頓或過度消耗流量，打字停止 300ms 後才發送網路請求。

### 3.2 驗收標準 (Acceptance Criteria)

- [ ] **AC-1 (入口整合)**：`MainPage` 的 AppBar 新增常駐搜尋按鈕 (`Icons.search`)，點擊叫起 `showSearch`，並移除側邊欄 Drawer 中重複的舊版「關鍵字過濾」入口與對話框。
- [ ] **AC-2 (防抖與字元門檻)**：文字輸入 $\ge 1$ 個字元時才觸發 API 請求；連續輸入時透過 300ms debounce 防抖；輸入清空時重置為初始空狀態。
- [ ] **AC-3 (分維度展示)**：聯想結果依序分區展示：
  - **熱門詞彙** (`terms`): 前綴 `Icons.search`，點擊回傳關鍵字給 `MainBloc` 並執行搜尋。
  - **推薦店家** (`businesses`): 前綴 `Icons.storefront`，點擊直接導航至 `RestaurantDetailPage`。
  - **相關分類** (`categories`): 前綴 `Icons.category`，點擊將分類標題回傳搜尋。
- [ ] **AC-4 (異常與空狀態處理)**：API 拋出例外或無結果時，畫面顯示簡潔提示文案，不崩潰、不彈出侵入性錯誤對話框。
- [ ] **AC-5 (測試覆蓋)**：
  - `AutocompleteBloc` 具備完整的 `blocTest` 單元測試（含 debounce、空字串跳過、成功資料發布、異常處理）。
  - Widget 測試驗證搜尋入口與建議項點擊互動。
  - `flutter analyze` 零警告。

---

## 4. 架構設計與檔案異動規劃

### 4.1 資料流架構

```text
  [MainPage / DrawerWidget]
            │ (點擊搜尋按鈕)
            ▼
  [RestaurantSearchDelegate] ─── (使用者輸入字元) ───► [AutocompleteBloc]
            ▲                                                   │ (300ms Debounce)
            │                                                   ▼
            │ (渲染聯想列表 / terms, businesses, categories)     [YelpAutocompleteRepository]
            │                                                   │ (GET /v3/autocomplete)
            │                                                   ▼
    [使用者點擊] ────────────────────────────────────► [Yelp API]
     ├─ 點擊 term / category ──► close(context, query) ──► MainBloc(FilterListByKeyword)
     └─ 點擊 business ─────────► Navigator.push(RestaurantDetailPage)
```

### 4.2 檔案變更清單

- **新增**：
  - `lib/flow/autocomplete/bloc/autocomplete_event.dart`
  - `lib/flow/autocomplete/bloc/autocomplete_state.dart`
  - `lib/flow/autocomplete/bloc/autocomplete_bloc.dart`
  - `lib/flow/autocomplete/bloc/autocomplete_barrel.dart`
  - `lib/flow/autocomplete/view/restaurant_search_delegate.dart`
  - `test/flow/autocomplete/autocomplete_bloc_test.dart`
  - `test/flow/autocomplete/restaurant_search_delegate_test.dart`
- **修改**：
  - `lib/flow/main/view/main_page.dart`（AppBar 加入搜尋按鈕，修改 `_showKeywordDialog` / 替換為 `_openSearch`）
  - `lib/l10n/intl_zh_TW.arb` 與 `lib/l10n/intl_en.arb`（補齊搜尋建議相關多語系字串）
