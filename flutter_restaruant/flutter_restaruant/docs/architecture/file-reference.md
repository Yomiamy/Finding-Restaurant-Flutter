# Finding Restaurant App - 檔案用途與類型參考表 (File Reference)

本文件列出專案中所有核心源檔的單一職責、包含的關鍵類別與模組歸屬，以作為新加入的貢獻者快速熟悉專案結構的指南。

> **命名慣例**：檔案 `snake_case`、類別 `PascalCase`、變數 `camelCase`。各目錄皆有 `*_barrel.dart` 統一導出，import 時優先用 barrel 而非逐檔引用。
>
> **自動產生檔**：`*.g.dart` 由 `build_runner` 產生（`json_serializable` / `retrofit_generator`），**不應手動編輯**。本表只列來源檔，不逐一列出對應的 `.g.dart`。

---

## 📂 核心模組與檔案結構

### 1. 入口與組合根 (`lib/` 根目錄、`lib/di/`、`lib/routes/`)

| 檔案路徑 | 關鍵類別/變數 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/main.dart`](../../lib/main.dart) | `main()`<br>`FindingRestaruantApp`<br>`navigatorKey` | App 入口。初始化 binding、DI、Firebase 與登入狀態後 `runApp`。組裝 `PlatformApp`（iOS/Android 雙分支）、掛載 `navigatorKey`、`navigatorObservers` 與 debug-only 的 5 連點喚起手勢。 |
| [`lib/di/injection.dart`](../../lib/di/injection.dart) | `getIt`<br>`setupInjection()` | GetIt 依賴注入註冊中心。以**介面為 key、實作為 value** 註冊全部 Repository、DataSource 與 Manager，全數 `registerLazySingleton`。 |
| [`lib/di/inspector.dart`](../../lib/di/inspector.dart) | `inspector` | Debug-only 除錯工具實例（頂層 `final FlutterInspector?`）。`kDebugMode` 為 false 時恆為 `null`，release build 中所有引用點成為 dead code 被 tree-shaking 移除。 |
| [`lib/routes/routes_table.dart`](../../lib/routes/routes_table.dart) | `routesTable` | **Composition Root**。路由名稱 → WidgetBuilder 的對照表，是全 App 唯一把「路由 / Bloc / Repository」接起來的地方（`BlocProvider` + `GetIt.I<介面>()`）。 |
| [`lib/firebase_options.dart`](../../lib/firebase_options.dart) | `DefaultFirebaseOptions` | FlutterFire CLI 產生的各平台 Firebase 設定，供 `Firebase.initializeApp` 使用。 |

### 2. 領域層 — 契約與業務模型 (`lib/domain/`)

> ⚠️ **本層不依賴 I/O 技術**：全目錄無 `dio`、`cloud_firestore`、`retrofit` 等 import。
>
> 🔴 **但有已知反向依賴**：11 個 entity 檔案全數 import `data_layer/dto/dto_barrel.dart`（因 `fromDto`/`toDto` 寫在 Entity 上），其中 `UserEntity` ⇄ `AccountDto` 為真實循環。5 個 Repository 介面則完全乾淨。詳見 [`overview.md`](./overview.md#-已知架構缺陷entity-反向依賴-dto)。

| 檔案路徑 | 關鍵類別/列舉 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/domain/repositories/main_repository.dart`](../../lib/domain/repositories/main_repository.dart) | `MainRepository` | 主畫面資料契約（`abstract interface class`）：Yelp 搜尋、關鍵字過濾、最愛切換。 |
| [`lib/domain/repositories/restaurant_detail_repository.dart`](../../lib/domain/repositories/restaurant_detail_repository.dart) | `RestaurantDetailRepository` | 餐廳詳情與評論的資料契約。 |
| [`lib/domain/repositories/favor_repository.dart`](../../lib/domain/repositories/favor_repository.dart) | `FavorRepository` | 最愛清單的讀取與切換契約。 |
| [`lib/domain/repositories/sign_in_repository.dart`](../../lib/domain/repositories/sign_in_repository.dart) | `SignInRepository` | 登入／登出／帳號狀態的資料契約。 |
| [`lib/domain/repositories/settings_repository.dart`](../../lib/domain/repositories/settings_repository.dart) | `SettingsRepository` | 設定頁的資料契約。 |
| [`lib/domain/entities/restaurant_entity.dart`](../../lib/domain/entities/restaurant_entity.dart) | `RestaurantEntity` | 餐廳摘要業務模型。持有 `fromDto` 具名建構式與 `copyWith`，欄位全 nullable 以容忍 Yelp 回傳缺漏。 |
| [`lib/domain/entities/restaurant_detail_entity.dart`](../../lib/domain/entities/restaurant_detail_entity.dart) | `RestaurantDetailEntity` | 餐廳詳情業務模型（含營業時間、座標、照片集）。 |
| [`lib/domain/entities/review_entity.dart`](../../lib/domain/entities/review_entity.dart) | `ReviewEntity` | 評論集合業務模型。 |
| [`lib/domain/entities/review_detail_entity.dart`](../../lib/domain/entities/review_detail_entity.dart) | `ReviewDetailEntity` | 單筆評論內容。 |
| [`lib/domain/entities/reviewer_entity.dart`](../../lib/domain/entities/reviewer_entity.dart) | `ReviewerEntity` | 評論者資訊。 |
| [`lib/domain/entities/user_entity.dart`](../../lib/domain/entities/user_entity.dart) | `UserEntity` | 使用者帳號業務模型。 |
| [`lib/domain/entities/restaurant_category_entity.dart`](../../lib/domain/entities/restaurant_category_entity.dart) | `RestaurantCategoryEntity` | 餐廳分類標籤。 |
| [`lib/domain/entities/restaurant_location_entity.dart`](../../lib/domain/entities/restaurant_location_entity.dart) | `RestaurantLocationEntity` | 地址資訊。 |
| [`lib/domain/entities/restaurant_coordinates_entity.dart`](../../lib/domain/entities/restaurant_coordinates_entity.dart) | `RestaurantCoordinatesEntity` | 經緯度座標。 |
| [`lib/domain/entities/restaurant_business_time_entity.dart`](../../lib/domain/entities/restaurant_business_time_entity.dart) | `RestaurantBusinessTimeEntity` | 單段營業時間。 |
| [`lib/domain/entities/restaurant_hours_entity.dart`](../../lib/domain/entities/restaurant_hours_entity.dart) | `RestaurantHoursEntity` | 營業時間集合與是否營業中。 |

### 3. 資料層 — 契約實作與外部來源 (`lib/data_layer/`)

| 檔案路徑 | 關鍵類別/列舉 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/data_layer/repositories/main_repo.dart`](../../lib/data_layer/repositories/main_repo.dart) | `MainRepo` | `MainRepository` 實作。呼叫 Yelp API 取 Dto → 轉 Entity，並合併 Firestore 的最愛狀態（`copyWith(favor:)`）。 |
| [`lib/data_layer/repositories/restaurant_detail_repo.dart`](../../lib/data_layer/repositories/restaurant_detail_repo.dart) | `RestaurantDetailRepo` | `RestaurantDetailRepository` 實作。取得詳情與評論並轉為 Entity。 |
| [`lib/data_layer/repositories/favor_repo.dart`](../../lib/data_layer/repositories/favor_repo.dart) | `FavorRepo` | `FavorRepository` 實作，委派 `FavorDataSource` 存取 Firestore。 |
| [`lib/data_layer/repositories/sign_in_repo.dart`](../../lib/data_layer/repositories/sign_in_repo.dart) | `SignInRepo` | `SignInRepository` 實作，串接各登入 Manager 並轉出 `UserEntity`。 |
| [`lib/data_layer/repositories/settings_repo.dart`](../../lib/data_layer/repositories/settings_repo.dart) | `SettingsRepo` | `SettingsRepository` 實作（`const` 建構式，無狀態）。 |
| [`lib/data_layer/datasources/favor_data_source.dart`](../../lib/data_layer/datasources/favor_data_source.dart) | `FavorDataSource` | **最愛清單在 Firestore 的單一存取點**，每個最愛項目以 subcollection `favors/{uid}/items/{restaurant_id}` 結構儲存。內含空字串 uid 的 guard，避免 Firestore 拋 `ArgumentError`。 |
| [`lib/data_layer/dto/yelp_search_dto.dart`](../../lib/data_layer/dto/yelp_search_dto.dart) | `YelpSearchDto` | Yelp 搜尋結果的線上格式鏡射（`@JsonSerializable`）。 |
| [`lib/data_layer/dto/yelp_restaurant_summary_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_summary_dto.dart) | `YelpRestaurantSummaryDto` | 餐廳摘要 Dto，對應 `RestaurantEntity`。 |
| [`lib/data_layer/dto/yelp_restaurant_detail_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_detail_dto.dart) | `YelpRestaurantDetailDto` | 餐廳詳情 Dto。 |
| [`lib/data_layer/dto/yelp_review_dto.dart`](../../lib/data_layer/dto/yelp_review_dto.dart) | `YelpReviewDto` | 評論集合 Dto。 |
| [`lib/data_layer/dto/yelp_review_detail_dto.dart`](../../lib/data_layer/dto/yelp_review_detail_dto.dart) | `YelpReviewDetailDto` | 單筆評論 Dto。 |
| [`lib/data_layer/dto/yelp_reviewer_dto.dart`](../../lib/data_layer/dto/yelp_reviewer_dto.dart) | `YelpReviewerDto` | 評論者 Dto。 |
| [`lib/data_layer/dto/yelp_restaurant_category_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_category_dto.dart) | `YelpRestaurantCategoryDto` | 分類 Dto。 |
| [`lib/data_layer/dto/yelp_restaurant_location_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_location_dto.dart) | `YelpRestaurantLocationDto` | 地址 Dto。 |
| [`lib/data_layer/dto/yelp_restaurant_coordinates_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_coordinates_dto.dart) | `YelpRestaurantCoordinatesDto` | 座標 Dto。 |
| [`lib/data_layer/dto/yelp_restaurant_business_time_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_business_time_dto.dart) | `YelpRestaurantBusinessTimeDto` | 營業時段 Dto。 |
| [`lib/data_layer/dto/yelp_restaurant_hours_dto.dart`](../../lib/data_layer/dto/yelp_restaurant_hours_dto.dart) | `YelpRestaurantHoursDto` | 營業時間 Dto。 |
| [`lib/data_layer/dto/account_dto.dart`](../../lib/data_layer/dto/account_dto.dart) | `AccountDto` | 帳號資料 Dto，對應 `UserEntity`。 |

### 4. 網路層 (`lib/api/`)

| 檔案路徑 | 關鍵類別/變數 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/api/api_clz.dart`](../../lib/api/api_clz.dart) | `APIClz`（`@RestApi`）<br>`dioClient`<br>`apiInstance` | Yelp Fusion API 的型別安全宣告（Retrofit）。同時以 IIFE 建構 `dioClient`：先掛 auth `InterceptorsWrapper` 注入 `Authorization`，**再掛** debug-only 的 `FlutterInspectorDioInterceptor`——順序決定除錯面板看得到已注入 header 的真實請求。 |
| [`lib/api/dio/dio_client.dart`](../../lib/api/dio/dio_client.dart) | `DioClient` | Dio 實例的封裝載體，提供 `dio` getter 供攔截器掛載與 Retrofit 使用。 |
| [`lib/api/google_api_util.dart`](../../lib/api/google_api_util.dart) | `GoogleApiUtil` | Google Maps 相關 API 的輔助工具。 |

### 5. 表現層 — Feature 垂直切片 (`lib/flow/`)

每個 feature 皆為 `bloc/`（Bloc + Event + State 三檔）與 `view/`（Page 與其專屬 Widget）的組合。

> **本表的收錄規則**：`main` feature 的 Event / State 檔已完整列出作為**參考範本**，其餘 feature 的 `*_event.dart` / `*_state.dart` 結構與之同形（Event 繼承 `Equatable` 基類、State 以互斥具名子類別表達），故不逐檔重複列舉。`lib/component/ad/*_state.dart` 三檔為廣告元件的內部狀態載體，同理省略。

| 檔案路徑 | 關鍵類別 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/flow/splash/view/splash_page.dart`](../../lib/flow/splash/view/splash_page.dart) | `SplashPage` | 啟動頁。延遲後依 `SignInManager().isGuest` 導向主畫面或登入頁；並在 debug 下掛載 Inspector 常駐 FAB。 |
| [`lib/flow/main/bloc/main_bloc.dart`](../../lib/flow/main/bloc/main_bloc.dart) | `MainBloc` | 主畫面業務邏輯：搜尋、載入更多、關鍵字過濾、最愛切換、推播設定。 |
| [`lib/flow/main/bloc/main_event.dart`](../../lib/flow/main/bloc/main_event.dart) | `MainEvent`<br>`FetchSearchInfo`<br>`FilterListByKeyword`<br>`ToggleFavor`<br>`Reset`<br>`NotificationSetup` | 主畫面事件定義（`Equatable`）。 |
| [`lib/flow/main/bloc/main_state.dart`](../../lib/flow/main/bloc/main_state.dart) | `MainState`<br>`MainInitial` / `InProgress` / `Success` / `Failure` / `LoadMoreSuccess` / `ResetSuccess` / `ToggleFavorSuccess` | 主畫面狀態。以**具名子類別**表達互斥狀態，而非布林旗標組合。 |
| [`lib/flow/main/view/main_page.dart`](../../lib/flow/main/view/main_page.dart) | `MainPage` | 主畫面（地圖 + 列表）。 |
| [`lib/flow/main/view/map_widget.dart`](../../lib/flow/main/view/map_widget.dart) | `MapWidget` | Google Maps 地圖與 Marker 呈現。 |
| [`lib/flow/main/view/restaurant_info_list_widget.dart`](../../lib/flow/main/view/restaurant_info_list_widget.dart) | `RestaurantInfoListWidget` | 餐廳列表（含載入更多）。 |
| [`lib/flow/main/view/filter_tags_widget.dart`](../../lib/flow/main/view/filter_tags_widget.dart) | `FilterTagsWidget` | 已套用篩選條件的標籤列。 |
| [`lib/flow/restaurant/bloc/restaurant_detail_bloc.dart`](../../lib/flow/restaurant/bloc/restaurant_detail_bloc.dart) | `RestaurantDetailBloc` | 餐廳詳情頁業務邏輯。 |
| [`lib/flow/restaurant/view/restaurant_detail_page.dart`](../../lib/flow/restaurant/view/restaurant_detail_page.dart) | `RestaurantDetailPage` | 餐廳詳情頁。 |
| [`lib/flow/favor/bloc/favor_bloc.dart`](../../lib/flow/favor/bloc/favor_bloc.dart) | `FavorBloc` | 最愛清單業務邏輯。 |
| [`lib/flow/favor/view/favor_page.dart`](../../lib/flow/favor/view/favor_page.dart) | `FavorPage` | 最愛清單頁。 |
| [`lib/flow/signinup/bloc/sign_in_bloc.dart`](../../lib/flow/signinup/bloc/sign_in_bloc.dart) | `SignInBloc` | 登入流程業務邏輯（多種登入方式分派）。 |
| [`lib/flow/signinup/view/sign_in_page.dart`](../../lib/flow/signinup/view/sign_in_page.dart) | `SignInPage` | 登入頁。 |
| [`lib/flow/settings/bloc/settings_bloc.dart`](../../lib/flow/settings/bloc/settings_bloc.dart) | `SettingsBloc` | 設定頁業務邏輯。 |
| [`lib/flow/settings/view/settings_page.dart`](../../lib/flow/settings/view/settings_page.dart) | `SettingsPage` | 設定頁。 |
| [`lib/flow/filter/view/filter_page.dart`](../../lib/flow/filter/view/filter_page.dart) | `FilterPage` | 搜尋條件篩選頁（無 Bloc，以本地狀態管理）。 |
| [`lib/flow/photo_viewer/view/photo_viewer.dart`](../../lib/flow/photo_viewer/view/photo_viewer.dart) | `PhotoViewer` | 全螢幕照片瀏覽（無 Bloc）。 |
| [`lib/flow/splash/bloc/splash_bloc.dart`](../../lib/flow/splash/bloc/splash_bloc.dart) | `SplashBloc` | 啟動頁業務邏輯。 |

### 6. 共用元件層 (`lib/component/`)

| 檔案路徑 | 關鍵類別 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/component/platform_widget.dart`](../../lib/component/platform_widget.dart) | `PlatformWidget<I, A>` | **iOS/Android 外觀分歧的抽象基底**。泛型約束兩平台的回傳型別，子類別必須同時實作 `createIosWidget` 與 `createAndroidWidget`，漏寫則編譯失敗。 |
| [`lib/component/loading_widget.dart`](../../lib/component/loading_widget.dart) | `LoadingWidget` | 統一的載入中指示器。 |
| [`lib/component/empty_data_widget.dart`](../../lib/component/empty_data_widget.dart) | `EmptyDataWidget` | 統一的空資料狀態呈現。 |
| [`lib/component/rating_stars.dart`](../../lib/component/rating_stars.dart) | `RatingStars` | 星等評分繪製元件（以 Flutter 內建 Icon 取代舊版 11 張 PNG）。 |
| [`lib/component/skeleton.dart`](../../lib/component/skeleton.dart) | `Skeleton` | Shimmer 骨架屏基底元件。 |
| [`lib/component/cell/main_page/restaurant_item_skeleton.dart`](../../lib/component/cell/main_page/restaurant_item_skeleton.dart) | `RestaurantItemSkeleton` | 餐廳列表卡片骨架屏。 |
| [`lib/component/cell/main_page/restaurant_item_cell.dart`](../../lib/component/cell/main_page/restaurant_item_cell.dart) | `RestaurantItemCell` | 餐廳列表卡片（列表與最愛頁共用）。 |
| [`lib/component/cell/restaurant_detail/restaurant_head_cell.dart`](../../lib/component/cell/restaurant_detail/restaurant_head_cell.dart) | `RestaurantHeadCell` | 詳情頁頁首（名稱、評分、價位）。 |
| [`lib/component/cell/restaurant_detail/restaurant_info_cell.dart`](../../lib/component/cell/restaurant_detail/restaurant_info_cell.dart) | `RestaurantInfoCell` | 詳情頁基本資訊列。 |
| [`lib/component/cell/restaurant_detail/restaurant_image_cell.dart`](../../lib/component/cell/restaurant_detail/restaurant_image_cell.dart) | `RestaurantImageCell` | 詳情頁照片輪播。 |
| [`lib/component/cell/restaurant_detail/restaurant_business_hour_cell.dart`](../../lib/component/cell/restaurant_detail/restaurant_business_hour_cell.dart) | `RestaurantBusinessHourCell` | 詳情頁營業時間。 |
| [`lib/component/cell/restaurant_detail/restaurant_comment_cell.dart`](../../lib/component/cell/restaurant_detail/restaurant_comment_cell.dart) | `RestaurantCommentCell` | 詳情頁評論卡片。 |
| [`lib/component/ad/banner_ad.dart`](../../lib/component/ad/banner_ad.dart) | `BannerAdWidget` | AdMob 橫幅廣告元件。 |
| [`lib/component/ad/interstitial_ad.dart`](../../lib/component/ad/interstitial_ad.dart) | `InterstitialAd` | 插頁廣告載入與展示。 |
| [`lib/component/ad/app_open_ad.dart`](../../lib/component/ad/app_open_ad.dart) | `AppOpenAd` | 開屏廣告。 |
| [`lib/component/ad/app_lifecycle_reactor.dart`](../../lib/component/ad/app_lifecycle_reactor.dart) | `AppLifecycleReactor` | 監聽 App 前景/背景切換以觸發開屏廣告。 |

### 7. 管理層 — 第三方 SDK 封裝 (`lib/manager/`)

> 全數採同一套 Singleton 模式：`static final _singleton` + `factory` 回傳同一實例。每個 Manager 只封裝**一個** SDK 的互動細節。

| 檔案路徑 | 關鍵類別 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/manager/sign_in_manager.dart`](../../lib/manager/sign_in_manager.dart) | `SignInManager` | 登入狀態的單一真實來源（含 `isGuest` 訪客模式判定），供 UI 同步查詢。 |
| [`lib/manager/fcm_manager.dart`](../../lib/manager/fcm_manager.dart) | `FcmManager` | Firebase Cloud Messaging 推播權限申請、token 管理與訊息處理。 |
| [`lib/manager/ad_counter_manager.dart`](../../lib/manager/ad_counter_manager.dart) | `AdCounterManager` | 廣告展示次數計數，決定何時顯示插頁廣告。 |
| [`lib/manager/google_sign_in_manager.dart`](../../lib/manager/google_sign_in_manager.dart) | `GoogleSignInManager` | Google 登入流程。 |
| [`lib/manager/apple_sign_in_manager.dart`](../../lib/manager/apple_sign_in_manager.dart) | `AppleSignInManager` | Apple 登入流程（iOS 必備）。 |
| [`lib/manager/facebook_sign_in_manager.dart`](../../lib/manager/facebook_sign_in_manager.dart) | `FacebookSignInManager` | Facebook 登入流程。 |
| [`lib/manager/mail_sign_in_up_manager.dart`](../../lib/manager/mail_sign_in_up_manager.dart) | `MailSignInUpManager` | Email/密碼註冊與登入。 |
| [`lib/manager/auto_sign_in_manager.dart`](../../lib/manager/auto_sign_in_manager.dart) | `AutoSignInManager` | 自動登入（憑證持久化與還原）。 |
| [`lib/manager/biometric_sign_in_manager.dart`](../../lib/manager/biometric_sign_in_manager.dart) | `BiometricSignInManager` | 生物辨識（Face ID / 指紋）登入。 |

### 8. 基礎設施 — 設計 Token 與工具 (`lib/features/`)

| 檔案路徑 | 關鍵類別 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/features/foundation/style/theme_data.dart`](../../lib/features/foundation/style/theme_data.dart) | `AppThemeData` | App 主題定義。`materialLight` 的色票**只做 `ColorScheme.fromSeed`、零 `copyWith` 覆寫**；另提供 `cupertinoLight` 供 iOS 分支使用。 |
| [`lib/features/foundation/style/theme_color.dart`](../../lib/features/foundation/style/theme_color.dart) | `ThemeColor` | 色彩 Token 常數。 |
| [`lib/features/foundation/style/theme_size.dart`](../../lib/features/foundation/style/theme_size.dart) | `ThemeSize` | 尺寸與間距 Token 常數。 |
| [`lib/features/foundation/style/theme_font_size.dart`](../../lib/features/foundation/style/theme_font_size.dart) | `ThemeFontSize` | 字級 Token 常數。 |
| [`lib/features/foundation/style/theme_text_style.dart`](../../lib/features/foundation/style/theme_text_style.dart) | `ThemeTextStyle` | 文字樣式 Token。 |
| [`lib/features/foundation/constants/constants.dart`](../../lib/features/foundation/constants/constants.dart) | `Constants` | 全域常數（API base URL、`authToken` 等）。 |
| [`lib/features/foundation/constants/ui_constants.dart`](../../lib/features/foundation/constants/ui_constants.dart) | `UIConstants` | UI 專用常數。 |
| [`lib/features/foundation/extension/future_extension.dart`](../../lib/features/foundation/extension/future_extension.dart) | `FutureExtension` | `Future` 的擴充方法。 |
| [`lib/features/utils/tuple.dart`](../../lib/features/utils/tuple.dart) | `Tuple2` … `Tuple7` | 泛型多值容器。<br>⚠️ **Dart 3 已內建 Records**，新程式碼應優先使用 `(a, b)` 語法，本檔屬既有程式碼的相容保留。 |
| [`lib/features/utils/view_utils.dart`](../../lib/features/utils/view_utils.dart) | `ViewUtils` | 通用 UI 輔助（對話框、提示等）。 |
| [`lib/features/utils/utils.dart`](../../lib/features/utils/utils.dart) | `Utils` | 泛用工具函式集。 |

### 9. 資料傳輸與在地化 (`lib/model/`、`lib/l10n/`、`lib/gen/`)

| 檔案路徑 | 關鍵類別 | 單一職責 (Single Responsibility) |
| :--- | :--- | :--- |
| [`lib/model/result_vo.dart`](../../lib/model/result_vo.dart) | `ResultVo` | 通用結果包裝（`@JsonSerializable`），承載操作成敗與訊息。 |
| [`lib/model/filter_configs.dart`](../../lib/model/filter_configs.dart) | `FilterConfigs` | 搜尋篩選條件的 UI 模型（價位、營業中、排序方式）。 |
| [`lib/generated/l10n.dart`](../../lib/generated/l10n.dart) | `S` | `intl_utils` 產生的在地化存取類別（en / zh_TW）。 |
| [`lib/gen/assets.gen.dart`](../../lib/gen/assets.gen.dart) | `Assets` | `flutter_gen` 產生的型別安全資源路徑。 |
