# Feature Spec: Fix `build()` Side-effects Anti-pattern

## What & Why (使用者故事與背景)
在 Flutter 中，`build()` 方法的唯一職責是根據當前狀態描述 UI。它應該要是 pure function，不能包含任何網路請求、Bloc Event 分發、狀態變更或導航等非同步的側邊效應 (Side-effects)。當前專案在多個頁面的 `build()` 內發動了 Event 導致重複觸發網路請求與潛在無窮迴圈的嚴重效能瓶頸。

本修復任務將移除所有不當放置於 `build()` 內的側邊效應，並將它們重構至正確的生命週期（如 `initState()` 或狀態管理機制中），以提升畫面渲染效能與應用穩定性。

## 範圍邊界 (Scope)
涵蓋以下 6 個核心頁面的 `build()` 側邊效應修復：
1. `lib/flow/signinup/view/sign_in_page.dart`: 移除 `build()` 內的 `AutoSignInEvent`。
2. `lib/flow/main/view/main_page.dart`: 移除 `BlocBuilder` 內的 `FetchSearchInfo`。
3. `lib/flow/restaurant/view/restaurant_detail_page.dart`: 移除 `build()` 內的 `FetchDetailInfo` 及 Toast 彈跳。
4. `lib/flow/favor/view/favor_page.dart`: 移除 `build()` 內的 `FetchFavorInfoEvent`。
5. `lib/flow/settings/view/settings_page.dart`: 移除 `build()` 內的 `InitBioAuthSettingEvent`。
6. `lib/flow/splash/view/splash_page.dart`: 將 `addPostFrameCallback` 及路由跳轉移至 `initState`。

本任務**不包含**修改地圖聚類 (Clustering)、API 密鑰安全處理、Yelp 分頁等其餘架構缺陷。

## 驗收條件 (Acceptance Criteria)
- [ ] 執行 `flutter test` 所有既有測試皆通過。
- [ ] 上述 6 個頁面的 `build()` 內不應出現任何 Bloc `add()` 事件或路由導航。
- [ ] UI 切換與重新渲染時，不應再產生多餘的重複 API 請求日誌。
