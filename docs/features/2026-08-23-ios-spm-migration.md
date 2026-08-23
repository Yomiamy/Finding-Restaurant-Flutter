# iOS SPM (Swift Package Manager) 遷移與 CocoaPods 淘汰規格書

**日期**: 2026-08-23
**狀態**: STAGE 0a - 規格定義

## 1. What (需求是什麼)
將 iOS 專案的第三方原生依賴管理機制，從即將被淘汰的 CocoaPods 徹底遷移至 Apple 官方的 Swift Package Manager (SPM)。

## 2. Why (為什麼要做)
- **CocoaPods 終止維護**: CocoaPods 官方已宣布進入維護模式，並預計在 2026 年底變為唯讀。Firebase 等核心 SDK 已停止發布 CocoaPods 更新。
- **Flutter 官方強制遷移**: Flutter 未來版本將移除 `enable-swift-package-manager: false` 的退出選項，屆時未遷移的專案將無法建置。
- **建置效能與現代化**: SPM 整合於 Xcode 中，能提供更乾淨的依賴樹解析與更快的增量建置體驗。

## 3. 驗收條件 (Acceptance Criteria)
1. **移除舊機制**: `pubspec.yaml` 中不再包含 `enable-swift-package-manager: false`。
2. **清理遺留物**: `ios/Podfile`, `ios/Podfile.lock`, 及 `ios/Pods/` 目錄被徹底刪除。
3. **無縫建置**: 在不使用 CocoaPods 的情況下，能夠順利解析所有 iOS 原生依賴並通過 iOS 建置（`flutter build ios` / `flutter run`）。
4. **功能不受損**: 遷移後，地圖 (Google Maps)、WebView、與 Firebase 全系列服務在 iOS 上運作正常，無執行期崩潰。

## 4. 範圍邊界 (Out of Scope)
- 不涉及 Android 端的 Gradle 或 Kotlin 升級（Android KGP 遷移已被另一份報告標記為暫緩）。
- 不涉及 UI 或業務邏輯的重構。
