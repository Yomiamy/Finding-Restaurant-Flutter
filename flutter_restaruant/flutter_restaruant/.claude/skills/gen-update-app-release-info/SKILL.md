---
name: gen-update-app-release-info
description: 當使用者要更新 Flutter App 的發布版本號時使用。負責同步更新 pubspec.yaml 的版號 (version 與 version code) 以及 iOS 專案的 project.pbxproj 中的 MARKETING_VERSION 與 CURRENT_PROJECT_VERSION。觸發語如「bump app 版號」、「更新 app release 版號」、「gen-update-app-release-info 1.4.0 26」。
---

# Gen Update App Release Info

依使用者指定的新版號與 Version Code，同步更新 Flutter 專案中的 App 版本資訊，確保跨平台 (pubspec.yaml 與 iOS pbxproj) 設定一致。

## 觸發與輸入

- 輸入格式：`gen-update-app-release-info <version> [version_code]`，例如 `gen-update-app-release-info 1.4.0 26`。
- 如果使用者沒有指定 `version_code`，請先讀取 `pubspec.yaml` 中當前的 version code，並自動將其遞增 1，再向使用者確認。
- 記正規化後的版號：`$VERSION`（純語意版號，如 `1.4.0`）、`$VERSION_CODE`（純數字版本號，如 `26`）。

## 流程

### 1. 更新 `pubspec.yaml`
讀取專案根目錄的 `pubspec.yaml`，找到 `version:` 開頭的設定行。
將其替換為新的版本號與 Version Code 組合。
例如：
`version: <舊版號>+<舊VersionCode>` → `version: $VERSION+$VERSION_CODE`

### 2. 更新 iOS `project.pbxproj`
讀取 `ios/Runner.xcodeproj/project.pbxproj`，找到 `CURRENT_PROJECT_VERSION` 與 `MARKETING_VERSION` 的設定行。
此檔案中通常會有多處設定 (對應 Debug, Release, Profile 等環境)，必須**全部更新**。

- `CURRENT_PROJECT_VERSION` 對應 `$VERSION_CODE`
  將 `CURRENT_PROJECT_VERSION = <舊數值>;` 改為 `CURRENT_PROJECT_VERSION = $VERSION_CODE;`
- `MARKETING_VERSION` 對應 `$VERSION`
  將 `MARKETING_VERSION = <舊版號>;` 改為 `MARKETING_VERSION = $VERSION;`

> **注意：** Flutter 在 Android 端會透過 `local.properties` 自動從 `pubspec.yaml` 抓取版本號與 version code，除非使用者有客製化 `android/app/build.gradle` 直接寫死版本號，否則通常無需修改 Android 設定。

### 3. 檢查修改與回報
修改完成後，使用 `git status` 確認是否成功變更了以下檔案：
- `pubspec.yaml`
- `ios/Runner.xcodeproj/project.pbxproj`

向使用者總結以下資訊：
- 新的版本名稱 (Marketing Version): `$VERSION`
- 新的建置號碼 (Version Code): `$VERSION_CODE`
- 已成功同步更新 `pubspec.yaml` 與 `ios/Runner.xcodeproj/project.pbxproj`。

## Quick Reference

| 步驟 | 檔案 | 改什麼 |
|------|------|--------|
| 1 | `pubspec.yaml` | 更新 `version: $VERSION+$VERSION_CODE` |
| 2 | `ios/.../project.pbxproj` | 將所有 `CURRENT_PROJECT_VERSION` 設為 `$VERSION_CODE` |
| 3 | `ios/.../project.pbxproj` | 將所有 `MARKETING_VERSION` 設為 `$VERSION` |
