# iOS SPM (Swift Package Manager) 遷移實作計畫

**日期**: 2026-08-23 (Updated: 2026-08-24 Hybrid Mode 修正)
**狀態**: STAGE 0b - 實作計畫 (已更新以反映實際混合模式架構)

## 1. 任務拆分 (Task Breakdown)

### 任務一：解開 SPM 封印與 Flutter 插件升級
- **修改檔案**: `pubspec.yaml`
- **動作**: 移除 `enable-swift-package-manager: false`，全域啟用 SPM。
- **動作**: 升級 `flutter_local_notifications` (至 v22.3.0) 以修復該套件舊版 `Package.swift` 內寫死 iOS 12.0 所造成的 SPM 建置崩潰。

### 任務二：配置 CocoaPods Fallback 機制 (混合模式)
- **目標路徑**: `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`
- **動作**:
  1. 移除 `project.pbxproj` 內不再需要的 CocoaPods 腳本（`[CP] Embed Pods Frameworks`），因為被 SPM 管理的套件已不再依賴此腳本。
  2. 保留原有的 `ios/Podfile` 作為 `google_maps_flutter` 和 `flutter_inappwebview` 的生命維持系統。
  3. 在 `ios/Podfile` 內加入 `post_install` 腳本，強制將所有 fallback 的 Pod target 部署目標（`IPHONEOS_DEPLOYMENT_TARGET`）拉升至 15.0，以解決與新版 Flutter Engine SPM 要求的 iOS 13+ 之間的版本衝突。
  4. (註記) 在修正過程中發現，原本試圖執行 `flutter create .` 來強補 `RunnerTests` target 會產生無用的垃圾檔案（如 `SceneDelegate.swift` 與預設圖示）。這些副作用已被全數退回並刪除，保留最乾淨的 `project.pbxproj` 狀態。

### 任務三：Xcode 專案檔重置與建置驗證
- **目標**: 確保 SPM 成功接管主流依賴，並與 CocoaPods fallback 和平共處。
- **動作**: 
  1. 執行 `flutter build ios --simulator --no-codesign` 觸發 Flutter 工具鏈生成 SPM `FlutterGeneratedPluginSwiftPackage` 結構。
  2. 觀察並確認 `Package.resolved` 已正確產生，且包含 Firebase 等重量級原生 SDK。
  3. 解析成功、編譯結束無錯誤 (Exit code 0)，即代表混合模式地基遷移完成。

## 2. 資料結構與影響範圍 (Impact Analysis)
- **影響範圍**: 僅限 iOS 平台的依賴解析與建置流程。
- **架構決策 (Architecture Decision)**: 
  - **為什麼保留 CocoaPods？** 實用主義。生態系中尚有未完全遷移至 SPM 的舊套件。強行拔除 `Podfile` 會導致專案無法編譯。透過混合模式，我們在不破壞現有功能的前提下，讓 90% 的重型套件享受到了 SPM 的好處。
- **未來展望**: 當 `google_maps_flutter` 與 `inappwebview` 發布 SPM 支援的更新時，Flutter 將自動把它們轉移。直到最後一個套件離開 CocoaPods，屆時即可安全刪除 `Podfile`。
