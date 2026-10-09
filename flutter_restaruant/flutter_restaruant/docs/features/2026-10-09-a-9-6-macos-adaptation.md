# 功能規格：A-9.6 macOS 適配（Menu Vision 相機入口、最小視窗、Google 登入）

- **項目編號**：A-9.6（沿用 `docs/brainstorm/2026-10-09-features-brainstorm.md` §9.6 編號）
- **日期**：2026-10-09
- **Effort（brainstorm 估計）**：1–1.5d。brainstorm A-9.6 列的四個子項中，entitlements 與地圖兩項實查後已無工作（§1.4），預期低於原估
- **依賴**：A-9.2（已合併，`37826b3`）：`lib/features/utils/platform_capabilities.dart` 的 `platformCapabilities()`
- **相關脈絡**：§9.4.3「Menu Vision」「視窗」兩列、§9.6 A-9.6 列、§9.9 排除 MapKit／`window_manager`、D-9.2、D-9.8
- **實查基線**：`main` @ `37826b3`（含 `9ec1f48`：macOS Runner 改用 Apple Development team 簽章）

---

## 1. 問題陳述與影響 (What & Why)

### 1.1 核心問題：A-9.2 之後，macOS 上仍有三處直接壞掉

A-9.2 解決了啟動期的問題（AdMob、FCM、地圖模式、App Check），但使用者實際操作時還會碰到三個壞掉的點：

| # | 觸發場景 | 位置 | 在 macOS 的後果 |
| :--- | :--- | :--- | :--- |
| 1 | 在詳情頁開啟 Menu Vision，點任一個「拍照」入口 | `lib/flow/menu_vision/view/menu_vision_sheet.dart`：標題列 `IconButton`（`:216-220`，接線於 `:91-93`）、初始畫面 `take_photo_button`（`:274-280`／`:105-107`）、失敗畫面「重新拍攝」（`:463-467`／`:129-133`）、取消畫面「拍照」（`:522-526`／`:141-143`） | **Sheet 永遠卡在載入畫面**（原始碼鏈已逐段確認，未實機執行）：bloc 先 `emit(MenuVisionLoading())`（`menu_vision_bloc.dart:28`）→ `captureImage()`（`menu_vision_repo.dart:47-53`）→ `image_picker` 1.2.3 `pickImage` → `getImageFromSource`（`image_picker.dart:88`）→ `image_picker_macos` 0.2.2+1 的 camera 分支交給父類（`image_picker_macos.dart:101-102`）→ `CameraDelegatingImagePickerPlatform` 沒有 `cameraDelegate`，拋出 **`StateError`**（`image_picker_platform_interface` 2.11.1 `image_picker_platform.dart:372-377`）。bloc 只接 `on Exception`（`menu_vision_bloc.dart:65`），接不到 `StateError`；`bloc` 9.2.1 會先 `onError` 再 `rethrow`（`bloc.dart:228-231`），所以狀態停在 Loading |
| 2 | 把視窗拖得很小 | `macos/Runner/MainFlutterWindow.swift:5-14` 沒有設最小尺寸；初始內容區是 800×600（`macos/Runner/Base.lproj/MainMenu.xib:335`） | 視窗可以縮到任意大小。Menu Vision 的初始、失敗、取消三個畫面都是**不可捲動**的 `Column`（`menu_vision_sheet.dart:247-291`、`:427-479`、`:493-538`），高度不夠就出現 RenderFlex overflow |
| 3 | 在登入頁點 Google 登入 | `lib/manager/google_sign_in_manager.dart:19` `GoogleSignIn().signIn()`；`macos/Runner/Info.plist` 沒有 `CFBundleURLTypes`，也沒有 `GIDClientID` | **還沒開瀏覽器就失敗**，詳見 §1.2 |

### 1.2 說法更正：Google 登入不是「回呼回不到 App」，而是「流程根本沒開始」

brief 描述的是「缺 URL scheme，OAuth 回呼無法回到 App」。實查 `google_sign_in_ios` 5.9.0（`google_sign_in` 6.3.0 在 macOS 的實作，`sharedDarwinSource`）與 macOS 實際解析的 `GoogleSignIn-iOS` 8.0.0（`macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`）原始碼，發現兩道檢查都在**開啟授權頁之前**：

1. **缺 client ID（第一道）**
   - plugin 先讀 bundle 內 `GoogleService-Info.plist` 的 `CLIENT_ID`（`FLTGoogleSignInPlugin.m:17-24`、`:148-155`），讀不到就交給 SDK 讀 Info.plist 的 `GIDClientID`（`GIDSignIn.m:1177`）。
   - `macos/Runner/GoogleService-Info.plist` **檔案存在，但沒有打包進 app**：macOS `project.pbxproj` 中 `GoogleService-Info` 出現 0 次，Runner 的 Resources build phase 只有 `Assets.xcassets` 與 `MainMenu.xib`（`:326-333`）。已建好的 `flutter_restaruant.app/Contents/Resources/` 內也沒有這個檔案。對照組：iOS 有把它打包進去（`ios/Runner.xcodeproj/project.pbxproj:210`），所以 iOS Info.plist 不需要 `GIDClientID`。
   - 兩處都讀不到，SDK 會拋 `NSInvalidArgumentException: No active configuration. Make sure GIDClientID is set in Info.plist.`（`GIDSignIn.m:572-577`）。
2. **缺 URL scheme（第二道）**：即使補上 client ID，SDK 會檢查 `CFBundleURLTypes` 是否包含反轉後的 client ID，沒有就拋 `Your app is missing support for the following URL schemes`（`GIDSignIn.m:584-595`）。
3. **失敗的呈現**：plugin 會先把錯誤回傳給 Dart，Dart 端收到 `PlatformException`，被 `google_sign_in_manager.dart:49` 的 `on Exception` 接住，回傳 `signInFailed`。但 plugin 接著又 `[e raise]` 把例外重新拋出（`FLTGoogleSignInPlugin.m:169-171`）。**原生端會因此 crash，還是只被 AppKit 記錄下來，未實測。**

**URL scheme 必須是 macOS client 的，不能照抄 iOS 的**：scheme 由 `configuration.clientID` 反轉得到（`GIDSignInCallbackSchemes.m:51-55`）。macOS 的 client 是 `35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71`（`macos/Runner/GoogleService-Info.plist:6`，與 `lib/firebase_options.dart:84` 的 `macos.iosClientId` 一致，bundle `com.yomi.find-restaurant.macos`），**不是** `ios/Runner/Info.plist:51` 的 `...8bh7hq1e...`。

**回呼路徑**：`AppAuth` 1.7.6 在 macOS 用 `ASWebAuthenticationSession`（`OIDExternalUserAgentMac.m:90`），回呼由 session 本身接回。只有在退回 `NSWorkspace` 開瀏覽器的路徑時（`:118`），才會經 `FlutterAppDelegate`（`macos/Runner/AppDelegate.swift:5`）轉給 plugin 的 `handleOpenURLs`（`FLTGoogleSignInPlugin.m:101-107`）。所以 `CFBundleURLTypes` 的主要作用是**通過 SDK 的檢查**，並支撐這條退路。

**brainstorm 所說的「補 macOS OAuth client」**：macOS 的 `GoogleService-Info.plist` 已經含有 `CLIENT_ID`／`REVERSED_CLIENT_ID`，可推論 Firebase 註冊 macOS app 時已建立 OAuth client（推論，未在 GCP Console 確認，見 §4.4）。

### 1.3 實查發現（原不在本項範圍，依 D-1 納入）：release 建置的基線已經壞了

- **2026-10-09 於 `37826b3` 實測**：`flutter build macos`（release）**失敗**，訊息為 `Signing for "Runner" requires a development team.`；`flutter build macos --debug` **成功**，產物簽章為 `TeamIdentifier=H2724L9BS5`。兩次執行後工作樹都沒有變動。
- **原因**：`9ec1f48` 把 Debug、Profile、Release 三個 configuration 都設成 `"CODE_SIGN_IDENTITY[sdk=macosx*]" = "Apple Development"`（`project.pbxproj:586`、`:719`、`:741`），但 `DEVELOPMENT_TEAM` 只加在 Debug（`:722`）。
- **影響**：A-9.2 AC-3 的基線（`65a9852` 時 release 建置成功）已經不成立。**D-1 已決 (a)**（§6.2）：本項在 Release 與 Profile 補上 `DEVELOPMENT_TEAM`（獨立 commit），AC-3 的 release 建置因此列為必過。

### 1.4 brainstorm A-9.6 列另外兩項：實查後確認不需要工作

| brainstorm 子項 | 現況 | 結論 |
| :--- | :--- | :--- |
| macOS entitlements | `network.client`、`personal-information.location`、`files.user-selected.read-only` 在 `DebugProfile`／`RunnerDebug`／`Release.entitlements` 三份都已存在。`image_picker_macos` 選圖靠 `file_selector`，需要 `files.user-selected.read-only`（套件 README）。相機入口要隱藏，所以不需要 `device.camera`。`aps-environment` 依 D-9.7 不做 | **無需變動**。唯一可能要加的是 `keychain-access-groups`，屬條件式範圍（§4.3） |
| 地圖降級為靜態圖＋外部導航 | 詳情頁顯示 Static Maps 圖（`lib/component/cell/restaurant_detail/restaurant_info_cell.dart:74`）。點擊後跳出 action sheet（`:61-62`），再由 `Utils.openUrl` 以 https 開啟 `maps.google.de`（`:230`、`constants.dart:34`）→ `launchUrlString`（`utils.dart:24`），`url_launcher_macos` 已在建置產物中。主頁的地圖模式已由 A-9.2 隱藏（`drawer_widget.dart:73`） | **已達成**，只列為人工回歸檢查（AC-14） |

### 1.5 核心資料：能力矩陣新增 `camera` 一列

| 能力 | Android | iOS | macOS | Web（不論瀏覽器所在 OS） | 依據 |
| :--- | :---: | :---: | :---: | :---: | :--- |
| ads／pushNotifications／mapMode | ✓ | ✓ | ✗ | ✗ | A-9.2（不變） |
| **camera**（Menu Vision 拍照入口） | ✓ | ✓ | ✗ | ✗（暫定） | `image_picker_macos` 沒有 `cameraDelegate` 就拋 `StateError`。Web 依白名單關閉；`image_picker_for_web` 技術上能用 `capture` 屬性開相機，但 Web target 尚未建立，日後要開只需改一處（與 `mapMode` 等 E-9.3 同理） |

**為什麼新增欄位，而不是用別的方式判斷**（brief 要求說明理由）：

- **這是一項平台能力，有自己獨立的成立理由**（套件限制），跟 `ads` 同一類。A-9.2 立下的規則是「平台能力只在一處回答，呼叫點只讀能力名稱」。
- **成本只有一行**：在既有 record 加一個欄位。不新增檔案、介面或 DI 註冊。唯一要改的既有測試是 `test/features/utils/platform_capabilities_test.dart:10-11` 的 `_Data.all`／`_Data.none` 常數。這是**純新增一欄**，原本三欄的期望值不變。
- **不採用的替代方案**：

| 方案 | 優點 | 不採用的理由 |
| :--- | :--- | :--- |
| `ImagePicker().supportsImageSource(ImageSource.camera)`（1.2.3 已提供，`image_picker.dart:369`） | 由套件自己回答；日後若設了 `cameraDelegate` 會自動翻轉 | (1) 等於「平台能力」有了第二套回答機制，出現兩個事實來源。(2) `ImagePicker` 由 `MenuVisionRepo._picker` 持有（`menu_vision_repo.dart:22,27`），UI 直接 new 一個會繞過 repository；改成在 `MenuVisionRepository` 加方法，則 3 個測試檔的 mocktail mock 都得補 stub。(3) 測 macOS 時要假造 `ImagePickerPlatform.instance`，跟全專案用的 `debugDefaultTargetPlatformOverride` 不一致 |
| 在 sheet 寫 `defaultTargetPlatform != TargetPlatform.macOS` | 改最少 | 違反 A-9.2 的約束（呼叫點不讀平台名稱）；而且 windows／linux／Web 都會漏掉 |

### 1.6 最小視窗尺寸：內容區 360×640

- **取值理由**：行動版版面設計時預設的就是手機直式視窗。360×640 是 Android 主流小螢幕的寬度基準（360dp），也是 Material 的參考裝置尺寸；iPhone SE 2／3 的 375×667 兩個維度都比它大。這個值保證所有畫面至少拿到「行動版實際會遇到的最小空間」。
- **以內容區計算，不含標題列**：要保證的是 Flutter view 的尺寸，標題列不應吃掉這個預算。
- **不採用 320×568**（iPhone SE 1 代，iOS 15 部署目標理論上涵蓋）：從沒在這個尺寸驗證過；在桌面上多放寬這 40×72 沒有任何好處。
- **不採用更大的值**：直式、窄的視窗正是現有版面最舒服的形狀。寬螢幕版面屬 UI-9.3。
- **初始視窗必須 ≥ 最小值**：xib 的初始內容區是 800×600，**高度 600 < 640**。只設最小值的話，啟動時的視窗會比最小值還小。這必須一併處理（AC-11）。
- 這個數值是設計決定，沒有實測過臨界值。0b 或實作期間若實測發現有更合理的值，可以提出修正，並在 PR 說明理由。

### 1.7 為什麼現在做

- 這是 §9.7 macOS 線第 3 步（A-9.6 ＋ UI-9.2、UI-9.4）的主體。A-9.2 已經讓 macOS 能乾淨啟動，剩下的是使用者操作時會碰到的壞點。
- 三個問題都是**確定可重現**（1、3 有原始碼鏈證據，2 是缺少設定），不是臆想出來的風險。

---

## 2. 使用者故事 (User Stories)

1. **作為 macOS 使用者**，我在 Menu Vision 只看到「從相簿／檔案選圖」的入口，看不到點了會卡住的「拍照」。選圖後照常進入分析；取消選圖會回到「已取消」畫面。不會有任何路徑讓我卡在載入畫面。
2. **作為 macOS 使用者**，我無法把視窗縮到內容區小於 360×640；App 第一次開啟時，視窗也不會比這更小。
3. **作為 macOS 使用者**，我在登入頁點 Google 登入，會看到 Google 授權頁；授權完成後回到 App，並以該帳號登入成功。中途取消會回到登入頁，App 不會崩潰。
4. **作為既有 Android／iOS 使用者**，我感受不到任何差異：Menu Vision 的四個拍照入口都還在，Google 登入流程不變。
5. **作為維護者**，「這個平台能不能拍照」只在 `platformCapabilities()` 一處回答。Menu Vision 不讀平台名稱。日後 Web 要開放相機，只改那一處。

### 受影響的使用情境

| 情境 | Android／iOS | macOS：現況 → 改動後 |
| :--- | :--- | :--- |
| Menu Vision 初始畫面 | **不變**（拍照＋相簿兩個按鈕） | 拍照會卡在 Loading → 只剩相簿按鈕 |
| Menu Vision 標題列 | **不變**（相機、相簿、關閉） | 相機圖示會卡住 → 只剩相簿、關閉 |
| Menu Vision 失敗畫面 | **不變**（重試此照片／重新拍攝／相簿重選） | 「重新拍攝」會卡住 → 只剩重試此照片（有圖時）與相簿重選 |
| Menu Vision 取消畫面 | **不變**（拍照／相簿） | 「拍照」會卡住 → 只剩相簿 |
| `autoStartCapture: true` 開啟 sheet（目前沒有呼叫點會傳入 true，見 §5.4） | **不變** | 會自動走相機而卡住 → 不自動觸發相機 |
| 縮小視窗 | 不適用 | 無下限 → 內容區最小 360×640 |
| Google 登入 | **不變**（原生設定與 Dart 呼叫都不動） | 拋 NSException、登入失敗 → 完成 OAuth 並登入 |

---

## 3. 驗收條件 (Acceptance Criteria)

### 3.1 可機械驗證（必須全數通過）

在 `flutter_restaruant/flutter_restaruant` 目錄下執行：

```bash
# AC-1：靜態分析零警告零錯誤
flutter analyze

# AC-2：既有＋新增測試全綠
flutter test

# AC-3：macOS 本機建置（D-9.8：macOS 以本機 build 驗收）
flutter build macos --debug
flutter build macos

# AC-4：Menu Vision 不自行判斷平台 —— 預期 0（基線 0）
grep -rn -e "defaultTargetPlatform" -e "kIsWeb" -e "TargetPlatform\." lib/flow/menu_vision/ | wc -l

# AC-5：做平台判斷的檔案集合不變 —— 基線 8 檔，改動後仍為同樣 8 檔
grep -rln --include="*.dart" -e "defaultTargetPlatform" -e "kIsWeb" lib/ | sort

# AC-6：macOS 的 URL scheme 必須是 macOS client，且不得混入 iOS client
grep -c "com.googleusercontent.apps.35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71" macos/Runner/Info.plist   # 預期 ≥ 1
grep -c "8bh7hq1e07129nav2gcme5n9p565su7k" macos/Runner/Info.plist                                          # 預期 0

# AC-7：行動版原生設定與 Google 登入的 Dart 呼叫不動 —— 預期無輸出
git diff --stat main -- ios/ android/ lib/manager/google_sign_in_manager.dart
```

- **AC-1** `No issues found!`
- **AC-2** 全部通過。**唯一允許修改的既有測試期望值**是 `platform_capabilities_test.dart` 的 `_Data.all`／`_Data.none` 新增 `camera` 欄，而且原本三欄的值不得改變。下列測試必須**原樣**通過，它們是「行動版 Menu Vision 不變」的回歸證據（預設測試平台為 android）：
  - `test/flow/menu_vision/menu_vision_sheet_test.dart`（點 `take_photo_button` 的三個案例）
  - `test/flow/menu_vision/menu_vision_view_characterization_test.dart`
  - `test/flow/menu_vision/menu_vision_bloc_test.dart`
- **AC-3** 兩個指令都輸出 `✓ Built build/macos/Build/Products/{Debug,Release}/flutter_restaruant.app`。
  - **基線**：debug 成功，**release 失敗**（§1.3）。依 D-1 (a) 補上 `DEVELOPMENT_TEAM` 後，release 必須成功，產物簽章為 `TeamIdentifier=H2724L9BS5`。
  - **例外**：若實作期間 `main` 合入他項導致建置失敗，先在未改動的基線重現；基線同樣失敗，則不計入本項，於 PR 註明。
- **AC-4** 預期 `0`。
- **AC-5** 基線 8 檔：`component/ad/{app_open,banner,interstitial}_ad_state.dart`、`features/utils/platform_capabilities.dart`、`firebase_options.dart`、`flow/signinup/view/third_party_sign_in_widget.dart`、`main.dart`、`manager/fcm_manager.dart`。`camera` 加在已列入的 `platform_capabilities.dart`，所以集合不應變動。
- **AC-6** 第一行 ≥ 1，第二行 0。另外，client ID 必須能被 SDK 讀到。依 D-2 的選擇，下列二者擇一成立：
  - `plutil -extract GIDClientID raw macos/Runner/Info.plist` 輸出 `35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71.apps.googleusercontent.com`
  - 建置後的 `build/macos/Build/Products/Debug/flutter_restaruant.app/Contents/Resources/GoogleService-Info.plist` 存在
- **AC-7** 無輸出。

### 3.2 新增測試（TDD-first，納入 AC-2）

- **AC-8 能力矩陣**：在既有 `platform_capabilities_test.dart` 表格加入 `camera`。android、iOS（非 Web）為 `true`；macOS、windows、linux、fuchsia 以及 Web × {android, iOS, macOS} 一律 `false`。
- **AC-9 Menu Vision Widget 測試**：用 `debugDefaultTargetPlatformOverride = TargetPlatform.macOS`，並在 `finally` 復原（沿用 `platform_capabilities_test.dart` 的寫法）：
  - **初始畫面**：沒有 `take_photo_button`，有 `gallery_pick_button`。標題列沒有相機 `IconButton`（`Icons.camera_alt_outlined`），仍有相簿與關閉
  - **取消畫面**（`pickImageFromGallery` 回 `null`）：沒有拍照按鈕（`Icons.camera_alt`），有相簿按鈕
  - **失敗畫面**（`pickImageFromGallery` 拋 `Exception`）：沒有「重新拍攝」，有「相簿重選」
  - **`autoStartCapture: true`**：`verifyNever(() => repo.captureImage())`
  - **android 對照組**：取消畫面的拍照入口仍存在。既有測試已涵蓋初始畫面的兩個按鈕與失敗畫面的「重新拍攝」，取消畫面只驗了標題，這個缺口由本項補上
- **不為 `MainFlutterWindow.swift` 寫 XCTest**：它只是一個常數設定，由 AC-11 人工確認。

### 3.3 需人工／情境確認（`flutter run -d macos`，Debug，已 team 簽章）

- **AC-10 註解同步**：`MenuVisionSheet` 的類別 doc comment（`menu_vision_sheet.dart:12`）必須註明拍照入口會依平台能力顯示。
- **AC-11 視窗**：
  - 往內拖曳視窗，內容區停在 360×640，無法再縮小
  - 首次啟動時，內容區不小於 360×640
  - 在最小尺寸下瀏覽登入頁、主頁列表、Drawer、詳情頁、Menu Vision（初始、取消、失敗三個畫面），console 不出現 `A RenderFlex overflowed`
  - 若出現 overflow：先在 360×640 的 Android 模擬器重現。能重現，代表是既有的行動版 bug，另開 issue，不擋本項；只在 macOS 出現則必須修
- **AC-12 Menu Vision**：從詳情頁開啟後，只看到相簿入口。選一張圖後，畫面離開 Loading，進入成功或失敗畫面（AI 呼叫成功與否取決於 App Check debug token 的登記，見 A-9.2 §4.3，不在本項）。取消檔案視窗則進入取消畫面，而且沒有拍照按鈕。
- **AC-13 Google 登入**：
  - 點 Google 登入，出現 Google 授權頁；完成後回到 App，並以該帳號登入成功（進入主頁）
  - 中途取消，回到登入頁，App 不崩潰
  - console 不出現 `No active configuration`、`missing support for the following URL schemes`、`keychain error`。若出現 `keychain error`，啟動 §4.3 的條件式範圍
- **AC-14 地圖回歸（不改動）**：詳情頁顯示靜態地圖；點擊後在 action sheet 選導航，預設瀏覽器開啟 `maps.google.de`。
- **AC-15 行動版**（建議，非必要）：真機確認 Menu Vision 拍照與 Google 登入如常。本項不動行動版的原生設定（AC-7），行動版唯一的變動面是 sheet 的 Dart 程式，已由 AC-2、AC-9 鎖住。

### 3.4 不納入本項驗收

- **release 組態下實際跑 Google 登入**：D-1 只保證 release 能以 Apple Development 憑證建置；實際登入驗證屬 E-9.4a／b。
- **Web**：Web target 尚未建立。
- **Menu Vision 在 macOS 上 AI 分析的成功率**：取決於 Firebase AI 與 App Check 的 Console 設定。

---

## 4. 範圍與邊界 (Scope & Boundaries)

### 4.1 In Scope

- `platformCapabilities()` 新增 `camera` 欄位（§1.5）
- `MenuVisionSheet`：四個拍照入口與 `autoStartCapture` 路徑都依 `camera` 能力決定
- `macos/Runner/MainFlutterWindow.swift`：內容區最小 360×640，初始視窗不小於此值（若需動 `MainMenu.xib` 也算在內，見 D-3）
- `macos/Runner/Info.plist`：`CFBundleURLTypes` 填入 macOS client 的 reversed client ID；並讓 SDK 讀得到 client ID（D-2）
- `macos/Runner.xcodeproj/project.pbxproj`：Runner target 的 Release 與 Profile 補 `DEVELOPMENT_TEAM = H2724L9BS5;`（D-1 (a)，獨立 commit）
- §3.2 的新增測試、AC-10 的註解同步
- **（2026-10-10 人工驗收後追加，使用者決定）UI-9.1**：AC-14 實測時詳情頁在 macOS 拋 `createPlatformChromeSafariBrowser is not implemented`（`restaurant_comment_cell.dart` 於建構時 new `ChromeSafariBrowser()`）。改用 `url_launcher` 的 `LaunchMode.inAppBrowserView`，並移除 `flutter_inappwebview`。行動版仍為 Custom Tabs／SFSafariViewController；`url_launcher_macos` 忽略 mode，macOS 由預設瀏覽器開啟（讀原始碼確認）
- **（2026-10-10 §4.3 條件已觸發）** Google 登入後 `firebase_auth` 回報 `keychain-error`，`RunnerDebug.entitlements` 加入 `keychain-access-groups`：App 本身的 group（Firebase Auth 預設寫入第一個 group）與 `com.google.GIDSignIn`。PR #145 review 後一併補到 `DebugProfile.entitlements`（Profile）與 `Release.entitlements`（Release），三組態一致，避免 release 登入遇到同一個 keychain-error

### 4.2 Out of Scope

- **地圖**：已達成（§1.4）。不引入 MapKit 或任何地圖套件（§9.9）
- **`window_manager` 等視窗套件**：最小視窗直接在 Swift 設定
- **entitlements**：§1.4 已確認不需變動（`keychain-access-groups` 除外，見 §4.3）
- **UI-9.2**（SnackBar）、**UI-9.3**（響應式）、**UI-9.4**（滑鼠拖曳）
- **Menu Vision 在 macOS 的文案**：「從相簿選擇照片」在 macOS 實際開的是檔案選擇視窗（`file_selector`，`public.image`），文字不完全貼切。但要改就得新增多個 l10n key（`menu_vision_btn_gallery`、`_tooltip_gallery`、`_btn_reselect_gallery`、`_btn_gallery_short`，以及 `_prompt_title`「拍下菜單」），屬於文案工作，不在本項
- **按鈕樣式**：拍照按鈕隱藏後，剩下的相簿按鈕維持 `OutlinedButton`，不升格為主要按鈕
- **在 bloc 補 `catch StateError`**：style guide §6.1 規定不捕捉 `Error`。UI 擋住之後，這條路徑在 macOS 已不可達
- **改 `CaptureAndAnalyzeMenu` 的預設 `source = camera`**（`menu_vision_event.dart:15`）：沒有使用者入口，而且 `menu_vision_bloc_test.dart` 有 5 個案例依賴這個預設值
- **刪除 `autoStartCapture`**：目前沒有呼叫點傳入 true，屬死碼。沿用 A-9.2 先例，死碼清理另案處理（§7）
- **為 macOS 提供相機**（設定 `cameraDelegate`）：需要新相依，而且 E-9.1 正要移除 `camera` 套件
- **Dart 端 `GoogleSignIn(clientId: ...)`**：會影響 Android，違反 AC-7
- **Facebook 登入（`facebook_auth_desktop`）、Apple 登入 capability**：E-9.4a
- **Web 啟動期的生物辨識**；**E-9.4 簽章與發布**（D-1 除外）

### 4.3 條件式範圍（視實測結果才做）

- **`keychain-access-groups`（`$(AppIdentifierPrefix)com.google.GIDSignIn`）**：只有 AC-13 出現 GIDSignIn `keychain error`（`Code=-2`）時才加。正反證據如下：
  - **要加**：`google_sign_in_ios` 5.9.0 README 的「macOS setup」說缺了它就會拋 `keychain error`。
  - **可能不必**：
    - `GoogleSignIn-iOS` 8.0.0 README（`:45-51`）只要求「sign your app」；範例 README（`Samples/Swift/DaysUntilBirthday/README.md:28-46`）把 `keychain error` 歸因於簽章，Keychain Sharing 只列為拿不到 provisioning profile 時的 workaround。
    - 原始碼顯示，GIDSignIn 在 macOS 用的是**舊式 keychain**：`GTMKeychainStore` 沒帶 `useDataProtectionKeychain`（`GIDSignIn.m:466`；`GTMAppAuth` 4.1.1 `KeychainStore.swift:120-126`、`:281-287`）。
    - 使用者 2026-10-09 已實測：Team 簽章本身就能修好 Firebase 的 Data Protection keychain（-34018），不需要 Keychain Sharing。Debug 現在就是 team 簽章。
    - **2026-10-10 AC-13 實測推翻上一點**：Team 簽章下 Google OAuth 成功，但 `firebase_auth` 仍回報 `keychain-error`，條件已觸發。
  - **已加（三個組態）**：先依實測只加 Debug → `RunnerDebug.entitlements`。D-1 (a) 之後 Release／Profile 也有 team 簽章（不再是 ad-hoc），PR #145 review 指出它們缺 group 會在 release 登入時遇到同樣的 keychain-error，因此一併補到 `DebugProfile.entitlements` 與 `Release.entitlements`（`--profile`／release 建置與 `codesign` 皆已驗證）。release 登入的實機驗證仍留給 E-9.4a（§3.4）。

### 4.4 部署前置注意事項（手動作業，非本項驗收）

- **GCP Console → Credentials**：確認 `35224406241-ujri5q7pfruts9uerq1vbu6omoa6nk71` 是 iOS 類型的 OAuth client，且 bundle ID 為 `com.yomi.find-restaurant.macos`。若 AC-13 遇到 `invalid_client` 或 bundle 不符，從這裡查起。
- **Firebase Auth**：Google provider 已為行動版啟用，無需額外設定。同專案的 client 簽發的 ID token 會被接受（推論）。

---

## 5. 風險與破壞性評估 (Never break userspace)

### 5.1 行動版必須零變化（鐵律）

| 項目 | 等價性論證 |
| :--- | :--- |
| `camera` 能力 | android／iOS 恆為 `true` → 四個入口與 `autoStartCapture` 走與現況相同的路徑（AC-8、AC-9 android 對照組） |
| 既有 Menu Vision 測試 | 原樣通過（AC-2） |
| iOS／Android 原生設定、`google_sign_in_manager.dart` | 不動（AC-7） |
| 既有三項能力 | 值不變（AC-2 只允許新增欄位） |

### 5.2 最大陷阱：抄錯 client

把 `ios/Runner/Info.plist:51` 的 scheme 直接複製到 macOS，看起來像是補好了，但 SDK 會用 macOS 的 client ID 推出另一個 scheme，結果仍然拋出 `missing support for the following URL schemes`。若改用 D-2 (b) 打包 plist，client ID 與 scheme 會來自同一個檔案，就不會不一致；若用 (a)，兩個值都要從 `macos/Runner/GoogleService-Info.plist` 取。AC-6 用機械方式擋住這個錯誤。

### 5.3 `BannerADState` 式的耦合：本項沒有

能力判斷只影響 UI 是否顯示，不涉及 `getIt` 的註冊與取用，所以不會出現 A-9.2 §5.3 那種「略過註冊卻沒略過取用」的崩潰風險。bloc 與 repository 都不改。

### 5.4 `autoStartCapture` 是潛伏的陷阱

`autoStartCapture`（`menu_vision_sheet.dart:66-69`）在開啟 sheet 時**無條件**派發 camera 事件。唯一的呼叫點（`restaurant_detail_page.dart:95-98`）沒有傳入這個參數，預設為 `false`，所以**目前開 sheet 不會自動觸發相機**。但只要有人傳入 `true`，macOS 就會直接卡住，因此 AC-9 要求一併擋住。

### 5.5 未實測推論

| 推論 | 依據 | 影響／確認方式 |
| :--- | :--- | :--- |
| macOS 點拍照會卡在 Loading | 原始碼鏈逐段確認（§1.1 #1） | 本項讓這條路徑不可達，不需另外驗證 |
| Google 登入失敗後，plugin 的 `[e raise]` 可能讓原生端 crash | `FLTGoogleSignInPlugin.m:169-171` | 本項補好設定後，正常流程不會觸發；異常時看 AC-13 的 console |
| Debug team 簽章下，GIDSignIn 不需要 `keychain-access-groups` | §4.3 | AC-13 實測；失敗就啟動條件式範圍 |
| FirebaseAuth 在 macOS 寫入 Data Protection keychain（`AuthKeychainServices.swift:246,274`，firebase-ios-sdk 12.19.0），team 簽章即可運作 | 與使用者已實測的 Firebase Installations 同機制 | AC-13：`signInWithCredential` 成功 |
| macOS 的 OAuth client 已存在於 GCP | plist 含 `CLIENT_ID` | §4.4 |
| 曾被縮到比最小值更小的視窗，更新後可能經 state restoration 以舊尺寸開啟（`AppDelegate.swift:10` 開啟了 secure restorable state；AppKit 的 min size 只限制使用者拖曳） | AppKit 行為推論 | AC-11 只驗首次啟動；舊尺寸問題在使用者拖曳一次後即自我修正，嚴重度低 |

### 5.6 Linus 式核心判斷

- **值得做**：三個都是真實、可重現的壞點，其中兩個有原始碼鏈證據，一個是明確缺少設定。修法也小：一個能力欄位、一個 sheet、兩個原生檔案。
- **關鍵洞察**：相機問題的本質，是 A-9.2 那張能力表少了一列；補上之後，sheet 只要問「能不能拍照」。Google 登入的本質則是 macOS 的設定**從來沒有被打包進 app**，問題不在 OAuth 流程。
- **最大破壞風險**：(1) 抄錯 client（§5.2）；(2) 修改既有 Menu Vision 測試來「通過」（AC-2 禁止）；(3) 把需要簽章的 entitlement 加給 ad-hoc 組態（§4.3）。
- **規模自律**：零新相依、零新抽象。預期 1 個能力欄位、1 個 widget 檔、2 個原生檔（可能另加 xib 或 pbxproj），再加測試。

---

## 6. 給 STAGE 0b 的設計約束與待決事項

### 6.1 約束（計畫必須遵守）

1. **`camera` 只從 `platformCapabilities()` 讀取**。`lib/flow/menu_vision/` 不讀平台名稱（AC-4）。
2. **隱藏，不是停用**：macOS 上拍照入口不出現，而不是變成灰色。
3. **只在 UI 層擋**：bloc、event、repository 都不改（§4.2）。
4. **沿用 sheet 既有的 nullable callback 慣例**：`_FailureRetryView.onRetryPhoto`（`menu_vision_sheet.dart:412`，以 `:450` 的 `if (onRetryPhoto != null)` 決定是否顯示）。不另外發明新模式。
5. **原生變更只限 `macos/Runner/`** 下的 `MainFlutterWindow.swift`、`Info.plist`，以及依 D-2、D-3、§4.3、D-1 可能涉及的 `MainMenu.xib`、`project.pbxproj`、entitlements。`ios/`、`android/` 不動。
6. **不新增相依**。

### 6.2 待決事項

| # | 決策者 | 問題 | 選項 | 建議 |
| :--- | :--- | :--- | :--- | :--- |
| **D-1** | **使用者** | release 建置的基線已壞（§1.3），AC-3 怎麼處理？ | (a) 在 Release 與 Profile 補上 `DEVELOPMENT_TEAM = H2724L9BS5`（2 行，與 Debug 一致）。<br>(b) Release 與 Profile 的簽章身分改回 ad-hoc `"-"`，建置會通過，但 release 會重新遇到 keychain -34018，Remote Config 拿到空值。<br>(c) 不處理，AC-3 降為只驗 `--debug` | **已決：(a)**（使用者 2026-10-10 確認），以獨立 commit 進行。這符合 `9ec1f48` commit message 的原意（「team 簽章讓 keychain 可用」）。release 因此改用 Apple Development 憑證簽章、不能拿去發布，但發布本來就屬 E-9.4b。這動到簽章設定，超出 brief 的「不做 E-9.4」，已取得使用者明確同意 |
| **D-2** | 0b | 讓 SDK 讀到 client ID 的方式 | (a) 在 macOS `Info.plist` 加 `GIDClientID`。<br>(b) 把 `macos/Runner/GoogleService-Info.plist` 加進 Runner 的 Resources build phase（作法與 iOS 相同） | **(a)**：只動一個檔案，是 plugin 原始碼註解中「recommended method」（`FLTGoogleSignInPlugin.m:146-147`），也不用動 pbxproj。(b) 的好處是 client ID 只有一個來源，而且與 iOS 一致；但 `CFBundleURLTypes` 不論選哪個都得手動同步，兩者在這點上沒有差別。(b) 另需確認把 plist 打包進 app 是否會改變其他 Firebase 原生 SDK 的行為（推論風險低，未查證） |
| **D-3** | 0b | 初始視窗不小於最小值的作法 | 修改 `MainMenu.xib:335` 的 `contentRect`，或在 `awakeFromNib` 以程式碼調整 | 二者皆可，選 diff 最小、最容易 review 的那個 |
| **D-4** | 0b | `camera` 的讀取時機 | 在 `initState` 讀一次存起來，或在 `build` 讀 | `platformCapabilities()` 是純函式、成本可忽略；以測試能用 `debugDefaultTargetPlatformOverride` 覆寫為準 |

---

## 7. 後續建議（不屬本項，留作記錄）

1. **更正 brainstorm 的 E-9.4a**：使用者 2026-10-09 已實測，Team 簽章本身就能修好 Remote Config 的 keychain（-34018）；但 2026-10-10 AC-13 實測顯示 `firebase_auth` 登入仍需要 `keychain-access-groups`（本項已加入三個組態）。壞掉的也不只是登入，還有 Remote Config 與 Yelp。
2. **更新 brainstorm 的 A-9.6 列**：註明 entitlements 與地圖兩項，實查後確認不需要工作（§1.4）。
3. **刪除 `MenuVisionSheet.autoStartCapture` 死碼**（零呼叫點）。
4. **Menu Vision 在 macOS 的文案**：「相簿」改為「檔案」。若有使用者回饋再做。
5. **Release 的正式簽章**（Developer ID 或 App Store）：E-9.4b。`keychain-access-groups` 是受限 entitlement，App 必須內嵌授權 `H2724L9BS5.*` 的 provisioning profile 才能啟動；手動簽章時要記得放 Developer ID／App Store profile。

---

## 8. 執行方式

規格確認後，由 STAGE 0b 產出 `docs/plans/2026-10-09-a-9-6-macos-adaptation.md`。可選的執行方式：

- **Subagent-driven**（建議）：三個子問題互相獨立，可分成三組任務依序執行：(1) `camera` 能力＋sheet＋測試；(2) 最小視窗；(3) Google 登入的 plist。每組完成後跑 AC-1、AC-2，最後一起跑 AC-3 到 AC-7 與人工 AC。
- **Parallel session**：(1) 只動 Dart，(2)、(3) 只動 `macos/Runner/`，檔案不重疊，可以平行進行。但 (2) 與 (3) 都需要 `flutter run -d macos` 做人工驗收，要共用同一台機器的建置產物，平行的效益有限。
