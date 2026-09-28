# Feature: Firebase Remote Config 動態模型控制（AI 參數遠端化）

> 建立日期：2026-09-27
> 來源：`docs/brainstorm/2026-09-27-features-brainstorm.md` §[A-8.5]（P0）、§7.5 第 2 點「Firebase Remote Config 動態模型控制」
> 範圍：`pubspec.yaml`、`lib/main.dart`、`lib/di/injection.dart`、`lib/data_layer/repositories/ai_foodie_repo.dart`、`lib/data_layer/repositories/menu_vision_repo.dart`，以及新增一個 Remote Config 存取點與對應測試
> 狀態：草稿 v1（待確認）

---

## 1. 背景與問題

AI 覓食助理與拍菜單分析的 Gemini 參數全部寫死在程式碼裡：

1. **改參數必須發版**：換模型、調 system instruction、調 temperature，都要重新 build、送審、等使用者更新。模型被下架或某個模型配額異常時，沒有辦法在 client 端止血，只能等新版上架。
2. **同一個值寫了兩份**：模型名 `'gemini-3.5-flash-lite'` 分別寫在兩個 repo，沒有任何東西保證它們一致；下次有人只改其中一處就會悄悄漂移。

本功能的本質一句話：**讓維運者不發版就能改這兩個 AI 功能的模型名、temperature 與 system instruction；拿不到遠端值時，行為和現在一模一樣。**

---

## 2. 現況（2026-09-27 實查）

| 事實 | 證據 |
|------|------|
| 未安裝 `firebase_remote_config`；已有 `firebase_core ^4.12.1`（lock 解析為 `4.15.0`）、`firebase_ai ^4.0.0`（lock `4.0.0`）、`firebase_app_check ^0.4.7` | `pubspec.yaml:51,57,58`、`pubspec.lock` |
| 模型名寫死兩份 | `ai_foodie_repo.dart:156`、`menu_vision_repo.dart:38` |
| System instruction 以 `static const` 寫死 | `ai_foodie_repo.dart:28`（private `_systemInstruction`）、`menu_vision_repo.dart:28`（public `systemInstruction`，lib/test 內無外部引用） |
| Temperature：**只有 AI 覓食助理有設定**（`0.2`）；拍菜單的 `GenerationConfig` **沒有設 temperature**，走模型預設值 | `ai_foodie_repo.dart:159`、`menu_vision_repo.dart:40-43` |
| **`GenerativeModel` 是每次呼叫時才建立**，不是建構 repo 時建立：`AiFoodieRepo.askAssistant` 在 `try` 內呼叫 `ai.generativeModel(...)`；`MenuVisionRepo._analyze` 每次呼叫 `_getModel()` | `ai_foodie_repo.dart:154-163`、`menu_vision_repo.dart:35-45,135-147` |
| 兩個 repo 以 `registerLazySingleton` 註冊，用無參數建構式 | `lib/di/injection.dart:35-36` |
| 啟動流程：`Future.wait([Constants.init(), Firebase.initializeApp(...), S.load(...), SignInManager().loadPrefs()])` → App Check `activate` → `FcmManager().init()`，整段包在 `try` 內，失敗只記 `Logger().e` 後照常 `runApp` | `lib/main.dart:34-61` |
| 既有測試**不初始化 Firebase**：`AiFoodieRepo()` 無參數建構後直接呼叫 `getInitialSuggestions`、`formatAssistantHistory`；其餘案例注入 `promptExecutor`／`analyzer` 繞過 Firebase | `test/data_layer/ai_foodie_repo_test.dart:252,268` 等、`test/data_layer/menu_vision_repo_test.dart:62,88` |

**關鍵推論**：因為 model 是每次呼叫才建，只要 repo 在「建 model 的那一刻」讀設定，遠端值 activate 後的**下一次 AI 請求**就會生效，不需要重啟 App、也不需要處理 model 快取失效。反過來，若實作時把 model 改成建構時快取，遠端值會卡在 lazy singleton 首次建立時的值——這是必須避免的回歸（見驗收條件 6）。

---

## 3. 使用者故事

主要使用者是**維運者／開發者**，終端使用者只應感受到「什麼都沒變」或「AI 回答變好了」。

1. 身為維運者，當 `gemini-3.5-flash-lite` 被下架或配額異常時，我希望在 Firebase Console 改一個參數就能把 AI 覓食助理與拍菜單切到其他模型，不必等新版上架。
2. 身為開發者，我希望調整 system instruction 或 temperature 後，不必發版就能在正式環境觀察效果；效果不好時再改回來。
3. 身為開發者，我希望程式碼裡每個 AI 參數的預設值只有一個來源，呼叫端透過型別化 getter 取值，不必記字串 key。
4. 身為終端使用者，首次啟動、離線、或 Remote Config 服務異常時，App 的啟動速度與 AI 功能行為都和現在一樣。

---

## 4. 範圍

### 4.1 第一批參數（只收 AI 參數）

| Remote Config key | 型別 | 預設值（= 現行寫死值） | 使用者 |
|---|---|---|---|
| `ai_foodie_model` | String | `gemini-3.5-flash-lite` | `AiFoodieRepo` |
| `ai_foodie_temperature` | Number | `0.2` | `AiFoodieRepo` |
| `ai_foodie_system_instruction` | String | 現行 `_systemInstruction` 全文 | `AiFoodieRepo` |
| `menu_vision_model` | String | `gemini-3.5-flash-lite` | `MenuVisionRepo` |
| `menu_vision_system_instruction` | String | 現行 `systemInstruction` 全文 | `MenuVisionRepo` |

**不新增 `menu_vision_temperature`**：拍菜單現在沒設 temperature（走模型預設）。要加 key 就得選一個預設數字，而任何數字都可能和模型預設值不同，等於改變現況行為。為了「沒有遠端值時完全不變」而發明「空值代表不設定」之類的特殊情況也不值得。等真的需要調拍菜單的溫度時再加。

### 4.2 模型名：分開兩個 key（建議）

兩個選項：

| 方案 | 優點 | 缺點 |
|---|---|---|
| A. 共用 `ai_model_name` | Console 只改一處；和現況「兩處同值」語意最接近 | 兩個功能的工作負載不同（多模態圖片 + 結構化 JSON vs. 多輪文字對話 + GenUI JSON），無法只替其中一個換模型；想單獨換時只能再拆 key，屆時要處理舊 key 相容 |
| **B. 分開 `ai_foodie_model`／`menu_vision_model`** | 各自獨立切換、獨立回滾；一邊換模型出事不會拖垮另一邊 | 模型下架時要在 Console 改兩個參數 |

**建議 B**。理由：

- 「同一設定不要兩份」針對的是**程式碼裡的字面值**。現在的問題是兩份 `'gemini-3.5-flash-lite'` 字串會漂移；解法是程式內的預設值只寫一次（兩個 key 的預設值引用同一個 Dart 常數），不是強迫兩個功能在執行期永遠用同一個模型。
- 兩個功能「現在剛好用同一個模型」是巧合，不是業務規則。視覺模型與對話模型的最佳選擇本來就會分歧，拆 key 的成本只在第一次建參數時多一筆。
- 下架情境要改兩個參數，是 Console 上的兩次編輯，可接受；不值得為此引入「共用 key + 個別覆寫」這種兩層查找的特殊情況。

### 4.3 In scope

- 新增依賴 `firebase_remote_config`。
- 一個 Remote Config 存取點（位置依既有慣例 `lib/data_layer/datasources/`），對外只暴露上表 5 個型別化 getter，並負責啟動時的 fetch/activate 與非法值回退。
- 兩個 repo 在建立 `GenerativeModel` 時改從上述 getter 取值。
- `main.dart` 在 Firebase 初始化成功後觸發 fetch（不阻塞）；`injection.dart` 註冊存取點。
- 對應單元測試（預設值、非法值回退、repo 取用遠端值）。

---

## 5. 明確不做（Out of scope）

- **金鑰（範圍後續擴充）**：原規格不含金鑰；PR #135 review 期間依使用者決定擴充——Yelp token 與 Static Map key 改由 `AiModelConfig.yelpAuthToken`／`staticMapApiKey` 讀取 Remote Config 的 `yelp_api_auth_token`、`static_map_api_key`，並從 `constants.dart` 移除寫死字串。兩者為必填、預設空字串，Console 未設定時對應功能失效（Yelp 401、地圖縮圖顯示佔位圖）。目的是讓金鑰輪替不必發版。注意 Remote Config 的值會完整下發到 client、可被讀取，不是機密儲存；金鑰已進 git 歷史仍須撤銷輪替，長期仍須走 Server-side Broker。
- **不做 A/B testing／Personalization／條件式參數的程式支援**：Console 端要怎麼設條件是維運者的事，client 只讀 activate 後的值。
- **不做 realtime listener（`onConfigUpdated`）**：本功能的主要情境是調參與模型汰換，下次啟動時觸發 fetch、間隔已到期且成功取得新值後生效已足夠；realtime 會多一條常駐連線與「值在一次 AI 請求中途變動」的語意問題。真的需要秒級止血時再評估。
- **不搬其他常數**：user prompt 模板（`ai_foodie_repo.dart:169` 的指示句、`menu_vision_repo.dart:141` 的提問句）、`responseSchema`、`responseMimeType`、圖片尺寸與品質、候選餐廳上限等都不動。§7.5-2 提到的「Prompt 模板」留待有實際調整需求時再加。
- **不設計介面 + 多實作、不做通用 config 框架**：只有一個實作，就是 Firebase Remote Config。
- 不改 `firebase_core` 等既有 Firebase 套件版本；不改 App Check 設定。

---

## 6. 驗收條件

1. **拿不到遠端值 = 現況**：裝置尚未成功 activate 過遠端值時（首次啟動且 fetch 未成功、離線、fetch 失敗或逾時、Firebase 初始化失敗），5 個 getter 回傳的值與 §4.1 預設值完全相同；兩個 repo 送給 `generativeModel` 的 `model`、`systemInstruction`、`temperature` 與現況逐字一致（拍菜單仍不設 temperature）。若裝置先前已成功 activate 過遠端值，之後 fetch 失敗或未再觸發 fetch 時，getter 會沿用上次 activate 的值，不會自動回退到預設值。
2. **預設值只有一份**：每個參數的預設值在程式碼中只出現一次；`'gemini-3.5-flash-lite'` 字面值在 `lib/` 只出現一次；in-app defaults 與 getter 回退值引用同一組常數，不得各寫一份。
3. **不阻塞啟動**：`runApp` 不等待 fetch 完成；fetch/activate 失敗只記 `Logger().e('<英文訊息>', error: e, stackTrace: st)`，不拋到 `main`、不影響首頁顯示。捕捉範圍為 `on Exception`，不捕捉 `Error`（flutter-styles §6.1）。
4. **生效時機明確**：fetch 並 activate 成功後，**下一次 AI 請求**即使用新值（不需重啟 App）；已送出的請求不受影響。測試需證明：同一個 repo 實例，在存取點回傳值改變後，下一次建立 model 時用的是新值。
5. **型別化 getter**：呼叫端（兩個 repo）只透過具名 getter 取值（如 `aiFoodieModel`、`aiFoodieTemperature`），`lib/` 中 Remote Config 字串 key 只出現在存取點內。
6. **不得快取 model**：`GenerativeModel` 維持每次呼叫時建立（或等效地每次呼叫時讀取設定），不因本功能改為建構時快取。
7. **非法遠端值回退到預設值**（並記 `Logger().w`，訊息英文）：
   - 模型名或 system instruction 為空字串或全空白 → 預設值。全空白記 `Logger().w`；空字串**不記**，因為 `getString` 對「key 不存在」也回傳 `''`，那是 Console 尚未建立參數時的正常狀態，每次 AI 請求都記 warning 只會製造噪音（實作計畫 §9 第 4 點，已確認）。
   - temperature 無法解析為數字、或超出 `[0.0, 2.0]` → 預設值 `0.2`。注意 `getDouble` 對非數字字串會回傳 `0.0`（落在合法範圍內），因此判斷必須基於原始字串或值來源，不能只看 `getDouble` 的結果。
   - 模型名「格式合法但不存在」不在 client 端驗證：會在 `generateContent` 時丟例外，沿用既有路徑處理（AI 覓食助理降級為本地推薦；拍菜單由 BLoC 顯示失敗）。
8. **既有測試不破**：`AiFoodieRepo()`、`MenuVisionRepo(...)` 既有建構方式照常可用，**建構 repo 本身不得觸碰 Firebase**（測試環境沒有初始化 Firebase）；`test/data_layer/ai_foodie_repo_test.dart`、`test/data_layer/menu_vision_repo_test.dart` 及全套既有測試零斷言修改、全綠。
9. **可測性**：存取點與 repo 的取值行為可在不初始化 Firebase 的單元測試中驗證（例如以 `mocktail` 替身注入，專案已有 `mocktail`）。
10. `flutter analyze` 零 issue；`dart format` 無 diff；新增依賴只有 `firebase_remote_config` 一個。

---

## 7. 相依套件版本

- `pubspec.lock`：`firebase_core 4.15.0`、`firebase_ai 4.0.0`。
- pub.dev 查詢（2026-09-27）：`firebase_remote_config` 最新版 `6.7.0`，依賴 `firebase_core: ^4.14.0`、Dart SDK `^3.6.0`、Flutter `>=3.27.0`——與目前 lock 的 `firebase_core 4.15.0`、專案 Flutter 3.35 相容。
- 建議以 `flutter pub add firebase_remote_config` 讓 resolver 選出與現有 FlutterFire 套件一致的版本（預期 `^6.7.0`），**不要**手動指定會迫使 `firebase_core` 升降級的版本。本規格階段未執行 `pub add`。
- iOS 需在 `pod install` 後確認 Firebase iOS SDK 版本與其他 FlutterFire pod 一致（同屬 FlutterFire BoM，正常情況下會一致）。

---

## 8. 風險與待決事項

| # | 項目 | 影響 | 建議／待決 |
|---|---|---|---|
| 1 | **fetch 間隔** | release 設定 `minimumFetchInterval` 為 12 小時：Console 改值後，只有在 App 下一次啟動並觸發 fetch，且間隔已到期時，才可能拿到新值；`minimumFetchInterval` 不會自行排程 fetch | **待決**。建議 release 維持 12h（配額友善），debug（`kDebugMode`）設 `Duration.zero` 方便驗證；`fetchTimeout` 設短（例如 10 秒以內）避免背景請求長時間掛著。若 12h 不能接受，再討論縮短或 realtime |
| 2 | **activate 時機造成同一 session 前後值不同** | 採「fetch 完立即 activate」時，使用者開 App 後的第一次 AI 請求可能用舊值、第二次用新值 | 建議接受（參數本來就是逐次請求讀取，單次請求內一致即可）。替代方案「本次只 fetch、下次啟動才 activate」行為較穩定但生效延遲多一次啟動，**待確認** |
| 3 | **model 快取回歸** | 日後有人為了效能把 `GenerativeModel` 提到建構時快取，遠端值會被凍結在 lazy singleton 首次建立時 | 驗收條件 4、6 的測試鎖住 |
| 4 | **Console 參數需手動建立** | 程式上線後 Console 沒建參數也不會壞（走預設值），但 key 拼錯會**無聲**地一直用預設值 | 上線前在 Firebase Console 建立 §4.1 的 5 個參數（值 = 預設值），key 與程式常數逐字比對；建議把 key 清單寫進 PR 描述作為維運檢查項 |
| 5 | **Firebase 初始化失敗** | `main.dart` 的 `Future.wait` 失敗時 Firebase 未初始化，此時存取 `FirebaseRemoteConfig.instance` 會丟例外 | 存取點取不到 instance 時一律回傳預設值；fetch 只在 Firebase 初始化成功後觸發 |
| 6 | **system instruction 長度** | `ai_foodie` 的 instruction 很長，貼進 Console 容易夾帶多餘空白或換行差異 | 不做正規化（逐字使用）；只擋空字串。Console 編輯後建議在 debug build 驗證一次 |
| 7 | **遠端值可被讀取** | system instruction 會下發到 client | 目前內容本來就編在 App 裡、非機密，無新增風險；日後若經 Remote Config 下發金鑰，須視同公開值處理（§5） |
| 8 | **setDefaults 的必要性** | getter 本身已對空值回退到程式常數，`setDefaults` 在功能上可能是多餘的 | **待決（交計畫階段）**：保留 `setDefaults` 可讓 Console／debug 工具看到一致的預設值；若保留，必須與 getter 回退引用同一組常數（驗收條件 2） |
