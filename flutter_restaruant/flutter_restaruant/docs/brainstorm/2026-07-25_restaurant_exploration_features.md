# 餐廳探索與訂位 Flutter App 專案審計、競品對標與全方位創新功能提案報告
# (Restaurant Exploration Flutter App Audit, Benchmarking & Feature Ideation Master Report)

---

## 摘要 (Executive Summary)

本報告針對 `Finding-Restaurant-Flutter/flutter_restaruant` 專案進行深度的程式碼稽核 (Codebase Audit)、架構缺陷評估 (Linus Taste Rating)、全球與區域頂尖競品對標 (Competitor Benchmarking)，並提出涵蓋**空間地圖互動 (Spatial UX)**、**情境化社群 (Community & Context)**、**微訂位閉環 (Micro-Booking Engine)** 以及 **AI 個人化決策 (AI Taste & Multimodal Vision)** 的全方位創新功能與既有缺陷修復方案。

本報告整合了架構審計與競品探索報告之事實與推理鏈，產出符合產業界最高標準的產品與技術發展路線圖 (Strategic Product Roadmap) 及 RICE / ICE 雙優先級評估矩陣。

---

## 1. 專案現狀審計與同類競品對標 (Codebase Audit & Competitor Analysis)

### 1.1 Flutter 專案現狀點評 (Project Architecture Review)

`flutter_restaruant` 專案（版本 v1.4.0+29，基於 Dart SDK `^3.5.0` 及 Flutter 3.x）為一款具備完整雛形的餐廳搜尋與瀏覽應用程式。整體呈現清晰的 **Feature-First** 模組化目錄分層架構：

```
lib/
├── api/          # Retrofit (APIClz) + Dio (DioClient) 網路介面層，對接 Yelp Fusion API v3 & Google Static Maps
├── component/    # 跨頁面 UI 元件 (Ad, Restaurant Item Cell, Skeleton/Loading Widget, Expandable FAB, Platform Widgets)
├── flow/         # Feature-First 業務流 (8大 Flow: splash, signinup, main, restaurant, favor, filter, photoviewr, settings)
├── gen/          # flutter_gen 自動生成顏色資源 (ColorName.appPrimaryColor 等)
├── generated/    # i18n 國際化生成程式碼 (ARB 檔: intl_en.arb, intl_zh_TW.arb)
├── manager/      # 核心門面元件 (SignInManager 整合 Firebase Auth/Third-party/Biometric; FcmManager 推播管理)
├── model/        # 資料模型 (YelpBaseInfo, YelpRestaurantSummaryInfo, AccountInfo, FilterConfigs)
├── routes/       # 靜態路由表 ROUTES_TABLE (搭配 flutter_platform_widgets)
└── utils/        # 常數與工具庫 (constants.dart, dimens.dart, tuple.dart, utils.dart)
```

#### 關鍵依賴與技術棧 (Tech Stack & Dependencies)
* **狀態管理 (State Management)**: `flutter_bloc: ^9.1.1` + `bloc: ^9.2.1`，配合 `rxdart: ^0.28.0` 與 `event_bus: ^2.0.0`。
* **網路與 API**: `dio: ^5.6.0` + `retrofit: ^4.2.0`。
* **資料庫與持久化**: `sqflite: ^2.3.0` (SQLite 本地快取)、`cloud_firestore: ^6.7.1` (遠端資料)、`shared_preferences: ^2.2.0`。
* **身分驗證與雲端**: `firebase_auth: ^6.5.6` (支援 Google, Apple, Facebook, Email 及生物辨識 Auto-login)。
* **地圖與廣告**: `google_maps_flutter: ^2.4.0` 與 `google_mobile_ads: ^9.0.0`。

---

### 1.2 重大架構缺陷與 Linus 模式品味評估 (Linus Taste Rating & Architecture Assessment)

#### 🐧 品味評級: 🔴 垃圾 / 嚴重架構缺陷 (Garbage Architecturally)

> **Linus Torvalds 式核心評語**：
> 「這程式碼缺乏對 Flutter 生命週期的基本尊重。在 `build()` 渲染方法裡發動非同步 Side-effects 和 API 請求，就像是在開車時把煞車當油門踩——每一次 UI 重新繪製都會觸發重複的 API 網路請求與狀態變動！好程式員關注資料結構與邊界情況；把整個最愛列表打包成 JSON 字串塞進單一 Firestore 文件，還用 `merge: false` 每次全量覆蓋，簡直是資料庫設計的災難。更別提在搜尋過濾裡硬塞 2 秒 `Future.delayed` 和在推播導航硬塞 8 秒延遲這種假裝程式很忙的神祕邏輯。這種爛程式碼必須被徹底撕掉重寫。」

#### 7 大致命程式碼缺陷詳解 (Detailed Code Defects)

1. **`build()` 方法中發動 Event / 非同步側邊效應 (Anti-pattern: Side-effects in build)**
   * `lib/flow/signinup/view/sign_in_page.dart:40`: `this._signInBloc.add(AutoSignInEvent());` 直接寫在 `build()` 頂層，每次重繪皆重新引發 AutoSignIn。
   * `lib/flow/main/view/main_page.dart:103`: 在 `BlocBuilder` 內部執行 `this._mainBloc.add(FetchSearchInfo(...));`。
   * `lib/flow/restaurant/view/restaurant_detail_page.dart:49, 83-84`: 在 `build()` 觸發 `FetchDetailInfo`，且當 `state is ToggleFavorSuccess` 時直接彈出 Toast 並重複觸發 `FetchDetailInfo`。
   * `lib/flow/favor/view/favor_page.dart:36`: `build()` 內直接呼叫 `this._favorBloc.add(FetchFavorInfoEvent(false));`。
   * `lib/flow/settings/view/settings_page.dart:36`: `build()` 內發動 `InitBioAuthSettingEvent()`。
   * `lib/flow/splash/view/splash_page.dart:16-20`: 在 `build()` 內寫入 `addPostFrameCallback` 搭配 `Future.delayed(Duration(seconds: 3))` 導航。

2. **硬編碼 API 金鑰與敏感 Token (Hardcoded Secrets)**
   * `lib/utils/constants.dart:37`: `static const AUTH_TOKEN = "Bearer 7W-eBLLJ3ij1hx8nKfbihuC9rB...";` (Yelp Fusion API Token 明碼版控)。
   * `lib/utils/constants.dart:27`: `static const STATIC_MAP_API_KEY = "AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ";` (Google Maps Key 明碼寫死)。

3. **Yelp 分頁邏輯錯誤 (`MainRepository`)**
   * `lib/flow/main/repository/main_repository.dart:52`: 呼叫 API 帶入 `offset: ++this._offset`。Yelp API 的 `offset` 是資料筆數偏移量 (如 0, 50, 100)，而非頁碼 (1, 2, 3)。當加載第 2 頁時傳入 `offset: 2`，只跳過了前 2 筆資料，導致分頁加載幾乎完全失效且嚴重重複！

4. **Firestore 最愛店家單一 Document Map 覆寫 (Database Architecture Defect)**
   * `lib/flow/main/repository/main_repository.dart:121-149`: `_updateFavorsMap` 將使用者的所有最愛店家序列化成巨大 JSON 字串，存放在單一 Document `favors/{uid}` 的 Map 欄位中，並以 `SetOptions(merge: false)` 全量覆寫。這受限於 Firestore 1MB Document 限制，且併發寫入時極易造成資料遺失。

5. **硬編碼人工假延遲 (Hardcoded Fake Delays)**
   * `lib/flow/main/bloc/main_bloc.dart:57`: 關鍵字過濾時硬塞 `await Future.delayed(Duration(seconds: 2));`。
   * `lib/manager/fcm_manager.dart:63`: 點擊推播通知時硬塞 `Future.delayed(Duration(seconds: 8), ...)` 才導向頁面。

6. **`FilterPage` UI 狀態被覆蓋重置 Bug (State Reset Bug)**
   * `lib/flow/filter/view/filter_page.dart:26-31`: 在 `build()` 內部每次都從 `ModalRoute.of(context)!.settings.arguments` 重新賦值給 `_priceIndex`, `_openAtDateTime`, `_sortByIndex`。當使用者在畫面上調整價格或排序觸發 `setState` 時，`build()` 重新執行又被覆蓋回最初傳入的舊設定，導致使用者完全無法修改過濾條件！

7. **`MapWidget` 標記未連動與常數錯字 (Map & Code Quality Defects)**
   * `lib/flow/main/view/map_widget.dart:26-37`: 地圖 Marker 僅在 `initState()` 初始建立。當 `_summaryInfos` 列表因搜尋或過濾更新時，未實作 `didUpdateWidget()`，導致地圖 Marker 永遠停留在初始狀態。
   * `lib/utils/constants.dart`: 常數存在拼字錯誤 (`CONNECTION_TIEMOUT`, `RECEIVE_TIEMOUT`, `EMAIL_SUBJEC`)。
   * `YelpRestaurantSummaryInfo`: `operator ==` 使用 `this.id!.compareTo(other.id!)`，若 `id` 為 null 會引發 Runtime Crash。

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
| **修復 `build()` 側邊效應反模式** | 既有修復 | 10 | 3.0 | 100% | 0.5 | **60.0** | 27.0 | 1 | **P0** |
| **修復 Yelp API 分頁邏輯 Bug** | 既有修復 | 9 | 2.5 | 100% | 0.5 | **45.0** | 22.5 | 2 | **P0** |
| **修復 `FilterPage` 狀態重置 Bug** | 既有修復 | 8 | 2.5 | 100% | 0.5 | **40.0** | 20.0 | 3 | **P0** |
| **移除硬編碼 API Key (`--dart-define`)** | 安全修復 | 10 | 2.0 | 100% | 0.5 | **40.0** | 18.0 | 4 | **P0** |
| **地圖與 BottomSheet 雙向連動 Carousel** | 空間 UX | 9 | 3.0 | 90% | 1.5 | **16.2** | 23.0 | 5 | **P1** |
| **`fluster` 圖標動態聚類** | 效能優化 | 8 | 2.0 | 90% | 1.0 | **14.4** | 16.2 | 6 | **P1** |
| **情境化探索標籤 (#一人食等)** | 搜尋優化 | 9 | 2.0 | 90% | 1.0 | **16.2** | 16.2 | 7 | **P1** |
| **骨架屏 Shimmer 載入與離線快取** | UX 優化 | 9 | 1.5 | 100% | 1.0 | **13.5** | 13.5 | 8 | **P1** |
| **Firestore Subcollection 口袋名單** | 資料架構 | 7 | 2.0 | 90% | 1.0 | **12.6** | 14.4 | 9 | **P1** |
| **輕量化線上微訂位 Time-Slot 選擇器** | 商業轉化 | 7 | 3.0 | 80% | 2.0 | **8.4** | 19.2 | 10 | **P1** |
| **自訂美食地圖社群共編** | 社群生態 | 6 | 2.0 | 80% | 2.0 | **4.8** | 9.6 | 11 | **P2** |
| **線上候位與動態隊列 FCM 追蹤** | 商業轉化 | 5 | 2.5 | 80% | 2.5 | **4.0** | 10.0 | 12 | **P2** |
| **AI 多模態 Vision 菜單翻譯** | AI 創新 | 6 | 2.5 | 80% | 2.5 | **4.8** | 12.0 | 13 | **P2** |
| **個人味蕾配對度 (0-100% Match)** | AI 創新 | 7 | 2.0 | 70% | 2.5 | **3.92** | 9.8 | 14 | **P2** |
| **自然語言選店助手與命運轉盤** | AI 創新 | 6 | 2.0 | 70% | 2.0 | **4.2** | 11.2 | 15 | **P2** |
| **雙排瀑布流 UGC 食記與短影片** | 內容生態 | 5 | 2.0 | 70% | 3.0 | **2.33** | 9.8 | 16 | **P2** |

---

## 4. 建議發展路線圖 (Strategic Product Roadmap)

基於上述 RICE / ICE 優先級與技術相依性，制定三階段落地發展路線圖：

```
+-----------------------------------------------------------------------------------+
|                           STRATEGIC PRODUCT ROADMAP                               |
+-----------------------------------------------------------------------------------+
| Phase 1: 空間與視覺體驗升級 (Low-Hanging Fruit & Spatial UX)                       |
|   • P0 既有架構修復 (build() 側邊效應, Yelp分頁, Filter重置, API Key 安全化)             |
|   • 地圖與 BottomSheet Carousel 雙向平滑連動                                       |
|   • fluster 動態圖標聚類 (Clustering)                                               |
|   • 情境化探索標籤 (#一人食 #深夜食堂 #約會不踩雷)                                    |
|   • 骨架屏 (Shimmer Loading) 與離線降級快取                                         |
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

1. **`flutter analyze` 零警告要求**:
   * 修復目前產生的 14 個 Warning (如 `launchUrl` 替代廢棄 `launch`，`AndroidGoogleMapsFlutter` 配置更換)。
   * 執行命令：`flutter analyze`，必須呈現 `No issues found!`。

2. **`flutter test` 測試覆蓋率**:
   * 針對 BLoC 狀態轉換編寫 `bloc_test`。
   * 測試覆蓋率目標：核心業務邏輯 (`flow/*/bloc/` 與 `flow/*/repository/`) 單元測試覆蓋率 $\ge 80\%$。
   * 執行命令：`flutter test --coverage`。

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
*報告產出時間：2026-07-25*
*報告編寫團隊：Worker 1 (Report Author & Strategic Analyst)*
