# Implementation Plan: AdMob 廣告刊登合規性修復 (防欺騙點擊 / 移至底部 / 消滅 Layout Shift)

## 1. 簡介與目標 (Overview)

本計畫旨在全面修復 Google AdMob 官方指出的刊登違規問題（意外點擊與欺騙性版位引導）：
1. **移除清單首項廣告**：將 `BannerAD` 自 `RestaurantInfoListWidget` 的 `ListView` 第 0 項移除，解決下拉手勢誤觸與緊貼頂部導覽列問題。
2. **固定於主頁面底部**：在 `MainPage` 的 `Scaffold.bottomNavigationBar` 透過 `SafeArea` 固定掛載橫幅廣告，與滑動列表和地圖模式徹底隔離。
3. **消除版面突跳 (CLS / Layout Shift)**：重構 `BannerAD`，在非同步載入完成前以固定高度（50dp）容器佔位，並以 `async/await` 取代 `.then()`；上方加入微型邊界分隔線，符合 AdMob 廣告與內容區隔規範。
4. **測試同步與驗證**：更新列表 itemCount 相關測試，確保零回歸且全數通過 `flutter analyze` 與 `flutter test`。

## 2. 檔案異動清單 (File Changes)

- **`lib/flow/main/view/restaurant_info_list_widget.dart`**：
  - 移除 `import '../../../component/ad/ad_barrel.dart';`。
  - `itemCount` 改為 `_summaryInfos.length + 1 + (_isLoadingMore ? 1 : 0)`。
  - `itemBuilder` 移除 `index == 0` 的 `BannerAD` 分支：
    - `index == 0` 改為 `FilterTagsWidget`。
    - `index == _summaryInfos.length + 1` 為加載更多指示器。
    - 餐廳項目取值改為 `_summaryInfos[index - 1]`。
- **`lib/component/ad/banner_ad.dart`**：
  - 改以 `async/await` 處理非同步廣告載入，消除禁用的 `.then()` 語法。
  - 載入前預留 50dp 固定佔位高度容器，徹底消滅 Layout Shift。
  - 容器加上頂部細微邊線 (`ThemeColor.color8a000000` 0.2 或適當細線) 明確區分廣告版位。
- **`lib/flow/main/view/main_page.dart`**：
  - 引入 `../../../di/di_barrel.dart`。
  - `Scaffold` 掛載 `bottomNavigationBar: SafeArea(child: BannerAD(adState: getIt<BannerADState>()))`。
- **`test/load_more_indicator_visibility_test.dart`**：
  - 同步將 mock 的 `_buildList` 結構由 `count + 2` 更新為 `count + 1`（移除 banner 佔位）。
- **`test/component/ad/banner_ad_test.dart`**（若無則新增）：
  - 針對 `BannerAD` 元件撰寫 Widget 測試，驗證初始載入時之預留高度與元件構建穩定性。

## 3. 任務拆分 (Tasks Breakdown)

- **Task 1: 清理 `RestaurantInfoListWidget` 列表內廣告與校正索引**
  - 移除清單頂部的 `BannerAD`。
  - 校正 `itemCount` 及所有索引映射邏輯。
  - 移除不必要的 import。
- **Task 2: 改造 `BannerAD` 元件（預留高度防突跳 + 視覺分隔 + 異步現代化）**
  - 改寫 `didChangeDependencies` 內的異步流程為 `async/await`。
  - 即使在 `loadedBanner == null` 時亦提供預留高度容器（50dp），避免介面跳動。
  - 頂部加入微型分隔邊框。
- **Task 3: 在 `MainPage` 底部固定掛載橫幅廣告**
  - 於 `MainPage` 的 `Scaffold` 配置 `bottomNavigationBar` 與 `SafeArea`。
  - 透過 `getIt<BannerADState>()` 注入廣告狀態。
- **Task 4: 更新測試與全面驗證**
  - 更新 `load_more_indicator_visibility_test.dart` 的列表結構。
  - 建立/維護 `BannerAD` 測試。
  - 執行 `flutter analyze` 與 `flutter test`。

## 4. 驗收標準 (Verification)

- `RestaurantInfoListWidget` 列表第 0 項為篩選晶片，店家卡片自 `index == 1` 開始精確對齊，無任何 off-by-one 越界。
- 首頁底部顯示固定之橫幅廣告區塊，不被手勢列遮擋。
- 進入主頁面時，頁面元素不因廣告異步載入而發生位置位移或上下跳動。
- `flutter analyze` 保持 `No issues found!`。
- `flutter test` 全數綠燈通過。
