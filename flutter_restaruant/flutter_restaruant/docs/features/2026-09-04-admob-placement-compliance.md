# Feature: AdMob 廣告刊登合規性修復 (防欺騙點擊 / 移至底部 / 消滅 Layout Shift)

## 1. 背景與動機 (Why)

近期應用程式收到 Google AdMob 官方政策違規警告：
> 「發布商不得為了爭取點擊或觀看次數，而以欺騙的導入方式插入廣告，使人有可能誤以為廣告是選單、導覽列或下載連結...網頁將廣告放在直覺上適合瀏覽的版位。」

經審查目前程式碼，發現存在四大違反 AdMob 刊登政策的設計缺陷：
1. **非同步版面突跳 (CLS / Layout Shift)**：`BannerAD`（[banner_ad.dart](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/component/ad/banner_ad.dart)）在廣告非同步加載完成前回傳 `const SizedBox()`（高度為 0）。載入完成後呼叫 `setState` 突然撐開 50~90dp，將下方的篩選晶片與店家列表猛烈下推，導致正在點擊內容的使用者手指誤觸剛出現的廣告（教科書級別的引誘意外點擊）。
2. **夾在導覽列與操作元件之間，無安全間距**：`RestaurantInfoListWidget` 將廣告直接貼在上方 `AppBar`（選單按鈕）與下方 `FilterTagsWidget`（篩選按鈕）之間，缺乏足夠邊距與區隔，極易誤觸且易被誤認為功能橫幅。
3. **置於可滾動列表最頂端 (Index 0)**：廣告隨 `ListView` 滾動且置於首項，恰為使用者下拉滾動（Scroll down / Pull-to-refresh）之大拇指慣性接觸區。
4. **廣告未明確標記且融入內容**：缺乏顯著邊界與「廣告 / Ad」辨別標示。

若不立即改善，將面臨 AdMob 廣告停權、營收凍結甚至 App 下架之致命風險。

## 2. 規格需求 (What)

### 2.1. 橫幅廣告移出 ListView，改固定於畫面底部 (SafeArea)
- 在 [restaurant_info_list_widget.dart](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/flow/main/view/restaurant_info_list_widget.dart) 中徹底移除頂部 `BannerAD`（移除 `index == 0` 的廣告判斷，調整清單 count 與 index 偏移）。
- 在 [main_page.dart](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/flow/main/view/main_page.dart) 的 `Scaffold` 中，將 `BannerAD` 固定於 `bottomNavigationBar` 或底層 `SafeArea`：
  - 不隨清單滾動，消滅滾動手勢誤觸。
  - 遠離頂部 `AppBar` 與漢堡選單按鈕。
  - 列表捲動與地圖瀏覽皆不再受廣告干擾。

### 2.2. 消滅版面突跳 (Zero Layout Shift / CLS)
- 改造 [banner_ad.dart](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/component/ad/banner_ad.dart)：
  - 於載入前預留佔位容器高度（預設為標準橫幅高度 50dp 或自適應高度），避免從 0 突變。
  - 提供細緻平滑的淡入動畫或固定高度佔位，防止下方/周圍任何內容跳動。

### 2.3. 強化視覺邊界與合規標示 (Compliance Distinction)
- 廣告容器上方加上細微分割線（Divider / Border）與獨立背景色，明確切分應用程式內容與廣告版位。
- 在廣告區塊右上角或周邊加上微型「廣告 / Ad」字樣，遵循 Google 廣告刊登指引。

## 3. 驗收條件 (Acceptance Criteria)

- [x] **移出列表**：`RestaurantInfoListWidget` 的 `ListView.builder` 內不再包含 `BannerAD`，清單第 0 項為篩選晶片 `FilterTagsWidget`，卡片索引偏移正常、無 Off-by-one 錯誤。
- [x] **底部固定**：`MainPage` 之 `Scaffold` 正確於底部（如 `bottomNavigationBar`）掛載 `BannerAD`，並包覆 `SafeArea` 避免被系統手勢條遮蔽。
- [x] **零版面突跳**：首頁進入時，底部廣告區塊在廣告載入前後無版面瞬間擠壓（Layout Shift），高度穩定。
- [x] **手勢不衝突**：清單上下滑動與點擊卡片時，手指接觸範圍不會觸發廣告點擊。
- [x] **品質保證**：
  - `flutter analyze` 零警告 (`No issues found!`)。
  - 既有單元與 Widget 測試全數通過 (`flutter test`)。
  - 針對調整後的清單與首頁廣告版位補齊 Widget 測試。

## 4. 範圍邊界 (Scope Boundary)

- **In-Scope**:
  - `lib/flow/main/view/restaurant_info_list_widget.dart` 清理列表內廣告與 index 修正。
  - `lib/flow/main/view/main_page.dart` 在底部掛載廣告。
  - `lib/component/ad/banner_ad.dart` 預留高度與視覺標記改善。
  - 對應的 Widget 測試維護。
- **Out-of-Scope**:
  - 插頁廣告 (`InterstitialAd`) 邏輯更動（目前於詳情頁獨立運作）。
  - 開屏廣告 (`AppOpenAd`) 邏輯更動。
