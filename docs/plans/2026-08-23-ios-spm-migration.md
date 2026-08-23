# iOS SPM (Swift Package Manager) 遷移實作計畫

**日期**: 2026-08-23
**狀態**: STAGE 0b - 實作計畫

## 1. 任務拆分 (Task Breakdown)

### 任務一：解開 SPM 封印與依賴升級
- **修改檔案**: `pubspec.yaml`
- **動作**: 移除 `enable-swift-package-manager: false`。
- **動作**: （選擇性）若解析過程中發生 Firebase 或 Google Maps 的 SPM 依賴衝突，將相關套件升級至能正確相容 SPM 的最新修補版本 (Patch bump)。

### 任務二：深度清理 CocoaPods 遺留物
- **目標路徑**: `ios/`
- **動作**:
  1. 刪除 `ios/Podfile`
  2. 刪除 `ios/Podfile.lock`
  3. 刪除 `ios/Pods/` 目錄
  4. 刪除 `ios/.symlinks/` 目錄
  5. 執行 `flutter clean` 與 `flutter pub get` 重建工作區狀態。

### 任務三：Xcode 專案檔重置與建置驗證
- **目標**: 確保 SPM 成功接管原生依賴解析。
- **動作**: 
  1. 刪除舊的 `ios/Runner.xcworkspace` (SPM 模式下 Flutter 會使用預設配置或重新生成結構，CocoaPods 特有的 workspace 將被淘汰)。
  2. 執行 `flutter build ios --simulator --config-only` (或完整 build) 以觸發 Flutter 工具鏈生成 SPM `FlutterGeneratedPluginSwiftPackage` 結構並下載 Swift 套件。
  3. 解析成功即代表地基遷移完成。

## 2. 資料結構與影響範圍 (Impact Analysis)
- **影響範圍**: 僅限 iOS 平台的依賴解析與建置流程。
- **風險點**: 
  - 某些老舊套件可能還沒有提供 `Package.swift`。若發生此情況，需評估替換套件或在 `pubspec.yaml` 宣告 `swift-package-manager: false` （只針對單一有問題的套件關閉，而非全域關閉）。
  - Firebase 套件的 iOS SDK 非常龐大，初次解析可能耗時較久。
