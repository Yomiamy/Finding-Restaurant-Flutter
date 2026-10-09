# 實作計畫：A-9.6 macOS 適配（Menu Vision 相機入口、最小視窗、Google 登入）

- **項目編號**：A-9.6
- **日期**：2026-10-10
- **對應規格**：`docs/features/2026-10-09-a-9-6-macos-adaptation.md`（已確認；D-1 已於規格標為已決）
- **Effort**：0.5d（規格 brainstorm 估 1–1.5d；entitlements 與地圖兩項實查後無工作）
- **工作目錄**：`/Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant`
- **實查基線**：`main` @ `37826b3`
- **已定案（不再討論）**：
  - D-1 (a)：使用者已確認。Release 與 Profile 補 `DEVELOPMENT_TEAM = H2724L9BS5;`，獨立任務、獨立 commit（T1）
  - D-2～D-4：本計畫 §2 選定，理由見該節
  - `keychain-access-groups` 維持條件式：不列任務，只列後備步驟（§7）

> 本文件只談 **How**。What／Why 見規格，不在此重述。

---

## 0. 實作前基線與 sandbox 預演（2026-10-10 實測）

### 0.1 基線

| 指標 | 基線實測值 | 目標值 |
| :--- | :--- | :--- |
| AC-1 `flutter analyze` | `No issues found!` | 同 |
| AC-2 `flutter test` | **All tests passed!（307 passed）** | **312 passed**（新增 5 個 case），0 failed |
| AC-3 `flutter build macos --debug`／`flutter build macos` | debug ✓／**release ✗**（`Signing for "Runner" requires a development team.`，規格 §1.3，同一 HEAD） | 兩者皆 ✓ |
| AC-4 `lib/flow/menu_vision/` 平台判斷行數 | **0** | 0 |
| AC-5 `lib/` 含 `defaultTargetPlatform`／`kIsWeb` 的檔案 | **8 檔**（同規格清單） | 同樣 8 檔 |
| AC-6 macOS `Info.plist` 含 macOS scheme／iOS scheme | 0／0 | ≥ 1／0 |
| `dart format --set-exit-if-changed lib test` | **exit 1：既有 20 檔未格式化**（如 `lib/manager/sign_in_manager.dart`） | 不處理；本項只格式化自己動到的檔案（T6） |
| 工作樹 | 僅 `?? docs/features/2026-10-09-a-9-6-...md` | 只多出本計畫 §3 列出的檔案 |

> ⚠️ **format 範圍陷阱**：A-9.2 計畫的 `dart format lib/ test/` 在這個基線上會順手改掉 20 個無關檔案，違反最小 diff。T6 一律指定檔名。

### 0.2 sandbox 預演（未碰工作樹）

把 `lib/`、`test/`、`macos/` 等複製到 scratchpad 的獨立副本，套用本計畫 §4 的**逐字程式碼**後實跑。工作樹在預演前後皆只有規格檔一個未追蹤變動。

**紅（改動前，T3 新測試直接對現況跑）**：4 個 macOS case 紅、android 對照組綠，失敗原因正是要修的 bug：

| case | 失敗訊息 |
| :--- | :--- |
| 初始畫面 | `Expected: no matching candidates / Actual: Found 1 widget with key [<'take_photo_button'>]` |
| 取消畫面 | `Actual: Found 1 widget with text "拍照"` |
| 失敗畫面 | `Actual: Found 1 widget with text "重新拍攝"` |
| `autoStartCapture: true` | `Unexpected calls: _MockRepo.captureImage()` |

紅燈也證明 autoStart 測試**不是空轉**：測試骨架確實觀察得到 post-frame callback 派發的相機事件。

**綠（套用 T2＋T3 後）**：

- `flutter analyze`：`No issues found!`
- `flutter test`：**312 passed**，0 failed（307＋5）
- 4 個異動 Dart 檔 `dart format --set-exit-if-changed`：0 changed（§4 的程式碼已是 formatter 輸出）
- AC-4 = `0`；AC-5 = 8 檔（集合不變）

**原生（套用 T1＋T4＋T5 後）**：

- `flutter build macos`（release）：`✓ Built build/macos/Build/Products/Release/flutter_restaruant.app (115.9MB)`，exit 0。**D-1 (a) 足以修好 release 基線**
- `flutter build macos --debug`：`✓ Built build/macos/Build/Products/Debug/flutter_restaruant.app`
- 兩個產物的 `codesign -dv` 皆為 `TeamIdentifier=H2724L9BS5`
- 兩個產物的 `Contents/Info.plist` 都帶有 `GIDClientID`（`35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71.apps.googleusercontent.com`）與 scheme `com.googleusercontent.apps.35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71`
- `plutil -lint`、`xmllint --noout` 通過；T5 一致性鎖輸出 `client-ok`、`scheme-ok`；pbxproj 中 `DEVELOPMENT_TEAM = H2724L9BS5;` 共 3 處
- 建置後受版控的 macOS 變動只有計畫中的 4 檔（pbxproj +2、xib 改 2 值、Info.plist +13、Swift +2）。sandbox 另外出現 `macos/Pods/Pods.xcodeproj/project.pbxproj` 的變動，原因是副本路徑改變觸發 `pod install` 重新產生；該目錄在真實 repo 被 `macos/.gitignore:3` 忽略、未追蹤，與本項無關
- 建置輸出中的 `umbrella header for module 'GoogleSignIn'` 警告來自 SwiftPM checkout 的第三方原始碼，與本項改動無關
- **未在 sandbox 驗證**：視窗實際縮放行為與 Google 登入實際流程（屬 §5 人工清單）；Profile 組態沒有建置（不在 AC-3；改動與 Release 相同，同一行、同一個值）

---

## 1. 資料結構

### 1.1 能力矩陣加一欄 `camera`

`platformCapabilities()` 回傳的 record 加一個欄位，值與其他三欄相同（`nativeMobile`）。這是規格 §1.5 決定的唯一事實來源。

```dart
({bool ads, bool pushNotifications, bool mapMode, bool camera})
platformCapabilities({@visibleForTesting bool isWeb = kIsWeb}) {
  ...
  return (
    ads: nativeMobile,
    pushNotifications: nativeMobile,
    mapMode: nativeMobile,
    camera: nativeMobile,
  );
}
```

- **相容性**：5 個呼叫點（`main.dart:32`、`restaurant_detail_page.dart:51`、`drawer_widget.dart:73`、`main_page.dart:46`、`:83`）都是讀欄位（`.ads`／`.mapMode`／`.pushNotifications`），加欄位不影響原始碼相容性。唯一會壞的是以整個 record 比對相等的地方，也就是測試的 `_Data.all`／`_Data.none`（規格 AC-2 允許改這裡）。
- 簽章換行（record 型別獨佔一行）是 `dart format` 的輸出，不要手動調整。

### 1.2 Sheet：一個可為 null 的 callback `_onCamera`

```
platformCapabilities().camera ──(initState 讀一次)──> _onCamera : VoidCallback?
                                                        │
        ┌───────────────┬───────────────┬───────────────┼────────────────────┐
  _SheetHeader     _InitialPromptView  _FailureRetryView  _CancelledView   autoStartCapture
  .onCameraPressed .onCamera          .onRetryCamera     .onCamera        _onCamera?.call()
```

- **閘門只有一個**：`initState` 依能力決定 `_onCamera` 是「派發 camera 事件的閉包」或 `null`。四個入口與 autoStart 都只讀它。macOS 上它是 `null`，五條路徑因此同時關閉。
- **子元件沿用 `_FailureRetryView.onRetryPhoto` 的慣例**（規格 §6.1-4）：欄位型別改為 `VoidCallback?`，再以 collection-if `if (x != null) ...[按鈕, 間距]` 決定是否顯示。間距一起包進去，隱藏後不會留下多餘空白。
- **不新增 helper method、不新增 widget 類別**：顯示判斷寫在既有 4 個私有 widget 的 `build` 內（flutter-styles §7.1）。`_MenuVisionSheetState.build` 只是把 `_onCamera` 傳下去，維持純淨。
- **autoStart 的特殊情況消失**：原本的 `if (autoStartCapture) { add(camera) }` 改成 `if (autoStartCapture) { _onCamera?.call() }`，不需要另加 `&& camera` 判斷。
- **bloc、event、repository 零改動**（規格 §6.1-3）。

---

## 2. 決策（規格 §6.2 D-1～D-4）

### D-1：Release／Profile 補 team（使用者已決 (a)）

- **位置**：只改 **Runner target** 的兩個 configuration，插在 `COMBINE_HIDPI_IMAGES = YES;` 之後，與 Debug（`:721-722`）的排序一致。
  - Profile：`338D0CEA231458BD00FA5F75`（`:579-598`），插在 `:588` 之後
  - Release：`33CC10FD2044A3C60003C045`（`:734-753`），插在 `:743` 之後
- **不動**：project 層級的三個 `CODE_SIGN_IDENTITY = "-"`（`:557`、`:634`、`:690`）。它們已被 target 層級的 `"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development"` 覆寫，改了只會擴大 diff。
- **影響面**：CI 不建置 macOS（`.github/workflows/` 只有 `release.yml` 的 `flutter build ios --no-codesign`、apk、appbundle），所以不會影響 CI。release 產物改以 Apple Development 憑證簽章，不能拿去發布；發布屬 E-9.4b（規格 §6.2）。

### D-2：採 (a) 在 macOS `Info.plist` 加 `GIDClientID`

| 選項 | 評估 |
| :--- | :--- |
| **(a) `Info.plist` 加 `GIDClientID`（🟢 採用）** | 只動 1 個檔（`CFBundleURLTypes` 本來就要改這個檔），是 plugin 原始碼註解中的「recommended method」（規格 §1.2）。不碰 pbxproj，因此與 T1 不會在同一檔案上衝突 |
| (b) 把 `GoogleService-Info.plist` 加進 Resources build phase | 需改 pbxproj 的 4 個區段（`PBXBuildFile`、`PBXFileReference`、group、Resources phase），與 T1 同檔，必須序列執行。另外，打包後其他 Firebase 原生 SDK 是否改變行為也沒有查證（規格 D-2）。`CFBundleURLTypes` 仍要手動同步，沒有省到任何事 |

- **(a) 的代價**：client ID 會同時存在兩個 plist，日後輪替 OAuth client 時可能不同步。**緩解**：T5 驗證以 `plutil` 直接比對兩檔的值（§4 T5），把規格 §5.2「抄錯 client」與日後不同步都變成機械檢查。

### D-3：採修改 `MainMenu.xib` 的初始高度 600 → 640

| 選項 | 評估 |
| :--- | :--- |
| **改 xib（🟢 採用）** | 零行程式碼，只改 2 個屬性值：`contentRect` 的 `height`（`:335`），以及 contentView `frame` 的 `height`（`:338`），讓兩者保持一致，與 Interface Builder 存檔時的寫法相同。寬度維持 800（版面形狀屬 UI-9.3） |
| 在 `awakeFromNib` 以程式碼調整 | 要寫「目前內容區比下限小就放大」，等於新增一個特殊情況分支，還要處理 frame 與 content rect 的換算。比改兩個數字複雜，卻沒有換到任何好處 |

- **最小值放在 Swift、初始值放在 xib**：規格 §4.2 要求最小視窗直接在 Swift 設定。兩處的不變式（初始 ≥ 最小）用 Swift 那行註解互相指涉，並由 AC-11 人工驗收。
- **已知限制**（規格 §5.5）：state restoration 可能以舊尺寸開啟，使用者拖曳一次即自我修正，不處理。

### D-4：採 `initState` 讀一次，存成 `_onCamera`

| 選項 | 評估 |
| :--- | :--- |
| **`initState` 讀一次（🟢 採用）** | autoStart 本來就在 `initState`，第一次 `build` 之前就需要答案。讀一次後存成 `_onCamera`，四個入口與 autoStart 共用同一個值，閘門只有一處。`build` 只傳欄位，符合 flutter-styles「build 純淨」 |
| 在 `build` 讀 | `initState` 仍要為 autoStart 再讀一次，變成兩處閘門；`build` 還得多一個三元式 |

- **測試可覆寫**：測試在 `pumpWidget` 之前設定 `debugDefaultTargetPlatformOverride`，`initState` 在 `pumpWidget` 期間執行，所以讀得到覆寫值。sandbox 紅綠兩階段都已實證（§0.2）。
- **與 A-9.2「不快取」不衝突**：A-9.2 §1.2 禁止的是 `static final` 這種跨測試的全域快取。這裡是每個 `State` 各讀一次，每個測試都會建立新的 `State`。
- **子元件參數保留 `required`，只把型別改成 `VoidCallback?`**：呼叫端仍須明確傳值（傳 `null` 也要寫出來），漏傳會在編譯期被抓到；diff 也只有型別這一處。

### 其他被否決的作法

| 作法 | 否決理由 |
| :--- | :--- |
| 4 個呼叫點各寫 `canCapture ? () => ... : null`，autoStart 再加 `&& canCapture` | 5 處閘門，與 §1.2 的單一閘門相比全是重複 |
| 子元件多傳一個 `bool showCamera` | 同一件事有兩個訊號（bool 與 callback），可能不一致 |
| `_buildCameraButton()` helper | flutter-styles 明文禁止 |
| 測試改用 `TargetPlatformVariant.only(TargetPlatform.macOS)` | 能省掉 try/finally，但規格 AC-9 指定沿用 `platform_capabilities_test.dart` 的寫法，與全專案一致優先 |
| 新測試追加到既有 `menu_vision_sheet_test.dart` | 另開新檔，AC-2「既有測試原樣通過」就能用 `git diff --exit-code` 機械驗證 |

---

## 3. 檔案異動清單（行號皆對照 `37826b3`）

### 3.1 `lib/`（2 檔修改）

| 檔案:行 | 現狀 | 目標 | 任務 |
| :--- | :--- | :--- | :--- |
| `lib/features/utils/platform_capabilities.dart:3-6` | doc 列舉三項能力 | 補「拍照」與 `image_picker_macos` 的成立理由 | T2 |
| `lib/features/utils/platform_capabilities.dart:10-12` | 三欄 record 型別 | 四欄（加 `bool camera`） | T2 |
| `lib/features/utils/platform_capabilities.dart:22` 之後 | — | `camera: nativeMobile,` | T2 |
| `lib/flow/menu_vision/view/menu_vision_sheet.dart:6` 之後 | — | `import '../../../features/utils/utils_barrel.dart';` | T3 |
| `menu_vision_sheet.dart:12` | 類別 doc 一行 | 補兩行，說明拍照入口依能力顯示（AC-10） | T3 |
| `menu_vision_sheet.dart:53` 之後 | — | `late final VoidCallback? _onCamera;` | T3 |
| `menu_vision_sheet.dart:66-70` | 無條件派發 camera | 先指派 `_onCamera`，autoStart 改呼叫 `_onCamera?.call()` | T3 |
| `menu_vision_sheet.dart:91-93`、`:105-107`、`:129-133`、`:141-143` | 4 個 camera 閉包 | 皆改為 `_onCamera` | T3 |
| `menu_vision_sheet.dart:163`、`:238`、`:413`、`:484` | `VoidCallback` | `VoidCallback?` | T3 |
| `menu_vision_sheet.dart:216-220`、`:274-281`、`:463-468`、`:522-527` | 拍照按鈕恆顯示 | collection-if 包住（含其後間距） | T3 |

**零改動（刻意）**：`menu_vision_bloc.dart`、`menu_vision_event.dart`、`menu_vision_repo.dart`、`menu_vision_repository.dart`、`google_sign_in_manager.dart`、`restaurant_detail_page.dart`、`pubspec.*`、`ios/**`、`android/**`、`macos/Runner/*.entitlements`。

### 3.2 `test/`（1 新、1 改）

| 檔案 | 動作 | case 數 | 任務 |
| :--- | :--- | :--- | :--- |
| `test/features/utils/platform_capabilities_test.dart:10-11` | `_Data.all`／`_Data.none` 各加 `camera` 欄，原三欄值不變 | 9（不變） | T2 |
| `test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart` | 新增 | +5 | T3 |

`menu_vision_sheet_test.dart`、`menu_vision_view_characterization_test.dart`、`menu_vision_bloc_test.dart` **一字不動**（AC-2）。

### 3.3 `macos/`（4 檔修改）

| 檔案:行 | 目標 | 任務 |
| :--- | :--- | :--- |
| `macos/Runner.xcodeproj/project.pbxproj:588`、`:743` 之後 | 各 +1 行 `DEVELOPMENT_TEAM = H2724L9BS5;` | T1 |
| `macos/Runner/MainFlutterWindow.swift:9` 之後 | +2 行（註解＋`contentMinSize`） | T4 |
| `macos/Runner/Base.lproj/MainMenu.xib:335`、`:338` | `height="600"` → `height="640"` | T4 |
| `macos/Runner/Info.plist:20`、`:22` 之後 | +11 行 `CFBundleURLTypes`、+2 行 `GIDClientID` | T5 |

---

## 4. 任務拆分

**微任務**的判準：單檔、≤ 20 行，且沒有公共 API 變更（測試檔不計入）。

| 任務 | 標題 | 寫入檔案 | 預估行數 | 公共 API | 微任務 | AC | 可並行 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| T1 | Release／Profile 補 team（D-1，獨立 commit） | `macos/Runner.xcodeproj/project.pbxproj` | +2 | 否 | **是** | AC-3 | 是（線 A） |
| T2 | 能力矩陣加 `camera` | `lib/features/utils/platform_capabilities.dart`、`test/features/utils/platform_capabilities_test.dart` | lib +7／−6；test +12／−2 | **是**（回傳 record 多一欄，原始碼相容） | 否 | AC-8、AC-2 | 是（線 B 起點） |
| T3 | Menu Vision 拍照入口依能力顯示 | `lib/flow/menu_vision/view/menu_vision_sheet.dart`、`test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart`（新） | lib +52／−46（多為重新縮排）；test +141（新檔） | 否（只動私有類別；`MenuVisionSheet` 建構式與 `show` 不變） | 否（> 20 行） | AC-9、AC-10、AC-4、AC-5、AC-2 | 線 B，**依賴 T2** |
| T4 | 最小視窗 360×640＋初始高度 640 | `macos/Runner/MainFlutterWindow.swift`、`macos/Runner/Base.lproj/MainMenu.xib` | +2；改 2 值 | 否 | 否（跨 2 檔，各 ≤ 2 行） | AC-11 | 是（線 C） |
| T5 | Google 登入 client ID 與 URL scheme | `macos/Runner/Info.plist` | +13 | 否 | **是** | AC-6、AC-13 | 是（線 D） |
| T6 | 格式化（限異動檔）＋機械驗收 | 無手寫 diff | — | — | 不適用 | AC-1、2、4、5、6、7 | 匯合後 |
| T7 | macOS 建置（debug＋release） | 無 | — | — | 不適用 | AC-3、AC-6 產物 | 匯合後，與 T6 可並行 |
| T8 | diff 審查 | 無（只讀） | — | — | 不適用 | AC-7、AC-10 | 最後 |

### T1：Release／Profile 補 `DEVELOPMENT_TEAM`（D-1，獨立 commit）

- **檔案**：`macos/Runner.xcodeproj/project.pbxproj`
- **微任務**：是（+2 行，單檔，無 API）
- **前置**：無。**建議最先做**：在其餘檔案都還沒改的工作樹上驗 release 建置，可以單獨證明 D-1 本身就修好了基線。
- **步驟 1｜先確認紅**：基線 `flutter build macos` 失敗（規格 §1.3 已實測，同一 HEAD）。不必重跑。
- **步驟 2｜實作**：在兩個 Runner target configuration 的 `COMBINE_HIDPI_IMAGES = YES;` 之後各插入一行（tab 縮排 4 格，與 `:722` 相同）：

```
				DEVELOPMENT_TEAM = H2724L9BS5;
```

  - Profile 區塊 `338D0CEA231458BD00FA5F75 /* Profile */`：`:588` 之後
  - Release 區塊 `33CC10FD2044A3C60003C045 /* Release */`：`:743` 之後（先插 Profile 的話，這裡會變成 `:744`）
  - Debug 區塊 `33CC10FC2044A3C60003C045` 已有（`:722`），**不要重複**

- **驗證**：

```bash
# 只動 1 檔、恰好 2 行新增
git diff --numstat -- macos/Runner.xcodeproj/project.pbxproj     # 預期：2	0	...
rtk proxy grep -c "DEVELOPMENT_TEAM = H2724L9BS5;" macos/Runner.xcodeproj/project.pbxproj   # 預期：3

# AC-3 release 半：預期 ✓ Built build/macos/Build/Products/Release/flutter_restaruant.app
flutter build macos
codesign -dv build/macos/Build/Products/Release/flutter_restaruant.app 2>&1 | grep TeamIdentifier   # 預期：TeamIdentifier=H2724L9BS5

# 建置不得改動受版控檔案：預期只列出 pbxproj（與規格檔、計畫檔）
rtk git status --short
```

- **commit 邊界**：本任務單獨一個 commit。建議訊息沿用 `9ec1f48` 的風格：`build(macos): set development team for Release and Profile`。是否 commit、何時 commit，依執行階段使用者的授權。
- **對應 AC**：AC-3（release）

### T2：能力矩陣加 `camera`（AC-8）

- **檔案**：
  - `test/features/utils/platform_capabilities_test.dart`（改 `_Data`）
  - `lib/features/utils/platform_capabilities.dart`
- **微任務**：否（公共函式的回傳型別多一欄）
- **前置**：無
- **步驟 1｜先改測試（紅）**：只改 `:10-11` 兩個常數，`rows` 與測試本體一字不動。原三欄的值不得改變（AC-2）。

```dart
  static const all = (
    ads: true,
    pushNotifications: true,
    mapMode: true,
    camera: true,
  );
  static const none = (
    ads: false,
    pushNotifications: false,
    mapMode: false,
    camera: false,
  );
```

- **驗證紅**：`rtk flutter test test/features/utils/platform_capabilities_test.dart`。預期 9 failed（三欄 record 與四欄 record 不相等）。
- **步驟 2｜實作**：`platform_capabilities.dart` 改為下列內容（`:13-18` 的本體不動）：

```dart
/// 平台能力閘門：回答「此平台有沒有廣告／推播／地圖模式／拍照」的唯一一處。
///
/// 四項目前同為「原生 Android 或原生 iOS」，但成立理由不同（AdMob 套件只支援
/// android／ios；D-9.7 macOS 不做推播；Web 地圖待 E-9.3 的 Maps JS API key；
/// `image_picker_macos` 未設 `cameraDelegate` 時拍照會拋 `StateError`）。
/// 呼叫點只讀能力名稱、不讀平台名稱，日後翻轉某一項只改這裡。
///
/// [isWeb] 僅供測試注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false。
({bool ads, bool pushNotifications, bool mapMode, bool camera})
platformCapabilities({@visibleForTesting bool isWeb = kIsWeb}) {
  // ……:13-18 原樣……
  return (
    ads: nativeMobile,
    pushNotifications: nativeMobile,
    mapMode: nativeMobile,
    camera: nativeMobile,
  );
}
```

- **驗證綠**：同一指令，9 passed。再跑 `rtk flutter analyze`，確認 5 個既有呼叫點不受影響，預期 `No issues found!`。
- **對應 AC**：AC-8（android／iOS `true`；macOS、windows、linux、fuchsia 與 3 個 Web 列 `false`）、AC-2（只新增欄位）

### T3：Menu Vision 拍照入口依能力顯示（AC-9、AC-10）

- **檔案**：
  - `test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart`（新）
  - `lib/flow/menu_vision/view/menu_vision_sheet.dart`
- **微任務**：否（lib 約 +52／−46，主要是 collection-if 帶來的重新縮排）
- **前置**：T2（讀 `platformCapabilities().camera`）
- **步驟 1｜先寫測試（紅；sandbox 已實證會紅在正確原因，見 §0.2）**：
  - 測試資料放 `_Data`（flutter-styles §8.2）
  - mock 與 `addTearDown(bloc.close)` 沿用 `menu_vision_view_characterization_test.dart:12,29` 的慣例
  - 等待 bloc 用 `runAsync` 延遲 50ms，沿用既有 Menu Vision 測試的寫法
  - 平台覆寫用 try/finally，沿用 `platform_capabilities_test.dart:30-35`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// 鎖住 A-9.6 AC-9：無相機能力的平台（macOS）不出現任何拍照入口、
/// 也不自動觸發相機；android 對照組確認行動版取消畫面的拍照入口仍在。
class _MockRepo extends Mock implements MenuVisionRepository {}

class _Data {
  static final pickFailure = Exception('mock gallery failure');
}

Future<void> _pumpSheet(
  WidgetTester tester,
  MenuVisionRepository repo, {
  bool autoStartCapture = false,
}) async {
  final bloc = MenuVisionBloc(repository: repo);
  // 不可在測試本體 await close()：fake async 下會卡住（A-9.2 計畫 §0）。
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MenuVisionSheet(bloc: bloc, autoStartCapture: autoStartCapture),
      ),
    ),
  );
}

/// 讓 bloc 的非同步 handler 跑完（沿用既有 Menu Vision 測試的 runAsync 寫法）。
Future<void> _settleBloc(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

Future<void> _tapGallery(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('gallery_pick_button')));
  await _settleBloc(tester);
}

void main() {
  setUpAll(() async {
    await S.load(const Locale('zh', 'TW'));
  });

  group('macOS 無相機能力', () {
    testWidgets('初始畫面與標題列：無拍照入口，相簿與關閉仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pumpSheet(tester, _MockRepo());

        expect(find.byKey(const Key('take_photo_button')), findsNothing);
        expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('取消畫面：無拍照按鈕，相簿按鈕仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.pickImageFromGallery()).thenAnswer((_) async => null);
        await _pumpSheet(tester, repo);
        await _tapGallery(tester);

        expect(
          find.text(S.current.menu_vision_cancelled_title),
          findsOneWidget,
        );
        expect(
          find.text(S.current.menu_vision_btn_take_photo_short),
          findsNothing,
        );
        expect(
          find.text(S.current.menu_vision_btn_gallery_short),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('失敗畫面：無「重新拍攝」，「相簿重選」仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.pickImageFromGallery()).thenThrow(_Data.pickFailure);
        await _pumpSheet(tester, repo);
        await _tapGallery(tester);

        expect(find.text(S.current.menu_vision_failure_title), findsOneWidget);
        expect(find.text(S.current.menu_vision_btn_retake), findsNothing);
        expect(
          find.text(S.current.menu_vision_btn_reselect_gallery),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('autoStartCapture: true 不觸發相機', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.captureImage()).thenAnswer((_) async => null);
        await _pumpSheet(tester, repo, autoStartCapture: true);
        await _settleBloc(tester);

        verifyNever(() => repo.captureImage());
        expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('android 對照組：取消畫面仍有拍照與相簿按鈕', (tester) async {
    final repo = _MockRepo();
    when(() => repo.pickImageFromGallery()).thenAnswer((_) async => null);
    await _pumpSheet(tester, repo);
    await _tapGallery(tester);

    expect(find.text(S.current.menu_vision_cancelled_title), findsOneWidget);
    expect(
      find.text(S.current.menu_vision_btn_take_photo_short),
      findsOneWidget,
    );
    expect(find.text(S.current.menu_vision_btn_gallery_short), findsOneWidget);
  });
}
```

> 設計註記：
> - 失敗畫面用相簿路徑讓 `pickImageFromGallery` 拋 `Exception`，所以 `failedImageBytes` 為 `null`，「重試此照片」不會出現。斷言只看「重新拍攝」與「相簿重選」，不受影響。
> - autoStart case 有先 stub `captureImage`：紅燈時才會停在乾淨的 `Unexpected calls`，不會變成 mocktail 未 stub 的 `TypeError`。

- **驗證紅**：`rtk flutter test test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart`。預期 1 passed、4 failed，失敗訊息同 §0.2 表格。
- **步驟 2｜實作**：`menu_vision_sheet.dart` 依序修改下列 9 處。

1. **import**：`:6` 之後插入（字母序位於 `domain` 與 `generated` 之間；與 `restaurant_detail_page.dart:9` 等 10 個 `lib/flow` 檔案相同路徑）：

```dart
import '../../../features/utils/utils_barrel.dart';
```

2. **類別 doc（AC-10）**：`:12` 改為：

```dart
/// AI 拍菜單翻譯與過敏原拆解 Sheet
///
/// 拍照入口（標題列、初始／失敗／取消畫面與 [autoStartCapture]）只在具相機
/// 能力的平台出現（見 [platformCapabilities]）；其餘平台只提供相簿選圖。
```

3. **欄位**：`:53` `late final bool _isLocalBloc;` 之後加：

```dart
  late final VoidCallback? _onCamera;
```

4. **`initState` `:66-70`** 改為：

```dart
    // 無相機能力的平台（如 macOS）為 null：四個拍照入口與自動拍照一併消失。
    _onCamera = platformCapabilities().camera
        ? () =>
              _bloc.add(const CaptureAndAnalyzeMenu(source: ImageSource.camera))
        : null;

    if (widget.autoStartCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onCamera?.call());
    }
```

5. **`build` 的 4 個 camera 閉包**，皆改為傳 `_onCamera`（gallery 閉包一字不動）：
   - `:91-93` → `onCameraPressed: _onCamera,`
   - `:105-107` → `onCamera: _onCamera,`
   - `:129-133` → `onRetryCamera: _onCamera,`
   - `:141-143` → `onCamera: _onCamera,`

6. **`_SheetHeader`**：`:163` 改為 `final VoidCallback? onCameraPressed;`。`:216-220` 改為：

```dart
          if (onCameraPressed != null)
            IconButton(
              tooltip: S.current.menu_vision_tooltip_camera,
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: onCameraPressed,
            ),
```

7. **`_InitialPromptView`**：`:238` 改為 `final VoidCallback? onCamera;`。`:274-281` 改為：

```dart
            if (onCamera != null) ...[
              FilledButton.icon(
                key: const Key('take_photo_button'),
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text(S.current.menu_vision_btn_camera),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              ),
              const SizedBox(height: 12),
            ],
```

8. **`_FailureRetryView`**：`:413` 改為 `final VoidCallback? onRetryCamera;`。`:463-468` 改為：

```dart
                if (onRetryCamera != null) ...[
                  OutlinedButton.icon(
                    onPressed: onRetryCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(S.current.menu_vision_btn_retake),
                  ),
                  const SizedBox(width: 12),
                ],
```

9. **`_CancelledView`**：`:484` 改為 `final VoidCallback? onCamera;`。`:522-527` 改為：

```dart
                if (onCamera != null) ...[
                  FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(S.current.menu_vision_btn_take_photo_short),
                  ),
                  const SizedBox(width: 12),
                ],
```

  4 個子元件的建構式**不改**：參數仍是 `required this.xxx`，只有欄位型別變成可為 null。

- **驗證綠**：

```bash
rtk flutter test test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart   # 5 passed
rtk flutter test test/flow/menu_vision/                                              # 既有 3 檔＋新檔全綠
rtk flutter analyze                                                                   # No issues found!
```

- **對應 AC**：AC-9（4 個 macOS case＋android 對照組）、AC-10（類別 doc）、AC-4（sheet 不讀平台名稱）、AC-2（既有 Menu Vision 測試原樣通過）

### T4：最小視窗 360×640＋初始高度 640（AC-11）

- **檔案**：
  - `macos/Runner/MainFlutterWindow.swift`
  - `macos/Runner/Base.lproj/MainMenu.xib`
- **微任務**：否（跨 2 檔；各 ≤ 2 行，無 API）
- **前置**：無
- **步驟 1｜測試**：**不適用**。規格 §3.2 已決定不寫 XCTest，由 AC-11 人工確認；編譯正確性由建置驗證。
- **步驟 2｜實作**：
  - `MainFlutterWindow.swift:9` `self.setFrame(windowFrame, display: true)` 之後插入下列兩行。放在 `setFrame` 之後，表示「內容 VC 掛好、frame 復原之後」由這一行做最後決定：

```swift
    // 內容區下限 360×640（行動版設計基準，A-9.6）；MainMenu.xib 的初始尺寸不得小於此值。
    self.contentMinSize = NSSize(width: 360, height: 640)
```

  - `MainMenu.xib:335`：`<rect key="contentRect" x="335" y="390" width="800" height="600"/>` → `height="640"`
  - `MainMenu.xib:338`：`<rect key="frame" x="0.0" y="0.0" width="800" height="600"/>` → `height="640"`
  - 用一般文字編輯修改這兩個屬性值即可，**不要**用 Xcode Interface Builder 開檔存檔，否則可能被重寫成新版 xib 格式而擴大 diff
- **驗證**：

```bash
xmllint --noout macos/Runner/Base.lproj/MainMenu.xib && echo xml-ok
rtk proxy grep -c 'height="640"' macos/Runner/Base.lproj/MainMenu.xib    # 預期 2
rtk proxy grep -c 'height="600"' macos/Runner/Base.lproj/MainMenu.xib    # 預期 0
flutter build macos --debug    # xib 編譯與 Swift 編譯一併驗證；預期 ✓ Built .../Debug/flutter_restaruant.app
```

- **對應 AC**：AC-11（實際行為由 §5 人工清單驗）

### T5：Google 登入 client ID 與 URL scheme（AC-6）

- **檔案**：`macos/Runner/Info.plist`
- **微任務**：是（+13 行，單檔，無 API）
- **前置**：無
- **步驟 1｜先確認紅**：AC-6 第一行基線為 `0`（§0.1）。
- **步驟 2｜實作**：兩段都依 key 的字母序插入，值**一律**取自 `macos/Runner/GoogleService-Info.plist` 的 `CLIENT_ID`／`REVERSED_CLIENT_ID`，**不得**取自 `ios/Runner/Info.plist`（規格 §5.2）。
  - `:20` `<string>$(FLUTTER_BUILD_NAME)</string>` 之後（`CFBundleShortVersionString` 與 `CFBundleVersion` 之間）插入：

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.googleusercontent.apps.35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71</string>
			</array>
		</dict>
	</array>
```

  - `:22` `<string>$(FLUTTER_BUILD_NUMBER)</string>` 之後（`CFBundleVersion` 與 `LSMinimumSystemVersion` 之間）插入：

```xml
	<key>GIDClientID</key>
	<string>35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71.apps.googleusercontent.com</string>
```

  - Facebook 的 `fb...` scheme **不加**（Facebook 登入屬 E-9.4a，規格 §4.2）
- **驗證**：

```bash
plutil -lint macos/Runner/Info.plist                                                     # OK

# AC-6
grep -c "com.googleusercontent.apps.35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71" macos/Runner/Info.plist   # ≥ 1
grep -c "8bh7hq1e07129nav2gcme5n9p565su7k" macos/Runner/Info.plist                                          # 0
plutil -extract GIDClientID raw macos/Runner/Info.plist   # 35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71.apps.googleusercontent.com

# D-2 一致性鎖：兩個值必須與 macOS 的 GoogleService-Info.plist 逐字相同
test "$(plutil -extract GIDClientID raw macos/Runner/Info.plist)" = "$(plutil -extract CLIENT_ID raw macos/Runner/GoogleService-Info.plist)" && echo client-ok
test "$(plutil -extract CFBundleURLTypes.0.CFBundleURLSchemes.0 raw macos/Runner/Info.plist)" = "$(plutil -extract REVERSED_CLIENT_ID raw macos/Runner/GoogleService-Info.plist)" && echo scheme-ok
```

- **對應 AC**：AC-6；AC-13 的前置條件（實際登入由 §5 人工清單驗）

### T6：格式化（限異動檔）＋機械驗收（AC-1、2、4、5、6、7）

```bash
# 格式化：只列本項動到的 4 個 Dart 檔（基線另有 20 檔未格式化，不得順手改）
dart format \
  lib/features/utils/platform_capabilities.dart \
  lib/flow/menu_vision/view/menu_vision_sheet.dart \
  test/features/utils/platform_capabilities_test.dart \
  test/flow/menu_vision/menu_vision_sheet_camera_capability_test.dart
# 預期：0 changed（§4 的程式碼已是 formatter 輸出）；有變動代表手抄偏離，以 formatter 結果為準

# AC-1：No issues found!
flutter analyze

# AC-2：All tests passed!，312 passed（基線 307 + 5），0 failed
flutter test

# AC-2「原樣」：三個既有 Menu Vision 測試檔零 diff —— 預期 exit 0、無輸出
git diff --exit-code main -- \
  test/flow/menu_vision/menu_vision_sheet_test.dart \
  test/flow/menu_vision/menu_vision_view_characterization_test.dart \
  test/flow/menu_vision/menu_vision_bloc_test.dart

# AC-2「只新增欄位」：platform_capabilities_test.dart 的 - 行只能是 :10-11 兩個舊常數
git diff main -- test/features/utils/platform_capabilities_test.dart

# AC-4：預期 0
grep -rn -e "defaultTargetPlatform" -e "kIsWeb" -e "TargetPlatform\." lib/flow/menu_vision/ | wc -l

# AC-5：預期與基線相同的 8 檔
grep -rln --include="*.dart" -e "defaultTargetPlatform" -e "kIsWeb" lib/ | sort

# AC-6：見 T5 驗證區塊

# AC-7：預期無輸出
git diff --stat main -- ios/ android/ lib/manager/google_sign_in_manager.dart
```

- AC-4、AC-5 的輸出是下判斷用的證據。依 `.claude/rules/rtk-rules.md`，用原生 `grep` 或 `rtk proxy grep`，**不要**用 `rtk grep`。
- 任何既有測試轉紅都是 regression：回頭修程式碼，**不准改測試期望值**。

### T7：macOS 建置（AC-3）

兩個建置共用 `build/macos`，**必須序列執行**。

```bash
flutter build macos --debug   # ✓ Built build/macos/Build/Products/Debug/flutter_restaruant.app
flutter build macos           # ✓ Built build/macos/Build/Products/Release/flutter_restaruant.app

# 簽章：兩者都應為 team 簽章
codesign -dv build/macos/Build/Products/Debug/flutter_restaruant.app 2>&1 | grep TeamIdentifier     # H2724L9BS5
codesign -dv build/macos/Build/Products/Release/flutter_restaruant.app 2>&1 | grep TeamIdentifier   # H2724L9BS5

# 產物確實帶到 T5 的設定（Info.plist 會經建置展開變數後複製）
plutil -extract GIDClientID raw build/macos/Build/Products/Debug/flutter_restaruant.app/Contents/Info.plist
plutil -extract CFBundleURLTypes.0.CFBundleURLSchemes.0 raw build/macos/Build/Products/Debug/flutter_restaruant.app/Contents/Info.plist

# 建置後工作樹：只列出 §3 的檔案（build/ 已被 gitignore）
rtk git status --short
```

- **例外處理**（規格 AC-3）：若失敗，先在未改動的基線重現（另開 worktree；`git stash` 需先徵得使用者同意）。基線同樣失敗則不計入本項，於 PR 註明。

### T8：diff 審查（AC-7、AC-10）

- `rtk git diff main`（只讀）：
  - `menu_vision_sheet.dart` 類別 doc 已補（AC-10）
  - gallery 閉包、`_CatalogContentView`、`_LoadingProgressView` 一字未動
  - `project.pbxproj` 只有 2 行新增，而且都在 Runner target 的 Profile／Release 區塊
  - `Info.plist` 沒有任何 `8bh7hq1e` 字串；也沒有 `fb` scheme
  - `pubspec.*`、`*.entitlements` 不在 diff 中
- 僅檢視，**不執行任何 git 寫入操作**。

---

## 5. STAGE 3 前的人工驗收清單（不偽裝成自動測試）

一律在 Debug（team 簽章）下執行：`flutter run -d macos`。console 輸出建議另存到 scratchpad，方便搜尋關鍵字。

### AC-11 視窗

- [ ] **首次啟動**：內容區不小於 360×640（xib 初始為 800×640）
  - 前提：若系統設定「結束 App 時關閉視窗」為關閉，或上次是異常結束，AppKit 可能以舊尺寸還原（規格 §5.5）。要驗「首次啟動」，請先確認不是還原出來的視窗
  - 輔助量測（選用，終端機需有「輔助使用」權限）：`osascript -e 'tell application "System Events" to get size of window 1 of process "flutter_restaruant"'`。這個值包含標題列，內容區高度 = 該值 − 標題列高度
- [ ] **往內拖曳**：寬度停在 360、內容區高度停在 640，無法再縮小
- [ ] 在最小尺寸下逐頁瀏覽，console 不出現 `A RenderFlex overflowed`：登入頁、主頁列表、Drawer、詳情頁、Menu Vision（初始、取消、失敗三個畫面）
- [ ] 若出現 overflow：先在 360×640 的 Android 模擬器重現。能重現就是既有的行動版 bug，另開 issue，不擋本項；只在 macOS 出現則必須修

### AC-12 Menu Vision

- [ ] 從詳情頁開啟：標題列只有相簿與關閉，初始畫面只有「從相簿選擇照片」
- [ ] 選一張圖：畫面離開 Loading，進入成功或失敗畫面（AI 是否成功取決於 App Check debug token，不在本項）
- [ ] 失敗畫面沒有「重新拍攝」
- [ ] 在檔案視窗按取消：進入取消畫面，而且沒有「拍照」按鈕

### AC-13 Google 登入

- [ ] 點 Google 登入，出現 Google 授權頁；完成後回到 App 並進入主頁
- [ ] 中途取消：回到登入頁，App 不崩潰
- [ ] console 不出現 `No active configuration`、`missing support for the following URL schemes`、`keychain error`
  - 出現 `keychain error`：執行 §7 後備步驟
  - 出現 `invalid_client` 或 bundle 不符：依規格 §4.4 檢查 GCP Console
- [ ] 記錄實測結果（尤其是有沒有用到 §7），供規格 §7-1 更新 brainstorm

### AC-14 地圖回歸（零改動）

- [ ] 詳情頁顯示靜態地圖；點擊後在 action sheet 選導航，預設瀏覽器開啟 `maps.google.de`

### AC-10 註解

- [ ] `MenuVisionSheet` 類別 doc 已註明拍照入口依平台能力顯示（T8 已審）

### AC-15 行動版（建議，非必要）

- [ ] 真機確認 Menu Vision 拍照（4 個入口）與 Google 登入如常

---

## 6. 任務相依與並行

```
 線 A：T1 (pbxproj)                     ─┐
 線 B：T2 (能力欄位) → T3 (sheet＋測試)  ─┼─→ T6 (format＋analyze＋test＋grep) ─┐
 線 C：T4 (Swift＋xib)                   ─┤                                    ├─→ T8 (diff 審查) ─→ §5 人工清單
 線 D：T5 (Info.plist)                   ─┘─→ T7 (build debug → release)      ─┘
```

| 關係 | 說明 |
| :--- | :--- |
| A／B／C／D 四條線可並行**編輯** | 寫入檔案完全不重疊：pbxproj｜2 個 Dart＋2 個測試｜Swift＋xib｜Info.plist |
| T2 → T3 序列 | T3 讀 `camera` 欄位 |
| `flutter build macos` 一律序列 | T1、T4 的驗證與 T7 共用 `build/macos`。flutter tool 本身也有全域啟動鎖，平行執行只會互相等待 |
| T6 與 T7 可並行 | 一個只跑 Dart 工具鏈，一個只跑 Xcode 建置；但兩者都會等 flutter 啟動鎖，實際收益有限 |
| T1 建議最先做 | 在其餘檔案未動時驗 release，可單獨證明 D-1 修好基線 |

### commit 邊界（建議；實際 commit 依使用者授權）

| commit | 內容 | 建議訊息 |
| :--- | :--- | :--- |
| C1 | T1 | `build(macos): set development team for Release and Profile` |
| C2 | T2＋T3 | `feat(menu-vision): hide camera entries on platforms without camera capability` |
| C3 | T4 | `feat(macos): enforce 360x640 minimum window content size` |
| C4 | T5 | `fix(macos): configure Google Sign-In client ID and URL scheme` |
| C0／C5 | 規格與計畫文件 | `docs: add A-9.6 macOS adaptation spec and plan` |

每個 commit 都能獨立 revert；C1 依使用者決策必須獨立。

---

## 7. 條件式後備：`keychain-access-groups`（**不是任務**）

- **觸發條件**：只有 AC-13 的 console 出現 GIDSignIn `keychain error`（`Code=-2`）時才執行。沒出現就不做，並在 PR 註明「Team 簽章即足夠」（規格 §4.3、§7-1）。
- **步驟**：
  1. 只改 `macos/Runner/RunnerDebug.entitlements`（Debug 用；規格 §4.3 已更新：只加到 AC-13 實測的組態），在 `<dict>` 內依字母序加入：

```xml
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)com.google.GIDSignIn</string>
	</array>
```

  2. `plutil -lint macos/Runner/RunnerDebug.entitlements`
  3. `flutter run -d macos` 重跑 AC-13 全部項目
  4. 獨立 commit：`fix(macos): add GIDSignIn keychain access group for debug`
- **不做**：`Release.entitlements`、`DebugProfile.entitlements`（本項不驗 release 登入，留給 E-9.4a）

---

## 8. AC 對照表

| AC | 任務 | 驗證方式 |
| :--- | :--- | :--- |
| AC-1 analyze | T2、T3、T6 | `No issues found!` |
| AC-2 測試全綠、既有期望值不變 | T2、T3、T6 | 312 passed／0 failed；3 個既有 Menu Vision 測試檔 `git diff --exit-code` 為 0；`platform_capabilities_test.dart` 只改 `:10-11` |
| AC-3 建置 | T1、T4、T7 | debug 與 release 皆 `✓ Built`；兩者 `TeamIdentifier=H2724L9BS5` |
| AC-4 menu_vision 不判平台 | T3、T6 | grep → `0` |
| AC-5 平台判斷檔案集合不變 | T6 | 同基線 8 檔 |
| AC-6 macOS client／無 iOS client | T5、T7 | grep ≥ 1／0；`GIDClientID` 正確；與 `GoogleService-Info.plist` 一致性鎖；產物 Info.plist 帶到 |
| AC-7 行動版原生與 Dart 登入呼叫不動 | T6、T8 | `git diff --stat` 無輸出 |
| AC-8 能力矩陣 `camera` | T2 | `platform_capabilities_test.dart` 9 passed |
| AC-9 Sheet macOS／android | T3 | 新測試檔 5 passed |
| AC-10 註解同步 | T3、T8 | 類別 doc 補兩行 |
| AC-11 視窗 | T4、§5 | 人工 |
| AC-12 Menu Vision 實機 | §5 | 人工 |
| AC-13 Google 登入實機 | T5、§5、（§7） | 人工 |
| AC-14 地圖回歸 | §5 | 人工 |
| AC-15 行動版實機 | §5 | 人工（建議） |

---

## 9. 破壞性分析（Never break userspace）

### 9.1 行動版（Android／iOS）：零行為變化

| 面向 | 行動版下的值 | 等價性 |
| :--- | :--- | :--- |
| `camera` 能力 | `true` | `_onCamera` 就是原本的閉包，派發同一個 `CaptureAndAnalyzeMenu(source: camera)` |
| 4 個拍照入口 | `_onCamera != null` | collection-if 成立，按鈕、key、間距、順序都與原本相同。既有 `take_photo_button` 測試 3 個原樣通過，新 android 對照組補上取消畫面的驗證 |
| autoStart | `_onCamera?.call()` | 與原本的 `_bloc.add(camera)` 同一個 post-frame 時機、同一個事件 |
| 原生設定 | — | `ios/`、`android/` 零 diff（AC-7） |

### 9.2 既有測試：不需修改期望值

| 測試 | 與本項的關係 | 是否需改 |
| :--- | :--- | :--- |
| `test/features/utils/platform_capabilities_test.dart` | record 多一欄 | **只改 `_Data.all`／`_Data.none`**（規格 AC-2 唯一允許處） |
| `test/flow/menu_vision/menu_vision_sheet_test.dart` | 預設平台 android，入口全在 | ❌ |
| `test/flow/menu_vision/menu_vision_view_characterization_test.dart` | 經 `take_photo_button` 進入，android 下仍在 | ❌ |
| `test/flow/menu_vision/menu_vision_bloc_test.dart` | bloc 零改動 | ❌ |
| `drawer_widget_test.dart`、`main_page_test.dart`、`app_check_provider_test.dart` | 只讀既有三欄 | ❌ |

### 9.3 刻意的行為變更

- **macOS**：Menu Vision 只剩相簿入口；視窗內容區下限 360×640，初始高度 640；Google 登入可完成。
- **macOS release／profile 建置**：從「無法建置」變成以 Apple Development 憑證簽章（D-1）。
- **Web**（尚無 target）：`camera` 為 `false`，日後開放只改 `platformCapabilities()` 一處。

### 9.4 剩餘風險

| 風險 | 緩解 |
| :--- | :--- |
| 日後有人把 iOS 的 scheme 抄進 macOS | T5 的一致性鎖與 AC-6 第二行 |
| OAuth client 輪替時，兩個 plist 不同步 | 同上，一致性鎖會失敗 |
| `contentMinSize` 與 xib 初始尺寸日後被分開修改 | Swift 那行註解互相指涉；AC-11 |
| GIDSignIn 需要 keychain access group | §7 後備步驟 |
| 有人日後把 `MenuVisionSheet` 子元件改成不分平台顯示 | 新測試的 4 個 macOS case |

---

## 10. 明確不做（守住範圍）

| 不做 | 依據 |
| :--- | :--- |
| 在 bloc 補 `catch StateError`；改 `CaptureAndAnalyzeMenu` 預設 source | 規格 §4.2 |
| 刪除 `autoStartCapture` 死碼 | 規格 §4.2、§7-3，另案 |
| macOS 文案「相簿」改「檔案」、相簿按鈕升格為主要按鈕 | 規格 §4.2 |
| `window_manager`、MapKit 等新相依 | 規格 §4.2、§6.1-6 |
| `GoogleService-Info.plist` 打包進 Resources（D-2 (b)） | §2 D-2 |
| Facebook `fb` scheme、Apple 登入 capability | E-9.4a |
| `keychain-access-groups`（未觸發時） | §7 條件式 |
| 格式化 `lib/`、`test/` 其他 20 個既有未格式化檔案 | §0.1；最小 diff |
| Release／Profile 的正式發布簽章（Developer ID 等） | E-9.4b |
| 任何 git 寫入（add／commit／push／stash） | 本階段僅規劃；commit 依 §6 邊界、待使用者授權 |

---

## 11. 執行方式選項

| 方式 | 做法 | Trade-off |
| :--- | :--- | :--- |
| **A. Subagent-driven（🟢 建議）** | 派 1 個 implementer subagent 依 T1 → T2 → T3 → T4 → T5 → T6 → T7 執行並回報；由 caller 做 T8 與 §5 人工清單的協調 | 手寫 diff 很小：lib 約 60 行，原生約 19 行，測試約 155 行（大多已在本計畫逐字列出）。單一 implementer 序列執行，協調成本最低。實作與驗收分離，避免自己驗自己的盲點 |
| B. Parallel session | T1／(T2→T3)／T4／T5 各開一個 session，匯合後跑 T6–T8 | 檔案確實互不重疊，技術上可行。但每條線只有 2–13 行原生改動，而且 T1、T4、T7 的 `flutter build macos` 必須序列（共用 `build/macos` 與 flutter 啟動鎖），平行省下的時間會被等待吃掉。§5 人工驗收也只能在同一台機器上做。不建議 |
| C. 單一 session 循序 | 在目前 session 依序做完 T1–T8 | 最省 context；但實作與驗收沒有分離 |

**建議**：採 **A**。規格 §8 原本建議「三組任務依序」，A 涵蓋這個安排，並把 D-1 獨立成 T1 先行。

---

## 12. 完成定義（DoD）

- [ ] T1–T5 完成。異動恰為 §3：`lib/` 2 檔、`test/` 1 新 1 改、`macos/` 4 檔
- [ ] AC-1 `No issues found!`
- [ ] AC-2 312 passed、0 failed；3 個既有 Menu Vision 測試檔零 diff；`platform_capabilities_test.dart` 只改 `_Data`
- [ ] AC-3 debug 與 release 都 `✓ Built`，`TeamIdentifier=H2724L9BS5`
- [ ] AC-4 = `0`；AC-5 = 同基線 8 檔
- [ ] AC-6 ≥ 1／0；`GIDClientID` 正確；一致性鎖輸出 `client-ok`、`scheme-ok`
- [ ] AC-7 無輸出
- [ ] AC-8 9 passed；AC-9 5 passed
- [ ] AC-10 類別 doc 已補
- [ ] 4 個異動 Dart 檔 `dart format --output=none --set-exit-if-changed` exit 0
- [ ] §5 人工清單（AC-11～AC-14）全部打勾；§7 是否觸發已記錄
