# Implementation Plan：AI 路徑錯誤處理收尾

> 關聯規格：[`docs/features/2026-09-26-ai-error-handling-cleanup.md`](../features/2026-09-26-ai-error-handling-cleanup.md)（v1，待確認）
> 建立日期：2026-09-26
> 狀態：草稿（待確認）
> 基準：`main` @ `5b9f29e`；`flutter test` 目前 269 個全綠
> 預估：0.5d 以內（4 個實作任務，每個 2–5 分鐘，外加驗證）

---

## 0. 已查證的事實（計畫依據）

所有結論都在 repo 的暫存複本（`/tmp`，已刪除）實際改碼、跑 `flutter test` 驗證過，不是推測。

| 事實 | 來源 | 對計畫的影響 |
|------|------|--------------|
| 只拿掉 8 處 catch、不載入 `S`：**+242 −27**，失敗集中在 5 個檔（清單見規格 §2.2） | 暫存複本實測 | 需要讓這 5 個檔在執行前載入 `S` |
| 再加上 `test/flutter_test_config.dart`（全域 `S.load`）：**271 個全綠**（含本計畫新增的 2 個案例） | 暫存複本實測 | T1 方案可行 |
| 兩個 BLoC 測試**早就**在 `setUp` 裡 `await S.load(const Locale('zh', 'TW'))` | `ai_foodie_bloc_test.dart:80-81`、`menu_vision_bloc_test.dart:82-83` | backlog 第 1 步「讓相關測試在 `setUp` 載入 `S`」寫錯對象，真正要處理的是另外 5 個檔 |
| repo 內 15 處 `S.load` 有 12 處用 `Locale('zh', 'TW')`，3 處用 `Locale('en')`；`menu_vision_entity_test.dart:8` 用 `setUpAll` | `rtk proxy grep -rn "S.load(" test` | 全域設定沿用多數慣例 `zh_TW` |
| `bloc` 9.2.1：handler 丟出的錯誤先呼叫 `onError(error, st)`（轉給 `BlocObserver.onError`），再 `rethrow` | `bloc-9.2.1/lib/src/bloc.dart:95-100、229-231` | `Error` 不會被 BLoC 吞掉，也不會 emit 任何狀態 |
| `bloc_test` 10.0.0：`blocTest` 在 `runZonedGuarded` 裡執行，並裝上 `_TestBlocObserver` 收集 `onError`；有給 `errors:` 時不 rethrow，改成 `expect(unhandledErrors, errors())`；沒給 `errors:` 時測試直接因為未處理的錯誤而失敗 | `bloc_test-10.0.0/lib/src/bloc_test.dart:185-246、261-270` | 用 `errors: () => [isA<StateError>()]` 加 `expect:` 只含 loading 狀態，就能同時斷言「錯誤外拋」與「沒有 emit 失敗狀態」 |
| 回歸偵測力：把 `ai_foodie_bloc.dart:92` 與 `menu_vision_bloc.dart:103` 暫時改成裸 `catch` 後，兩個新案例都失敗 | 暫存複本實測 | 新案例確實能擋住回歸 |
| `bloc_test: ^10.0.0` 已在 `dev_dependencies`；兩個 BLoC 測試都用手寫 `implements` 的 fake repository（類別名叫 `Mock...`，但不是 mocktail） | `pubspec.yaml:104`、兩個測試檔頂部 | 不新增依賴；在既有 fake 加一個欄位 |
| `ai_foodie_bloc.dart` 移除 fallback 後，檔內沒有其他地方用 `Logger` | 讀檔 | 同時刪掉 `import 'package:logger/logger.dart';`，否則 `unused_import` |
| `_rouletteDefaultTitle()` 和 `A2UIFallbackStrings.decisionRouletteTitle` 讀的是同一個 key `ai_foodie_roulette_default_title` | `ai_foodie_bloc.dart:167`、`a2ui_fallback_strings.dart:58` | 兩個 roulette helper 各只有一個呼叫點，直接 inline 成 `S.current.x`，不另外抽共用 |

---

## 1. 實作方向與 trade-off

### 1.1 讓測試環境載入 `S`（本次唯一的設計判斷）

| 方案 | 做法 | 寫入檔案 | 優點 | 缺點 |
|------|------|----------|------|------|
| **A（推薦）`test/flutter_test_config.dart`** | Flutter 官方機制：`flutter test` 會自動找 test 目錄（含上層）的 `flutter_test_config.dart`，並用 `testExecutable` 包住每個測試檔的 `main` | 新增 1 檔，既有測試 0 修改 | diff 最小；不必碰三個標明「禁止修改」的 characterization test；讓測試前提跟生產一致（`main()` 一定先 `S.load` 才 `runApp`）；之後新增的測試不會再踩到 | 屬於隱式的全域設定，讀單一測試檔時看不到；`dart test` 不會讀（本 repo 的 `Makefile`、CI 都用 `flutter test`） |
| B backlog 原案：各檔 `setUpAll` | 在 5 個會壞的檔各加 `setUpAll(() async => S.load(const Locale('zh', 'TW')))`，外加 import | 修改 5 檔 | 依賴關係寫在檔案內，一目了然 | 必須修改 `a2ui_characterization_test.dart`，違反它檔頭「T2 之後禁止修改」的規定（上一份計畫已經例外修改過一次）；以後新測試還是可能忘記載入 |
| C 保留 fallback，改成不捕捉 `Error` 的判斷 | 例如先檢查 `S` 是否已載入 | 改 lib | 測試不用動 | `S._current` 是 private，generated 檔不能改；沒有 context 也無法用 `S.maybeOf`。做不到，而且等於保留一個在生產環境永遠不會走到的分支 |

**結論：採方案 A。** 這些 fallback 從頭到尾只在保護「沒載入 `S` 的測試」。真正的問題在測試環境跟生產環境前提不一致，把前提補齊，特殊情況自然就不存在了。

### 1.2 `A2UIFallbackStrings` 要不要 inline 並刪檔

| 方案 | 寫入檔案 | 結論 |
|------|----------|------|
| **保留類別，每個 getter 改成一行 `=> S.current.x`** | 1 檔 | **採用**。呼叫端 0 修改 |
| inline 到呼叫端，刪檔 | lib 2 檔（`a2ui_component.dart` 5 處、`ai_foodie_model.dart` 3 處）＋ test 5 檔（約 25 處，其中 3 檔禁止修改）＋ 刪 1 檔 | 否決：diff 大好幾倍，並且會改到特性測試的斷言。這個類別本身也有價值：它是「降級文字」的唯一來源，測試靠它比對 |

### 1.3 `AiFoodieBloc` 的 `on Exception catch (e)`（L44、L92）要不要補 log

不補。`AiFoodieRepo.askAssistant` 已經在自己的 `on Exception catch (e, st)` 裡 `Logger().e` 並降級（`ai_foodie_repo.dart:181-187`）；`getInitialSuggestions` 回傳本地靜態資料。在生產環境中，BLoC 這兩個分支只有在 repo 實作換掉時才會走到，現在補 log 只會重複記錄。`on Exception` 本身已經符合 §6.1。

---

## 2. 異動檔案

| 檔案 | 動作 | 任務 |
|------|------|------|
| `test/flutter_test_config.dart` | 新增 | T1 |
| `lib/domain/entities/a2ui_fallback_strings.dart` | 修改：6 個 getter 改成一行，刪除 `logger` import | T2 |
| `lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart` | 修改：刪除兩個 roulette helper 並 inline，刪除 `logger` import | T2 |
| `lib/flow/menu_vision/bloc/menu_vision_bloc.dart` | 修改：2 處 `on Exception catch (e, st)` 加上 `Logger().e`，新增 `logger` import | T3 |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | 修改：fake 新增 `analyzeError` 欄位，新增 1 個 `blocTest` | T3 |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | 修改：fake 新增 `errorToThrow` 欄位，新增 `bloc_test` import 與 1 個 `blocTest` | T4 |

---

## 3. 任務總覽與並行判斷

| # | 標題 | 寫入路徑 | 依賴 | 可並行 |
|---|------|----------|------|--------|
| T1 | 測試全域載入 `S` | `test/flutter_test_config.dart`（新） | — | 可與 T3、T4 並行 |
| T2 | 移除 8 處 i18n fallback catch | `lib/domain/entities/a2ui_fallback_strings.dart`、`lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart` | **T1**（沒有 T1 會出現 27 個紅燈） | 可與 T3、T4 並行 |
| T3 | Menu Vision：`Error` 外拋測試＋Logger | `lib/flow/menu_vision/bloc/menu_vision_bloc.dart`、`test/flow/menu_vision/menu_vision_bloc_test.dart` | — | 可與 T1、T2、T4 並行 |
| T4 | AI 覓食：`Error` 外拋測試 | `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | — | 可與 T1、T2、T3 並行 |
| T5 | 收尾驗證 | 不寫入 | T1–T4 | 否 |

T1–T4 的寫入路徑兩兩不重疊（T2 改 `lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart`，T4 只改它的測試檔）。唯一的順序限制是 T2 必須在 T1 之後。
關鍵路徑：T1 → T2 → T5；T3、T4 可以隨時做。

**鐵律**：
1. 既有測試的斷言一條都不改。`test/domain/entities/a2ui_characterization_test.dart`、`test/flow/ai_foodie/ai_foodie_view_characterization_test.dart`、`test/flow/menu_vision/menu_vision_view_characterization_test.dart` 必須零 diff。
2. 每個任務結束時 `flutter analyze` 零 issue，並且跑過該任務列出的驗收指令。
3. 每個任務可以單獨 commit；要 commit 需經使用者授權。

---

## 4. 任務細節

### T1：測試全域載入 `S`

**TDD 說明**：這個任務是測試基礎設施，沒有獨立的紅燈。它的紅燈就是 T2：如果沒有 T1，T2 一改就會出現 27 個失敗（已實測）。

**步驟 1**：新增 `test/flutter_test_config.dart`

```dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter_restaruant/generated/l10n.dart';

/// 所有測試共用：比照 `main()` 在 runApp 前載入 `S`，讓 `S.current` 永遠可用。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await S.load(const Locale('zh', 'TW'));
  await testMain();
}
```

**驗收**：
```bash
flutter analyze test/flutter_test_config.dart   # No issues found
flutter test                                     # 269 個全綠（行為不變）
```

---

### T2：移除 8 處 i18n fallback catch（依賴 T1）

**步驟 1（紅燈，選做）**：如果想看到紅燈，先在還沒有 T1 的狀態下做步驟 2，`flutter test test/domain/entities/a2ui_characterization_test.dart` 應該會出現 16 個 `AssertionError: No instance of S was loaded`。確認後再接著做。

**步驟 2**：把 `lib/domain/entities/a2ui_fallback_strings.dart` 整檔換成下面的內容

```dart
import '../../generated/l10n.dart';

abstract class A2UIFallbackStrings {
  static String get unknownComponent => S.current.a2ui_error_unknown_component;
  static String get dishCatalogEmpty => S.current.a2ui_dish_catalog_empty;
  static String get comparisonMatrixTitle =>
      S.current.a2ui_comparison_matrix_title;
  static String get comparisonItemName => S.current.a2ui_comparison_item_name;
  static String get actionChipGroupTitle =>
      S.current.a2ui_action_chip_group_title;
  static String get decisionRouletteTitle =>
      S.current.ai_foodie_roulette_default_title;
}
```

**步驟 3**：修改 `lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart`
- 刪除第 1–2 行的 `import 'package:logger/logger.dart';` 與後面的空行。
- `_onTriggerActionChip` 內的 `: _rouletteDefaultTitle();` 改成 `: S.current.ai_foodie_roulette_default_title;`。
- `_onSpinRouletteWinnerSelected` 內的 `AiFoodieMessage.assistant(text: _rouletteResultMessage(event.winner)),` 改成：
  ```dart
          AiFoodieMessage.assistant(
            text: S.current.ai_foodie_roulette_result_msg(event.winner),
          ),
  ```
- 刪除 `_rouletteDefaultTitle()` 與 `_rouletteResultMessage()` 兩個方法（原 L165–187）。

**驗收**：
```bash
dart format lib/domain/entities/a2ui_fallback_strings.dart lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart
flutter analyze                                  # No issues found（確認沒有 unused_import）
flutter test                                     # 全綠
rtk proxy grep -n "catch\|Logger" lib/domain/entities/a2ui_fallback_strings.dart lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart
# 期望只剩 ai_foodie_bloc.dart 原本的兩處 `on Exception catch (e)`
```

---

### T3：Menu Vision 的 `Error` 外拋測試與 Logger

**步驟 1（先寫測試）**：修改 `test/flow/menu_vision/menu_vision_bloc_test.dart`

在 `MockMenuVisionRepository` 的 `bool shouldThrow = false;` 下一行加上：
```dart
  Error? analyzeError;
```
在 `analyzeMenuImageBytes` 方法的第一行加上（用區域變數做型別提升，不用 `!`）：
```dart
    final error = analyzeError;
    if (error != null) throw error;
```
在 `'emits [Initial] on ResetMenuVision'` 這個 `blocTest` 前面新增：
```dart
    blocTest<MenuVisionBloc, MenuVisionState>(
      'Error from repository propagates instead of emitting Failure',
      build: () {
        mockRepo.analyzeError = StateError('bug');
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        RetryMenuAnalysis(imageBytes: Uint8List.fromList([1, 2, 3])),
      ),
      expect: () => [const MenuVisionLoading()],
      errors: () => [isA<StateError>()],
    );
```

**步驟 2（確認新測試能擋回歸）**：
```bash
flutter test test/flow/menu_vision/menu_vision_bloc_test.dart   # 新案例是綠的（現況本來就沒有吞 Error）
```
接著暫時把 `menu_vision_bloc.dart:103` 的 `} on Exception catch (e) {` 改成 `} catch (e) {`，再跑一次，**新案例必須失敗**；確認後改回來。

**步驟 3（Logger）**：修改 `lib/flow/menu_vision/bloc/menu_vision_bloc.dart`
- 在 `import 'package:image_picker/image_picker.dart';` 下面加上 `import 'package:logger/logger.dart';`。
- `CaptureAndAnalyzeMenu` handler（原 L64）：
  ```dart
      } on Exception catch (e, st) {
        Logger().e('Menu vision analyze failed', error: e, stackTrace: st);
        emit(
  ```
- `RetryMenuAnalysis` handler（原 L103）：
  ```dart
      } on Exception catch (e, st) {
        Logger().e('Menu vision retry failed', error: e, stackTrace: st);
        emit(
  ```
  注意：`on Exception` **必須保留**，只把 `(e)` 改成 `(e, st)`。

**驗收**：
```bash
dart format lib/flow/menu_vision/bloc/menu_vision_bloc.dart test/flow/menu_vision/menu_vision_bloc_test.dart
flutter analyze                                              # No issues found
flutter test test/flow/menu_vision/                          # 全綠
rtk proxy grep -n "catch" lib/flow/menu_vision/bloc/menu_vision_bloc.dart
# 期望：兩行都是 `} on Exception catch (e, st) {`
```

---

### T4：AI 覓食的 `Error` 外拋測試

**步驟 1**：修改 `test/flow/ai_foodie/ai_foodie_bloc_test.dart`
- 在 import 區加上 `import 'package:bloc_test/bloc_test.dart';`（放在 `package:` 區塊）。
- 在 `MockAiFoodieRepository` 的 `bool shouldThrow = false;` 下一行加上：
  ```dart
  Error? errorToThrow;
  ```
- 在 `askAssistant` 的 `lastHistory = history;` 下一行加上：
  ```dart
    final error = errorToThrow;
    if (error != null) return Future.error(error);
  ```
- 在 `test('history 是送出前的 state.messages（entity）', ...)` 前面新增：
  ```dart
    blocTest<AiFoodieBloc, AiFoodieState>(
      'SendUserPrompt 遇到 Error 往外拋出，不 emit errorMessage',
      build: () {
        repository.errorToThrow = StateError('bug');
        return AiFoodieBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SendUserPrompt('4人聚餐')),
      expect: () => [
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
      ],
      errors: () => [isA<StateError>()],
    );
  ```
  說明：`repository` 由 group 的 `setUp` 建立（`setUp` 在 `blocTest` 的 `build` 之前執行）。`setUp` 建的 `bloc` 這個案例沒用到，但 `tearDown` 仍會關閉它，不需要另外處理。`expect` 只有一個狀態（送出使用者訊息的 loading），代表錯誤發生後沒有再 emit 任何狀態，自然也就不會出現 `errorMessage`。

**步驟 2（確認新測試能擋回歸）**：
```bash
flutter test test/flow/ai_foodie/ai_foodie_bloc_test.dart   # 全綠
```
暫時把 `ai_foodie_bloc.dart:92` 的 `} on Exception catch (e) {` 改成 `} catch (e) {`，再跑一次，**新案例必須失敗**；確認後改回來。（如果 T2 已經先完成，行號會往前移，用 `_onSendUserPrompt` 裡的那一處為準。）

**驗收**：
```bash
dart format test/flow/ai_foodie/ai_foodie_bloc_test.dart
flutter analyze                                              # No issues found
flutter test test/flow/ai_foodie/                            # 全綠
```

---

### T5：收尾驗證

```bash
flutter analyze                                   # No issues found
flutter test                                      # 271 個全綠（269 + 2 個新案例）
git diff main --stat -- test/domain/entities/a2ui_characterization_test.dart \
  test/flow/ai_foodie/ai_foodie_view_characterization_test.dart \
  test/flow/menu_vision/menu_vision_view_characterization_test.dart   # 期望：沒有輸出
rtk proxy grep -nE "\} catch \(" lib/domain/entities/a2ui_fallback_strings.dart \
  lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart lib/flow/menu_vision/bloc/menu_vision_bloc.dart   # 期望：沒有輸出
git diff main --stat                              # 期望只有 §2 列出的 6 個檔
```

---

## 5. 風險與回滾

| 風險 | 偵測點 | 緩解／回滾 |
|------|--------|------------|
| T2 早於 T1 合併 | 27 個測試失敗 | 依賴已寫在 §3；並行執行時，T2 要 rebase 到 T1 之後再驗收 |
| 全域 `zh_TW` 影響依賴 `Intl.defaultLocale` 的測試 | T1 的 `flutter test` | 已實測全綠；如果出現問題，只要 revert T1＋T2 兩個 commit |
| `on Exception` 被誤刪 | T3、T4 新案例 | 新案例已證實能在裸 `catch` 下失敗 |
| 新案例的 `Logger().e` 在測試輸出很吵 | 不影響結果 | 只有 Exception 案例會印 log，和 `ai_foodie_repo_test` 現況相同，不處理 |

每個任務各自一個 commit，彼此可以獨立 revert。T2 依賴 T1：revert T1 之前要先 revert T2。

---

## 6. 執行方式選項

- **Subagent-driven（推薦）**：這次的量很小，一個 subagent 依序做 T1 → T2 → T3 → T4 → T5 即可，主 session 在每個任務結束後檢查驗收輸出與 diff。全部都是機械性改動，設計判斷已經在 §1 定案。
- **Parallel session**：開 3 個 worktree 分別做「T1 → T2」、「T3」、「T4」，寫入路徑完全不重疊，合併時不會衝突；合併後由一個 session 做 T5。只是以這個量來說，協調成本會比省下的時間還高，不建議。

---

## 7. 與 backlog（brainstorm §[E-8.5]）描述不同之處（請確認）

1. **需要載入 `S` 的對象不同**：backlog 說要在兩個 BLoC 測試的 `setUp` 載入 `S`，但它們早就載入了（`zh_TW`）。會壞的是另外 5 個檔、27 個測試（規格 §2.2）。本計畫改用 `test/flutter_test_config.dart` 一次處理，理由見 §1.1。
2. **locale**：backlog 寫 `Locale('en')`，本計畫沿用 repo 多數測試的 `Locale('zh', 'TW')`。受影響的測試斷言都是拿 `A2UIFallbackStrings` getter 跟實際值比對，跟 locale 無關，兩種都會綠。
3. **`catch (e, st)` 的寫法**：backlog 第 4 步寫「改為 `catch (e, st)`」，照字面做會變成吞掉 `Error` 的裸 catch。正確寫法是 `on Exception catch (e, st)`。
4. **`AiFoodieBloc` L44、L92**：backlog 沒提到。評估後不在本次範圍內（§1.3）。
5. **`A2UIFallbackStrings` 保留**：backlog 沒提到要刪。評估過 inline，否決（§1.2）。
6. **backlog 漏列 3 處同樣模式的裸 `catch (_)`**：`lib/domain/entities/dish_item_entity.dart:41`、`allergen_info.dart:30`、`restaurant_business_time_entity.dart:47`，都是在 `S.current` 讀取失敗時退回寫死的中文／英文字串。T1 之後可以用同樣的方式拿掉（每處約 −10 行），但本計畫依 backlog 範圍不納入。若要一併處理，就新增一個 T2b（寫入這 3 個檔，依賴 T1，可與 T2 並行），驗收方式與 T2 相同。
