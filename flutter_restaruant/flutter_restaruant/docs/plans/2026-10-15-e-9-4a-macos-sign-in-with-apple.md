# 實作計畫：E-9.4a macOS 補齊 Sign in with Apple Capability

- **項目編號**：E-9.4a 剩餘項
- **日期**：2026-10-15
- **對應規格**：`docs/features/2026-10-15-e-9-4a-macos-sign-in-with-apple.md`
- **預估 Effort**：0.2d（僅配置檔與 Xcode 屬性宣告）
- **工作目錄**：`/Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant`
- **實查基線**：`main` @ `4c8dd88`

---

## 1. 架構與技術方案 (How)

### 1.1 Entitlements 配置

在下列三份 macOS entitlements 檔案中加入 Apple Sign In 權限：
- `macos/Runner/Release.entitlements`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/RunnerDebug.entitlements`

加入內容：
```xml
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
```

### 1.2 Xcode 專案 TargetAttributes SystemCapabilities 配置

在 `macos/Runner.xcodeproj/project.pbxproj` 中的 `Runner` target（ID `33CC10EC2044A3C60003C045`）之 `SystemCapabilities` 區塊，加入 `com.apple.SignInWithApple`：

```pbxproj
					33CC10EC2044A3C60003C045 = {
						CreatedOnToolsVersion = 9.2;
						LastSwiftMigration = 1100;
						ProvisioningStyle = Automatic;
						SystemCapabilities = {
							com.apple.Sandbox = {
								enabled = 1;
							};
							com.apple.SignInWithApple = {
								enabled = 1;
							};
						};
					};
```

---

## 2. 異動檔案清單 (File Changes)

1. `macos/Runner/Release.entitlements` (修改)
2. `macos/Runner/DebugProfile.entitlements` (修改)
3. `macos/Runner/RunnerDebug.entitlements` (修改)
4. `macos/Runner.xcodeproj/project.pbxproj` (修改)

---

## 3. 任務拆分與執行步驟 (Tasks Breakdown)

- **Task 1: 更新 3 份 Entitlements 檔案**
  - 在 `Release.entitlements`、`DebugProfile.entitlements`、`RunnerDebug.entitlements` 補齊 `com.apple.developer.applesignin`。
- **Task 2: 更新 Xcode 專案 Capability 宣告**
  - 在 `macos/Runner.xcodeproj/project.pbxproj` 加入 `com.apple.SignInWithApple` capability。
- **Task 3: 本機建置與靜態分析驗證**
  - 執行 `flutter analyze .`
  - 執行 `flutter test`
  - 執行 `flutter build macos --debug` 與 `flutter build macos` 確保編譯與簽章無誤。
