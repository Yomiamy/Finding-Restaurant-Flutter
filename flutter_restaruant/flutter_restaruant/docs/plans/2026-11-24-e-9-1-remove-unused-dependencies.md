# 實作計畫：E-9.1 移除 4 個零使用相依套件

> **給執行者（For agentic workers）：** 本計畫於 STAGE 1 依 `main` 建立的獨立 worktree 內執行。依 `delegation-and-parallel.md` 派發煞車契約，本計畫為單一 `[原地修改]` 微任務（`total_tasks = 1`）：人工編輯僅移除 `pubspec.yaml` 4 行且無任何公共 API 變更，`pubspec.lock` 為 `flutter pub get` 衍生輸出；須由主進程於該 worktree 原地完成修改與測試驗證，**不派發 `implementer` 或獨立 `verifier` subagent**。步驟以核取方塊（`- [ ]`）追蹤進度。

- **建立日期**：2026-11-24
- **對應規格**：[`docs/features/2026-11-24-e-9-1-remove-unused-dependencies.md`](../features/2026-11-24-e-9-1-remove-unused-dependencies.md)
- **狀態**：✅ READY（STAGE 0b，修訂版 1 已通過獨立 `plan-verifier` 複審，待確認）

**Goal：** 在 STAGE 1 建立之獨立 worktree 中，自 `pubspec.yaml` 移除 4 個零使用直接相依（`sqflite`、`path_provider`、`camera`、`firebase_storage`），透過 `flutter pub get` 同步 `pubspec.lock`、`.flutter-plugins-dependencies` 與三平台自動產生的原生插件註冊清單，並驗證 `pubspec.lock` 邊界、靜態分析與全案測試（含 `MenuVision` 拍照／選圖）零回歸。

**Architecture：** 純依賴清理。僅從 `pubspec.yaml` `dependencies` 刪除 4 行未使用的直接宣告並執行 `flutter pub get`；不改動 `lib/`、`test/`、原生權限宣告（`ios/Runner/Info.plist` 等）或任何 SDK／其餘套件版本約束。

**Tech Stack：** Flutter (`>=3.44.1`), Dart (`>=3.10.1 <4.0.0`), `pubspec.yaml`, `pubspec.lock`, `image_picker: ^1.0.2`（保留，負責 `MenuVision` 拍照／選圖）

**Spec：** [`docs/features/2026-11-24-e-9-1-remove-unused-dependencies.md`](../features/2026-11-24-e-9-1-remove-unused-dependencies.md)

## Global Constraints

- 所有實作與驗證必須在 STAGE 1 從 `main` 建立之新 worktree 內執行。
- `pubspec.yaml` `environment` 維持 `sdk: '>=3.10.1 <4.0.0'` 與 `flutter: '>=3.44.1'`，且不連帶升級、降級或增刪其餘無關套件。
- `pubspec.lock` 檔尾 `sdks:` 不可出現非預期的下限上調；基線為 `dart: ">=3.13.0 <4.0.0"`、`flutter: ">=3.47.0"`（移除套件後下限維持不變或自然放寬皆可接受，絕不可無故提高下限）。
- 嚴禁更動 `ios/Runner/Info.plist`（第 95 行 `NSCameraUsageDescription` 由 `image_picker` 使用）、`lib/app/firebase_options.dart`（`storageBucket`）及 `docs/brainstorm/`。

---

## 1. 設計取捨分析（Approaches & Trade-offs）

| 實作方向 | 作法 | 優點 | 缺點 / 風險 | 結論 |
|---|---|---|---|---|
| **方案 A：直接移除 4 行宣告 + `flutter pub get`（不碰其他檔案）** | 自 `pubspec.yaml` 移除 `sqflite`、`path_provider`、`camera`、`firebase_storage` 4 行，執行 `flutter pub get` 更新 `pubspec.lock` 與本地自動產生的插件清單 | 1. 最小 diff，嚴格對齊規格 AC-1～AC-5 與 YAGNI<br>2. 既有傳遞依賴鏈（`flutter_facebook_auth` → `facebook_auth_desktop` → `flutter_secure_storage` → `flutter_secure_storage_windows` → `path_provider`，以及 `shared_preferences_{linux,windows}` → `path_provider_{linux,windows}`）由 `flutter pub get` 自動降級保留為 `transitive`，零破壞風險<br>3. 失敗時可單行 `git checkout` 完整回滾 | 需在檢核步驟機械驗證 `pubspec.lock` 沒有連帶變動其他無關直接依賴 | **採用** |
| **方案 B：連帶執行 `flutter pub upgrade` 或手動刪改原生設定／註解** | 移除 4 個套件同時升級其餘相依，或嘗試刪除 `Info.plist` / `firebase_options.dart` 相關項目 | 無額外正當收益 | 1. 違反規格 §3 Out of Scope<br>2. 刪除 `NSCameraUsageDescription` 會直接打壞 `image_picker` 拍照功能（iOS 必閃退）<br>3. 混雜版本變動擴大回歸面 | **不採用** |

**決策依據：** 經實查，4 個套件（含平台子套件）在 `lib/` 與 `test/` 皆為 0 import（專案目前無 `integration_test/` 目錄），原生設定檔（`pbxproj`、`build.gradle`、`Podfile.lock`、4 份 SPM `Package.resolved`）亦無手動引用；`pubspec.lock` 雖位於 `.gitignore:3`（`*.lock`）範圍內，但已透過 `git ls-files --error-unmatch pubspec.lock` 實證受 Git 追蹤；`GeneratedPluginRegistrant.*` 與 `Flutter/ephemeral/` 均在 `.gitignore` 內。方案 A 是風險最低、變更最小且完全可逆的作法。

---

## 2. 檔案異動清單（File Changes）

於 STAGE 1 建立的獨立 worktree 中，git 追蹤之預期異動範圍嚴格限定如下：

### 2.1 修改檔案（Git 追蹤）

| 檔案 | 異動方式 | 變更內容 |
|---|---|---|
| `pubspec.yaml` | 人工編輯（刪除 4 行） | 移除 L35 `sqflite: ^2.3.0`、L37 `path_provider: ^2.1.3`、L42 `camera: ^0.12.0+2`、L53 `firebase_storage: ^13.4.5` |
| `pubspec.lock` | 指令自動更新（註：雖 `.gitignore:3` 含 `*.lock`，但 `pubspec.lock` 已實證受 Git 追蹤） | 執行 `flutter pub get` 同步移除 `sqflite`、`camera`、`firebase_storage` 及其平台子套件，並將 `path_provider` 由 `dependency: "direct main"` 轉為 `dependency: transitive`；其餘所有 `direct main` / `direct dev` 套件版本完全不變 |

### 2.2 本地自動產生檔案（Gitignored，不入版控但於 Step 4 嚴格核對同步）

- `.flutter-plugins-dependencies`（全 6 平台插件相依真實來源，`flutter pub get` 必更新）
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`（`.gitignore:71`、`android/.gitignore:5`，`flutter pub get` 必更新）
- `ios/Runner/GeneratedPluginRegistrant.m`（`.gitignore:102`、`ios/.gitignore:27`，`flutter pub get` 必更新）
- `macos/Flutter/GeneratedPluginRegistrant.swift`（`.gitignore:105`，`flutter pub get` 必更新）
- 註：`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 與 `macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 為 gitignored 的 SPM ephemeral 檔，由原生建置（`flutter build` / `flutter run`）再生而非 `flutter pub get` 必產物，不與 Step 4 之 `flutter pub get` 驗證混為一談。

### 2.3 唯讀驗證清單（禁止修改）

- `ios/Runner/Info.plist:95`（`NSCameraUsageDescription`）
- `lib/app/firebase_options.dart`
- `lib/data_layer/repositories/menu_vision_repo.dart`、`lib/flow/menu_vision/`、`lib/features/utils/platform_capabilities.dart`
- `test/data_layer/menu_vision_repo_test.dart`、`test/flow/menu_vision/`

---

## 3. 實作任務拆分（Tasks）

> **任務收斂說明（`total_tasks = 1`）：** 本案人工修改僅刪除 `pubspec.yaml` 4 行且無任何公共 API 變更，符合 `delegation-and-parallel.md` 的派發煞車門檻（單檔 ≤ 20 行且無公共 API 變更），收斂為單一 `[原地修改]` 微任務，由主進程於新 worktree 一次閉環完成清理與完整回歸驗證（預估 3–5 分鐘）。

### Task 1：移除 4 個零使用相依並驗證 lockfile 邊界與回歸測試 `[原地修改]`

**Files:**
- Modify: `pubspec.yaml:35,37,42,53`
- Generated Update: `pubspec.lock`（Git 追蹤）
- Local Generated Verification (Gitignored): `.flutter-plugins-dependencies`、`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`、`ios/Runner/GeneratedPluginRegistrant.m`、`macos/Flutter/GeneratedPluginRegistrant.swift`
- Read-only verification targets: `ios/Runner/Info.plist:95`, `lib/`, `test/`

**Interfaces:**
- Consumes: STAGE 1 新 worktree 基線 `pubspec.yaml` 與 `pubspec.lock`
- Produces: 已移除 4 個零使用直接相依且通過 lockfile 邊界、插件註冊同步、`flutter analyze` 與全案 `flutter test` 的乾淨工作區

- [ ] **Step 1：基線檢查（Pre-check）**

於 STAGE 1 新 worktree 的 Flutter 專案根目錄執行：

```bash
git status --short --branch
git ls-files --error-unmatch pubspec.lock
grep -nE "^\s+(sqflite|path_provider|camera|firebase_storage):" pubspec.yaml
TARGETS=(lib test)
[ -d integration_test ] && TARGETS+=(integration_test)
grep -rlnE "package:(sqflite|path_provider|camera|firebase_storage)[_/]" "${TARGETS[@]}"
rc=$?; [ "$rc" -eq 1 ] && echo "ZERO_IMPORTS" || { echo "UNEXPECTED_IMPORT_OR_ERROR (rc=$rc)"; exit 1; }
tail -n 10 pubspec.lock
```

**預期輸出：**
- `git status` 顯示位於新分支且工作區乾淨。
- `git ls-files --error-unmatch pubspec.lock` exit code `0` 並輸出 `pubspec.lock`（確認受 Git 追蹤，確保 Step 4 `git diff` 與回滾指令有效）。
- `pubspec.yaml` 命中上述 4 行（L35、L37、L42、L53）。
- `lib/`、`test/`（及若存在之 `integration_test/`）對主套件與其平台子套件之 import 檢查精確回傳 exit code `1` 並印出 `ZERO_IMPORTS`。
- `pubspec.lock` 檔尾 `sdks:` 記錄為基線（`dart: ">=3.13.0 <4.0.0"`、`flutter: ">=3.47.0"`）。

- [ ] **Step 2：自 `pubspec.yaml` 移除 4 個零使用直接相依**

刪除 `pubspec.yaml` 中以下 4 行（保留區段註解與相鄰套件，特別保留 `shared_preferences`、`image_picker`、`cloud_firestore` 等既有直接相依）：

```yaml
# Remove these 4 lines:
  sqflite: ^2.3.0 # SQLite 本地資料庫套件
  path_provider: ^2.1.3 # 獲取裝置常用目錄路徑 (如 Documents, Temp)
  camera: ^0.12.0+2 # 相機鏡頭控制與拍照功能
  firebase_storage: ^13.4.5 # Firebase Cloud Storage 檔案儲存
```

- [ ] **Step 3：執行 `flutter pub get` 同步相依鎖定檔與本地插件註冊清單**

```bash
flutter pub get
```

**預期輸出：**
- exit code `0`，輸出 `Got dependencies!`，無 version solving failed 或相容性錯誤。

- [ ] **Step 4：核對 `pubspec.yaml`、`pubspec.lock` 邊界與插件註冊同步（AC-1、AC-2、AC-3）**

```bash
# 4a. Git 追蹤變更與 pubspec.yaml / pubspec.lock 差異摘要
git status --short
git diff pubspec.yaml
git diff pubspec.lock | grep -E '^[+-]  [a-z0-9_]+:|^[+-]    (dependency|version):|^[+-]  (dart|flutter):'

# 4b. 確認 sqflite* / camera* / firebase_storage* 已自 pubspec.lock 徹底移除（grep 必為 exit 1）
grep -nE "^  (sqflite|camera|firebase_storage)(_[a-z0-9_]+)?:" pubspec.lock
rc=$?; [ "$rc" -eq 1 ] && echo "REMOVED_3_PKGS_CLEANLY" || { echo "RESIDUAL_PKG_OR_ERROR (rc=$rc)"; exit 1; }

# 4c. 確認 path_provider 轉為 transitive（不再為 direct main）並印出傳遞依賴鏈
grep -n -A 2 "^  path_provider:" pubspec.lock
flutter pub deps --style=compact | grep -E "path_provider|flutter_facebook_auth|shared_preferences"

# 4d. 斷言 flutter pub get 產出之 4 個插件註冊檔皆存在，且零殘留（grep 精確回傳 exit 1，杜絕 exit 2 假通過）
REG_FILES=(
  ".flutter-plugins-dependencies"
  "android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
  "ios/Runner/GeneratedPluginRegistrant.m"
  "macos/Flutter/GeneratedPluginRegistrant.swift"
)
for rf in "${REG_FILES[@]}"; do
  test -f "$rf" || { echo "MISSING_GENERATED_FILE: $rf"; exit 1; }
done
grep -nE "sqflite|camera_android|camera_avfoundation|camera_web|firebase_storage" "${REG_FILES[@]}"
rc=$?; [ "$rc" -eq 1 ] && echo "REGISTRANTS_CLEAN" || { echo "RESIDUAL_REGISTRANT_OR_ERROR (rc=$rc)"; exit 1; }
```

**可證偽驗收標準（全部成立才進 Step 5）：**
1. **變更檔案受控**：`git status --short` 僅包含 `pubspec.yaml` 與 `pubspec.lock`（無預期外的原生檔或程式碼檔變更）。
2. **`pubspec.yaml` 精準度**：`git diff pubspec.yaml` 僅刪除該 4 行，其他套件與 SDK 約束完全未動。
3. **3 個零傳遞相依套件徹底移除**：Step 4b 印出 `REMOVED_3_PKGS_CLEANLY`（`sqflite*`、`camera*`、`firebase_storage*` 全數自 `pubspec.lock` 移除）。
4. **`path_provider` 轉為 `transitive`**：Step 4c 確認 `path_provider` 之 `dependency:` 由 `"direct main"` 轉為 `transitive`（已知傳遞鏈：`flutter_facebook_auth` → `facebook_auth_desktop` → `flutter_secure_storage` → `flutter_secure_storage_windows` → `path_provider`，以及 `shared_preferences_{linux,windows}` → `path_provider_{linux,windows}`）。
5. **其他直接依賴不變且 `sdks:` 未異常上調**：Step 4a 的 `git diff pubspec.lock` 摘要中，除上述 4 套件及其專屬子套件外，不得有任何其他 `direct main` / `direct dev` 套件的版本升級、降級或增刪，且 `sdks:` 下限不得高於 Step 1 基線（`dart: ">=3.13.0 <4.0.0"`、`flutter: ">=3.47.0"`）。
6. **插件註冊真實來源同步**：Step 4d 確認 `.flutter-plugins-dependencies` 與三平台 `GeneratedPluginRegistrant.*` 均存在且 grep 精確回傳 exit code `1`（印出 `REGISTRANTS_CLEAN`）。

**Step 4 失敗／漂移回滾方式：**
若 `flutter pub get` 失敗，或違反上述任一驗收標準（無關直接依賴被改動、殘留插件註冊、或任一套件實為隱藏必要相依），立即還原並回報中止：

```bash
git checkout -- pubspec.yaml pubspec.lock
flutter pub get
```

- [ ] **Step 5：執行靜態分析與全案回歸測試（AC-4、AC-5）**

```bash
flutter analyze
flutter test
git diff ios/ android/ macos/ lib/ test/
```

**可證偽驗收標準：**
- `flutter analyze` exit code `0`（`No issues found!`）。
- `flutter test` exit code `0`，全案所有測試通過（特別確認 `test/data_layer/menu_vision_repo_test.dart` 與 `test/flow/menu_vision/` 拍照／選圖相關測試皆綠燈）。
- `git diff ios/ android/ macos/ lib/ test/` 為空（確認 `ios/Runner/Info.plist:95` 的 `NSCameraUsageDescription` 與其餘業務／測試檔皆未被改動）。

---

## 4. 可選執行方式（Execution Options）

1. **主進程原地執行（推薦，符合本計畫派發煞車契約）**：確認計畫後進入 STAGE 1 建立 Issue + Worktree，在 STAGE 2 由主進程原地完成 Task 1 全部步驟與驗證。
2. **獨立乾淨 Session 執行**：於 STAGE 1 建好 worktree 後，另開乾淨 session 搭配 `executing-plans` skill 依本計畫逐步驟執行。
