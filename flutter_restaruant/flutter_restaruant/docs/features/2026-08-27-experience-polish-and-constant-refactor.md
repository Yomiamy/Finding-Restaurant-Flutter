# Feature Spec: §S4 體驗收尾與常數清理 (篩選頁 / Splash / 常數重構)

## 1. 背景與動機 (Context & Motivation)
在完成 §S1 (地基與樣式體系)、§S2 (共用元件與骨架屏) 與 §S3 (頁面級視覺重塑) 後，應用程式的核心頁面與元件皆已接軌 Material 3。
本階段為收尾里程碑 §S4，聚焦於：
1. **篩選頁 (`FilterPage`) 體驗升級**：將「套用」按鈕由頂部 AppBar actions 移至底部固定 `FilledButton`，符合單手拇指操作；區塊分組與日期選擇器卡片化。
2. **Splash 啟動畫面 (`SplashPage`) 修正**：將啟動圖由 `BoxFit.fill` 修正為 `BoxFit.cover`，防止不同螢幕比例變形。
3. **字串與常數收尾清理**：
   - 掃除 `FavorPage` 中殘留的硬編碼 `UIConstants.favorTitle`，遷移至 `S.current.favorite_stores` 多語系。
   - 將 `UIConstants.emptyWidget` 替換為 Flutter 慣用 `const SizedBox.shrink()`。
   - 清理 `UIConstants` 廢棄的字串常數。
4. **測試覆蓋與品質把關**：補齊 `FilterPage` 與 `SplashPage` 測試，確保整體全綠零警告。

## 2. 功能範圍與目標 (Scope & Goals)

### In-Scope
- **`FilterPage` 重構**：
  - 底部固定「套用」按鈕 (`FilledButton(colorScheme.primary)`)，置於 `bottomNavigationBar` + `SafeArea`。
  - 價格與排序選項採用分組卡片化版面。
  - 日期選擇器加入圓角邊框與容器包裹。
- **`SplashPage` 修復**：
  - `BoxFit.fill` → `BoxFit.cover`。
- **常數清理與多語系遷移**：
  - `FavorPage` AppBar 標題改用 `S.current.favorite_stores`。
  - 清理 `UIConstants` 中未使用的字串。
- **單元與 Widget 測試**：
  - `test/flow/filter/filter_page_test.dart`
  - `test/flow/splash/splash_page_test.dart`

### Out-of-Scope (YAGNI)
- 不重寫 `FilterConfigs` 領域模型或新增篩選 API 參數。
- 不引進重量級狀態管理。

## 3. 驗收標準 (Acceptance Criteria)
1. **AC-1 (篩選頁體驗)**：`FilterPage` 底部顯示「套用」FilledButton，點擊後正確回傳 `FilterConfigs` 並關閉頁面。
2. **AC-2 (啟動頁滿版)**：`SplashPage` 的 `launch_image.png` 使用 `BoxFit.cover`。
3. **AC-3 (多語系與常數)**：`FavorPage` 標題走 `S.current.favorite_stores`，無殘留無用靜態字串。
4. **AC-4 (代碼品質與測試)**：`flutter analyze` 零錯誤零警告，`flutter test` 100% 通過。
