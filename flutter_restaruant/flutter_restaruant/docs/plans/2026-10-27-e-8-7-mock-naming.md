# 實作計畫：E-8.7 檔內 mock 替身命名統一為 `_Mock` 前綴

- **建立日期**：2026-10-27
- **對應規格**：`docs/features/2026-10-27-e-8-7-mock-naming.md`
- **預估 Effort**：0.1d
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 目標 (Goal)

把 5 個測試檔內宣告成 public 的 mocktail 替身改名為 `_` 前綴，讓命名反映「只在本檔使用」的事實。只改識別字，不動任何行為、stub、斷言與 `lib/`。

---

## 2. 實作方向與取捨 (Approaches & Trade-offs)

| 方向 | 作法 | 優點 | 缺點 | 結論 |
|---|---|---|---|---|
| A | 每檔一次 Edit `replace_all`（`MockX` → `_MockX`） | 最短路徑；所有引用都在宣告檔內，無跨檔問題；diff 可逐行核對 | 純字串替換，需先確認檔內沒有會被誤傷的子字串 | **採用** |
| B | Serena `rename_symbol`（LSP） | 語意化，不會誤傷註解或字串 | 5 次 LSP 呼叫，需 language server 正確載入 `test/`；為單檔私有改名付出不成比例的成本 | 備案（A 的前置檢查失敗時才用） |
| C | `sed` / `perl` 一次批次改 | 一條指令 | 違反專案規則（禁止以 shell 編輯程式碼）；BSD `sed` 不支援 `\b`，容易誤傷 | 不採用 |

**A 的安全前提（規劃階段已實查）**：

- 4 個名稱在 `lib/`、`test/` 中只出現在下表 5 個檔案，共 18 行，沒有跨檔引用。
- 5 個檔案內都還沒有 `_MockX` 同名識別字，`replace_all` 不會產生 `__MockX`。`test/flow/signinup/sign_in_page_test.dart` 已有自己的 `_MockSignInRepository`，但它是另一個 library 的私有類別，兩者互不衝突。
- 改名後最長的宣告行是 79 字元（`menu_vision_*`），不超過 80，`dart format` 不會重排。5 個檔案改名前已通過 `dart format --set-exit-if-changed`（0 changed）。

---

## 3. 檔案異動清單 (File Changes)

只修改以下 5 個檔案，不新增也不刪除任何檔案。

| 檔案 | 改名 | 受影響行（宣告 + 引用） | 行數 |
|---|---|---|---|
| `test/sign_in_bloc_test.dart` | `MockSignInRepository` → `_MockSignInRepository` | 8, 14, 18 | 3 |
| `test/main_bloc_load_more_test.dart` | `MockMainRepository` → `_MockMainRepository` | 8, 56, 62, 78, 96, 119 | 6 |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | `MockAiFoodieRepository` → `_MockAiFoodieRepository` | 11, 57, 62 | 3 |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | `MockMenuVisionRepository` → `_MockMenuVisionRepository` | 12, 37, 41 | 3 |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | `MockMenuVisionRepository` → `_MockMenuVisionRepository` | 10, 127, 132 | 3 |

合計 18 行。不動 `FakeImagePicker`、`_FakeMainBloc`，也不動其他已經是 `_Mock*` 的替身（規格 §4）。

---

## 4. 實作任務 (Tasks)

只有一個任務。改名是單一機械性動作，拆開只會多出交接成本。

### 任務 1：5 個測試檔替身改名，並做全案回歸驗證

**步驟 1：記錄基準（改名前，先確認現況是 red）**

```bash
cd /Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant

# 1a. 驗收條件 1 的 red 狀態：預期 5 行
rtk proxy grep -rnE "^class Mock" test/

# 1b. 5 檔測試數量基準：預期依序 5 / 4 / 14 / 9 / 8（合計 40）
for f in test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart; do
  echo "$f $(rtk proxy grep -cE '^\s*(test|testWidgets|blocTest)[<(]' "$f")"
done

# 1c. analyze 基準：記錄 issue 數（或 "No issues found!"）
flutter analyze 2>&1 | tail -n 3

# 1d. 全案測試基準：記錄最後一行的 +N（通過數）與 ~K（skip 數，若有）
flutter test 2>&1 | tail -n 3
```

把 1c、1d 的輸出記下來，供步驟 3 比對。若 1d 本來就有失敗，先停下來回報，不要繼續改名（否則無法判斷失敗是不是改名造成的）。

**步驟 2：改名（每檔一次 Edit `replace_all`）**

依 §3 表格，對每個檔案執行一次 Edit 工具，`replace_all: true`：

| 檔案 | `old_string` | `new_string` |
|---|---|---|
| `test/sign_in_bloc_test.dart` | `MockSignInRepository` | `_MockSignInRepository` |
| `test/main_bloc_load_more_test.dart` | `MockMainRepository` | `_MockMainRepository` |
| `test/flow/ai_foodie/ai_foodie_bloc_test.dart` | `MockAiFoodieRepository` | `_MockAiFoodieRepository` |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | `MockMenuVisionRepository` | `_MockMenuVisionRepository` |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | `MockMenuVisionRepository` | `_MockMenuVisionRepository` |

5 個 Edit 互相獨立，可以平行執行。

**步驟 3：驗證（改名後為 green）**

```bash
cd /Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant

# 3a. 驗收條件 1：預期輸出為空
rtk proxy grep -rnE "^class Mock" test/

# 3b. 殘留引用：預期輸出為空
#     \b 不會在 "_" 與 "M" 之間成立，所以已改名的 _MockX 不會命中
rtk proxy grep -rnE "\bMock(SignIn|Main|AiFoodie|MenuVision)Repository\b" lib test

# 3c. 新名稱數量：預期依序 3 / 6 / 3 / 3 / 3（合計 18，與 §3 一致）
for f in test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart; do
  echo "$f $(rtk proxy grep -cE '\b_Mock(SignIn|Main|AiFoodie|MenuVision)Repository\b' "$f")"
done

# 3d. 沒有誤產生雙底線：預期輸出為空
rtk proxy grep -rnE "__Mock" test/

# 3e. 驗收條件 2：5 檔測試數量與 1b 相同（5 / 4 / 14 / 9 / 8）
for f in test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart; do
  echo "$f $(rtk proxy grep -cE '^\s*(test|testWidgets|blocTest)[<(]' "$f")"
done

# 3f. 格式不變：預期 "Formatted 5 files (0 changed)"，exit 0
dart format --output=none --set-exit-if-changed \
  test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart

# 3g. 先跑受影響的 5 檔：預期全部通過，合計 40 個測試
flutter test test/sign_in_bloc_test.dart test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart 2>&1 | tail -n 3

# 3h. 驗收條件 3：issue 數與 1c 相同，沒有新增
flutter analyze 2>&1 | tail -n 3

# 3i. 驗收條件 4：全部通過，+N（與 ~K）與 1d 相同
flutter test 2>&1 | tail -n 3
```

**步驟 4：核對 diff 範圍（僅限 5 個實作測試檔；完整 PR 另含規格、計畫與 brainstorm 文件）**

```bash
rtk git diff --stat -- \
  test/sign_in_bloc_test.dart \
  test/main_bloc_load_more_test.dart \
  test/flow/ai_foodie/ai_foodie_bloc_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart \
  test/flow/menu_vision/menu_vision_sheet_test.dart
```

預期在上述 5 個檔案中，共 18 insertions(+) / 18 deletions(-)。

> commit 不在本計畫範圍。要 commit 必須先取得使用者明確授權；若獲授權，建議訊息為 `test(e-8.7): prefix in-file mocktail doubles with underscore`。

---

## 5. 驗收標準 (Acceptance Criteria)

1. `rtk proxy grep -rnE "^class Mock" test/` 輸出為空（改名前 5 行）。
2. `rtk proxy grep -rnE "\bMock(SignIn|Main|AiFoodie|MenuVision)Repository\b" lib test` 輸出為空，沒有殘留舊名。
3. 5 個檔案的測試數量不變（5 / 4 / 14 / 9 / 8，合計 40）。
4. `flutter analyze` 的 issue 數與基準相同，沒有新增。
5. `flutter test` 全部通過，總測試數與基準相同。
6. `git diff --stat -- test/` 只涉及 5 個測試檔案，共 18 行替換（完整 PR 另含 3 個規格與規劃文件）。

---

## 6. 風險點 (Risks)

| 風險 | 評估 | 對策 |
|---|---|---|
| `replace_all` 誤傷子字串 | 低。已實查 5 檔內沒有 `_MockX`，也沒有以這 4 個名稱為前綴的其他識別字 | 3c 數量核對（18）與 3d 雙底線檢查 |
| 與 `sign_in_page_test.dart` 的 `_MockSignInRepository` 撞名 | 無。Dart 私有識別字以 library（檔案）為範圍 | 3i 全案測試 |
| 改名後超過 80 字元，被 `dart format` 重排 | 無。最長 79 字元 | 3f |
| 基準測試本來就有失敗，混淆判讀 | 取決於現況 | 步驟 1d 先記錄；有失敗就停下回報 |
| 文件仍引用舊名（如 E-8.2 規格） | 屬於歷史紀錄，不影響程式 | 不修改（規格 §4 沒有要求） |

---

## 7. 執行方式 (Execution Options)

1. **Subagent-driven（建議）**：派一個 implementer subagent 依序執行任務 1 的步驟 1 → 4，完成後交給 reviewer 核對 diff 與驗證輸出。整體約 5 分鐘，大部分時間花在 `flutter test`。
2. **Parallel session**：不建議。只有 1 個任務，5 個 Edit 在同一個 session 內就能平行完成；開平行 session 只會多出協調成本，沒有加速效果。
