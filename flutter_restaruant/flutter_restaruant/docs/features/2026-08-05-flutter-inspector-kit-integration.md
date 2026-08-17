# F-0.1 — 整合 `flutter_inspector_kit` 除錯套件 (Developer Tooling Foundation)

> 功能規格（STAGE 0a：What & Why）
> 出處：`docs/brainstorm/2026-08-18_features_brainstorm.md` §2.0（F-0.1，P-1 最高優先）
> 本文件**不含**實作步驟、逐行異動與任務拆分——那是 STAGE 0b 實作計畫的內容。
> 撰寫日期：2026-08-05
> 基準 commit：`2890610`（branch `main`）

## 定位聲明 (Positioning)

**這不是產品功能，是開發工具。**

終端使用者永遠不會看到它、不會受它影響、不會知道它存在。它的價值不在自身，而在於**讓後續每一個待辦項目的修復都更快、更有證據**——先裝溫度計，再治病。

因此本規格的使用者故事全部是**開發者故事**，不是終端使用者故事；驗收條件的核心也不是「功能可用」，而是「**debug 可用且 release 絕對不存在**」。

---

## 1. 問題陳述 (Problem Statement)

### 1.1 現況：修 bug 全靠猜

專案 `docs/brainstorm/2026-08-18_features_brainstorm.md` §1.2 目前累積 **4 項未解缺陷**（2026-08-05 複測），其中三項的修復與驗證都需要「看得到執行期真實行為」的能力，而現在沒有：

| 缺陷（§1.2） | 現況 | 缺少的量測能力 |
| :--- | :--- | :--- |
| 缺陷 2：硬編碼 API 金鑰 | `lib/features/foundation/constants/constants.dart:30` `staticMapApiKey`、`:41` `authToken` 明碼在版控中（已複驗，行號 30/41） | 無法實地確認送出的 header 內容是否已改由 broker 供給 |
| 缺陷 4：Firestore 單一 Document 全量覆寫 | `FavorDataSource` 仍 `set(..., merge: false)` | 無法觀察寫入量與併發時序 |
| 缺陷 5：硬編碼假延遲 | `main_bloc.dart:56` 過濾 2 秒、`fcm_manager.dart:51` 推播導航 8 秒 | **無法證明 2 秒是多餘的**——沒人知道真實 round-trip 是 200ms 還是 1.8s |
| 缺陷 7：`MapWidget` Marker 未連動 | `map_widget.dart` 無 `didUpdateWidget()` | 無法確認 rebuild 是否真的被觸發 |

目前唯一的觀測手段是 `lib/api/dio/dio_client.dart:24-25` 的 `LogInterceptor(requestBody: true, responseBody: true)`——它把請求與回應**沖進 console 純文字流**，無法搜尋、無法比對兩次請求的差異、無法量測耗時、無法在實機上查看、無法匯出附在問題回報裡。

### 1.2 為什麼排 P-1（先於 P0 安全修復）

**不是因為它比洩漏金鑰更嚴重**，而是因為：

1. **它是後續每一項的量測前提**。移除假延遲之後如果畫面開始閃爍，沒有 timeline 就只能靠猜；有了 timeline 才能指出被 2 秒延遲掩蓋掉的 race condition。
2. **Effort 極低（0.5）**。四個接線點**全部是既有掛載點加行**，零重構——這一點已於下方 §1.3 逐一複驗。
3. **破壞性為零**。全數包在 `kDebugMode` 內，release 行為完全不變。

一個 effort 0.5、破壞性 0、且能讓後面四項缺陷的修復都變得可驗證的項目，排第一是純粹的槓桿計算，不是價值排序。

### 1.3 接線點複驗 (Wiring Points — Re-verified 2026-08-05)

| # | 接線 | 位置（複驗結果） | 現況 |
| :--- | :--- | :--- | :--- |
| 1 | 建立單一 `FlutterInspector` 實例 | `lib/di/injection.dart` | ✅ 專案已用 GetIt（**非 injectable**），`setupInjection()` 內 12 個 `registerLazySingleton`，沿用即可 |
| 2 | Dio 攔截器 | `lib/api/dio/dio_client.dart:24`、`:29` | ✅ 已有 `dio.interceptors.add(...)` 與 `.addAll(...)` 兩處掛載點 |
| 3 | `navigatorObservers` | `lib/main.dart:51` `PlatformApp` | ✅ `PlatformApp` 支援頂層 `navigatorObservers`，Material／Cupertino 兩分支共用；目前**尚未使用**此參數 |
| 4 | 喚起手勢 | `lib/main.dart:79-82` `builder:` | ✅ 既有 `builder:` 層（S1 為跨平台 theme 解析而加，回傳 `Theme(...)` 包 `child`）可直接複用，**無須新增層級** |

**結論：四個接線點全部已存在，本次整合不需要任何前置重構。**

---

## 2. 使用者故事 (Developer Stories)

> 全部是開發者故事。本功能對終端使用者的可感知度為 **零**——這是設計目標，不是妥協。

### DS-1：驗證假延遲確實多餘

> **身為**準備移除 `main_bloc.dart:56` 那 2 秒 `Future.delayed` 的開發者，
> **我希望**能在 App 內直接看到 Yelp 搜尋請求的真實 round-trip 時間，
> **以便**我能用數據證明「這 2 秒是純粹的無謂等待」，而不是憑感覺刪掉別人寫的程式碼。

### DS-2：驗證金鑰已不再隨請求送出

> **身為**要修復 §1.2 缺陷 2（硬編碼 `authToken`）的開發者，
> **我希望**能逐筆檢視實際送出的 request header，
> **以便**在改為 broker 供給後，我能實地確認 header 內容真的變了，而不是只確認程式碼看起來變了。

### DS-3：確認 Marker rebuild 是否真的觸發

> **身為**要修 `MapWidget` 標記未連動的開發者，
> **我希望**能對照 Navigator 事件與 console log 的時序，
> **以便**判斷問題出在「rebuild 沒被觸發」還是「觸發了但 Marker 沒重建」。

### DS-4：實機除錯不必接電腦

> **身為**在實機上重現問題的開發者，
> **我希望**用一個手勢就能在 App 內叫出網路請求列表，
> **以便**我不必為了看一行 log 而回頭接 USB、開 IDE、重跑一次流程。

### DS-5：回報問題時附得上證據

> **身為**要向團隊回報一個難以重現的問題的開發者，
> **我希望**能一鍵匯出含網路與導航 timeline 的診斷報告，
> **以便**接手的人看到的是紀錄而不是我的描述。

---

## 3. 驗收條件 (Acceptance Criteria)

> 分三組：**功能可用**（AC-1～3）、**安全防線**（AC-4～6，🔴 硬性）、**零破壞**（AC-7～10）。
> AC-4～6 任一項不通過，本功能**不得合併**——無論其他項目多完美。

### 3.1 功能可用

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| **AC-1** | Debug build 中可透過套件提供的喚起手勢**或**常駐 FAB 開啟 inspector dashboard（2026-08-05 修訂：使用者要求 FAB 與五連點並存，兩者皆為 debug-only 進入點） | 模擬器／實機 debug build 實跑，執行手勢或點擊 FAB 後 dashboard 皆能顯示 |
| **AC-2** | Dashboard 的 Network 分頁可看到**實際發出的 Yelp 搜尋請求**，含 URL、method、狀態碼、耗時，以及 request／response body | debug build 執行一次餐廳搜尋，於 Network 分頁確認該筆請求存在且欄位完整 |
| **AC-3** | Dashboard 的 Navigator 分頁可看到頁面切換紀錄 | debug build 執行「列表 → 餐廳詳情 → 返回」，確認三筆導航事件被記錄 |

### 3.2 🔴 安全防線（硬性條件）

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| **AC-4** | **Release build 中不存在任何 inspector 進入點**：無喚起手勢、無 FAB、無任何可觸發 dashboard 的路徑（FAB 現為刻意新增的第二 debug-only 進入點，仍受同一 `kDebugMode` guard 約束，故本條驗收範圍不變） | `flutter build` 產出 release 版本並實機安裝，於所有畫面嘗試喚起手勢，並全螢幕檢視確認無 FAB 常駐，確認皆無反應 |
| **AC-5** | **Release build 不註冊 inspector 的 Dio 攔截器與 navigator observer**：不記錄任何請求／回應 body | 檢視 release 路徑的接線是否全數位於 `kDebugMode` 判斷之內 |
| **AC-6** | **Release bundle 經 tree-shaking 移除 dashboard UI** | 對 release 產物驗證 inspector dashboard 相關符號已不存在（具體驗證指令由 STAGE 0b 決定） |

> **AC-4～6 的理由見 §5.1。這是本功能唯一的真實風險，也是唯一不可妥協的驗收面向。**

### 3.3 零破壞

| # | 條件 | 驗證方式 |
| :--- | :--- | :--- |
| **AC-7** | `flutter analyze` 維持 **`No issues found!`** | 現為零警告，**不得回退** |
| **AC-8** | 既有測試檔全綠 | `flutter test` |
| **AC-9** | Release build 的行為與外觀**完全不變** | 整合前後的 release build，主要流程（搜尋、篩選、詳情、最愛、訪客模式）逐一比對 |
| **AC-10** | `dart format` 通過 | — |

---

## 4. 範圍邊界 (Scope)

### 4.1 本次要做 (In Scope)

1. 引入 `flutter_inspector_kit` 相依（pub.dev 最新版 `1.9.0`，MIT 授權）。
2. 接上 §1.3 的**四個既有接線點**：DI 實例、Dio 攔截器、`navigatorObservers`、喚起手勢。
3. 確保上述接線**全部以 `kDebugMode` 圍住**。
4. 完成 §3 全部驗收條件。

**就這四件事。**

### 4.2 🚫 明確不做 (Out of Scope — YAGNI)

| 排除項 | 理由 |
| :--- | :--- |
| ❌ **順便修 §1.2 的既有 P0 缺陷**（硬編碼金鑰、假延遲、Firestore 結構、Marker 未連動） | 這些是**各自獨立的待辦項**，各有各的規格與風險。混進來會讓「零破壞」這條驗收失去意義——出問題時分不清是 inspector 還是缺陷修復造成的。**本功能的價值正是讓那些項目更好修，而不是替它們動手** |
| ❌ **移除既有的 `LogInterceptor`** | `dio_client.dart:24-25` 的 `LogInterceptor` 是否被 inspector 取代，是整合後的**觀察結論**，不是整合的前置動作。留著不衝突 |
| ❌ **套件功能之外的客製化** | 不寫自訂 dashboard 分頁、不改套件的 UI、不包裝抽象層。套件開箱即用的能力已滿足 §2 全部故事。**單一實作的抽象層是純負債** |
| ❌ **為 inspector 本身寫測試** | 它是 debug-only 的第三方工具，不參與產品邏輯。真正需要被驗證的是 AC-4～6（release 不存在），而那靠 build 驗證，不靠單元測試 |
| ❌ **CI 自動化 release 檢查** | AC-6 本次為**人工驗證**。若未來重複發生誤入 release 的疑慮，再考慮自動化 |
| ❌ **調整 inspector 的告警閾值等設定的長期治理** | 先用套件預設值。有具體不合用的情境再調 |

### 4.3 邊界原則

> 這是一個 effort 0.5 的項目。**任何讓它膨脹的提議，都在削弱它「先裝溫度計」的定位。**
> 溫度計裝好就該去量體溫，而不是繼續改造溫度計。

---

## 5. 風險與緩解 (Risks & Mitigation)

### 5.1 🔴 R-1：Inspector 進入 release build，造成機密即時外洩（最大風險）

**風險內容**

`flutter_inspector_kit` 的核心能力是**記錄完整的請求與回應 body**。而本專案 `lib/features/foundation/constants/constants.dart:30`／`:41` 目前**仍有硬編碼的 `staticMapApiKey` 與 `authToken`**（§1.2 缺陷 2，2026-08-05 複驗仍存在）。

兩者相加的後果是**風險等級的躍升，不是疊加**：

| | 目前 | 若 inspector 進入 release |
| :--- | :--- | :--- |
| 洩漏管道 | git 歷史 | **每一台裝了 App 的終端裝置** |
| 需要的能力 | 取得 repo 存取權 | **裝 App、比出一個手勢** |
| 可觀測範圍 | 原始碼中的常數 | **執行期實際送出的 header 與完整回應 body** |

**這會把一個「已知的 P0」放大成「即時、大規模、零門檻」的洩漏。**

**緩解手段**

1. **`kDebugMode` guard 為強制設計約束**：DI 註冊、Dio 攔截器、`navigatorObservers`、喚起手勢、常駐 FAB（2026-08-05 新增），五個接線點**無一例外**必須位於 `kDebugMode` 判斷之內。`kDebugMode` 是編譯期常數，release build 中該分支為 dead code，會被 tree-shaking 移除。
2. **驗收硬條件**：AC-4（release 無進入點）、AC-5（release 不註冊攔截器）、AC-6（release bundle 不含 dashboard UI）為**合併前必過項**，任一不過即不得合併。
3. **實機驗證，非程式碼審閱**：AC-4 必須以**實際安裝的 release build** 驗證，不接受「看程式碼覺得應該沒問題」。
4. **不因此延後缺陷 2 的修復**：本項緩解的是「不讓風險擴大」，**不等於風險已解除**。硬編碼金鑰仍須依 §1.2 缺陷 2 獨立處理（含 revoke & rotate）。

> **殘餘風險（2026-08-05 更新）**：即使 AC-4～6 全過，`kDebugMode` guard 的正確性仍依賴人為紀律。未來新增接線點時可能漏包。**本次不建 CI 防護（§4.2）**。原判斷前提是「接線點只有四個且集中在兩個檔案」——此前提已被打破：新增 FAB 進入點（`lib/flow/splash/view/splash_page.dart`）後現為**五個接線點、四個檔案**（詳見 `docs/plans/...md` §2.5、§3、§5.1）。文件自身設下的「若日後接線點增加，應重新評估」觸發條件已達成：重新評估結論為風險性質不變（仍是同一種「人為紀律」依賴），數量增加不代表控制力下降，`kDebugMode` guard 與 T5 的 `grep` 齊全檢查對每一處新接線點同樣有效。

### 5.2 🟡 R-2：新增傳遞相依帶來的相容性風險

**風險內容**

套件會引入額外相依。**2026-08-05 複驗 `pubspec.yaml` 與 `pubspec.lock` 後，實際狀況比 brainstorm §2.0 的預估樂觀**：

| 相依 | 套件需求 | 本專案現況（複驗） | 判定 |
| :--- | :--- | :--- | :---: |
| `dio` | `^5.2.0` | `pubspec.yaml:30` `^5.6.0` | 🟢 相容 |
| Dart SDK | — | `pubspec.yaml:11` `>=3.5.0 <4.0.0` | 🟢 相容 |
| `flutter_local_notifications` | `^22.0.0` | `pubspec.yaml:65` **已直接安裝 `^22.1.0`** | 🟢 已存在且版本相容（brainstorm §2.0 記為「未安裝」，**應更正**） |
| `web` | `^1.1.0` | `pubspec.lock` 已存在（既有傳遞相依） | 🟢 已存在 |
| `share_plus` | `^13.0.0` | 未安裝 | 🟡 **唯一真正新增的相依** |

**緩解手段**

* 實際只新增 `share_plus` 一個相依，風險面遠小於原估的三個。
* `flutter_local_notifications` 已是直接相依且主版本相同（22.x），版本衝突風險低；若 `pub get` 仍解不開，該衝突會在 STAGE 0b 的第一步就暴露，屬**早期可見的失敗**。
* AC-7／AC-8（analyze 零警告、測試全綠）作為相依引入後的即時回歸信號。

### 5.3 🟢 R-3：Debug build 效能受影響

**風險內容**：攔截與記錄本身有開銷，可能讓 debug 下的操作感覺變慢，干擾對效能問題的主觀判斷。

**緩解手段**：效能量測本就應在 **profile 模式**進行（§6.7 既有驗證規範已如此要求），profile 模式不啟用 `kDebugMode` 分支，不受影響。**不需額外處理。**

### 5.4 🟢 R-4：套件本身的穩定性

**風險內容**：第三方套件可能有 bug 或影響宿主 App。

**緩解手段**：套件設計為「錯誤鉤子鏈接（chain）而非覆蓋（override）」，不劫持宿主的錯誤處理；且所有接線位於 `kDebugMode` 內，**release 使用者零暴露**。最壞情況是 debug 體驗受影響，不影響任何產品行為。若確實不堪用，**移除成本等同於 revert 一個小 PR**。

---

## 6. 成功判準 (Definition of Done)

本功能完成的定義是：

1. §3 全部 10 條驗收條件通過，其中 **AC-4～6 為不可妥協項**。
2. 開發者能在 debug build 中，用一個手勢看到 Yelp 請求的真實耗時——即 **DS-1 可被實際執行**。
3. Release build 的行為、外觀與 bundle 內容，與整合前無可觀測差異。

**不包含**：任何 §1.2 缺陷的修復。那些是本功能交付之後才開始的工作，也正是本功能存在的目的。

---

## 7. 後續銜接 (Follow-up)

本功能交付後，下列項目應**優先**排入，因為它們的驗證能力剛剛才建立起來：

| 後續項目 | 本功能提供的量測能力 |
| :--- | :--- |
| §1.2 缺陷 5：移除假延遲 | Network 分頁可讀出真實 round-trip；移除後若閃爍，timeline 可定位被掩蓋的 race condition |
| §1.2 缺陷 2：硬編碼金鑰 | 可實地確認 header 中的 `authToken` 是否已改由 broker 供給 |
| §1.2 缺陷 7：Marker 未連動 | Navigator 分頁 + Console 對照，確認 rebuild 是否真的觸發 |
| §6.7 S2／S3 視覺改造 | 診斷報告一鍵匯出，回報視覺問題時附得上網路與導航 timeline |

---

## 附錄 A：參考資訊

**套件**：[`flutter_inspector_kit`](https://pub.dev/packages/flutter_inspector_kit)

* 版本：`1.9.0`（2026-08-05 時的 pub.dev 最新版）
* 授權：MIT
* 平台：Android／iOS／Web／Windows／macOS／Linux
* 能力：console log、網路請求攔截（含 replay）、導航追蹤、資料庫監控、診斷報告匯出

**套件公開 API 形貌**（取自套件官方文件，**非本專案的整合方式**——實際接線由 STAGE 0b 決定）：

```dart
final inspector = FlutterInspector(slowRequestThreshold: const Duration(seconds: 3));

MaterialApp(
  navigatorObservers: [inspector.navigatorObserver],
  builder: (context, child) => FlutterInspectorMagicalTap(
    onTap: () => inspector.openDashboard(context),
    child: child ?? const SizedBox.shrink(),
  ),
);

dio.interceptors.add(FlutterInspectorDioInterceptor(inspector, sourceDio: dio));
```

> 此範例僅供理解套件 API 長相。本專案為 `PlatformApp` 而非 `MaterialApp`、DI 走 GetIt、Dio 建立於 `DioClient`，**實際整合形式與 `kDebugMode` 的包法留給 STAGE 0b 實作計畫**。

---

## 附錄 B：複驗紀錄 (Re-verification Log — 2026-08-05)

| 事項 | brainstorm §2.0 原記載 | 本次複驗結果 |
| :--- | :--- | :--- |
| 硬編碼金鑰行號 | `constants.dart:30,40` | `:30`（`staticMapApiKey`）、**`:41`**（`authToken`，原記 `:40` 應更正） |
| Dio 掛載點 | `dio_client.dart:24,29` | ✅ 一致 |
| `PlatformApp` | `main.dart:51` | ✅ 一致，且目前未使用 `navigatorObservers` |
| `builder:` 層 | `main.dart:79` | ✅ 一致（`:79-82`，回傳 `Theme(...)`） |
| DI 機制 | GetIt，非 injectable | ✅ 一致（`lib/di/injection.dart`，12 個 `registerLazySingleton`） |
| 新增傳遞相依 | 3 個（`flutter_local_notifications`、`share_plus`、`web`）皆未安裝 | ⚠️ **應更正為 1 個**：`flutter_local_notifications ^22.1.0` 已直接安裝於 `pubspec.yaml:65`、`web` 已存在於 `pubspec.lock`，**僅 `share_plus` 為新增** |
