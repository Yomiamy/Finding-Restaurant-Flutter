# Implementation Plan: BLoC 測試統一改用 `blocTest` (Unify BLoC Tests with `blocTest`)

> 項目編號：**E-8.6**  
> 建立日期：2026-10-31  
> 規格文檔：`docs/features/2026-10-31-e-8-6-unify-bloc-test.md`  
> 預計變更範圍：`test/sign_in_bloc_test.dart`、`test/main_bloc_load_more_test.dart`、`test/flow/ai_foodie/ai_foodie_bloc_test.dart`  
> 狀態：草稿（待確認）

---

## 1. 架構與設計原則

1. **依循 `flutter-styles.md` §7.3.3 標準**：
   - 每個 BLoC 測試案例採用 `blocTest<XBloc, XState>(...)`。
   - `build`：回傳被測 BLoC 實例，並設定該案例專屬之 Mocktail stub。
   - `seed`：當需要初始狀態時（如預設已載入成功的狀態），使用 `seed: () => ...` 注入，杜絕手動 `emit`。
   - `act`：派發事件。
   - `expect`：定義狀態期望序列（使用精確比對或 `isA<XState>()` + `having`）。
   - `verify`：驗證 Repository 互動次數與參數。
2. **生命週期自動化**：
   - 移除手寫 `tearDown(() => bloc.close())`，由 `blocTest` 框架管理 BLoC 之生命週期與 Stream 釋放。
3. **保持測試行為與斷言強度 100% 等價**：
   - 不刪除、不放寬任何既有斷言；原有驗證（包含 repository 呼叫次數、參數等）全部保留並搬移至 `verify` 區塊。

---

## 2. 任務清單 (Tasks)

### Task 1: 遷移 `test/sign_in_bloc_test.dart` 至 `blocTest`
- **目標檔案**：`test/sign_in_bloc_test.dart`
- **改動細節**：
  1. 導入 `package:bloc_test/bloc_test.dart`。
  2. 將 5 個測試全數改寫為 `blocTest<SignInBloc, SignInState>`：
     - `GoogleSignInEvent passes correct parameters to repository`
     - `MailSignUpEvent passes correct parameters to repository`
     - `AutoSignInEvent failure emits SignInInitial, not Failure`
     - `SignIn failure emits Failure state`
     - `MailSignIn wrong password emits Failure with wrongPassword reason`
  3. 將 `when(() => mockRepo.signInUp(...))` 移入各 `build` 回呼；將 `verify(...)` 移入各 `verify` 回呼。
  4. 移除手動宣告之 `late SignInBloc bloc;` 與 `tearDown(() => bloc.close())`。
- **驗證**：`flutter test test/sign_in_bloc_test.dart` 通過。

### Task 2: 遷移 `test/main_bloc_load_more_test.dart` 至 `blocTest`
- **目標檔案**：`test/main_bloc_load_more_test.dart`
- **改動細節**：
  1. 導入 `package:bloc_test/bloc_test.dart`。
  2. 將 4 個測試改寫為 `blocTest<MainBloc, MainState>`：
     - 案例 1：首次載入（無既有資料）發出 `InProgress` → `Success`。
     - 案例 2：已有資料時再載入發出 `LoadMoreInProgress` → `LoadMoreSuccess`。
     - 案例 3：關鍵字過濾中載入更多，使用 `seed: () => const Success(summaryInfos: [_Data.existing])` 注入，`expect` 驗證發射之 `LoadMoreInProgress` 及其 `summaryInfos`，以及隨後的 `LoadMoreSuccess`。
     - 案例 4：LoadMoreInProgress 攜帶當前已載入清單供 UI 續繪，同樣使用 `seed: () => const Success(summaryInfos: [_Data.existing])`。
  3. 移除手動宣告之 `late MainBloc bloc;` 與 `tearDown(() => bloc.close())`。
- **驗證**：`flutter test test/main_bloc_load_more_test.dart` 通過。

### Task 3: 遷移 `test/flow/ai_foodie/ai_foodie_bloc_test.dart` 至 `blocTest`
- **目標檔案**：`test/flow/ai_foodie/ai_foodie_bloc_test.dart`
- **改動細節**：
  1. 初始狀態與 State 模型純 getter 測試（共 2 個）保留為同步 `test()`：
     - `初始狀態為空 messages 且 isLoading 為 false`
     - `messageModels 由建構式傳入的 messages 衍生`
  2. 其餘 12 個涉及事件派發與非同步處理之測試遷移為 `blocTest<AiFoodieBloc, AiFoodieState>`：
     - `LoadInitialSuggestions 成功載入歡迎訊息`：`expect: () => [isA<AiFoodieState>().having(isLoading, true), isA<AiFoodieState>().having(messages.length, 1)]`
     - `SendUserPrompt 依序追加使用者訊息與助理回應`：`expect: () => [isA<AiFoodieState>().having(isLoading, true), isA<AiFoodieState>().having(messages.length, 2)]`
     - `SendUserPrompt 空字串直接被忽略`：`expect: () => []`
     - `LoadInitialSuggestions 錯誤時更新 errorMessage`：`expect: () => [isA<AiFoodieState>().having(isLoading, true), isA<AiFoodieState>().having(errorMessage, isNotNull)]`
     - `SendUserPrompt 錯誤時更新 errorMessage`：`expect: () => [isA<AiFoodieState>().having(isLoading, true), isA<AiFoodieState>().having(errorMessage, isNotNull)]`
     - `TriggerActionChip query 動作正確觸發送出 Prompt`：`expect: () => [isA<AiFoodieState>().having(isLoading, true), isA<AiFoodieState>().having(messages.length, 2)]`
     - `OpenRoulette 與 SpinRouletteWinnerSelected 狀態流轉正確`
     - `ResetAiFoodie 正確重置狀態並重新載入初始建議`
     - `ResetAiFoodie 會作廢先前的非同步請求避免覆蓋重設狀態`
     - `messageModels 與 messages 同步`
     - `SendUserPrompt 遇到 Error 往外拋出，不 emit errorMessage`（既有 `blocTest` 保留）
     - `history 是送出前的 state.messages（entity）`：利用 `blocTest` 的 `act` 派發並在 `verify` 驗證 repository 呼叫。
  3. 移除手動宣告之 `late AiFoodieBloc bloc;` 與 `tearDown(() => bloc.close())`。
- **驗證**：`flutter test test/flow/ai_foodie/ai_foodie_bloc_test.dart` 通過。

### Task 4: 整合驗證與程式碼風格確認
- **執行驗證**：
  1. `flutter analyze lib/ test/` 確保零 issue。
  2. `dart format --output=none --set-exit-if-changed test/` 確保格式合規。
  3. `flutter test` 執行全專案 463 個測試，確保 100% 通過。

---

## 3. 回歸風險與破壞性評估

- **對 Production 程式碼**：零風險。完全不修改 `lib/` 任何程式碼。
- **對測試覆蓋與有效性**：`blocTest` 會嚴格驗證 states 釋放順序，比原有的 `pumpEventQueue()` 更加嚴謹，可防範未預期的中介狀態（intermittent states）。
