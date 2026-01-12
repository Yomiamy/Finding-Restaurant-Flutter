# GitHub Actions CI/CD 配置

## 📚 目錄

- [快速開始](#快速開始)
- [Workflows 說明](#workflows-說明)
- [設定指南](#設定指南)
- [使用範例](#使用範例)
- [疑難排解](#疑難排解)

## 🚀 快速開始

### 前置需求

1. GitHub CLI (`gh`) - 用於設定 secrets
   ```bash
   brew install gh
   gh auth login
   ```

2. 準備以下檔案:
   - Android release keystore (`.jks` 或 `.keystore`)
   - Firebase service account JSON
   - Google Play Store service account JSON

### 一鍵設定 Secrets

```bash
cd .github/scripts
./setup-secrets.sh
```

這個腳本會引導你設定所有必要的 GitHub Secrets。

### 手動設定 Secrets

詳細步驟請參考 [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

## 📋 Workflows 說明

本專案包含 2 個自動化工作流程:
1. **Tag 觸發建置** - 建置 release APK
2. **Firebase App Distribution** - 測試版本自動分發

### 1. Tag 觸發建置 (`android-tag-build.yml`)

**觸發條件:**
- 推送 tag: `rc/android-x.y.z`
- 手動觸發 (workflow_dispatch)

**執行內容:**
- 建置 Android release APK
- 執行 Fastlane `build_apk` lane
- 上傳 APK 為 artifact (保留 30 天)
- 提取版本號並顯示在執行摘要中

**狀態徽章:**
[![Tag Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/android-tag-build.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/android-tag-build.yml)

---

### 2. Firebase App Distribution (`android-firebase-distribution.yml`)

**觸發條件:**
- Push 到 `develop`, `staging` 或 `release/*` 分支
- 手動觸發 (可指定 release notes)

**執行內容:**
- 建置 Android release APK
- 執行 Fastlane `build_apk_and_upload` lane
- 上傳到 Firebase App Distribution
- 上傳 APK 為 artifact (保留 30 天)

**測試人員會收到通知:**
- Firebase App Distribution 會自動發送 email 通知
- 測試人員可透過 Firebase App Tester app 下載

**狀態徽章:**
[![Firebase Distribution](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/android-firebase-distribution.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/android-firebase-distribution.yml)

## 🎯 使用範例

### 場景 1: 開發功能並測試

```bash
# 1. 開發功能
git checkout -b feature/new-feature
# ... 開發 ...

# 2. 建立 PR (會自動觸發 PR build)
git push origin feature/new-feature
# 到 GitHub 建立 PR → 等待 CI 建置完成

# 3. 合併到 develop (會自動部署到 Firebase)
# merge PR → Firebase App Distribution 自動部署
```

### 場景 2: 發布測試版本

```bash
# 1. 更新版本號 (選用)
# 修改 pubspec.yaml 和 Fastfile 的 versionCode/versionName

# 2. 合併到 develop 分支
git checkout develop
git merge feature/awesome-feature
git push origin develop
# → 自動部署到 Firebase App Distribution

# 3. QA 測試
# 測試人員會收到 Firebase email 通知並下載測試
```

### 場景 3: 緊急修復

```bash
# 1. 建立 hotfix 分支
git checkout -b hotfix/critical-bug main

# 2. 修復並推送
git push origin hotfix/critical-bug
# 建立 PR → 自動建置測試

# 3. 合併到 main 和 develop
git checkout main
git merge hotfix/critical-bug
git push origin main

# 4. 部署到 Firebase 供測試
git checkout develop
git merge hotfix/critical-bug
git push origin develop
# → 自動部署到 Firebase App Distribution
```

## 🔧 本地測試

在推送前,可以先在本地測試 Fastlane lanes:

```bash
cd android

# 測試 APK 建置
bundle exec fastlane build_apk

# 測試 Firebase 部署 (需要先設定 credentials)
bundle exec fastlane build_apk_and_upload
```

## 🔍 監控與偵錯

### 查看建置狀態

1. 前往 GitHub Repository
2. 點擊 "Actions" 頁籤
3. 選擇對應的 workflow
4. 查看執行記錄

### 下載建置產物

1. 在 Actions 執行記錄頁面
2. 滾動到底部 "Artifacts" 區塊
3. 點擊下載對應的 APK/AAB

### 常見錯誤排查

| 錯誤訊息 | 可能原因 | 解決方法 |
|---------|---------|---------|
| "Keystore not found" | Keystore secret 未設定 | 檢查 `ANDROID_KEYSTORE_BASE64` |
| "Firebase upload failed" | Firebase credentials 錯誤 | 檢查 `FIREBASE_CREDENTIALS_BASE64` |
| "Version code too low" | versionCode 未遞增 | 更新 Fastfile 的 versionCode |
| "Authentication failed" | Service account 權限不足 | 檢查 Google Cloud Console 權限 |

## 📊 最佳實踐

### 版本管理

```yaml
版本號格式: vMAJOR.MINOR.PATCH
範例:
  - v1.0.0 → 首次發布
  - v1.1.0 → 新功能
  - v1.1.1 → Bug 修復
  - v2.0.0 → 重大更新
```

### 分支策略

```
main
  ↑
  └─ develop (testing)
       ↑
       └─ feature/* (development)
```

### CI/CD 流程

```
開發 → PR Build → Code Review → Merge to develop
  → Firebase Distribution → QA Testing → Merge to main
```

## 📖 相關文件

- [詳細設定指南](GITHUB_ACTIONS_SETUP.md)
- [Fastlane 文件](https://docs.fastlane.tools/)
- [GitHub Actions 文件](https://docs.github.com/en/actions)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

## 🤝 貢獻

如有問題或建議,請建立 Issue 或 Pull Request。

## 📝 更新日誌

### 2025-01-10
- ✅ 初始化 GitHub Actions workflows
- ✅ 整合 Fastlane 建置流程
- ✅ 設定 Firebase App Distribution
- ✅ 建立自動化設定腳本
