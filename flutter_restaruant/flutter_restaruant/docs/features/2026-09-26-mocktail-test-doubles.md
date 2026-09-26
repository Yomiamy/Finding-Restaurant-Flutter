# Feature: 引入 mocktail，淘汰手寫 Repository Fake (Mocktail Test Doubles)

> 項目編號：**E-8.2**  
> 優先級別：**P2（測試工程規範）**  
> 建立日期：2026-09-26  
> 參考文檔：`docs/brainstorm/2026-09-25-features-brainstorm.md` [E-8.2]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **手寫 Fake 氾濫（9 個檔案）**：
   - Backlog 只點名 `menu_vision_bloc_test.dart`，但實際上已有 9 個測試檔各自手寫 `implements XRepository` 的替身，每新增一個 repository 方法就要改 N 個檔。
2. **旗標驅動的替身 (Flag-heavy Fake)**：
   - `MockMenuVisionRepository` 以 `shouldThrow`、`analyzeShouldThrow`、`captureCalled`、`galleryCalled`、`captureResult` 等旗標組合行為，`analyzeMenuImageBytes` 還有 `analyzeResult ?? captureResult ?? galleryResult ?? ...` 的回退鏈。測試意圖埋在替身實作裡，讀測試看不出「這個 case 到底 stub 了什麼」。
   - 替身還實作了 `captureAndAnalyzeMenu()`、`pickFromGalleryAndAnalyzeMenu()`，但 `MenuVisionBloc` 根本不呼叫它們——死代碼，且 `captureCalled` 同時在兩處被設為 `true`，驗證語意模糊。
3. **重複**：
   - `MockMenuVisionRepository` 在 `menu_vision_bloc_test.dart` 與 `menu_vision_sheet_test.dart` 各寫一份，行為還略有不同（一個 `async throw`，一個 `Future.error`）。
4. **「呼叫紀錄」自己刻**：
   - `lastAccountType`、`lastMail`、`lastHistory`、`lastToggled`、`fetchCallCount` 等欄位都是在重做 `verify` / `captureAny`。
5. **transitive 依賴直接 import 是 lint 違規**：
   - `mocktail 1.0.5` 已被 `bloc_test` 帶進 `pubspec.lock`（`dependency: transitive`），但未宣告在 `dev_dependencies`，直接 import 會觸發 `depend_on_referenced_packages`。

### 1.2 改造目標
- **資料結構先行**：替身一律是 `class MockX extends Mock implements XRepository {}` 一行宣告；行為在每個 test 內用 `when(...)` 宣告，驗證用 `verify(...)`。
- **消滅特殊情況**：刪除所有 `shouldThrow` / `*Called` / `last*` 旗標與回退鏈，改由 stub 與 `verify` 表達。
- **零新依賴解析**：mocktail 版本已鎖在 `1.0.5`，只是把 transitive 升為 direct dev。

---

## 2. 使用者故事 (User Stories)

- **身為開發者**，新增 repository 方法時，我不想為了讓測試編譯通過而去改 9 個手寫 Fake。
- **身為開發者**，讀一個測試 case 時，我想在 case 本身看到 stub 的回傳與被驗證的呼叫，而不是回頭解讀替身內的旗標組合。
- **身為 reviewer**，我想要所有 repository 替身都用同一種寫法，review 時不必每個檔重新理解一套自製 Fake。

---

## 3. 規格需求 (What)

### 3.1 依賴
- `pubspec.yaml` 的 `dev_dependencies` 新增 `mocktail: ^1.0.5`（`flutter pub add --dev mocktail`）。`pubspec.lock` 僅 `dependency` 欄由 `transitive` 變 `direct dev`，版本不變。

### 3.2 遷移範圍（9 個檔案）

| 檔案 | 現有替身 | 遷移後 |
|---|---|---|
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | `MockMenuVisionRepository`（旗標） | `MockMenuVisionRepository extends Mock` |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | `MockMenuVisionRepository`（重複） | 同上（檔內一行宣告） |
| `test/flow/menu_vision/menu_vision_view_characterization_test.dart` | `_FakeRepo` | `_MockRepo extends Mock` |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | `MockAiFoodieRepository` | `MockAiFoodieRepository extends Mock` |
| `test/flow/ai_foodie/ai_foodie_view_characterization_test.dart` | `_FakeRepo` | `_MockRepo extends Mock` |
| `test/sign_in_bloc_test.dart` | `MockSignInRepository` | `MockSignInRepository extends Mock` |
| `test/flow/signinup/sign_in_page_test.dart` | `_FakeSignInRepository` | `_MockSignInRepository extends Mock` |
| `test/main_bloc_load_more_test.dart` | `MockMainRepository` | `MockMainRepository extends Mock` |
| `test/component/restaurant_head_cell_test.dart` | `_FakeRestaurantDetailRepository` | `_MockRestaurantDetailRepository extends Mock` |

### 3.3 遷移規則
1. 旗標 → stub：`shouldThrow` → `thenThrow` / `thenAnswer((_) async => throw ...)`；`xxxResult` → `thenAnswer((_) async => ...)`。
2. 呼叫紀錄 → 驗證：`captureCalled` / `galleryCalled` / `lastToggled` → `verify(...)`；`lastAccountType` / `lastMail` / `lastHistory` → `verify(...).captured` 或直接以具體參數 `verify`。
3. 非 primitive 的 `any()` 需 `registerFallbackValue`（`Uint8List`、`AccountTypeModel`、`RestaurantEntity`），放在 `setUpAll`。
4. 測試資料（如 `sampleBytes`）依專案規範放進檔內 `_Data`。
5. **不建立共用 mock 檔**：一行宣告在兩個檔重複，比新增 `test/mock/` 檔與 import 更便宜。

---

## 4. 邊界與非目標 (Out of Scope)

- `test/flow/main/view/main_page_content_widget_test.dart` 的 `_FakeMainBloc extends Bloc implements MainBloc`：它是真實的 Bloc stream，改用 `MockBloc` + `whenListen` 屬於另一種遷移（bloc_test API），不混入本項。
- `test/data_layer/menu_vision_repo_test.dart` 的 `FakeImagePicker extends ImagePicker`：它是測試「真實 repository」時的平台邊界替身，換成 mock 不會減少任何複雜度。
- `test/component/cell/error_builder_constraint_test.dart` 的 `_BigImageStub`：是 Widget，不是 test double。
- 不修改任何 `lib/` 程式碼、不改 repository 介面。
- 不改測試內既有的中文例外訊息字串（部分測試以 `contains('模擬建議取得失敗')` 斷言，改字串屬行為變更）。

---

## 5. 驗收條件 (Verification)

1. `rtk proxy grep -rnE "^class .* implements .*Repository" test/ | grep -v "extends Mock"` 輸出為空（遷移前為 9 行）。
2. 9 個檔案的測試數量不變（合計 57 個 `test` / `testWidgets` / `blocTest`），且沒有任何斷言被刪除或放寬。
3. 原本以旗標驗證的呼叫（`captureCalled`、`galleryCalled`、`lastToggled`、`lastAccountType` 等）皆有對應 `verify`。
4. `flutter analyze` 無新增 issue（含 `depend_on_referenced_packages`）。
5. `flutter test` 全數通過。
