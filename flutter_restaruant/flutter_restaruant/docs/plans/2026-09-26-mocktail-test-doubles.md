# Implementation Plan: 引入 mocktail，淘汰手寫 Repository Fake (Mocktail Test Doubles)

> 項目編號：**E-8.2**  
> 優先級別：**P2（測試工程規範）**  
> 關聯規格：[`docs/features/2026-09-26-mocktail-test-doubles.md`](../features/2026-09-26-mocktail-test-doubles.md)  
> 建立日期：2026-09-26  
> 狀態：草稿（待確認）

---

## 1. 簡介與目標 (Overview)

把 9 個測試檔中手寫的 `implements XRepository` 替身，換成 `class MockX extends Mock implements XRepository {}` 一行宣告，行為改由 `when` / `thenAnswer` / `thenThrow` 在 case 內宣告，呼叫驗證改用 `verify` / `captureAny`。**只動 `test/` 與 `pubspec.*`，不碰 `lib/`。** 每檔測試數量不變、斷言不刪不放寬。

---

## 2. 架構設計與 Trade-off 分析 (Design & Trade-offs)

### 2.1 方案比較

| 方案 | 作法 | 優點 | 缺點 |
|---|---|---|---|
| **A. mocktail，每檔一行宣告（採用）** | 各檔 `class MockX extends Mock implements XRepository {}` | 無 codegen；依賴已在 lock 中；宣告只有一行，重複成本趨近零 | 未 stub 的非 nullable 回傳會在執行期報錯（需在 `setUp` 補預設 stub） |
| B. mocktail + 共用 `test/mock/` 檔 | 集中宣告 Mock 與 fallback 註冊 | 單一來源 | 只有 `MockMenuVisionRepository` 重複兩次，為一行宣告多一個檔與 import，不划算（YAGNI） |
| C. mockito `@GenerateMocks` | build_runner 產生 `*.mocks.dart` | 型別完整、未 stub 可 nice mock | 多一個 codegen 產物與新依賴解析；本專案 `bloc_test` 已選 mocktail 生態 |
| D. 保留手寫 Fake，只去重 | 抽出共用 Fake | 改動最小 | 旗標與回退鏈仍在，不解決「意圖埋在替身裡」的根本問題 |

### 2.2 關鍵事實（已核對原始碼）
- `mocktail 1.0.5` 已在 `pubspec.lock`（transitive，來自 `bloc_test ^10.0.0`）；`flutter pub add --dev mocktail` 只把它升為 direct dev，版本不變。
- mocktail 1.0.5 未 stub 的呼叫回傳 `null`：`void` 方法（如 `MainRepository.reset()`）安全；回傳 `Future<T>` 的方法若未 stub 會拋 `TypeError`。**所以原本 Fake 的「預設行為」要搬進 `setUp` 當預設 stub**。
- 內建 fallback 只涵蓋 `bool/int/double/String/List/Map/Set/DateTime/Function`。本案需額外 `registerFallbackValue`：`Uint8List(0)`、`AccountTypeModel.none`、`const RestaurantEntity(id: '', name: '')`（僅在該型別參數使用 `any()` 時）。
- `MenuVisionBloc` 只呼叫 `captureImage` / `pickImageFromGallery` / `analyzeMenuImageBytes`；Fake 內的 `captureAndAnalyzeMenu` / `pickFromGalleryAndAnalyzeMenu` 是死碼，遷移後自然消失，不需 stub。
- `SignInPage` 進入頁面時（`sign_in_page.dart:38`）會送出 `AutoSignInEvent` → 呼叫 `signInUp`，所以 `sign_in_page_test.dart` 必須 stub `signInUp` 回傳 `Tuple2(null, null)`。
- `MainBloc` 讀 `summaryInfoSet` getter、呼叫 `fetchYelpSearchInfo`；需 `when(() => repo.summaryInfoSet).thenReturn({...})`。`fetchCallCount` / `returnFilteredInfos` 在測試中未被斷言，直接刪除。

### 2.3 待確認：特性測試的「禁止修改」註解
`ai_foodie_view_characterization_test.dart` 與 `menu_vision_view_characterization_test.dart` 標註「T2 之後禁止修改」（源自 `docs/plans/2026-09-24-domain-entity-json-serializable.md` 的特性測試鎖，該重構已合併）。本計畫預設**納入遷移**：只替換替身與其建構方式，所有 `expect` 的期望值不變；`h.repo.lastHistory` 改為 `verify(...).captured` 屬斷言來源替換而非語意變更。註解保留。若決定維持凍結，直接略過 T3b / T2c，其餘任務不受影響。

---

## 3. 檔案異動清單 (File Changes)

| 檔案 | 任務 |
|---|---|
| `pubspec.yaml`、`pubspec.lock` | T1 |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | T2a |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | T2b |
| `test/flow/menu_vision/menu_vision_view_characterization_test.dart` | T2c |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | T3a |
| `test/flow/ai_foodie/ai_foodie_view_characterization_test.dart` | T3b |
| `test/sign_in_bloc_test.dart` | T4a |
| `test/flow/signinup/sign_in_page_test.dart` | T4b |
| `test/main_bloc_load_more_test.dart` | T5a |
| `test/component/restaurant_head_cell_test.dart` | T5b |

**平行化**：T1 必須先完成（其他任務需要 direct dependency 才不觸發 lint）。T2 / T3 / T4 / T5 寫入路徑互不重疊，可平行。T6 最後執行。

**基線**（開工前記錄，供收尾比對）：
```bash
rtk proxy grep -c "testWidgets(\|test(\|blocTest<" \
  test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/component/restaurant_head_cell_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/ai_foodie/ai_foodie_view_characterization_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart \
  test/flow/menu_vision/menu_vision_view_characterization_test.dart \
  test/flow/signinup/sign_in_page_test.dart
# 預期：5 / 4 / 2 / 13 / 8 / 8 / 8 / 6 / 3（合計 57）
```

---

## 4. 任務拆分 (Tasks Breakdown)

共通模式（每個檔案都一樣）：
1. 新增 `import 'package:mocktail/mocktail.dart';`（package 區塊內依字母序）。
2. 手寫類別整段換成一行 `class MockX extends Mock implements XRepository {}`。
3. 原 Fake 的預設行為 → `setUp` 預設 stub；個別 case 的旗標設定 → case 內 `when(...)`（後宣告的 stub 覆蓋先前的）。
4. `*Called` / `last*` → `verify(...)` / `verify(...).captured`。
5. 若使用 `any()` 於非 primitive 型別 → `setUpAll(() => registerFallbackValue(...))`。

> TDD 註記：本案是純測試重構，「先寫失敗測試」不適用；替代紀律為**先跑綠 → 改 → 再跑綠，且測試數與基線一致**。每個任務另做一次「故意改壞 stub 使其失敗」的手動 sanity check（例如把 `thenAnswer` 回傳改錯），確認新斷言真的有在驗證，再還原。

- [ ] **T1: 宣告 mocktail 為 direct dev dependency**（2 分鐘）
  - 檔案：`pubspec.yaml`、`pubspec.lock`
  - 指令：`flutter pub add --dev mocktail`（應寫入 `mocktail: ^1.0.5`；若寫出其他版本，手動改為 `^1.0.5` 後 `flutter pub get`）
  - 將該行移到 `bloc_test` 下方並加註解 `# Repository test doubles`，與既有風格一致。
  - 驗證：`rtk git diff pubspec.lock` 只應看到 mocktail 的 `dependency: transitive` → `"direct dev"`，`version: "1.0.5"` 不變。

- [ ] **T2a: `menu_vision_bloc_test.dart`**（5 分鐘）
  - 刪除旗標 Fake，改為：
    ```dart
    class MockMenuVisionRepository extends Mock implements MenuVisionRepository {}

    class _Data {
      static final Uint8List sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
    }
    ```
  - `setUpAll(() => registerFallbackValue(Uint8List(0)));`
  - 對照表：

    | 舊 case 設定 | 新 stub / 驗證 |
    |---|---|
    | `captureResult = sampleCatalog` | `when(() => mockRepo.captureImage()).thenAnswer((_) async => _Data.sampleBytes);` + `when(() => mockRepo.analyzeMenuImageBytes(any())).thenAnswer((_) async => sampleCatalog);` |
    | `captureResult = null` | `captureImage()` → `null` |
    | `captureResult = FallbackMarkdownComponent(...)` | `captureImage()` → bytes；`analyzeMenuImageBytes(any())` → 該 fallback；期望 `failedImageBytes: _Data.sampleBytes` |
    | `shouldThrow = true` | `when(() => mockRepo.captureImage()).thenThrow(Exception('模擬相機錯誤'));` |
    | `captureResult` + `analyzeShouldThrow` | `captureImage()` → bytes；`analyzeMenuImageBytes(any())` → `thenThrow(const FormatException('Empty menu analysis response'))` |
    | `galleryResult = sampleCatalog` | `pickImageFromGallery()` → bytes；`analyzeMenuImageBytes(any())` → catalog |
    | `analyzeResult = sampleCatalog`（Retry） | `analyzeMenuImageBytes(any())` → catalog |
    | `verify: expect(mockRepo.captureCalled, isTrue)` | `verify: (_) => verify(() => mockRepo.captureImage()).called(1)` |
    | `verify: expect(mockRepo.galleryCalled, isTrue)` | `verify: (_) => verify(() => mockRepo.pickImageFromGallery()).called(1)` |
  - 驗證：`flutter test test/flow/menu_vision/menu_vision_bloc_test.dart`（8 個通過）

- [ ] **T2b: `menu_vision_sheet_test.dart`**（4 分鐘）
  - 同 T2a 的一行 `MockMenuVisionRepository` 宣告（**不抽共用檔**）、同一個 `registerFallbackValue(Uint8List(0))`。
  - `captureResult = sampleCatalog` → `captureImage()` 回 `Uint8List.fromList([1, 2, 3])`、`analyzeMenuImageBytes(any())` 回 catalog；`shouldThrow` → `captureImage()` `thenThrow(Exception('模擬錯誤'))`；`captureResult = null` → `captureImage()` 回 `null`。
  - 驗證：`flutter test test/flow/menu_vision/menu_vision_sheet_test.dart`（8 個通過）

- [ ] **T2c: `menu_vision_view_characterization_test.dart`**（3 分鐘，見 §2.3）
  - `_FakeRepo(data)` → `class _MockRepo extends Mock implements MenuVisionRepository {}`；在 `_pumpCatalog` 內建立並 stub：`captureImage()` → `Uint8List.fromList([1])`、`analyzeMenuImageBytes(any())` → `A2UIComponent.fromJson({'component_type': 'dish_catalog', 'data': data})`。`main()` 的 `setUpAll` 補 `registerFallbackValue(Uint8List(0))`。
  - 所有 `expect` 一字不動。
  - 驗證：`flutter test test/flow/menu_vision/menu_vision_view_characterization_test.dart`（6 個通過）

- [ ] **T3a: `ai_foodie_bloc_test.dart`**（5 分鐘）
  - `class MockAiFoodieRepository extends Mock implements AiFoodieRepository {}`
  - 原 Fake 的預設回傳（歡迎訊息、比較清單回覆）搬到 `_Data`（`static final welcome = [...]`、`static AiFoodieMessage reply(String prompt) => ...`），於 `setUp` 預設 stub：
    ```dart
    when(() => repository.getInitialSuggestions())
        .thenAnswer((_) async => _Data.welcome);
    when(() => repository.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        )).thenAnswer((inv) async =>
        _Data.reply(inv.positionalArguments.first as String));
    ```
  - `shouldThrow = true` → 在該 case 內重新 stub 為 `thenAnswer((_) async => throw Exception('模擬建議取得失敗'))` / `'模擬對話連線失敗'`（保持非同步拋錯，與原 `Future.error` 同語意）。
  - `expect(repository.lastHistory, priorMessages)` →
    ```dart
    final captured = verify(() => repository.askAssistant(
          '第二句',
          history: captureAny(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        )).captured;
    expect(captured.single, priorMessages);
    ```
  - `List<...>?` 的 `any()` 由內建 `const <Never>[]` fallback 涵蓋，不需註冊。
  - 驗證：`flutter test test/flow/ai_foodie/ai_foodie_bloc_test.dart`（13 個通過，特別注意 `ResetAiFoodie 會作廢先前的非同步請求` 仍綠）

- [ ] **T3b: `ai_foodie_view_characterization_test.dart`**（4 分鐘，見 §2.3）
  - `_FakeRepo` → `class _MockRepo extends Mock implements AiFoodieRepository {}`；`_Harness.repo` 型別改為 `_MockRepo`。
  - `_pump` 內 stub：`getInitialSuggestions()` → `[AiFoodieMessage.fromJson(messageJson)]`；`askAssistant(...)` → `AiFoodieMessage.assistant(text: '回覆：$prompt')`。
  - `expect(h.repo.lastHistory, [AiFoodieMessage.fromJson(_Data.full)])` → `verify(... history: captureAny(named: 'history') ...).captured.single` 等於同一期望值。
  - `expect(h.repo.lastHistory, isNull)`（未知 chip 無動作）→ `verifyNever(() => h.repo.askAssistant(any(), history: any(named: 'history'), candidateRestaurants: any(named: 'candidateRestaurants')))`。
  - 驗證：`flutter test test/flow/ai_foodie/ai_foodie_view_characterization_test.dart`（8 個通過）

- [ ] **T4a: `sign_in_bloc_test.dart`**（4 分鐘）
  - `class MockSignInRepository extends Mock implements SignInRepository {}`；`setUpAll(() => registerFallbackValue(AccountTypeModel.none));`
  - 各 case 的 `returnAccountInfo` / `returnFailureReason` → case 內 stub：
    ```dart
    when(() => mockRepo.signInUp(
          accountType: any(named: 'accountType'),
          isSignUp: any(named: 'isSignUp'),
          mail: any(named: 'mail'),
          passwd: any(named: 'passwd'),
        )).thenAnswer((_) async => const Tuple2(account, null));
    ```
  - `lastAccountType` / `lastIsSignUp` / `lastMail` / `lastPasswd` 斷言 → 以具體值 `verify`：
    ```dart
    verify(() => mockRepo.signInUp(
          accountType: AccountTypeModel.mail,
          isSignUp: true,
          mail: 'test@mail.com',
          passwd: 'secret',
        )).called(1);
    ```
    Google case 為 `accountType: AccountTypeModel.google, isSignUp: false, mail: '', passwd: ''`。
  - 驗證：`flutter test test/sign_in_bloc_test.dart`（5 個通過）

- [ ] **T4b: `sign_in_page_test.dart`**（2 分鐘）
  - `class _MockSignInRepository extends Mock implements SignInRepository {}`；`setUpAll` 註冊 `AccountTypeModel.none`；`setUp` 內 stub `signInUp(...)` → `const Tuple2(null, null)`（`AutoSignInEvent` 會觸發，未 stub 會 `TypeError`）。
  - 驗證：`flutter test test/flow/signinup/sign_in_page_test.dart`（3 個通過）

- [ ] **T5a: `main_bloc_load_more_test.dart`**（4 分鐘）
  - `class MockMainRepository extends Mock implements MainRepository {}`；刪除 `fetchCallCount`、`returnFilteredInfos`（無斷言使用）。
  - 每個 case：
    ```dart
    mockRepo = MockMainRepository();
    when(() => mockRepo.summaryInfoSet).thenReturn({_Data.existing});
    when(() => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()))
        .thenAnswer((_) async => _Data.nextPage);
    ```
    首次載入 case 的 `summaryInfoSet` 回 `<RestaurantEntity>{}`。`double` / `int?` / `String?` 皆有內建 fallback。
  - 驗證：`flutter test test/main_bloc_load_more_test.dart`（4 個通過）

- [ ] **T5b: `restaurant_head_cell_test.dart`**（3 分鐘）
  - `class _MockRestaurantDetailRepository extends Mock implements RestaurantDetailRepository {}`；`setUpAll(() => registerFallbackValue(const RestaurantEntity(id: '', name: '')));`
  - `setUp` stub `toggleFavor(any())` → `thenAnswer((inv) async { final e = inv.positionalArguments.first as RestaurantEntity; return e.copyWith(favor: !e.favor); })`。`fetchYelp*` 未被此測試觸發，不 stub（YAGNI）；若執行期出現 `TypeError` 再補。
  - `expect(fakeRepo.lastToggled?.id, 'unfavor_1')` →
    ```dart
    final toggled = verify(() => mockRepo.toggleFavor(captureAny()))
        .captured.single as RestaurantEntity;
    expect(toggled.id, 'unfavor_1');
    ```
  - 驗證：`flutter test test/component/restaurant_head_cell_test.dart`（2 個通過）

- [ ] **T6: 全域驗收**（3 分鐘）
  ```bash
  dart format test/
  flutter analyze
  flutter test
  rtk proxy grep -rnE "^class .* implements .*Repository" test/ | grep -v "extends Mock"   # 預期空輸出
  ```
  並重跑 §3 基線指令，數字必須與基線一致（57）。

---

## 5. 執行方式 (Execution Options)

1. **Subagent-driven（建議）**：主 agent 先做 T1，接著派 4 個 subagent 分別執行 T2（menu_vision）/ T3（ai_foodie）/ T4（sign_in）/ T5（main + restaurant_head_cell），寫入路徑不重疊；全部回報後主 agent 執行 T6 並做 review。
2. **Parallel session**：T1 合併後，開 2 個 session：A 做 T2+T3（A2UI 相關），B 做 T4+T5；各自跑自己的 `flutter test <files>`，最後一方執行 T6。
3. **單一 session 依序執行**：9 個檔案總量約 35 分鐘，改動機械化，單人依序做也可接受。

---

## 6. 驗證與退出標準 (Exit Criteria)

1. `pubspec.yaml` 有 `mocktail: ^1.0.5`，`pubspec.lock` 版本仍為 `1.0.5`。
2. 9 個檔案不再有手寫 Repository 替身；Out of Scope 的 `_FakeMainBloc`、`FakeImagePicker`、`_BigImageStub` 未被改動。
3. 各檔測試數與基線一致，無 `skip`、無刪除的 `expect`。
4. `flutter analyze` 無新增 issue；`flutter test` 全綠。
