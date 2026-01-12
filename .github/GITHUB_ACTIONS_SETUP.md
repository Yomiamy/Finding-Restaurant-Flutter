# GitHub Actions CI/CD 設定指南

## 📋 概述

本專案使用 GitHub Actions 搭配 Fastlane 進行 Android 應用程式的自動化建置與部署。

## 🔧 必要設定

### 1. GitHub Secrets 設定

請到 GitHub Repository Settings → Secrets and variables → Actions 新增以下 Secrets:

#### Android Signing Secrets

```bash
# 將你的 keystore 檔案轉換為 base64
base64 -i your-release-keystore.jks | pbcopy

# 然後貼到 GitHub Secret: ANDROID_KEYSTORE_BASE64
```

- **ANDROID_KEYSTORE_BASE64**: Keystore 檔案的 base64 編碼
- **KEYSTORE_PASSWORD**: Keystore 密碼
- **KEY_ALIAS**: Key 別名
- **KEY_PASSWORD**: Key 密碼

#### Firebase App Distribution Secrets

```bash
# 將 Firebase credentials JSON 轉換為 base64
base64 -i android/fastlane/findrestaurant_credentials.json | pbcopy

# 然後貼到 GitHub Secret: FIREBASE_CREDENTIALS_BASE64
```

- **FIREBASE_CREDENTIALS_BASE64**: Firebase service account JSON 的 base64 編碼

### 2. 本地測試指令

```bash
# 測試 PR build workflow (需要設定 secrets)
cd android
bundle exec fastlane build_apk

# 測試 Firebase distribution
bundle exec fastlane build_apk_and_upload
```

## 🚀 Workflow 說明

### 1. Tag 觸發建置 (android-tag-build.yml)

**觸發時機:**
- 推送 tag: `rc/android-x.y.z`
- 手動觸發 (workflow_dispatch)

**執行動作:**
- ✅ 建置 release APK
- ✅ 上傳 APK 為 artifact (保留 30 天)
- ✅ 提取版本號並顯示在摘要中

### 2. Firebase App Distribution (android-firebase-distribution.yml)

**觸發時機:**
- Push 到 develop, staging 或 release/* 分支
- 手動觸發 (workflow_dispatch)

**執行動作:**
- ✅ 建置 release APK
- ✅ 上傳到 Firebase App Distribution
- ✅ 上傳 APK 為 artifact (保留 30 天)

## 📱 使用範例

### 發布測試版到 Firebase

```bash
# 推送到 develop 分支會自動觸發
git push origin develop

# 或手動觸發
# 到 GitHub Actions → Android Firebase App Distribution → Run workflow
```

## 🔍 檢查建置狀態

1. 前往 GitHub Repository 的 Actions 頁面
2. 選擇對應的 workflow
3. 查看執行記錄和 logs
4. 下載建置的 artifact (APK/AAB)

## ⚠️ 注意事項

1. **首次部署前**必須先手動上傳一次 APK/AAB 到 Play Store
2. 確保 `versionCode` 遞增,否則 Play Store 會拒絕上傳
3. Firebase credentials 檔案不應該 commit 到 repository
4. Keystore 檔案必須妥善保管,遺失無法找回

## 🛠️ 疑難排解

### 建置失敗: "Keystore not found"

檢查 `ANDROID_KEYSTORE_BASE64` secret 是否正確設定

### Firebase 上傳失敗

1. 檢查 `FIREBASE_CREDENTIALS_BASE64` secret
2. 確認 Firebase App ID 正確
3. 確認 service account 有正確權限

## 📚 相關文件

- [GitHub Actions 官方文件](https://docs.github.com/en/actions)
- [Fastlane 官方文件](https://docs.fastlane.tools/)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

## 🔄 更新記錄

- 2025-01-10: 初始設定
  - PR 自動建置
  - Firebase App Distribution
