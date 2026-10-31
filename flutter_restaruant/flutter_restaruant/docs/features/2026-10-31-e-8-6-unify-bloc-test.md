# Feature: BLoC 測試統一改用 `blocTest` (Unify BLoC Tests with `blocTest`)

> 項目編號：**E-8.6**  
> 優先級別：**P2（測試工程品質規範）**  
> 預估 Effort：**0.5d**  
> 建立日期：2026-10-31  
> 參考文檔：`docs/brainstorm/2026-10-29-features-brainstorm.md` [E-8.6]；前置規範 `flutter-styles.md` §7.3.3；關聯項目 `docs/features/2026-09-26-mocktail-test-doubles.md` [E-8.2]、`docs/features/2026-10-27-e-8-7-mock-naming.md` [E-8.7]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

- 根據專案程式碼規範 `flutter-styles.md` §7.3.3「BLoC 測試」明定：*「使用 bloc_test 套件來簡化 BLoC 的測試過程」*。
- 目前專案內 BLoC 測試寫法不一致：
  - `menu_vision_bloc_test.dart` 與 `review_summary_bloc_test.dart` 已 100% 採用 `blocTest` 宣告式風格。
  - `sign_in_bloc_test.dart`（5 個測試）、`main_bloc_load_more_test.dart`（4 個測試）仍全數使用傳統 `test()` 搭配 `bloc.add(...)` 與 `await expectLater(bloc.stream, emitsInOrder([...]))`。
  - `ai_foodie_bloc_test.dart`（14 個測試中僅 1 處使用 `blocTest`，其餘多數使用 `test()` 搭配 `pumpEventQueue()` 手動等待狀態後斷言 `bloc.state`）。
- 傳統手動 stream 監聽或手動 `pumpEventQueue()` 存在以下痛點：
  1. **生命週期管理零散**：需在各 group 手動宣告 `late XBloc bloc;`、手動 `setUp()` 與手動 `tearDown(() => bloc.close())`，若漏寫易造成 stream 洩漏。
  2. **職責分離不明確**：stub 設定、事件派發（`act`）、狀態期望（`expect`）、呼叫次數驗證（`verify`）雜揉在同一個非同步函式本體內，可讀性低。
  3. **風格混亂**：不同 BLoC 測試風格迥異，維護成本提高。

---

## 2. 使用者故事 (User Stories)

- **身為開發者**，在閱讀或編寫 BLoC 單元測試時，所有 BLoC 測試皆遵循 `blocTest` 的四段式標準（`build`、`seed`、`act`、`expect`、`verify`），使狀態機轉移與副作用驗證一目了然。
- **身為維護者**，無須在每個測試檔重複手寫 `tearDown(() => bloc.close())`，由 `blocTest` 自動管理 BLoC 生命週期，消除潛在記憶體或 Stream 洩漏。

---

## 3. 規格需求 (What)

將下列測試檔案中的 BLoC 狀態測試重構遷移為 `blocTest<Bloc, State>`：

### 3.1 遷移目標清單

1. **`test/sign_in_bloc_test.dart`**（5 個案例，全數轉換為 `blocTest`）：
   - `GoogleSignInEvent passes correct parameters to repository`
   - `MailSignUpEvent passes correct parameters to repository`
   - `AutoSignInEvent failure emits SignInInitial, not Failure`
   - `SignIn failure emits Failure state`
   - `MailSignIn wrong password emits Failure with wrongPassword reason`
   - 移除手動 `tearDown(() => bloc.close())`。

2. **`test/main_bloc_load_more_test.dart`**（4 個案例，全數轉換為 `blocTest`）：
   - `首次載入（無既有資料）發出 InProgress → Success`
   - `已有資料時再載入發出 LoadMoreInProgress → LoadMoreSuccess`
   - `關鍵字過濾中載入更多：LoadMoreInProgress 不得把被過濾掉的項目撈回來`（使用 `seed` 注入初始 `Success` 狀態，`expect` 驗證 `LoadMoreInProgress`）
   - `LoadMoreInProgress 攜帶當前已載入清單供 UI 續繪`（使用 `seed` 注入初始 `Success` 狀態，`expect` 驗證 `LoadMoreInProgress`）
   - 移除手動 `tearDown(() => bloc.close())`。

3. **`test/flow/ai_foodie/ai_foodie_bloc_test.dart`**（14 個案例中，重構狀態事件測試）：
   - 保留 1 個純 State 類別的同步 getter 測試（`messageModels 由建構式傳入的 messages 衍生` 保留為 `test()`）。
   - 保留/轉換初始狀態測試（`初始狀態為空 messages 且 isLoading 為 false`，使用 `test()` 或 `blocTest`）。
   - 其餘 12 個涉及事件派發與狀態流轉的案例遷移為 `blocTest`：
     - `LoadInitialSuggestions 成功載入歡迎訊息`
     - `SendUserPrompt 依序追加使用者訊息與助理回應`
     - `SendUserPrompt 空字串直接被忽略`
     - `LoadInitialSuggestions 錯誤時更新 errorMessage`
     - `SendUserPrompt 錯誤時更新 errorMessage`
     - `TriggerActionChip query 動作正確觸發送出 Prompt`
     - `OpenRoulette 與 SpinRouletteWinnerSelected 狀態流轉正確`
     - `ResetAiFoodie 正確重置狀態並重新載入初始建議`
     - `ResetAiFoodie 會作廢先前的非同步請求避免覆蓋重設狀態`
     - `messageModels 與 messages 同步`
     - `SendUserPrompt 遇到 Error 往外拋出，不 emit errorMessage`（既有 `blocTest` 維持）
     - `history 是送出前的 state.messages（entity）`（透過 `blocTest` 的 `verify` 或保留多步驟測試）
   - 移除全域手動 `tearDown(() => bloc.close())`。

### 3.2 轉換設計準則

- **零行為變更**：只改測試架構與表現形式，不放寬任何斷言條件，不變更任何現有業務邏輯。
- **測試總數不變**：改寫後既有 463 個測試數保持一致，全部通過。
- **標準四段結構**：
  - `build`：建立 BLoC 實例並設置該測試需要的 Mock stub。
  - `seed`：當測試需要特定初始狀態時（如 `main_bloc_load_more_test.dart` 的既有過濾狀態），使用 `seed: () => ...` 取代手動 `bloc.emit(...)`。
  - `act`：派發 Event。
  - `expect`：狀態比對（使用 matcher 或確切實例）。
  - `verify`：Mocktail 的 `verify(...)` 驗證。

---

## 4. 邊界與非目標 (Out of Scope)

- **不修改任何 `lib/` 業務代碼**：BLoC、Repository、UI 程式碼一律不動。
- **不修改 Widget 測試**：`test/flow/main/view/` 等 Widget 測試內部的 `_FakeMainBloc`、`_RecordingMainBloc` 保持不變。
- **不新增其他 BLoC 的全新單元測試**：例如 `RestaurantDetailBloc`、`FavorBloc`、`SettingsBloc`、`SplashBloc` 原本即無獨立單元測試，不在本項目範圍內（擴充覆蓋率留待覆蓋率專案處理）。
- **`menu_vision_bloc_test.dart` 與 `review_summary_bloc_test.dart`** 已完全符合規範，無需修改。

---

## 5. 驗收條件 (Verification)

1. `test/sign_in_bloc_test.dart` 中不再含有 `expectLater`，5 個測試全數採用 `blocTest`。
2. `test/main_bloc_load_more_test.dart` 中不再含有 `expectLater`，4 個測試全數採用 `blocTest`。
3. `test/flow/ai_foodie/ai_foodie_bloc_test.dart` 中的狀態轉移測試全數改用 `blocTest`，移除不必要的 `pumpEventQueue()`。
4. `flutter analyze lib/ test/`：0 warnings、0 errors。
5. `dart format --output=none --set-exit-if-changed test/`：格式完全合規。
6. `flutter test`：全數通過，無任何測試失敗。
