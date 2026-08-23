# 餐廳探索與訂位 Flutter App 專案審計、競品對標與全方位創新功能提案報告
# (Restaurant Exploration Flutter App Audit, Benchmarking & Feature Ideation Master Report)

---

## 摘要 (Executive Summary)

本報告針對 `Finding-Restaurant-Flutter/flutter_restaruant` 專案進行深度的程式碼稽核 (Codebase Audit)、架構缺陷評估 (Linus Taste Rating)、全球與區域頂尖競品對標 (Competitor Benchmarking)，並提出涵蓋**空間地圖互動 (Spatial UX)**、**情境化社群 (Community & Context)**、**微訂位閉環 (Micro-Booking Engine)** 以及 **AI 個人化決策 (AI Taste & Multimodal Vision)** 的全方位創新功能與既有缺陷修復方案。

本報告整合了架構審計與競品探索報告之事實與推理鏈，產出符合產業界最高標準的產品與技術發展路線圖 (Strategic Product Roadmap) 及 RICE / ICE 雙優先級評估矩陣。

---

## 📌 實查校正紀錄 (Codebase Re-verification — 2026-08-05)

本次以直接檢視 `lib/` 當前程式碼（branch `main` @ `f643502`）校正既有記載與實況的落差。驗證基準：`flutter analyze` → **`No issues found!`**（維持零警告）。

**新增一項待開發項目（依需求指定最高優先）**

| 項目 | 優先級 | 說明 |
| :--- | :---: | :--- |
| ✅ **整合 `flutter_inspector_kit`**（見 **§2.0 F-0.1**）— **已於 2026-08-05 完成** | **P-1（先於所有既有項目）** | pub.dev `1.9.0`，`dio ^5.2.0` 與本專案 `^5.6.0` 相容。⚠️ 需求原文為 `flutter_inspect_kit`，pub.dev 查無，**正確名為 `flutter_inspector_kit`**。必須以 `kDebugMode` 圍住，否則會把含 `authToken` 的請求 body 暴露給終端使用者。**落地補充**：安裝時需將 Dart SDK 下限由 `3.5.0` 上修至 `3.10.1`；實際接線 5 處／4 檔（原估 4 處）|

> 連帶調整：§3 RICE 表新增一列並將原排名 5～16 順延為 6～17；§4 Roadmap Phase 1 進度改記 9/13；§6.9 Phase 1.5 順序表新增 P-1 前置段。

**四項實查更正（未新增／未否決任何既有項目）**

**四項更正（已就地寫入各章節）**

| # | 章節 | 原記載 | 實查結果 |
| :--- | :--- | :--- | :--- |
| C-1 | §6.5 破壞性評估 | `RatingHelper` **2 處**呼叫 | **3 處** —— 漏計 `restaurant_comment_cell.dart`，S2 effort 上修 |
| C-2 | §S1 覆核 / §6.7 T-9 | 硬編 `appPrimary` **16 處／7 檔** | **19 處／8 檔** |
| C-3 | §6.6.3 列表頁 | `FilterTagsWidget` 待改 `colorScheme.primary` | ✅ **已完成**（`filter_tags_widget.dart:62`），S1 掛 theme 時順帶生效 |
| C-4 | §1.2 缺陷 2、5 | 路徑 `lib/utils/constants.dart`、`fcm_manager.dart:53` | 路徑改為 **`lib/features/foundation/constants/constants.dart`**（§6.4 A-1 已解散 `lib/utils/`）；行號更正為 `:51` |

**複測吻合、未漂移者**（毋須更正）

| 項目 | 記載 | 複測 |
| :--- | :--- | :--- |
| T-2 裸 `Colors.xxx` | 33 處／13 檔 | ✅ 一致 |
| T-3 `@Deprecated` 字級常數 | 10 個常數、29 處使用、14 檔 | ✅ 一致 |
| P0 三項（API Key／假延遲／`didUpdateWidget`） | 全未修 | ✅ 一致，全數仍未修 |
| §1.2 缺陷 4 Firestore 單 doc 覆寫 | 未修 | ✅ `favor_data_source.dart:23,81` 仍 `merge: false` 全量覆寫 |
| S2 產物 `RatingStars` / `RestaurantListSkeleton` | 未建立 | ✅ 全 `lib/` 查無 |
| Phase 1.5 三項（Carousel／fluster／情境標籤） | 未動工 | ✅ 無 `PageController`、`pubspec.yaml` 無 `fluster` |

> **教訓（供後續 effort 估計參考）**：本次兩處數字更正（C-1、C-2）**皆往低估方向偏**，且都偏在「動到的既有使用點數量」而非「要寫的新程式碼」。C-4 更是整批路徑過時 —— **照舊路徑 grep 會查無，容易誤判成「已修」**。往後標 trivial／low 的項目，動工前先重 grep 一次使用點。

---

## 📌 進度覆核摘要 (Progress Review — 2026-08-19 更新)

初版報告產出於 2026-07-26，歷經多次迭代覆核。本次依 2026-08-19 實際落地的變更（PR #70, v1.5.0+31）覆核全文。**覆核方式為直接檢視當前程式碼，而非採信 commit 訊息**。

**✅ 已落地（16 項）**

| 項目 | 驗證依據 |
| :--- | :--- |
| 修復 `build()` 側邊效應 | Event 已移入 `initState()` / `BlocListener` |
| 修復 Yelp 分頁 `offset` | `main_repo.dart:56,70` 改為筆數累加 |
| 修復 `FilterPage` 狀態重置 | 改用 `didChangeDependencies` + `_isInit` |
| 目錄分層 (Domain / Data) | 新增 `domain/`、`data_layer/`、`di/` |
| 導入 DI | `get_it: ^8.0.0`（未用 `injectable`） |
| DTO 與 Domain Entity 分離 | `RestaurantEntity` / `UserEntity` 取代 legacy model |
| 常數清理與 Lint 嚴格化 | `flutter analyze` → `No issues found!` |
| 側選單順序調整 | 設定已移至末位 |
| 訪客模式 Guest Mode | 規劃外新增，PR #56 |
| **Firestore Subcollection 口袋名單** | ✅ **已於 2026-08-19 完成 (PR #70)**，消除 1MB 限制與併發覆寫 |
| **Android Kotlin 版本升級 (2.2.20)** | ✅ **已於 2026-08-19 完成**，消除 Flutter 3.44.1 的 Kotlin 版本過舊警告 |
| **移除無謂假延遲 (2s / 8s)** | ✅ 實查程式碼確認已清理，僅保留啟動頁 3s |
| **MapWidget 實作 didUpdateWidget** | ✅ 實查 `map_widget.dart` 已實作 |
| **列表載入骨架屏 (Shimmer)** | ✅ 實查 `skeleton.dart` 已實作並廣泛使用 |
| **列表底部載入更多動畫** | ✅ 實查 `restaurant_info_list_widget.dart` 已實作 |
| **RatingStars 評分星等元件 (取代 11 張 PNG)** | ✅ 實查 `rating_stars.dart` 已實作並接線，PNG 與 `RatingHelper` 已移除 (PR #73 驗證) |
| **iOS UIScene Lifecycle 支援遷移** | ✅ **已於 2026-08-23 完成**，正確掛載 `FlutterSceneDelegate` 並保留原生推播委派 |

**🔴 仍未解決與新納入阻擋項（6 項，全數為 P0 最高優先）**

| 項目 | 現況 | 風險 / 影響 |
| :--- | :--- | :--- |
| **Flutter SDK 版本遷移 (≥ 3.44.1)** | 目前位於 `3.41.9` / Dart `3.11.5` | 缺少最新效能優化、第三方套件相容性限制，需升級至最新 stable |
| **iOS Swift Package Manager (SPM) 遷移** | 目前透過 `pubspec.yaml` 暫時關閉 SPM 回退 CocoaPods | **官方強制性遷移**：CocoaPods 即將唯讀且 Firebase 停止 CocoaPods 發布，Flutter 未來將移除關閉 SPM 選項，需等待/升級套件相容後完成全面遷移 |
| **Android Built-in Kotlin 遷移** | 已升級 Kotlin 2.2.20 消除過舊警告，但仍使用顯式 KGP | **官方棄用警告**：Flutter 未來將強制推行 Built-in Kotlin 並移除 KGP 支援，需在未來升級中徹底移除顯式 KGP 依賴 |
| **硬編碼 API Key** | 僅改名為 `camelCase`，明碼仍在 `constants.dart:30,40` | 金鑰已入 git 歷史，須**撤銷並輪替**，非搬移可解 |
| **修復地圖模式定位按鈕遮擋問題** | 地圖右下角 FAB 會被列表卡片遮擋 | 嚴重影響地圖操作體驗（按鈕完全無法點擊） |
| ✅ **修復地圖底部列表 UI 溢出 (RenderFlex overflow)** | ~~Android 地圖底部發生溢出~~ | **已於 PR #73 修復**（實際位置為 `restaurant_item_cell.dart`，非 `rating_stars.dart`） |

> **判斷**：架構地基已完成最關鍵的資料層重構（Subcollection）。但 **iOS UIScene Lifecycle 遷移**、**iOS SPM 遷移**、**Android Built-in Kotlin 遷移** 與 **Flutter SDK 升級** 關係到未來的平台相容性與可建置性，已與安全性（API Key）一同提升至 **P0 絕對最高優先序**。

---

## 1. 專案現狀審計與同類競品對標 (Codebase Audit & Competitor Analysis)

### 1.1 Flutter 專案現狀點評 (Project Architecture Review)

`flutter_restaruant` 專案（版本 v1.4.0+30，基於 Dart SDK `^3.5.0` 及 Flutter 3.x）為一款具備完整雛形的餐廳搜尋與瀏覽應用程式。經 2026-07-26 至 07-30 的 Clean Architecture 對齊重構後，目錄已從單純 Feature-First 演進為 **Feature-First + 分層 (Domain / Data)** 架構：

```
lib/
├── api/          # Retrofit (APIClz) + Dio (DioClient) 網路介面層，對接 Yelp Fusion API v3 & Google Static Maps
├── component/    # 跨頁面 UI 元件 (Ad, Restaurant Item Cell, Skeleton/Loading Widget, Platform Widgets)
├── data_layer/   # 【新增】資料層實作 (datasources/ 資料源、dto/ 網路模型、repositories/ Repo 實作)
├── di/           # 【新增】get_it 依賴注入容器註冊
├── domain/       # 【新增】業務層 (entities/ 領域實體、repositories/ 抽象介面契約)
├── extension/    # 【新增】Dart extension 工具擴充
├── flow/         # Feature-First 業務流 (8大 Flow: splash, signinup, main, restaurant, favor, filter, photo_viewer, settings)
├── gen/          # flutter_gen 自動生成顏色資源 (ColorName.appPrimaryColor 等)
├── generated/    # i18n 國際化生成程式碼 (ARB 檔: intl_en.arb, intl_zh_TW.arb)
├── l10n/         # 【新增】ARB 語系原始檔
├── manager/      # 核心門面元件 (SignInManager 整合 Firebase Auth/Third-party/Biometric; FcmManager 推播管理)
├── model/        # 殘餘資料模型 (FilterConfigs 等；legacy DTO 已遷出至 data_layer/dto)
├── routes/       # 靜態路由表 (搭配 flutter_platform_widgets，Bloc 改由 get_it 解析)
└── utils/        # 常數與工具庫 (constants.dart, dimens.dart, rating_helper.dart, utils.dart)
```

#### 關鍵依賴與技術棧 (Tech Stack & Dependencies)
* **狀態管理 (State Management)**: `flutter_bloc: ^9.1.1` + `bloc: ^9.2.1`，配合 `rxdart: ^0.28.0` 與 `event_bus: ^2.0.0`。
* **依賴注入 (DI)**: `get_it: ^8.0.0`（2026-07-27 導入，未採用 `injectable` 程式碼生成，改為手寫註冊）。
* **網路與 API**: `dio: ^5.6.0` + `retrofit: ^4.2.0`。
* **資料庫與持久化**: `sqflite: ^2.3.0` (SQLite 本地快取)、`cloud_firestore: ^6.7.1` (遠端資料)、`shared_preferences: ^2.2.0`。
* **身分驗證與雲端**: `firebase_auth: ^6.5.6` (支援 Google, Apple, Facebook, Email、生物辨識 Auto-login 及**訪客模式 Guest Mode**)。
* **地圖與廣告**: `google_maps_flutter: ^2.4.0` 與 `google_mobile_ads: ^9.0.0`。

---

### 1.2 重大架構缺陷與 Linus 模式品味評估 (Linus Taste Rating & Architecture Assessment)

#### 🐧 品味評級

| 時間點 | 評級 | 依據 |
| :--- | :--- | :--- |
| 2026-07-26（初次稽核） | 🔴 **垃圾 / 嚴重架構缺陷** | 7 大缺陷全數存在，無分層、無 DI |
| 2026-07-30（重構後覆核） | 🟡 **湊合 (Mediocre)** | 生命週期與分頁缺陷已清除，分層／DI 到位；但金鑰、Firestore 結構、假延遲三項未解 |

> **Linus Torvalds 式核心評語（2026-07-26 初次稽核）**：
> 「這程式碼缺乏對 Flutter 生命週期的基本尊重。在 `build()` 渲染方法裡發動非同步 Side-effects 和 API 請求，就像是在開車時把煞車當油門踩——每一次 UI 重新繪製都會觸發重複的 API 網路請求與狀態變動！好程式員關注資料結構與邊界情況；把整個最愛列表打包成 JSON 字串塞進單一 Firestore 文件，還用 `merge: false` 每次全量覆蓋，簡直是資料庫設計的災難。更別提在搜尋過濾裡硬塞 2 秒 `Future.delayed` 和在推播導航硬塞 8 秒延遲這種假裝程式很忙的神祕邏輯。這種爛程式碼必須被徹底撕掉重寫。」

> **重構後覆核評語（2026-07-30）**：
> 「生命週期的問題修對了——Event 回到 `initState()`，`FilterPage` 用 `didChangeDependencies` + 旗標只初始化一次，`build()` 終於是純函式。分頁的 `offset` 從『把筆數當頁碼』改成正確的累加，這是把錯誤的資料語意修正，不是加 if 打補丁，有品味。導入分層與 DI 讓依賴可以被 Mock，13 個測試檔與 `flutter analyze` 零警告是實打實的證據。
>
> 但別急著慶功。**金鑰還在版控裡明碼躺著**——把 `AUTH_TOKEN` 改名成 `authToken` 不叫修復，叫換個姿勢繼續裸奔，而且既然已經進過 git 歷史，光搬走也沒用，得撤銷重發。**Firestore 那坨 JSON 大字串還在單一 Document 裡用 `merge: false` 全量覆寫**——資料結構錯了就是錯了，包一層 `FavorDataSource` 只是把災難換了個資料夾放。還有那 2 秒和 8 秒的假延遲，程式碼沒事幹就別裝忙。
>
> 從垃圾爬到湊合是進步，但剩下這三項不是風格問題，是會噴錢和掉資料的問題。」

#### 7 大致命程式碼缺陷詳解 (Detailed Code Defects)

> **⚠️ 修復進度更新 (2026-07-30 覆核)**：下列缺陷經 07-27～07-30 重構後，**5 項已修復、2 項仍存在**。各項狀態已於標題標註，內文保留原始稽核紀錄以供追溯。覆核方式為直接檢視當前程式碼，非依賴 commit 訊息。

1. **✅ 已修復 — `build()` 方法中發動 Event / 非同步側邊效應 (Anti-pattern: Side-effects in build)**
   * **現況**：`sign_in_page.dart:37`、`main_page.dart:49-50`、`favor_page.dart:32`、`settings_page.dart:33` 的初始化 Event 皆已移入 `initState()`；`restaurant_detail_page.dart:38` 移入 `BlocListener` 回呼。原始缺陷紀錄如下：
   * `lib/flow/signinup/view/sign_in_page.dart:40`: `this._signInBloc.add(AutoSignInEvent());` 直接寫在 `build()` 頂層，每次重繪皆重新引發 AutoSignIn。
   * `lib/flow/main/view/main_page.dart:103`: 在 `BlocBuilder` 內部執行 `this._mainBloc.add(FetchSearchInfo(...));`。
   * `lib/flow/restaurant/view/restaurant_detail_page.dart:49, 83-84`: 在 `build()` 觸發 `FetchDetailInfo`，且當 `state is ToggleFavorSuccess` 時直接彈出 Toast 並重複觸發 `FetchDetailInfo`。
   * `lib/flow/favor/view/favor_page.dart:36`: `build()` 內直接呼叫 `this._favorBloc.add(FetchFavorInfoEvent(false));`。
   * `lib/flow/settings/view/settings_page.dart:36`: `build()` 內發動 `InitBioAuthSettingEvent()`。
   * `lib/flow/splash/view/splash_page.dart:16-20`: 在 `build()` 內寫入 `addPostFrameCallback` 搭配 `Future.delayed(Duration(seconds: 3))` 導航。

2. **🔴 仍未修復 — 硬編碼 API 金鑰與敏感 Token (Hardcoded Secrets)**
   * **現況（2026-08-05 複測，仍未修）**：金鑰僅隨常數改名為 `camelCase`，**明碼仍留在版控中**。⚠️ **路徑已變更** —— 因 §6.4 A-1 解散 `lib/utils/`，現位於 **`lib/features/foundation/constants/constants.dart:30`** 的 `staticMapApiKey` 與 `:40` 的 `authToken`，皆未移除。（照舊路徑 `lib/utils/constants.dart` grep 會查無，勿誤判為已修）此為當前**唯一未解的 P0 安全風險**，且既有金鑰已外洩於 git 歷史，修復時必須同步「撤銷並輪替 (revoke & rotate)」，僅搬移位置無效。
   * 原始稽核紀錄：`constants.dart:37` `AUTH_TOKEN` (Yelp Fusion Token)、`constants.dart:27` `STATIC_MAP_API_KEY` (Google Maps Key)。

3. **✅ 已修復 — Yelp 分頁邏輯錯誤 (`MainRepository` → `MainRepo`)**
   * **現況**：邏輯已遷至 `lib/data_layer/repositories/main_repo.dart`，改為 `offset: _offset`（`:56`）搭配成功後 `_offset += _maxItemsCountInList`（`:70`），偏移量語意正確。
   * 原始缺陷：舊 `main_repository.dart:52` 傳入 `offset: ++this._offset`，將筆數偏移量誤當頁碼，導致分頁幾乎完全重複。

4. **✅ 已修復 — Firestore 最愛店家單一 Document Map 覆寫 (Database Architecture Defect)**
   * **現況（2026-08-19 覆核）**：已重構為 Subcollection 結構（`favors/{uid}/items/{restaurant_id}`）。不再依賴全量下載與上傳，1MB 上限與併發寫入覆蓋風險已解除，並包含無痛向後相容遷移機制。

5. **🔴 仍未修復 — 硬編碼人工假延遲 (Hardcoded Fake Delays)**
   * **現況（2026-08-05 複測，仍未修）**：三處延遲全數保留 —— `main_bloc.dart:56` 過濾 2 秒、`fcm_manager.dart:51`（行號更正，原記 `:53`）推播導航 8 秒、`splash_page.dart:22` 啟動頁 3 秒。啟動頁延遲屬品牌曝光的合理設計，但過濾與推播導航的延遲純屬無謂等待，應移除。

6. **✅ 已修復 — `FilterPage` UI 狀態被覆蓋重置 Bug (State Reset Bug)**
   * **現況**：`lib/flow/filter/view/filter_page.dart:27-36` 已改為在 `didChangeDependencies()` 搭配 `_isInit` 旗標僅初始化一次，`build()` 回歸純淨。使用者調整條件不再被舊參數覆寫。

7. **🟡 部分修復 — `MapWidget` 標記未連動與常數品質 (Map & Code Quality Defects)**
   * **✅ 常數錯字已修**：`CONNECTION_TIEMOUT` / `RECEIVE_TIEMOUT` / `EMAIL_SUBJEC` 已更正並改為 `connectionTimeout` / `receiveTimeout` / `emailSubject`。
   * **✅ 風險 `operator ==` 已移除**：`YelpRestaurantSummaryInfo` 已由 `RestaurantEntity` 取代，`id!.compareTo()` 的 null crash 風險消失。
   * **🔴 Marker 未連動仍存在**：`lib/flow/main/view/map_widget.dart` 至今未實作 `didUpdateWidget()`，Marker 僅於 `initState()`（`:22-35`）建立。搜尋或過濾更新列表時，地圖標記仍停留在初始狀態。

---

### 1.3 競品功能對標 (Competitor Feature Benchmarking)

針對四大類全球與區域頂尖產品進行深度解構：

#### 1. Google Maps (動態地圖探索與導航整合)
* **核心 UX 機制**:
  * **動態鏡頭加載 (Dynamic Viewport Bounds)**: 拖移地圖時觸發 `onCameraIdle` / 邊界非同步請求。
  * **圖標動態聚類 (Clustering)**: 高 Zoom 展示品牌 Icon/星級；低 Zoom 自動聚類為數字圈並伴隨平滑解散動畫。
  * **雙向連動 Snap Sheet**: `DraggableScrollableSheet` + `PageView` 卡片 Carousel 雙向同步（點 Pin 平移 Carousel；滑 Carousel 平移地圖相機）。
  * **即時人潮熱度 (Live Popular Times)**: 每小時熱門趨勢疊加「Live」紅色即時擁擠度。
* **參與度迴圈與轉化漏斗**:
  * **探索迴圈**: 地圖瀏覽 $\rightarrow$ 點 Pin/晶片 $\rightarrow$ 即時人潮/評價 $\rightarrow$ 一鍵導航/預訂 $\rightarrow$ 離店在地嚮導評分/上傳照片 $\rightarrow$ 點數徽章.
  * **轉化漏斗**: 區域展示 (100%) $\rightarrow$ 篩選晶片精準鎖定 (60%) $\rightarrow$ 地點卡片查看 (35%) $\rightarrow$ 路線/電話/訂位 (15% 高意圖轉化).

#### 2. OpenTable & Inline (線上訂位引擎與候位管理)
* **核心 UX 機制**:
  * **即時空位時段選擇器 (Real-time Availability Slot Picker)**: 「人數」+「日期」+「時間」三軸動態 Time Slot Chips (`18:00`, `18:30`, `19:15`)。
  * **訂金預扣 (Deposit Handling & Auth-Hold)**: 整合 Apple Pay / Google Pay / Stripe，熱門時段或高檔餐廳需預扣保證金，減少 No-show 損失。
  * **線上候位與動態隊列 (Real-time Queue Tracking)**: 遠端取號，顯示前方組數與預估時間，透過 FCM 推播與 SMS 提醒報到。
* **參與度迴圈與轉化漏斗**:
  * **預訂迴圈**: 搜尋餐廳 $\rightarrow$ 選擇時間人數 $\rightarrow$ 輸入資料/預付款 $\rightarrow$ 行事曆同步/導航提醒 $\rightarrow$ 用餐後評價 $\rightarrow$ 累積紅利點數.
  * **轉化漏斗**: 詳情頁 (100%) $\rightarrow$ 時間人數 (45%) $\rightarrow$ 鎖定 Time Slot (25%) $\rightarrow$ 完成個人資料 (18%) $\rightarrow$ 完成訂位/預訂金 (12%).

#### 3. 大眾點評 & 小紅書 (社群美食地圖與探店筆記)
* **核心 UX 機制**:
  * **情境化標籤 (Situational Scenarios)**: 拋棄傳統單一菜系，強調 `#一人食` `#約會餐廳` `#深夜食堂` `#寵物友善` `#帶爸媽吃` `#景觀酒吧`。
  * **雙排瀑布流 (Masonry Grid UGC)**: 圖文筆記與 15 秒探店短影片，內嵌點擊可展開導航與優惠券的「地點打卡 Tag」。
  * **權威排行榜與社群共編**: 「黑珍珠指南」、「必吃榜」；自訂「台北必吃拉麵地圖」點陣圖分享與共編。
* **參與度迴圈與轉化漏斗**:
  * **種草迴圈**: 滑動瀑布流筆記 (種草) $\rightarrow$ 收藏至美食地圖 $\rightarrow$ 到店消費打卡 (拔草) $\rightarrow$ 發布圖文短影音 $\rightarrow$ 獲得點贊/等級提升.
  * **轉化漏斗**: 筆記曝光 (100%) $\rightarrow$ 點擊筆記 (40%) $\rightarrow$ 點擊地點 Tag (20%) $\rightarrow$ 購買團購券/預訂 (10%) $\rightarrow$ 下單結帳 (4-6%).

#### 4. Niche AI Food Apps (Bready, TasteSeeker, DineAI)
* **核心 UX 機制**:
  * **AI 多模態菜單 Vision 翻譯 (AI Multimodal Menu Vision)**: 拍攝紙本菜單，自動翻譯並標註食材、過敏原 (Gluten-free, Vegan)、辣度與熱量。
  * **個人風味配對度 (Flavor Profile Matching)**: 建立味覺檔案，計算每家餐廳 「98% 味蕾配對度 (Match Score)」與個人化推薦理由。
  * **自然語言選店助手與轉盤 (AI Meal Decision Helper & Wheel)**: 支援模糊對話（例：「想找中山區 500 元以內、安靜可以聊天的日式串燒」）與輪盤抽籤/二選一 Swipe卡片。
* **參與度迴圈與轉化漏斗**:
  * **AI 輔助決策迴圈**: 輸入困境/上傳菜單 $\rightarrow$ AI 輸出對配理由 $\rightarrow$ 體驗反饋 $\rightarrow$ 微調 AI 味覺模型 $\rightarrow$ 下次決策更精準.
  * **轉化漏斗**: 啟動 AI 助手 (100%) $\rightarrow$ 產生 3 家精準推薦 (80%) $\rightarrow$ 查看解析與配對理由 (50%) $\rightarrow$ 前往訂位/導航 (25%).

---

### 1.4 白地機會矩陣 (White Space Matrix)

| 功能維度 | Google Maps | OpenTable / Inline | 大眾點評 / 小紅書 | Niche AI Food Apps | 典型 Flutter 模板 (`flutter_restaruant`) | **Flutter 升級白地機會 (White Space Opportunities)** |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **地圖與空間探索** | ⭐⭐⭐⭐⭐ (動態叢集/連動) | ⭐⭐ (基本地圖) | ⭐⭐⭐⭐ (地圖打卡) | ⭐⭐⭐ (地圖探索) | ⭐⭐ (固定 Pin) | **地圖與 BottomSheet 雙向動態平滑連動 Carousel + fluster 高效能聚類** |
| **訂位與候位閉環** | ⭐⭐⭐ (第三方導流) | ⭐⭐⭐⭐⭐ (即時時段/預扣/排隊) | ⭐⭐⭐⭐ (團購/預約) | ⭐ (無) | ❌ (僅顯示電話) | **輕量化即時空位 Time-Slot 預訂選擇器 + FCM 動態隊列追蹤** |
| **社群與情境標籤** | ⭐⭐⭐ (收藏清單) | ⭐ (無) | ⭐⭐⭐⭐⭐ (UGC瀑布流/情境標籤) | ⭐⭐ (個人社群) | ⭐ (僅傳統分類) | **情境化標籤 (#一人食 #深夜食堂) + 社群共編美食地圖與打卡 Tag** |
| **AI 智慧決策** | ⭐⭐ (AI摘要) | ⭐ (無) | ⭐⭐ (內容推薦) | ⭐⭐⭐⭐⭐ (菜單Vision/配對度) | ❌ (無) | **AI Vision 多模態菜單翻譯 + 個人 0-100% 味蕾配對度 + 對話選店轉盤** |

---

## 2. 全方位創新功能提案與既有 UX 優化 (Comprehensive Feature Ideation & UX Optimization)

### 2.0 開發者工具地基：整合 `flutter_inspector_kit` (P-1，最高優先) — ✅ 已於 2026-08-05 完成

> **定位**：這**不是產品功能，是修其他所有項目時的量測工具**。排在最前面的理由不是它最有價值，而是**它讓後面每一項都更快、更有證據**——先裝溫度計，再治病。

#### F-0.1 整合 `flutter_inspector_kit` 除錯套件

* **套件**：[`flutter_inspector_kit`](https://pub.dev/packages/flutter_inspector_kit) — pub.dev 已發布，**最新版 `1.9.0`**，MIT 授權，支援 Android／iOS／Web／Windows／macOS／Linux 全平台。
* **⚠️ 名稱更正**：需求提及的 `flutter_inspect_kit` 於 pub.dev **不存在**；正確套件名為 **`flutter_inspector_kit`**（`inspector`，非 `inspect`）。

**相依相容性（2026-08-05 實查 `pubspec.yaml`）**

| 項目 | 套件需求 | 本專案現況 | 判定 |
| :--- | :--- | :--- | :---: |
| `dio` | `^5.2.0` | `^5.6.0` | 🟢 相容 |
| Dart SDK | Flutter 套件 | 原 `>=3.5.0 <4.0.0` | 🟡 **實際安裝時需上修至 `>=3.10.1`**（套件傳遞相依要求），已於本次一併調整 |
| 新增傳遞相依 | `flutter_local_notifications` `^22.0.0`、`share_plus` `^13.0.0`、`web` `^1.1.0` | 皆未安裝 | 🟡 新增 3 個傳遞相依 |

**接線點（實際落地為 5 處／4 檔，與原估的 4 處有出入）**

| # | 接線 | 規劃位置 | 實際落地 |
| :--- | :--- | :--- | :--- |
| 1 | 建立單一 `FlutterInspector` 實例 | `lib/di/`（沿用 GetIt 註冊） | `lib/di/inspector.dart` —— **改用頂層 `final FlutterInspector?`**，`kDebugMode ? ... : null`，未走 GetIt（release 恆為 `null`，引用點成為 dead code 被 tree-shaking 移除，比 GetIt 註冊更能保證 AC-9） |
| 2 | Dio 攔截器 | `lib/api/dio/dio_client.dart:24,29` | `lib/api/api_clz.dart` —— 掛載點實際在此檔，**排在既有 auth `InterceptorsWrapper` 之後**，確保攔得到已注入 header 的請求 |
| 3 | `navigatorObservers` | `lib/main.dart:51` `PlatformApp` | 同規劃，`PlatformApp` 頂層掛載 |
| 4 | 喚起手勢（5 連點） | `lib/main.dart:79` `builder:` | 同規劃包 `FlutterInspectorMagicalTap`；⚠️ 但 `onTap` **不可用 builder 的 `context`**（位於 Navigator 之上，`showGeneralDialog` 解析不到 `NavigatorState`），改由 `navigatorKey.currentContext` 取得 |
| 5 | **常駐 FAB（`attach()`）** | *（原未規劃）* | `lib/flow/splash/view/splash_page.dart` —— 套件另一進入點，與 5 連點並存。需用路由 widget 自身的 `context`（已在 Overlay 之下）才找得到 `Overlay` |

**🔴 必要防線：絕不可進 production build**

此為除錯工具，**必須以 `kDebugMode` 圍住**，否則等同把完整網路請求／回應 body（含 `authToken`）暴露給終端使用者——**會讓 §1.2 缺陷 2 的金鑰外洩風險從「git 歷史」擴大到「線上 App」**。

* 攔截器、observer、FAB 掛載一律包 `if (kDebugMode)`；
* 驗收時須確認 release build 的 bundle 不含 dashboard UI（tree-shaking 生效）。

**為什麼排 P-1（先於 P0 安全修復）**

不是因為它比洩漏金鑰更嚴重，而是**它是後續每一項的量測前提**，且 effort 極低（0.5）：

| 後續項目 | 裝了它之後 |
| :--- | :--- |
| §1.2 缺陷 5 移除假延遲 | Network tab 直接看出**真實 round-trip 時間**，證明 2 秒延遲純屬多餘；移除後若閃爍，timeline 能指出被掩蓋的 race condition（§6.6 破壞性評估正是要求驗這件事） |
| §1.2 缺陷 3 Yelp 分頁 | 逐筆檢視 `offset` 參數與回傳筆數，分頁重複與否一眼可見 |
| §1.2 缺陷 7 Marker 未連動 | Navigator tab + Console 對照，確認 rebuild 是否真的觸發 |
| §1.2 缺陷 2 API Key | 可實地確認 header 中的 `authToken` 是否已改由 broker 供給 |
| S2／S3 視覺改造 | 診斷報告一鍵導出，附網路與導航 timeline，回報視覺問題時附得上證據 |

* **Effort**: 0.5（實際 5 個接線點／4 檔，全部是既有掛載點加行，無重構——估計吻合）
* **破壞性評估**: 🟢 —— 全數包在 `kDebugMode` 內，release 行為零改變；套件本身設計為「絕不破壞宿主 App」（錯誤鉤子鏈接而非覆蓋）
* **驗收**: ✅ `flutter analyze` 維持 `No issues found!`；`flutter test` 54/54 通過
* **落地後補充（2026-08-05）**：
  * 啟用 `showNetworkNotification`／`captureUncaughtErrors`／`captureLifecycleEvents`，並設 `redactSensitiveData: false`（僅影響匯出／分享／複製路徑，畫面顯示本就不遮蔽）。全在 `kDebugMode` 分支內，不影響 release 零改變的結論。
  * ⚠️ **`captureUncaughtErrors` 會在建構子內即時改寫三個全域 error hook**（`FlutterError.onError`／`PlatformDispatcher.onError`／`ErrorWidget.builder`）。`test/app_theme_platform_test.dart` 是全專案唯一 mount 真實 App 的測試，`flutter_test` 會比對 `pumpWidget` 前後的 `ErrorWidget.builder`，故該測試需在 `try/finally` 內自行復原三個 hook——**`tearDown()` 太晚，救不了**。日後若有新測試 mount 真實 App，同樣要處理。

---

### 2.1 搜尋與地圖體驗 (Map & Spatial Search)

#### F-1.1 情境化探索標籤 (Situational Filter Chips)
* **設計理念**: 替代「拉麵」、「美式」等硬性菜系分類，頂部採用水平滾動情境 Chips：`#一人食` `#深夜食堂` `#約會不踩雷` `#寵物友善` `#景觀酒吧` `#帶爸媽吃` `#氣氛安靜好工作`。
* **技術實現**: 在 `FilterConfigs` 擴充 `situationalTags` List，與 BLoC 的 `FilterChangedEvent` 連動，動態過濾本地 SQLite 與 Yelp/Google API 結果。

#### F-1.2 地圖與 BottomSheet 雙向平滑連動卡片 (Bi-directional Map Carousel Sync)
* **設計理念**: MainPage 底層為全螢幕 `GoogleMap`，上層疊加可展開之 `DraggableScrollableSheet` 及橫向 `PageView` 餐廳卡片 Carousel。
* **雙向同步機制**:
  * **點擊地圖 Marker**: 地圖相機平移置中，下方 PageView 自動以動畫 `animateToPage()` 滾動至對應餐廳卡片。
  * **橫向滑動 PageView 卡片**: `onPageChanged` 回呼觸發 `GoogleMapController.animateCamera(CameraUpdate.newLatLngZoom(...))`，地圖自動滑動至當前選中餐廳。
* **效能優化**: 使用 `RepaintBoundary` 隔離 Native Map View 與 Flutter Carousel Widget 的繪製區域，防止拖移掉幀。

#### F-1.3 `fluster` 圖標動態聚類 (Dynamic Marker Clustering)
* **設計理念**: 解決地圖點位過多導致的 UI 卡頓與標記重疊問題。
* **技術實現**: 引入 `fluster` Dart 聚合套件。在 Dart 側將餐廳座標構建為 KD-Tree 索引，依據 `GoogleMap.onCameraMove` 的當前 `zoom` 層級動態計算可視區域內的 Cluster Points。高 Zoom 展示獨立餐廳 Custom Bitmap Marker（含星級評分），低 Zoom 展示聚類數量圈。

#### F-1.4 即時人潮熱度與時段預測 (Live Popular Density Indicator)
* **設計理念**: 於餐廳卡片與詳情頁展示柱狀圖熱門時段，並以動態閃爍之紅色 `Live` 標籤提示當前時間的人潮擁擠程度（例：「目前比平時擁擠」、「擁擠度 85%」）。

---

### 2.2 社群與內容生態 (Community & Content Ecosystem)

#### F-2.1 個人/好友口袋名單與 Firebase 結構重構 (Saved Lists & Subcollection Refactoring)
* **設計理念**: 廢除單一 Document Map 覆寫的舊結構。
* ** Firestore 資料結構重構**:
  ```
  users/{uid}/
    └── saved_lists/{listId}/ (Document: listName, isPublic, createdAt)
          └── items/{restaurantId}/ (Document: addedAt, note, restaurantSummaryJson)
  ```
* **好處**: 單一最愛項目原子化新增/刪除，解除 1MB 限制，支援多套名單（如「深夜私房名單」、「週五酒吧清單」）。

#### F-2.2 自訂美食地圖社群共編 (Collaborative Food Maps)
* **設計理念**: 使用者可將自己的口袋名單設定為「公開/共編」，產出專屬地圖 URL / QR Code。
* **協作機制**: 允許受邀好友新增/刪除餐廳、對特定餐廳點讚 (Thumbs Up/Down) 與留下私房推薦語，在地圖畫面上以不同頭像標記好友推薦點。

#### F-2.3 雙排瀑布流 UGC 食記與短影片 (Masonry Grid UGC & Short Vlogs)
* **設計理念**: 於首頁整合「探店筆記」Tab，採用 `flutter_staggered_grid_view` 實現雙排瀑布流。
* **內容形態**: 支援多圖與 15 秒短影片 (使用 `video_player` / `chewie` 封裝)，展現極致餐飲視覺誘惑 (Food Porn)。

#### F-2.4 筆記地點打卡 Tag (Clickable Location Chips)
* **設計理念**: 每篇 UGC 筆記下方內嵌高亮「地點打卡 Tag」（例：「📍 隱家拉麵 中山店」）。
* **互動體驗**: 點擊 Tag 彈出輕量 BottomSheet 展示餐廳評分、地址、即時空位與「一鍵預訂/導航」按鈕，縮短導流鏈路。

---

### 2.3 AI 與個人化 (AI & Personalization)

#### F-3.1 AI 多模態 Vision 菜單翻譯與食材拆解 (AI Multimodal Menu Vision)
* **設計理念**: 解決外國旅客或看不懂特色菜單的用餐痛點。
* **技術實現**: 使用者拍照上傳紙本菜單，傳送至 Gemini 1.5 Flash Vision / OpenAI GPT-4o API。
* **結構化輸出**: 返回 JSON 包含：原始菜名、繁體中文翻譯、食材解析（如「含花生/麩質/牛奶」過敏原標示）、辣度等級、估算熱量，並自動抓取網路參考菜色圖片。

#### F-3.2 個人味蕾配對度 (0-100% Personal Flavor Match Score)
* **設計理念**: 突破傳統星級評分，提供「針對使用者個人」的專屬相性評分。
* **演算法邏輯**:
  1. 使用者初次使用時勾選味覺偏好雷達（酸/甜/苦/辣/麻/重口味/偏好高蛋白/蔬食）。
  2. 系統分析餐廳歷史標籤與評論關鍵詞向量。
  3. 為每家餐廳計算 0-100% Match Score，並於 UI 呈現卡片標記（例：「🔥 96% 味蕾配對！理由：你喜歡大麻大辣且偏好牛肉」）。

#### F-3.3 自然語言決策轉盤與對話助手 (AI Meal Decision Helper)
* **設計理念**: 解決「今天吃什麼」聚餐選擇困難症。
* **雙模式對話介面**:
  * **對話模式**: 輸入「想找中山區 500 元以內、氣氛安靜可以聊天的日式串燒」，AI 輸出 3 家精準對配餐廳並說明推薦理由。
  * **命運轉盤 (Decision Wheel)**: 一鍵將當前篩選結果/口袋名單載入 3D 轉盤，轉動進行隨機抽籤，伴隨物理音效與慶祝粒子動畫。

---

### 2.4 轉化與預訂流程 (Conversion & Micro-Reservation)

#### F-4.1 輕量化線上微訂位 Time-Slot 選擇器 (In-App Micro-Booking Engine)
* **設計理念**: 無需跳出 App 即可完成 3 步極速預訂。
* **UX 流程**:
  1. 選擇人數 (`Party Size: 1, 2, 3, 4+`)。
  2. 選擇日期 (`DatePicker` 日曆控制)。
  3. 選擇可訂位時間晶片 (`Time Slot Chips`: `18:00` (熱門), `18:30`, `19:00`, `20:15`)。
  4. 確認送出並生成 App 內數位訂位憑證與 QR Code。

#### F-4.2 訂金預扣與第三方支付整合 (Deposit Guarantee & Payment Integration)
* **設計理念**: 針對高級餐廳或熱門時段，支援線上支付保證金。
* **技術實現**: 整合 `flutter_stripe` / Apple Pay / Google Pay SDK。執行 `PaymentIntent` 預授權扣款 (Auth-Hold)，無故 No-show 依政策處理，降低店家損失。

#### F-4.3 線上候位與動態隊列 FCM 追蹤 (Queue Tracking & Real-time Push)
* **設計理念**: 遠端領取號碼牌，無須現場排隊。
* **動態追蹤**: 顯示「目前前方還有 3 組」、「預計等待 15 分鐘」。當隊列更新時，透過 Firebase Cloud Messaging (FCM) 發送推播：「您的桌位已準備好！請於 5 分鐘內返回報到」，並提供「一鍵延後 10 分鐘」或「取消排隊」選項。

---

### 2.5 既有 UI/UX 重構與優化建議 (Refactoring & UX Repairs)

1. **徹底修復 `build()` 側邊效應**
   * 將所有 `bloc.add(Event)` 自 `build()` 清除。初始化請求移至 `initState()`，狀態變更引發的 UI 提示 (Toast/Dialog) 或頁面導向移至 `BlocListener` / `BlocConsumer` 的 `listener` 回呼中。

2. **修復 Yelp API 分頁與 `FilterPage` 狀態重置 Bug**
   * 將 `MainRepository` 的 `offset` 計算改為 `_offset * limit`。
   * 將 `FilterPage` 的初值讀取移至 `initState()` / BLoC 初始化，避免 `setState` 時被傳入引數重置。

3. **修復 `MapWidget` 標記連動**
   * 在 `MapWidgetState` 實作 `didUpdateWidget(MapWidget oldWidget)`，當傳入的餐廳列表發生改變時，自動重新計算並更新地圖 Marker。

4. **優化骨架屏載入 (Skeleton Shimmer Loading)**
   * 全面取代傳統 `CircularProgressIndicator`，導入 `shimmer` 套件，在列表與詳情頁顯示高質感骨架屏，顯著提升體感載入速度。

5. **離線與網路錯誤處理 (Offline & Graceful Error Recovery)**
   * 利用 `sqflite` 快取最近瀏覽的餐廳列表與詳情。斷網時自動降級顯示本地快取，並在 UI 頂部展示優雅的「離線模式」提示橫幅與一鍵重試按鈕。

6. **調整側選單功能項目順序 (Drawer Menu Reordering)**
   * **設計理念**: 側選單（Drawer）中的「設定 (Settings)」等非頻繁使用的功能通常不該放置於首位。應重新規劃順序，將「首頁 / 探索」、「口袋名單」等核心與高頻功能置頂，符合通用 UX 直覺與操作習慣。

7. **列表底部載入更多動畫 (Load-More Loading Indicator)**
   * **設計理念**: 在無限滾動 (Infinite Scroll) 觸發「加載更多」時，列表最底部應動態顯示一個 Loading Indicator (例如骨架屏的最後一個 item 或 `CircularProgressIndicator`)。這能讓使用者明確知道正在拉取下一頁資料，避免因網路延遲而產生「滑到底卡住」的錯覺。

8. **修復地圖模式定位按鈕遮擋問題 (Map Locate Button Obscured Bug)**
   * **痛點**: 首頁切換到地圖模式時，右下角的「定位當前位置」按鈕會被底部的橫向店家列表卡片遮住，導致使用者無法點擊。
   * **改造要點**: 調整地圖元件的 `padding` (特別是 `bottom` padding) 或直接更改 FAB 的佈局位置，使其在橫向列表出現時自動上移，確保核心互動按鈕不被遮擋。

9. **修復地圖底部列表 UI 溢出問題 (RenderFlex Overflow Bug)** — ✅ 已於 2026-08-20 完成（Issue #72 / PR #73）
   * **痛點**: 在 Android 裝置上，地圖模式底部的橫向店家列表出現了右側溢出 14 pixels 的錯誤 (`A RenderFlex overflowed by 14 pixels on the right`)，導致畫面上出現黃黑警告條紋。
   * **實際根因與原先推測不同**: 溢出點不在 `rating_stars.dart`，而在 `restaurant_item_cell.dart` 的評分列 `Row`。`RatingStars` 被包在 `Expanded` 內參與 flex 分配，但它是 5 個固定 16px 的 Icon、寬度本就不可壓縮；在地圖 carousel 的窄卡片（`viewportFraction: 0.85`）下，分配到的寬度小於實際需求即溢出。
   * **實際解法與原先提案不同**: 未採用 `Wrap`（會讓星等換行，破壞單列版面）。改為把 `RatingStars` 移出 flex（不再包 `Expanded`），剩餘空間全部交給評論數與價格兩段文字，並為其加上 `overflow: TextOverflow.ellipsis` 與 `textAlign: TextAlign.right`——不可壓縮的元素不參與分配，可截斷的才參與。
   * **回歸測試**: `restaurant_item_cell_test.dart` 新增 298px 窄卡片測試，驗證無 layout exception 且 5 顆星維持完整寬度。

### 2.6 對照組架構與風格對齊重構 (Architecture Alignment) — ✅ 已於 2026-07-27～07-29 完成

依據對標對照組 Monorepo 的架構風格所規劃的 Clean Architecture 調整，**5 項全數落地**。以下記錄各項的最終實作與偏離規劃之處：

1. **✅ 目錄架構與層級分離重構 (Clean Directory Structure)**
   * **原問題**: `flow/{feature}/repository` 將資料層綁死在 UI 流程中。
   * **實作結果**: 已抽出 `domain/`（`entities/` + `repositories/` 抽象介面）與 `data_layer/`（`dto/` + `datasources/` + `repositories/` 實作）。legacy 的 `flow/*/repository/` 實作已全數移除。
2. **✅ 導入全域依賴注入 (Dependency Injection with GetIt)**
   * **實作結果**: 導入 `get_it: ^8.0.0`，於 `lib/di/` 集中註冊，路由表改由 get_it 解析 Bloc。
   * **⚠️ 與原規劃偏離**: **未導入 `injectable` 程式碼生成**，改採手寫註冊。以當前規模而言，手寫註冊足夠且少一層 build_runner 相依，屬合理取捨。
3. **✅ 資料模型與職責分離 (DTO vs Domain Model 分離)**
   * **實作結果**: 建立 `RestaurantEntity` / `UserEntity` 等領域實體與 DTO mapping，legacy `YelpRestaurantSummaryInfo`、`AccountInfo` 已移除，連帶消滅了有 null crash 風險的 `operator ==`。
4. **✅ 全域常數與狀態管理修正 (Constants Cleanup)**
   * **實作結果**: `UIConstants` 改為 `camelCase`，可變狀態移出常數類，並新增 `RatingHelper` 收斂評分邏輯。工具檔名亦統一為 `lower_case_with_underscores`。
5. **✅ 程式碼風格與 Linting 嚴格化 (Coding Style & Linting)**
   * **實作結果**: 全專案清除冗餘 `this.`、統一單引號、現代化 `url_launcher` / `geolocator` API 用法。**`flutter analyze` 目前為 `No issues found!`**（原稽核時的 14 個 Warning 已全數清除）。

---

### 2.7 訪客模式 (Guest Mode) — ✅ 已於 2026-07-29～07-30 完成

規劃期間新增並已交付的功能（原報告未涵蓋，補記於此）：

* **設計理念**: 降低首次使用門檻 —— 使用者無須註冊或登入即可瀏覽餐廳搜尋、地圖與詳情，僅在觸及需身分的功能（如收藏最愛）時才引導登入。
* **實作要點**:
  * 登入頁提供與「註冊」並列的訪客入口，避免藏在次要位置。
  * 訪客旗標**以 `shared_preferences` 為單一事實來源**讀取，不在記憶體另外鏡射一份狀態 —— 消除了兩份狀態不同步的邊界情況。
  * 最愛寫入路徑加上訪客守衛 (write guard)，防止無 uid 情境下寫入 Firestore。
* **相關文件**: `docs/features/2026-07-29-guest-mode.md`、`docs/plans/2026-07-29-guest-mode.md`（PR #56, issue #55）。

---

### 2.8 基礎設施與平台生命週期遷移 (Platform & Infrastructure Migration) (P0，最高優先)

為確保 App 在最新行動作業系統上的相容性、建置效能與長期可維護性，以下幾項底層升級列為 **P0 阻擋級地基任務**：

#### F-0.2 Flutter SDK 升級遷移至 3.44.1+ (Flutter SDK Version Migration)
* **背景與痛點**:
  * 目前專案運行於 Flutter `3.41.9` / Dart `3.11.5`，未能充分享受新版 Flutter 的 Dart 3.x 效能優化、WebAssembly/Impeller 渲染改進及安全性修補。
  * 許多現代套件相容性約束已逐漸向 Flutter 3.44+ 靠攏。
* **改造要點**:
  * 升級本機與 CI/CD 環境之 Flutter SDK 至 `3.44.1` 或最新穩定版。
  * 解決套件版本衝突與 deprecated API（如 `flutter_platform_widgets` 與 Swift Package Manager 相關配置）。
  * 執行全量單元測試、Widget 測試與靜態程式碼分析（確保 `flutter analyze` 零警告）。

#### F-0.3 iOS UIScene Lifecycle 支援遷移 (iOS UIScene Lifecycle Migration) — ✅ 已於 2026-08-23 完成
* **背景與痛點**:
  * Flutter 工具鏈明確發出強制性警告：
    > *“To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle support will soon be required. Please see https://flutter.dev/to/uiscene-migration for the migration guide.”*
  * 蘋果與 Flutter 官方預告未來 iOS 版本即將強制要求支援 UIScene lifecycle，若未及時遷移，App 將面臨在未來 iOS 系統上無法啟動 (Launch Crash) 的災難性風險。
* **改造要點**:
  * 依據 [Flutter 官方 UIScene 遷移指南](https://flutter.dev/to/uiscene-migration) 改造 `ios/Runner` 專案架構。
  * 調整 `AppDelegate.swift` 與新增 `SceneDelegate.swift`（或於 `Info.plist` 設定 `UIApplicationSceneManifest`）。
  * 確保原有之推播（FCM / APNs）、Deep Link（Universal Links）、生物辨識認證與第三方登入在 UIScene 生命週期下無縫運作。
  * 驗證 iOS 模擬器與實機冷啟動、背景喚醒、多工切換與情境恢復。

#### F-0.4 iOS Swift Package Manager (SPM) 遷移與 CocoaPods 淘汰 (iOS SPM Migration)
* **背景與痛點**:
  * **CocoaPods 維護終止**：CocoaPods 官方已正式進入維護模式（預計 2026 年底註冊表唯讀），Firebase 官方亦已宣布 iOS SDK 的 CocoaPods 支援自 2026 年 10 月起停止發布新版。
  * **Flutter 強制轉向 SPM**：Flutter 官方明確警告未來版本將強制全面轉向 SPM，並移除 `enable-swift-package-manager: false` 的退出選項（*“Disabling Swift Package Manager will not be allowed in a future version of Flutter.”*）。
  * **現況阻礙**：目前因專案內部分關鍵套件（如 `google_maps_flutter_ios`、`flutter_inappwebview_ios`）以及 `firebase_analytics` 與 `firebase-ios-sdk` 的 SPM 版本解析衝突，專案暫時透過 `pubspec.yaml` 關閉 SPM 降級回 CocoaPods。
* **改造要點**:
  * 待依賴之社群與官方套件全面支援 SPM（或升級至相容之最新 Plugin 版本）後，解除 SPM 關閉旗標。
  * 遷移 iOS 原生依賴至 Swift Package Manager（`FlutterGeneratedPluginSwiftPackage`）。
  * 移除 `ios/Podfile`、`Podfile.lock` 與 `Pods/` 目錄，徹底消除 CocoaPods 技術債務，提升 iOS 建置效能。

#### F-0.5 Android Built-in Kotlin 遷移 (移除顯式 KGP 依賴)
* **背景與痛點**:
  * 專案原先的 Kotlin 版本過舊 (2.2.0)，目前雖已暫時升級至 2.2.20 以消除 Flutter 3.44.1 的警告，但專案仍在使用顯式的 Kotlin Gradle Plugin (`org.jetbrains.kotlin.android`) 依賴。
  * Flutter 3.27+ 已棄用顯式的 KGP 依賴，轉而強制推行 "Built-in Kotlin" (由 Flutter 工具鏈內部統一管理 Kotlin 版本)。
  * 若持續保留顯式的 KGP 宣告，在未來的 Flutter SDK 更新中將面臨 Android 建置失敗或工具鏈衝突的風險。
* **改造要點**:
  * 依據 Flutter 官方遷移指南，徹底移除 `android/settings.gradle` 或 `android/build.gradle` 檔案內的 `org.jetbrains.kotlin.android` 依賴。
  * 移除 `android/gradle.properties` 中的 `android.builtInKotlin=false` 旗標（若存在），將 Kotlin 的版本控制權完整交還給 Flutter。
  * 確保清理後重新執行 Android 建置（`flutter build apk`）順利通過且無 Gradle/Kotlin 衝突。

---

## 3. 功能優先級評估矩陣 (ICE / RICE Prioritization Matrix)

為了客觀評估所有提案與修復項目，採用 **RICE** 與 **ICE** 雙模型評估體系：

* **RICE 模型**: $RICE Score = \frac{Reach \times Impact \times Confidence}{Effort}$
  * *Reach*: 覆蓋使用者比例 (1-10)
  * *Impact*: 對使用者體驗與商業目標的影響程度 (0.25=微小, 1=中度, 2=重大, 3=極大)
  * *Confidence*: 評估信心度 (50%=低, 80%=中, 100%=高)
  * *Effort*: 開發與測試人月/精力 (0.5=極少, 1=小, 2=中, 3=大, 4=極大)

* **ICE 模型**: $ICE Score = Impact \times Confidence \times Ease$ (Ease = 10 - Effort 相當之易用度)

### RICE / ICE 雙評估模型總表

| 功能/修復項目 | 類別 | Reach (1-10) | Impact (0.25-3) | Confidence (%) | Effort (0.5-4) | RICE 得分 | ICE 得分 | 綜合排名 | **優先級** |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| ✅ **修復 `build()` 側邊效應反模式** | 既有修復 | 10 | 3.0 | 100% | 0.5 | **60.0** | 28.5 | 1 | **已完成** |
| ✅ **修復 Yelp API 分頁邏輯 Bug** | 既有修復 | 9 | 2.5 | 100% | 0.5 | **45.0** | 23.75 | 2 | **已完成** |
| ✅ **修復 `FilterPage` 狀態重置 Bug** | 既有修復 | 8 | 2.5 | 100% | 0.5 | **40.0** | 23.75 | 3 | **已完成** |
| ✅ **整合 `flutter_inspector_kit` 除錯套件** | 開發工具 | 10 | 2.0 | 100% | 0.5 | **40.0** | 19.0 | 4 | **已完成**（2026-08-05） |
| 🔴 **移除硬編碼 API Key (改用 Server-side Broker)** | 安全修復 | 10 | 2.0 | 100% | 0.5 | **40.0** | 19.0 | 5 | **P0（唯一未解安全風險）** |
| ✅ **對照組風格: 目錄架構與層級分離重構** | 架構重構 | 10 | 3.0 | 100% | 2.0 | **15.0** | 24.0 | - | **已完成** |
| ✅ **對照組風格: 導入全域依賴注入 (GetIt)** | 架構重構 | 10 | 2.5 | 100% | 1.5 | **16.6** | 21.2 | - | **已完成** |
| ✅ **對照組風格: DTO 與 Domain Entity 分離** | 架構重構 | 10 | 2.5 | 100% | 1.5 | **16.6** | 21.2 | - | **已完成** |
| ✅ **對照組風格: 全域常數與可變狀態清理** | 程式碼重構 | 10 | 2.0 | 100% | 1.0 | **20.0** | 18.0 | - | **已完成** |
| ✅ **對照組風格: 程式碼風格與 Lint 嚴格化** | 程式碼重構 | 10 | 1.0 | 100% | 1.0 | **10.0** | 9.0 | - | **已完成** |
| ✅ **訪客模式 (Guest Mode)** | 轉化優化 | 10 | 2.0 | 100% | 1.0 | **20.0** | 18.0 | - | **已完成** |
| ✅ **Firestore Subcollection 口袋名單** | 資料架構 | 10 | 2.5 | 100% | 1.0 | **25.0** | 22.5 | - | **已完成**（2026-08-19, PR #70） |
| ✅ **iOS UIScene Lifecycle 支援遷移 (強制性相容)** | 平台遷移 | 10 | 3.0 | 100% | 1.0 | **30.0** | 27.0 | - | **已完成**（2026-08-23） |
| 🔴 **iOS Swift Package Manager (SPM) 遷移與 CocoaPods 淘汰** | 平台遷移 | 10 | 2.5 | 90% | 1.5 | **15.0** | 19.12 | - | **P0（官方強制遷移）** |
| 🔴 **Android Built-in Kotlin 遷移 (移除顯式 KGP)** | 平台遷移 | 10 | 2.5 | 100% | 0.5 | **50.0** | 23.75 | - | **P0（官方棄用警告）** |
| 🔴 **Flutter SDK 版本遷移 (≥ 3.44.1)** | 基礎設施 | 10 | 2.5 | 100% | 1.0 | **25.0** | 22.5 | - | **P0（基礎設施升級）** |
| ✅ **移除無謂假延遲 (過濾 2s / 推播 8s)** | 既有修復 | 9 | 1.5 | 100% | 0.5 | **27.0** | 14.25 | - | **已完成** |
| ✅ **`MapWidget` 實作 `didUpdateWidget` 連動 Marker** | 既有修復 | 8 | 2.0 | 100% | 0.5 | **32.0** | 19.0 | - | **已完成** |
| 🔴 **修復地圖模式定位按鈕遮擋問題** | 既有修復 | 10 | 2.0 | 100% | 0.5 | **40.0** | 19.0 | - | **P0** |
| ✅ **修復地圖底部列表 UI 溢出 (RenderFlex overflow)** | 既有修復 | 10 | 1.5 | 100% | 0.5 | **30.0** | 14.25 | - | **已完成**（PR #73） |
| ❌ **地圖與 BottomSheet 雙向連動 Carousel (已放棄)** | 空間 UX | 9 | 3.0 | 90% | 1.5 | **16.2** | 22.95 | 6 | **放棄 (無實質效益)** |
| ✅ **調整側選單功能項目順序** | UX 優化 | 10 | 1.0 | 100% | 0.5 | **20.0** | 10.0 | - | **已完成** |
| ✅ **列表底部載入更多動畫** | UX 優化 | 9 | 1.0 | 100% | 0.5 | **18.0** | 10.0 | - | **已完成** |
| **情境化探索標籤 (#一人食等)** | 搜尋優化 | 9 | 2.0 | 90% | 1.0 | **16.2** | 16.2 | 7 | **P1** |
| **`fluster` 圖標動態聚類** | 效能優化 | 8 | 2.0 | 90% | 1.0 | **14.4** | 16.2 | 8 | **P1** |
| **骨架屏 Shimmer 載入與離線快取** | UX 優化 | 9 | 1.5 | 100% | 1.0 | **13.5** | 13.5 | 9 | **P1 (Shimmer✅ / 離線未做)** |
| **輕量化線上微訂位 Time-Slot 選擇器** | 商業轉化 | 7 | 3.0 | 80% | 2.0 | **8.4** | 19.2 | 11 | **P1** |
| **自訂美食地圖社群共編** | 社群生態 | 6 | 2.0 | 80% | 2.0 | **4.8** | 9.6 | 12 | **P2** |
| **線上候位與動態隊列 FCM 追蹤** | 商業轉化 | 5 | 2.5 | 80% | 2.5 | **4.0** | 10.0 | 13 | **P2** |
| **AI 多模態 Vision 菜單翻譯** | AI 創新 | 6 | 2.5 | 80% | 2.5 | **4.8** | 12.0 | 14 | **P2** |
| **個人味蕾配對度 (0-100% Match)** | AI 創新 | 7 | 2.0 | 70% | 2.5 | **3.92** | 9.8 | 15 | **P2** |
| **自然語言選店助手與命運轉盤** | AI 創新 | 6 | 2.0 | 70% | 2.0 | **4.2** | 11.2 | 16 | **P2** |
| **雙排瀑布流 UGC 食記與短影片** | 內容生態 | 5 | 2.0 | 70% | 3.0 | **2.33** | 9.8 | 17 | **P2** |

---

## 4. 建議發展路線圖 (Strategic Product Roadmap)

基於上述 RICE / ICE 優先級與技術相依性，制定三階段落地發展路線圖：

```
+-----------------------------------------------------------------------------------+
|                           STRATEGIC PRODUCT ROADMAP                               |
+-----------------------------------------------------------------------------------+
| Phase 1: 地基修復與架構對齊 (Foundation & Architecture)   ── 進度 13/20 ✅        |
|   • [x] P-1 整合 flutter_inspector_kit ✅ 2026-08-05（量測地基就位）             |
|   • [x] P0 修復 `build()` 側邊效應反模式                                          |
|   • [x] P0 修復 Yelp API 分頁邏輯 Bug                                              |
|   • [x] P0 修復 `FilterPage` 狀態重置 Bug                                          |
|   • [x] P0 對照組風格對齊: 目錄架構與層級分離重構 (Domain / Data)                |
|   • [x] P0 對照組風格對齊: 導入全域依賴注入 (GetIt；未用 Injectable)             |
|   • [x] P0 對照組風格對齊: 資料模型與職責分離 (DTO vs Domain Entity)             |
|   • [x] P1 對照組風格對齊: 全域常數清理與 Lint 嚴格化 (analyze 零警告)           |
|   • [x] P1 調整側選單功能項目順序 (Drawer Menu Reordering)                        |
|   • [x] ── 訪客模式 Guest Mode (規劃外新增，PR #56)                               |
|   • [x] P1 Firestore Subcollection 最愛名單重構 ✅ 2026-08-19 (PR #70)            |
|   • [x] P0 ✅ iOS UIScene Lifecycle 支援遷移 ✅ 2026-08-23                               |
|   • [ ] P0 🔴 iOS Swift Package Manager (SPM) 遷移與 CocoaPods 淘汰               |
|   • [ ] P0 🔴 Android Built-in Kotlin 遷移 (移除顯式 KGP)                             |
|   • [ ] P0 🔴 Flutter SDK 版本遷移至 3.44.1+                                       |
|   • [ ] P0 移除硬編碼 API Key ⚠️ 未動；金鑰已入 git 歷史，須撤銷並輪替            |
|   • [x] P0 移除無謂假延遲 (過濾 2s / 推播導航 8s) ✅ 實查已清除                   |
|   • [x] P0 `MapWidget` 實作 `didUpdateWidget` 使 Marker 連動列表 ✅ 實查已實作    |
|   • [ ] P0 修復地圖模式定位按鈕遮擋問題 (Map Locate Button Obscured Bug)          |
|   • [x] P0 修復地圖底部列表 UI 溢出 (Android RenderFlex overflow) ✅ PR #73        |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
| Phase 1.5: 空間與視覺體驗升級 (Spatial UX & Polish)                               |
|   • ❌ P1 地圖與 BottomSheet Carousel 雙向平滑連動 (含點擊至詳情頁) - 缺乏實質效益已放棄 |
|   • [x] P1 列表底部載入更多動畫 (Load-More Indicator) ✅ 實查已於列表實作             |
|   • [x] RatingStars 評分星等元件 (取代 11 張 PNG) ✅ 已實作並接線                     |
|   • ❌ P1 fluster 動態圖標聚類 (Clustering) - 使用者體驗不佳已暫緩/放棄 (Issue #76)    |
|   • [ ] P1 情境化探索標籤 (#一人食 #深夜食堂 #約會不踩雷)                             |
|   • [ ] P1 骨架屏 (Shimmer Loading) 與離線降級快取 (✅ 骨架屏已實作 / ❌ 離線未做)    |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
| Phase 2: 社群生態與轉化閉環 (Engagement & Conversion)                             |
|   • Firestore Subcollection 最愛口袋名單與社群共編美食地圖                          |
|   • 輕量化線上微訂位 Time-Slot 選擇器                                               |
|   • 線上候位領號與 FCM 動態隊列推播追蹤                                             |
|   • 筆記/清單地點打卡 Tag 輕量彈窗                                                  |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
| Phase 3: AI 差異化壁壘與白地探索 (AI Differentiators & White Space)                |
|   • AI 多模態 Vision 菜單翻譯與食材過敏原拆解                                       |
|   • 個人味蕾配對度 (0-100% Match Score & 味覺雷達)                                  |
|   • 自然語言選店對話助手與命運轉盤                                                  |
|   • 雙排瀑布流 UGC 食記與 15 秒探店短影片                                           |
+-----------------------------------------------------------------------------------+
```

---

## 5. 驗證與落地規範 (Verification & Delivery Standards)

為確保開發品質與系統穩定度，團隊必須嚴格執行以下靜態驗證與動態 KPI 指標：

### 5.1 靜態程式碼與單元測試驗證 (Static Code Quality)

1. **`flutter analyze` 零警告要求 — ✅ 已達成**:
   * 原稽核的 14 個 Warning（`launchUrl` 替代廢棄 `launch`、`AndroidGoogleMapsFlutter` 配置等）已於 07-27 的 lint 現代化重構中全數清除。
   * 2026-07-30 覆核執行 `flutter analyze` → **`No issues found!`**。此為後續 PR 的最低門檻，不得回退。

2. **`flutter test` 測試覆蓋率 — 🟡 進行中**:
   * 現況：13 個 test 檔，已涵蓋 DI 註冊、repositories 與 sign-in bloc。
   * 待補：BLoC 狀態轉換的 `bloc_test` 尚未全面覆蓋；測試目標路徑因分層重構已變更為 `flow/*/bloc/`、`domain/` 與 `data_layer/repositories/`（舊路徑 `flow/*/repository/` 已不存在）。
   * 測試覆蓋率目標：核心業務邏輯單元測試覆蓋率 $\ge 80\%$（尚未量測，需先跑 `flutter test --coverage` 取得基線）。

---

### 5.2 效能與 UX 驗證 KPI 指標 (Performance Benchmarks)

1. **FPS 幀率預算 (FPS Budget - 60 FPS)**:
   * 在 Profile 模式下 (`flutter run --profile`)，拖移地圖與滑動 BottomSheet Carousel 時，UI 與 Raster 執行緒之每幀繪製時間必須 $< 16.6\text{ ms}$ (無掉幀)。

2. **地圖圖標聚類延遲 (Cluster Latency)**:
   * `fluster` 處理 500 個 Marker 之動態聚合計算，耗時需 $< 50\text{ ms}$。

3. **AI 回應延遲與體驗 (AI Response Latency)**:
   * 菜單 Vision 解析與自然語言推薦，端到端回應時間需控制在 $< 2.5\text{ s}$ 以內，並搭配打字機動畫 (Typewriter Effect) 消除等候焦慮。

4. **訂位轉化步數 (Booking Conversion Steps)**:
   * 使用者從點擊餐廳卡片到完成預訂，操作路徑不可超過 **3 次點擊**。

---

> **檔名日期慣例**：本檔前綴為**最後更新日**（隨每次覆核更新），非報告產出日。各章節的實際產出時間見下方時間軸與各章末註記。

*報告初版產出時間：2026-07-26*
*進度覆核更新時間：2026-07-30（對應版本 v1.4.0+30，commit `d4aa8f1`）*
*報告編寫團隊：Worker 1 (Report Author & Strategic Analyst)*

---
---

# 6. UI/UX 視覺重塑計畫 (Visual Redesign Initiative)

> **本章新增於 2026-07-31**，掛載於 Roadmap 的 **Phase 1.5（空間與視覺體驗升級）** 之下，為其前置地基。
> 產出方式：直接檢視當前 `lib/` 原始碼，非採信既有文件敘述。

## 📌 S1 交付覆核 (2026-08-03)

**S1 Design System 地基已完成**（分支 `refactor/202607/57-design-system-foundation`，13 個 commit，`ef2f4e7` ～ `9c2ec3f`）。本節依**實際檢視程式碼**覆核，非採信 commit 訊息。

**驗證實測（2026-08-03）**

| 項目 | 結果 |
| :--- | :--- |
| `flutter analyze` | ✅ `No issues found!` |
| `flutter test` | ✅ `All tests passed!`（54 tests / 14 檔） |

**實作與 §6.4 原規劃的四項偏離**（規格與實作計畫已同步，本章此前未更新）：

| # | 原規劃（§6.4） | 實際交付 | 原因 |
| :--- | :--- | :--- | :--- |
| A-1 | `lib/theme/` 四檔 | `lib/features/foundation/style/` 四檔，統一 `theme_` 前綴，走 `style_barrel.dart` | 改採 features-first；連帶 `lib/utils/` 整個解散並入 `lib/features/`（`utils/`、`constants/`、`extension/`） |
| A-2 | `app_colors.dart` 放語意化 ColorScheme | `theme_color.dart` 只放 2 個品牌原始色 | 語意色由 `ColorScheme` 自身提供，另建一份是第二個真相來源 |
| A-3 | `app_spacing.dart` 填實 `Dimens`，5 個 4 的倍數階梯 | `theme_size.dart` 的 `ThemeSize`，**10 個 5 的倍數階梯** + 圓角 + 圖片尺寸；`lib/utils/dimens.dart` 已刪除 | 階梯取自實測既有值，使既有使用點能一對一替換、零視覺變更 |
| A-4 | FlutterGen 生成 `ColorName` | **整套生成鏈移除**：刪 `assets/colors.xml`、`lib/gen/colors.gen.dart` 與 pubspec 的 `flutter_gen:` 區塊，改手寫 `ThemeColor` | 2 個顏色不值得維持 xml + build_runner 工具鏈 |

### 🔴 交付後才發現的事實：種子色映射不等於品牌色

§6.4 的「色票以 `#D84A20` 為種子」隱含一個未經驗證的假設：`colorScheme.primary` 會**是**品牌橘。**實測不成立** ——
`ColorScheme.fromSeed(seedColor: #D84A20)` 依 M3 tonal palette 將 primary 映射為 **`#8F4B38`（較濁的棕橘）**，非原色。

後果：`colorScheme.primary` 與仍硬編 `ThemeColor.appPrimary` 的 **19 處使用點（8 個檔案）**（2026-08-05 複測更正，原記 16 處／7 檔）並存時有可見色差。這是零 `copyWith` 決策（D-4 額度用 0 個）的既定後果，非缺陷，但 §6.4 原文未預料到，於此更正。**S2 引入 `surface` 覆寫時須一併決定 primary 是否也要 `copyWith` 鎖回 `#D84A20`。**

### 另一項計畫外發現：跨平台 theme 解析

`PlatformApp` 在 iOS 走 `CupertinoApp` 分支，`material:` **不生效**。原計畫僅掛 `material:`，實測 iOS 端 Material widget 取不到 ThemeData。最終實作補了三層：`cupertino:`（`CupertinoThemeData`）、`builder:`（外包一層 `Theme`），並鎖 `themeMode: ThemeMode.light` + `darkTheme` 指向同一份 light，避免系統深色模式下狀態列與淺色內容相衝。

因此**新增了一個測試檔** `test/app_theme_platform_test.dart`（原計畫 §2.5 定「不新增任何測試」）—— 這是跨平台行為差異而非資料宣告，若 `builder:` 層被移除，iOS case 會紅。

---

## 6.1 觸發原因：這個 App 沒有 Theme

第 1～5 章的稽核聚焦於**架構**（分層、DI、生命週期），未檢視**視覺層**。本次針對 UI 的專項稽核發現一個前幾輪完全未被記錄的根本性缺陷：

### 🔴 致命發現：`PlatformApp` 未掛載任何 ThemeData

`lib/main.dart:52` 的 `PlatformApp` 僅設定 `navigatorKey`、`locale`、`localizationsDelegates`、`routes`，**不存在 `material:` 或 `cupertino:` 參數**。

這代表整個 App：
* 沒有 `ThemeData`
* 沒有 `ColorScheme`
* 沒有 Material 3
* 沒有 `TextTheme`

所有樣式皆為各 widget 內硬編碼。

### 缺陷證據表

| 症狀 | 證據位置 |
| :--- | :--- |
| 全 App 色票僅 2 色 | `gen/colors.gen.dart` 只有 `appPrimaryColor` (#D84A20) 與 `backBtnColor` (#FFFFFF) |
| 顏色硬編碼散落 | `Colors.grey` **共 12 處、分佈於 5 個檔案**（`restaurant_item_cell` ×4、`sign_in_page` ×4、`restaurant_info_cell` ×2、`restaurant_business_hour_cell` ×1、`banner_ad` ×1），另有 `Colors.white`、`Colors.blue`、`Colors.red` 散見各處 |
| 字級為 12 個無語意常數 | `UIConstants.xlFontSize` ～ `xxxxxxhFontSize`；`xxxxxxhFontSize` 無法從命名判讀實際大小 |
| 間距無系統 | `EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 0)` 等手感值 |
| `Dimens` 是空類別 | `lib/utils/dimens.dart` 全檔內容為 `class Dimens {}` |
| **主題色取用失效** | `filter_tags_widget.dart:61` 使用 `Theme.of(context).primaryColor`，因無 theme 而取得 **Material 預設藍**，與 AppBar 橘色不一致 |

> **最後一項為實錘**：篩選標籤目前顯示藍色、AppBar 顯示橘色，同一畫面兩種主色。這不是設計選擇，是缺少 theme 的直接後果。

> **📐 上表三處數字經 S1 規格實測訂正**（`docs/features/2026-07-31-design-system-foundation.md` §6，本表保留原值以存證）：
> * 裸用 `Colors.xxx` 實為 **33 處、13 個檔案**（非 12 處 5 檔，規模低估近 3 倍）。**2026-08-03 複測仍為 33 處 13 檔** —— S1 依 §4.2 刻意不掃除，債務 T-2 完整留給 S2/S3/S4。
> * 字級常數實為 **10 個**（非 12 個），位於 `lib/utils/ui_constants.dart:25-34`（現已遷至 `lib/features/foundation/constants/ui_constants.dart`），被使用 **29 次、跨 14 個檔案**。S1 已全數標 `@Deprecated` 且未移除；2026-08-03 複測使用點仍為 29 處，待 S4 遷移。
> * `filter_tags_widget.dart` 位於 **`lib/flow/main/view/`**（非 `lib/flow/filter/`）。

### 🐧 Linus 式判斷

> 「在沒有 ThemeData 的情況下談美化，等於每個畫面各自貼一次膠帶。改一個顏色要動 20 個檔案 —— 這不是樣式問題，是**資料結構問題**。設計 token 就是 UI 的資料結構，它現在不存在。
>
> 先把資料結構建對，後面每個畫面的美化都變成『套用』而不是『手刻』。這是唯一有槓桿的順序。」

---

## 6.2 決策紀錄 (Design Decisions)

本計畫經逐項確認，決策與理由如下：

| # | 決策項 | 選定方案 | 理由 |
| :--- | :--- | :--- | :--- |
| D-1 | 範圍層級 | **視覺重塑**（地基 + 版面重設計） | 純地基使用者無感；加動效則是把裝飾釘在流沙上 |
| D-2 | 風格方向 | **暖食慾派 (Appetite Warm)** | 保留既有 `#D84A20` 品牌資產；暖色系符合餐飲場景與轉化目標 |
| D-3 | 深色模式 | **不做**，但顏色一律走 `ColorScheme` | 不交付 dark 色值；但禁止裸 `Colors.xxx`，確保「改一次顏色不動 20 個檔案」 |
| D-4 | 色票生成 | **`ColorScheme.fromSeed` + ≤3 個 `copyWith` 覆寫** | M3 演算法保證 30+ 色角色的和諧度與 WCAG 對比；手工指定必然遺漏且不一致 |
| D-5 | 星等呈現 | **改 Flutter 內建 Icon 繪製** | 免套件；解決記憶體、精度、無法連動 theme 三個問題 |
| D-6 | 載入體驗 | **骨架屏 (Skeleton)** | 體感效能手段；Yelp API 行動網路下常需 1-2 秒 |
| D-7 | 假延遲 | **併入本次移除** | 過濾硬等 2 秒是當前最傷體感的單一問題，3 行刪除卻最有感 |

### D-3 補充說明（重要）

「不做深色模式」與「顏色走 ColorScheme」是**兩件獨立的事**：

* **不交付**：dark 色值、跟隨系統切換 → `darkTheme` 留空
* **仍必須做**：程式碼中不再出現裸 `Colors.grey`，一律 `Theme.of(context).colorScheme.onSurfaceVariant`

後者並非為了未來的深色模式，而是**本次美化本身的前提** —— 沒有它，D-1 的「視覺重塑」就退回各頁貼膠帶。

---

## 6.3 改造範圍 (Scope)

| 分類 | 畫面 | 判斷依據 |
| :--- | :--- | :--- |
| **必做** | 餐廳列表 (`main`) | 使用者停留最久 |
| **必做** | 餐廳詳情 (`restaurant`) | 決策發生地 |
| **必做** | 登入頁 (`signinup`) | **主按鈕硬編碼藍與品牌色衝突，屬視覺識別錯誤** |
| **必做** | 共用元件 | ItemCell / RatingHelper / LoadingWidget / EmptyDataWidget |
| **順帶** | 最愛 (`favor`) | 共用 cell，改完自動生效 |
| **順帶** | 啟動頁 (`splash`) | `BoxFit.fill` → `cover`，一行 |
| **建議做** | 篩選頁 (`filter`) | 搜尋主流程一環 |
| **延後** | 設定 (`settings`)、看圖 (`photo_viewer`) | 停留時間短、權重低 |

> **登入頁提升為必做的原因**：初判為「可延後」，實際檢視 `sign_in_page.dart:180` 後修正 —— 主要登入按鈕為 `Color.fromARGB(255, 5, 97, 245)`（硬編碼藍），與 App 主色橘紅無關。這是新使用者的第一印象，且訪客模式入口（PR #56 新功能）目前是灰色小字，功能價值被 UI 埋沒。
>
> **📍 2026-08-03 更新**：該按鈕現位於 `sign_in_page.dart:183`（S1 的 token 遷移使行號位移），**顏色未改，仍是硬編碼藍**。S1 依規格 §4.3 定案不動它 —— 它不是 theme 缺失造成的（是明寫顏色，掛 theme 對它零影響），改它會讓 S1「除 FilterChip 外外觀不變」的驗收失去意義。列為債務 T-1，**S3 連同灰色訪客入口（T-5）整頁處理**。該檔的 `ThemeColor` / `ThemeSize` token 遷移則已於 S1 完成。

---

## 6.4 架構設計：Design System 地基

> ⚠️ **本節為 2026-07-31 的規劃原文，路徑與識別字已不等於現況。** 實際交付見本章開頭的「S1 交付覆核 (2026-08-03)」，偏離四項（A-1～A-4）已列表說明。以下保留原樣以存證當時的推導。

### 目錄結構（規劃）

```
lib/theme/
├── app_theme.dart      # ThemeData 組裝，掛進 PlatformApp(material:)
├── app_colors.dart     # 語意化 ColorScheme（暖食慾派，light 一組）
├── app_typography.dart # TextTheme，取代 12 個 xxxhFontSize 常數
└── app_spacing.dart    # 間距 / 圓角 token，填滿現在空的 Dimens
```

### 目錄結構（實際交付）

```
lib/features/foundation/style/
├── style_barrel.dart      # 對外唯一入口
├── theme_data.dart        # AppThemeData：materialLight + cupertinoLight
├── theme_color.dart       # ThemeColor：2 個品牌原始色（手寫，非 FlutterGen）
├── theme_text_style.dart  # ThemeTextStyle（TextTheme）+ ThemeFontSize（原始值）
└── theme_size.dart        # ThemeSize：間距 / 圓角 / 圖片尺寸
```

### 關鍵實作點

1. **`PlatformApp` 掛載 theme**（整個改動的起點）
   ```dart
   PlatformApp(
     material: (_, __) => MaterialAppData(theme: AppTheme.light),
     // ...既有參數
   )
   ```

2. **色票以 `#D84A20` 為種子**
   ```dart
   ColorScheme.fromSeed(seedColor: const Color(0xFFD84A20)).copyWith(
     surface: const Color(0xFFFFFBF7), // 奶油白，取代 M3 預設中性白
   )
   ```
   * `fromSeed` 定調性，`copyWith` 修氛圍
   * **覆寫上限 3 個**，每個須於 PR 說明理由
   * 超過 3 個代表種子色選錯，應調種子色而非繼續補丁

   > **⚠️ 實作更正（2026-08-03）**：S1 定案零 `copyWith`（3 個額度完整保留給 S2），故奶油白 `surface` 未交付。
   > 更重要的是，**`fromSeed` 產出的 `primary` 是 `#8F4B38` 而非種子色 `#D84A20`** —— 上方寫法隱含「primary 即品牌橘」的假設並不成立。詳見本章開頭的交付覆核。

3. **字級改語意命名**
   * `UIConstants.xxxxhFontSize` → `Theme.of(context).textTheme.titleLarge`
   * 舊常數**保留並標 `@Deprecated`**，避免一次性編譯失敗

4. **`Dimens` 填實**
   * `space4 / space8 / space12 / space16 / space24`
   * `radiusCard = 16`、`radiusChip = 20`、`radiusImage = 12`

   > **⚠️ 實作更正（2026-08-03）**：改為 `ThemeSize`（`theme_size.dart`），階梯取**實測既有值的 5 的倍數**（`space3/4/5/10/15/20/25/30/50` + `zero`），非上列 4 的倍數 —— 目的是讓既有使用點一對一替換、零視覺變更。另含 `radiusTag = 15` 與 4 個圖片尺寸常數。空殼 `lib/utils/dimens.dart` 已刪除。

### 破壞性評估

| 風險 | 等級 | 說明 |
| :--- | :---: | :--- |
| 掛上 ThemeData 後現有畫面外觀改變 | 🟡 | `FilterChip` 等吃預設 theme 的元件將由藍轉橘 —— **此為修正而非破壞** |
| 舊常數保留 | 🟢 | 不會一次性編譯失敗 |
| `flutter_platform_widgets` 相容性 | 🟢 | `PlatformApp` 原生支援 `material:` 參數，無須更換套件 |

---

## 6.5 共用元件重塑 (Shared Components)

> 槓桿最大處：這 4 個元件被列表、詳情、最愛三畫面共用，改一次三處生效。

### 6.5.1 `RestaurantItemCell`（餐廳列表卡片）

**現況缺陷**：

| 問題 | 證據 |
| :--- | :--- |
| **圖片變形** | `BoxFit.fill` + 固定 110×110 |
| 資訊擠成一團 | 三個 `Expanded` 硬塞一行：星等、評論數、價格 |
| 無視覺容器 | 無 Card、無圓角、無陰影、無分隔 |
| **距離顯示為 bug** | `sprintf('%.2fm', [distance])` → 顯示「1523.47m」而非「1.5 km」 |
| 點擊無回饋 | 外層 `GestureDetector`，無 Material 漣漪 |

**目標版面**：

```
┌─────────────────────────────────────┐
│ ┌────────┐  店名             1.5 km │
│ │        │  ★★★★☆ 4.5 (128)        │
│ │  16px  │  $$ · 日式料理 · 拉麵     │
│ │  圓角  │  台北市中山區...          │
│ └────────┘                          │
└─────────────────────────────────────┘
```

**改造項**：
* 圖片 `BoxFit.cover` + `ClipRRect(radius: 12)`，尺寸 96×96
* 外層改 `Card` + `InkWell`（點擊漣漪）
* 資訊分層：主行（店名 + 距離）／次行（星等 + 評論數）／輔行（價格 · 分類）／末行（地址）
* 距離格式化：`< 1000m` → `xxx m`；`>= 1000m` → `x.x km`
* 分類分隔改用 `·`（現為空格串接）

### 6.5.2 `RatingHelper` → `RatingStars` widget — ✅ 已於 2026-08-20 完成 (PR #73 驗證)

> **實查確認**：`lib/component/rating_stars.dart` 已建立（使用 `Icons.star` / `star_half` / `star_border`），11 張 `Star_rating_X_of_5.png` 與 `RatingHelper` 已全數移除，並已在 `restaurant_item_cell.dart`、`restaurant_comment_cell.dart`、`restaurant_info_cell.dart` 完整接線使用。

### 6.5.3 `LoadingWidget` → 骨架屏 — ✅ Skeleton 已實作

> **實查確認**：`lib/component/skeleton.dart` 與 `restaurant_item_skeleton.dart`（搭配 `shimmer: ^3.0.0`）已建立並在餐廳列表廣泛使用；`LoadingWidget` 仍保留供部分小範圍使用。

### 6.5.4 `EmptyDataWidget`

**現況**：一行黑色粗體 `Text('目前無任何資料')`，**中文硬編碼未走 i18n**。

**改造**：
* 加入圖示（`Icons.restaurant_outlined`，`onSurfaceVariant` 色）
* 主文案 + 輔助說明（例：「試著調整篩選條件或擴大搜尋範圍」）
* 文案走 i18n
* 可選重試按鈕（傳入 `onRetry` callback 才顯示）

### 破壞性評估

| 項目 | 等級 | 說明 |
| :--- | :---: | :--- |
| 刪除 11 張星等 PNG | 🟢 | 僅 `RatingHelper` 引用，已確認 |
| `RatingHelper` API 變更 | 🟡 | **3 處**呼叫（item cell、info cell、**comment cell**）須同步改。⚠️ 2026-08-05 複測更正：原記「2 處」漏計 `restaurant_comment_cell.dart`，S2 effort 據此上修 |
| 卡片高度由 110 變動 | 🟢 | `RestaurantItemCell.itemH` 雖為 public static，但經 grep 確認**僅在自身檔案內引用**（`:23`、`:44`），無外部依賴 |
| 距離格式改變 | 🟢 | 純顯示層 |

---

## 6.6 頁面級改造 (Page-level Redesign)

### 6.6.1 餐廳詳情頁 (`restaurant`)

| 問題 | 證據 | 改造 |
| :--- | :--- | :--- |
| Head 圖變形 | `restaurant_head_cell.dart:36` `BoxFit.fill`，200px 固定高 | `BoxFit.cover`，高度 240，底部漸層遮罩使店名可疊圖上 |
| 收藏鍵為 PNG | `ic_favor_empty.png` / `ic_favor_fill.png` 塞於 `CircleAvatar` | 改 `Icons.favorite` / `favorite_border`，走 theme 色，**刪 2 張 PNG** |
| **OPEN/CLOSE 語意錯誤** | `restaurant_info_cell.dart` 紅底圓角，**營業中也顯示紅色** | 語意色：營業中綠系、已打烊 `outline` 灰；文案走 i18n |
| 電話為裸藍字 | `Colors.blue` 硬編碼，無 icon、點擊區域小 | `Icons.phone` + 文字，整列可點，走 `primary` 色 |
| 地圖縮圖變形 | 140×140 `BoxFit.fill` | `BoxFit.cover` + 圓角 12，加「點擊導航」提示 |
| 資訊無分組 | 地址/電話/分類/星等/評論/營業狀態擠於單一 Column | 分區塊：基本資訊 / 營業時間 / 評論，區塊間以 `Divider` 或間距分隔 |

### 6.6.2 登入頁 (`signinup`)

| 問題 | 證據 | 改造 |
| :--- | :--- | :--- |
| **主按鈕與品牌色衝突** | `sign_in_page.dart:180` `Color.fromARGB(255, 5, 97, 245)` | 改 `colorScheme.primary`（橘紅），**移除硬編碼藍** |
| 動作階級不明 | 註冊 / 訪客皆為 `Colors.grey` TextButton，視覺權重相同 | **三層階級**：主要=Email 登入 (filled)／次要=Google/Apple (outlined)／第三=註冊、訪客 (text，訪客加邊框提升可見度) |
| 輸入框無裝飾 | `Icon` + `TextFormField` 手拼 `Row`，無 `InputDecoration` | `InputDecoration(filled: true, prefixIcon:, border: OutlineInputBorder(radius: 12))` |
| 小螢幕表單被擠壓 | 上下各 `Expanded(flex: 1)` 平分螢幕 | 主體改 `SingleChildScrollView`；gif 改**固定最大高度**而非 `Expanded` |

### 6.6.3 餐廳列表頁 (`main`)

* 卡片間距與 padding 全數走 token
* **新增列表底部載入更多指示器** ← 現況完全無指示（`restaurant_info_list_widget.dart` 觸發 `FetchSearchInfo` 但 UI 無反應）
* 首次載入改用 `RestaurantListSkeleton`
* ~~`FilterTagsWidget` 的 `Theme.of(context).primaryColor` 修正為 `colorScheme.primary`~~ → ✅ **已完成**（2026-08-05 複測：`filter_tags_widget.dart:62` 已為 `Theme.of(context).colorScheme.primary`，S1 掛 theme 時順帶生效，S3 無須再做）

### 6.6.4 篩選頁 (`filter`) — 建議做

* Segment 控制項統一風格（現為 Cupertino / Material 混搭）
* `CupertinoDatePicker` 硬塞 200px → 以容器包裝並加標題分組
* 「套用」按鈕由 AppBar `actions` 移至**底部固定 filled 按鈕**（拇指可及區）

### 6.6.5 順帶項

| 項目 | 改動 | 備註 |
| :--- | :--- | :--- |
| Splash | `BoxFit.fill` → `cover` | 一行 |
| 最愛頁 | 共用 cell 自動生效 | 僅需確認空狀態文案 |
| **移除假延遲** | `main_bloc.dart:56` 過濾 2 秒 | **P0，最有感的單一改善**（見 §1.2 缺陷 5） |

### 破壞性評估

| 風險 | 等級 | 說明 |
| :--- | :---: | :--- |
| 登入頁版面重排 | 🟡 | 須於小螢幕（iPhone SE / 375pt）實機驗證 |
| **移除假延遲** | 🟡 | 須確認該 `Future.delayed` 非在掩蓋 race condition。**若移除後出現閃爍，代表有真問題被藏住，應修根因而非還原延遲** |
| 刪除 favor PNG | 🟢 | 僅 head cell 引用 |
| 詳情頁分組 | 🟢 | 純版面，無邏輯變更 |

---

## 6.7 交付策略 (Delivery Strategy)

### 分階段落地（每階段可獨立 PR、獨立驗證）

| 階段 | 內容 | 依賴 | 使用者可感知度 | 狀態 |
| :--- | :--- | :--- | :---: | :---: |
| **S1 地基** | `lib/features/foundation/style/` 建立、`PlatformApp` 掛 `material:`／`cupertino:`／`builder:`、token 定義 | 無 | 低（僅 FilterChip 藍→橘） | ✅ **已完成 (2026-08-03)** |
| **S2 共用元件** | ItemCell、RatingStars(✅)、Skeleton(✅)、EmptyDataWidget | S1 | **高**（列表與最愛同時改觀） | 🟡 **部分完成**（`RatingStars` 與 `Skeleton` 已完成，剩餘 `ItemCell`、`EmptyDataWidget` 與 Token 覆寫） |
| **S3 頁面改造** | 詳情頁、登入頁、列表頁 | S2 | **高** | ⬜ 待辦 |
| **S4 收尾** | 篩選頁、Splash、移除假延遲、清理舊常數 | S3 | 中 | ⬜ 待辦 |

### S1 移交 S2 的債務清單

| # | 債務 | 承接 |
| :--- | :--- | :---: |
| T-1 | `sign_in_page.dart:183` 硬編碼藍 `Color.fromARGB(255, 5, 97, 245)`，品牌識別錯誤。S1 依 §4.3 定案不修（改它會污染「除 FilterChip 外外觀不變」的地基驗證，且單改主按鈕會做出「橘按鈕配灰入口」的半成品） | **S3** |
| T-2 | 33 處裸 `Colors.xxx`、13 個檔案（2026-08-03 複測數字未變） | S2 / S3 / S4 |
| T-3 | 10 個 `@Deprecated` 字級常數、29 處使用、14 個檔案待遷移 | ✅ **已於 S1 (PR #66) 移除並由 ThemeFontSize 替換** |
| T-6 | 奶油白 `surface` (`#FFFBF7`) 覆寫，D-4 的 3 個 `copyWith` 額度完整保留 | **S2** |
| **T-9（新增）** | **`colorScheme.primary` = `#8F4B38` ≠ 品牌色 `#D84A20`**，與 **19 處**硬編 `ThemeColor.appPrimary`（**8 檔**）並存有色差。須決定是否 `copyWith` 鎖回品牌色。⚠️ 2026-08-05 複測更正：原記 16 處／7 檔 | **S2** |

> **順序理由**：S2 完成後列表與最愛兩畫面同時改觀，是最快看到成果的切點。S1 單獨看幾乎無變化，但為 S2/S3 的前提。

### 驗證方式

**靜態**
* `flutter analyze` 維持 **`No issues found!`**（現為零警告，**不得回退**）
* `dart format` 通過

**視覺**
* 以 `mobile-mcp` 於模擬器實跑，逐頁截圖比對改造前後
* **必驗小螢幕**（iPhone SE / 375pt 寬）—— 登入頁版面重排的主要風險點

**功能回歸**
* 現有 13 個測試檔須全綠
* 手動驗證：列表滾動載入、收藏切換、篩選套用、訪客模式流程

**效能**
* Profile 模式下列表滾動不掉幀（每幀 < 16.6ms）
* 刪除 11 張 PNG 後確認 app bundle 縮小

### 實作時待決事項

| # | 事項 | 判準 | 狀態 |
| :--- | :--- | :--- | :--- |
| 1 | 骨架屏自繪 vs `shimmer` 套件 | 先自繪；超過 40 行改用套件 | ✅ **已於 S2 引入 `shimmer` 套件並完成 `Skeleton`** |
| 2 | 舊 `UIConstants` 字級常數何時刪 | S4 標 `@Deprecated`；全數遷移後另開獨立 PR 移除 | ✅ **已於 S1 移除**（10 個常數全數移除並替換為 ThemeFontSize，PR #66 完成） |
| 3 | `Colors.grey` 全域掃除 | 各階段順手改；S4 做最後一次 grep 確認歸零 | S1 刻意不掃（維持 AC-7 乾淨驗證），33 處原封不動 |
| **4（新增）** | `colorScheme.primary` 是否 `copyWith` 鎖回 `#D84A20` | 見 T-9。與 T-6 的 `surface` 覆寫一併決定，共用 D-4 的 3 個額度 | **S2 待決** |

---

## 6.8 明確排除範圍 (YAGNI — Out of Scope)

為避免範圍蔓延，本次**明確不做**：

| 排除項 | 理由 |
| :--- | :--- |
| ❌ 深色模式 | 見 D-3。`darkTheme` 留空，但 token 架構不阻擋未來補做 |
| ❌ 頁面轉場動畫、收藏彈跳動效 | 報酬遞減。**在還會硬等 2 秒的 App 上做轉場動畫，等於幫塞車的路口重鋪柏油** |
| ❌ 地圖 Carousel 雙向連動 | 屬 Phase 1.5 獨立功能，非美化範疇 |
| ❌ 情境化標籤 `#一人食` | 需 API 支援，是功能不是美化 |
| ❌ 設定頁、看圖頁改造 | 停留時間短、權重低 |
| ❌ 硬編碼 API Key、Firestore 重構 | 屬 P0 但非 UI 範疇，另案處理（見 §1.2 缺陷 2、4） |

---

## 6.9 與既有 Roadmap 的關係

本計畫為 **Phase 1.5 的前置地基**。原 Phase 1.5 的五項（地圖 Carousel、載入更多動畫、fluster 聚類、情境標籤、骨架屏）之中：

* **載入更多動畫** → 併入本計畫 §6.6.3
* **骨架屏 Shimmer** → 併入本計畫 §6.5.3
* 其餘三項（地圖 Carousel、fluster 聚類、情境標籤）維持原 Phase 1.5，**且應於本計畫 S1 完成後才動工** —— 它們都需要 theme 才能正確著色

### 更新後的 Phase 1.5 建議順序

```
+-----------------------------------------------------------------------------------+
| Phase 1.5: 空間與視覺體驗升級 (Spatial UX & Polish)                               |
|                                                                                   |
|  ── P-1 開發工具地基（先於一切，見 §2.0）──                                       |
|   • [x] 整合 flutter_inspector_kit (kDebugMode 圍住，release 零改變) ✅ 08-05     |
|                                                                                   |
|  ── 6.x UI 視覺重塑（本章，前置地基）──                                           |
|   • [x] S1 Design System 地基 (ThemeData / ColorScheme / token) ✅ 2026-08-03     |
|   • [ ] S2 共用元件重塑 (ItemCell / RatingStars✅ / Skeleton✅ / Empty)           |
|   • [ ] S3 頁面改造 (詳情頁 / 登入頁 / 列表頁)                                    |
|   • [ ] S4 收尾 (篩選頁 / Splash / 移除假延遲 / 清理舊常數)                       |
|                                                                                   |
|  ── 原 Phase 1.5 剩餘項（依賴 S1 完成）──                                         |
|   • ❌ P1 地圖與 BottomSheet Carousel 雙向平滑連動 (含點擊至詳情頁) - 缺乏實質效益已放棄 |
|   • ❌ P1 fluster 動態圖標聚類 (Clustering) - 使用者體驗不佳已暫緩/放棄 (Issue #76) |
|   • [ ] P1 情境化探索標籤 (#一人食 #深夜食堂 #約會不踩雷)                             |
+-----------------------------------------------------------------------------------+
```

---

*第 6 章產出時間：2026-07-31*
*產出方式：直接檢視 `lib/` 當前原始碼（分支 `release/202607/release-1.4.0(30)`, commit `c8c40ae`）*
*S1 交付覆核：2026-08-03（分支 `refactor/202607/57-design-system-foundation`, commit `9c2ec3f`）—— 實測 `flutter analyze` 零警告、`flutter test` 54 tests 全綠*
*實查校正：2026-08-05（分支 `main`, commit `f643502`）—— 見文首「實查校正紀錄」，4 項更正、6 項複測吻合、新增 P-1 項目；`flutter analyze` 維持 `No issues found!`*
*檔名日期前綴同步更新為 `2026-08-16`（原 `2026-08-05`，以 `git mv` 改名保留檔案歷史）。內文各處的舊日期屬史實紀錄，不隨檔名更動。*

# 廢棄/暫緩功能紀錄：F-1.3 Fluster Dynamic Marker Clustering

**日期**：2026-08-22
**相關 Issue / PR**：#76, #77

## 決策
使用者覺得目前使用 Dart 層運算（`Fluster`）來做地圖標記聚合（Marker Clustering）的體驗不好，因此決定先不做此功能。

## 後續動作
- 已關閉 GitHub Issue #76 
- 已關閉 GitHub PR #77
- 已移除相關的 Git Worktree 隔離工作區

未來若要重啟此功能，建議重新評估以下方案：
1. 等待官方 `google_maps_flutter` 內建更成熟的原生聚合 (ClusterManager) 方案。
2. 評估其他原生封裝的第三方套件，將運算壓力交給底層 C++/Java/Objective-C 處理，以改善操作體驗。
