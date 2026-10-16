# 功能規格：E-9.4a macOS 補齊 Sign in with Apple Capability

- **項目編號**：E-9.4a 剩餘項（沿用 `docs/brainstorm/2026-10-17-features-brainstorm.md` §9.6 編號）
- **日期**：2026-10-15
- **Effort（估計）**：0.2d（純 Xcode 配置與 Entitlements 聲明）
- **依賴**：A-9.6（PR #145 已完成，補齊 DEVELOPMENT_TEAM 與 Keychain Access Groups）
- **實查基線**：`main` @ `4c8dd88`
- **問題編號 / 關聯**：Issue #144 後續剩餘項目

---

## 1. 問題陳述與影響 (What & Why)

### 1.1 核心問題：macOS 點擊 Apple 登入回報 `AuthorizationError 1000`

在 A-9.6 完成後，macOS 上的 Google 登入已可正常授權並以 Firebase Auth 登入；但在點擊 Apple 登入按鈕時，原生授權彈窗無法順利完成授權，回報 `AuthorizationError 1000`，登入流程中斷。

### 1.2 根因分析 (Root Cause)

經實查 Xcode 專案與 entitlements 配置：
1. **Entitlements 缺失**：`macos/Runner/Release.entitlements`、`macos/Runner/DebugProfile.entitlements` 與 `macos/Runner/RunnerDebug.entitlements` 均未宣告 `com.apple.developer.applesignin`。
2. **Xcode TargetAttributes 缺失**：`macos/Runner.xcodeproj/project.pbxproj` 中的 `SystemCapabilities` 僅包含 `com.apple.Sandbox`，缺乏 `com.apple.SignInWithApple` capability。
3. 對照 iOS 原生配置（`ios/Runner/Runner.entitlements:7-10`），iOS 已明確宣告：
   ```xml
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   ```

---

## 2. 驗收標準 (Acceptance Criteria)

- [ ] **AC-1 (Entitlements 配置)**：
  - `macos/Runner/Release.entitlements` 包含 `com.apple.developer.applesignin`。
  - `macos/Runner/DebugProfile.entitlements` 包含 `com.apple.developer.applesignin`。
  - `macos/Runner/RunnerDebug.entitlements` 包含 `com.apple.developer.applesignin`。
- [ ] **AC-2 (Xcode 專案 Capability)**：
  - `macos/Runner.xcodeproj/project.pbxproj` 之 `Runner` TargetAttributes 的 `SystemCapabilities` 宣告 `com.apple.SignInWithApple = { enabled = 1; };`。
- [ ] **AC-3 (建置驗證)**：
  - `flutter build macos --debug` 建置成功且 0 警告。
  - `flutter build macos` (Release) 簽章與建置通過。
  - `flutter analyze .` 與 `flutter test` 維持零錯誤。
- [ ] **AC-4 (執行期授權驗證)**：
  - macOS 點擊「Sign in with Apple」不再拋出 `AuthorizationError 1000`，能正常彈出 macOS 系統原生 Apple 授權驗證視窗。

---

## 3. 範圍邊界 (Scope & Boundaries)

- **包含**：
  - macOS 3 份 entitlements 檔案的 `com.apple.developer.applesignin` 配置。
  - `macos/Runner.xcodeproj/project.pbxproj` 的 `SystemCapabilities` 配置。
- **明確排除 (Out of Scope)**：
  - 不更動 iOS 現有 entitlements 或 Xcode 專案。
  - 不變動 `apple_sign_in_manager.dart` 的核心業務邏輯。
  - 不碰觸 Google 登入或非 Apple 登入管道。
