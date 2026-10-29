# Feature: 檔內 mock 替身命名統一為 `_Mock` 前綴 (Mock Naming)

> 項目編號：**E-8.7**  
> 優先級別：**P2（測試工程規範）**  
> 預估 Effort：**0.1d**  
> 建立日期：2026-10-27  
> 參考文檔：`docs/brainstorm/2026-10-26-features-brainstorm.md` [E-8.7]；前置項目 `docs/features/2026-09-26-mocktail-test-doubles.md` [E-8.2]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

- E-8.2 引入 mocktail 後，測試檔內宣告的替身有兩種寫法混用：5 個是 public `MockXRepository`，其餘都是私有 `_MockX`（如 `_MockRepo`、`_MockSignInRepository`、`_MockAPIClz`）。
- 對照規則是「共用替身放 `test/mock/`、用 public `MockX`；檔內私有替身用 `_MockX`」。本專案所有替身都在檔內宣告，沒有共用替身，所以 public 命名傳達了錯誤訊息：讀者會以為它被其他檔案共用。
- 觸發場景：開發者新增或修改 BLoC／Repository 測試時，參照既有檔案照抄，結果不一致的命名繼續擴散。

## 2. 使用者故事 (User Stories)

- **身為開發者**，看到替身的命名就要能判斷它是共用的還是只在這個檔案內使用，不必再全域搜尋確認。
- **身為開發者**，照著任一個既有測試檔寫新測試時，抄到的都是同一種命名慣例。

## 3. 規格需求 (What)

將下列 5 個 public 替身改名為 `_` 前綴，只改名稱，不動行為。所有引用都在宣告檔內，沒有跨檔引用（已實查：`lib/`、其他 `test/` 檔皆無引用）。

| 檔案 | 宣告行 | 改名前 | 改名後 |
|---|---|---|---|
| `test/sign_in_bloc_test.dart` | 8 | `MockSignInRepository` | `_MockSignInRepository` |
| `test/main_bloc_load_more_test.dart` | 8 | `MockMainRepository` | `_MockMainRepository` |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | 11 | `MockAiFoodieRepository` | `_MockAiFoodieRepository` |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | 12 | `MockMenuVisionRepository` | `_MockMenuVisionRepository` |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | 10 | `MockMenuVisionRepository` | `_MockMenuVisionRepository` |

## 4. 邊界與非目標 (Out of Scope)

- 不統一已經是私有、只有後綴不一致的替身（如 `_MockRepo`、`_MockAPIClz`、`_MockRemoteConfig`）。
- 不動 `FakeImagePicker`（`test/data_layer/menu_vision_repo_test.dart`）與 `_FakeMainBloc`（`test/flow/main/view/main_page_content_widget_test.dart`）：兩者都不是 mocktail 替身，E-8.2 已說明保留原因。
- 不做 E-8.6（`test()` 遷移為 `blocTest`）。
- 不建立 `test/mock/` 共用替身檔。
- 不修改任何 `lib/` 程式碼、測試邏輯、stub 或斷言。

## 5. 驗收條件 (Verification)

1. `rtk proxy grep -rnE "^class Mock" test/` 輸出為空（改名前為 5 行）。
2. 5 個檔案的測試數量不變：`rtk proxy grep -cE "^\s*(test|testWidgets|blocTest)[<(]" <file>` 改名前後一致（改名前依序為 5／4／14／9／8，合計 40）。
3. `flutter analyze` 無新增 issue。
4. `flutter test` 全數通過，總測試數與改名前相同。
