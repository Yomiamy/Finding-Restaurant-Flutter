# iOS SPM (Swift Package Manager) 遷移與 CocoaPods 淘汰規格書

**日期**: 2026-08-23 (Updated: 2026-08-24 Hybrid Mode 修正)
**狀態**: STAGE 0a - 規格定義 (已更新以反映實際混合模式架構)

## 1. What (需求是什麼)
將 iOS 專案的第三方原生依賴管理機制，從即將被淘汰的 CocoaPods 盡可能遷移至 Apple 官方的 Swift Package Manager (SPM)。對於尚未支援 SPM 的遺留套件，則採用 Flutter 內建的「混合模式 (Hybrid Mode)」退回 CocoaPods 處理。

## 2. Why (為什麼要做)
- **CocoaPods 終止維護**: CocoaPods 官方已宣布進入維護模式。Firebase 等核心 SDK 已不再保證相容舊的 CocoaPods 架構。
- **Flutter 官方強制遷移**: 移除 `enable-swift-package-manager: false` 的退出選項，讓專案能跟上現代建置流程。
- **生態系現實**: 經實測，部分套件（如 Google Maps、InAppWebView）尚無 SPM `Package.swift` 支援。為了保持專案順利編譯（實用主義），必須接納混合構建模式，而非教條式地強行刪除 `Podfile`。

## 3. 驗收條件 (Acceptance Criteria)
1. **移除舊機制限制**: `pubspec.yaml` 中不再包含 `enable-swift-package-manager: false`，全域啟用 SPM。
2. **多數套件成功遷移至 SPM**: Firebase 全家桶、Facebook SDK、Google Sign In 等支援 SPM 的現代套件，已成功由 `Package.resolved` 鎖定版本。
3. **未支援套件成功 Fallback (混合模式)**: 保留 `ios/Podfile` 作為 `google_maps_flutter` 與 `flutter_inappwebview` 的生命維持系統，並統一提升 Fallback 陣營的 iOS Deployment Target 至 15.0 以消除 SPM 衝突。
4. **無縫建置**: 在混合模式下，能夠順利解析所有 iOS 原生依賴並通過 iOS 建置（`flutter build ios` / `flutter run`）。
5. **功能不受損**: 遷移後，地圖 (Google Maps)、WebView、與 Firebase 全系列服務在 iOS 上運作正常，無執行期崩潰。

## 4. 範圍邊界 (Out of Scope)
- 不涉及 Android 端的 Gradle 或 Kotlin 升級（Android KGP 遷移已被另一份報告標記為暫緩）。
- 不涉及 UI 或業務邏輯的重構。
- 不強求「100% 抹除 CocoaPods」。在依賴套件作者尚未支援 SPM 之前，保留 `Podfile` 是唯一且正確的架構決策。
