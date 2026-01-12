# 🚀 簡化版 CI/CD 設定指南

## 📋 概述

本專案使用 **GitHub Actions + Fastlane** 進行 Android 應用程式的自動化建置與 Firebase 測試版分發。

## ✅ 包含的自動化流程

### 1️⃣ APK 建置
- **觸發**: 推送 `rc/android-x.y.z` tag
- **目的**: 建置 release APK
- **輸出**: APK artifact (保留 30 天)

### 2️⃣ Firebase App Distribution
- **觸發**: 推送 `rc/android-x.y.z` tag
- **目的**: 自動建置並上傳到 Firebase 分發給測試人員
- **輸出**: Firebase 測試版本 + APK artifact (保留 30 天)

## 🔐 需要設定的 Secrets (5 個)

| Secret 名稱 | 說明 |
|------------|------|
| `ANDROID_KEYSTORE_BASE64` | Keystore 檔案 (base64) |
| `KEYSTORE_PASSWORD` | Keystore 密碼 |
| `KEY_ALIAS` | Key 別名 |
| `KEY_PASSWORD` | Key 密碼 |
| `FIREBASE_CREDENTIALS_BASE64` | Firebase credentials (base64) |

## 🚀 快速開始

### 方法 1: 使用自動化腳本 (推薦)

```bash
cd .github/scripts
./setup-secrets.sh
```

腳本會:
- ✅ 自動讀取 `android/local.properties` 中的配置
- ✅ 自動找到 keystore 檔案位置
- ✅ 自動找到 Firebase credentials 檔案
- ✅ 詢問確認後自動設定所有 secrets

### 方法 2: 手動設定

```bash
# 1. 安裝 GitHub CLI
brew install gh
gh auth login

# 2. 設定 Secrets
cd android
base64 -i app/find_restaurant.keystore | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set KEYSTORE_PASSWORD -b "你的密碼"
gh secret set KEY_ALIAS -b "你的別名"
gh secret set KEY_PASSWORD -b "你的key密碼"
base64 -i fastlane/findrestaurant_credentials.json | gh secret set FIREBASE_CREDENTIALS_BASE64
```

## 📊 工作流程

```
開發者本地開發
    ↓
建立 feature 分支
    ↓
開發完成,合併到 develop
    ↓
準備發布測試版
    ↓
打 tag: rc/android-1.3.0
    ↓
推送 tag: git push origin rc/android-1.3.0
    ↓
✅ 自動觸發 2 個 workflows:
   1. Build APK (建置 APK)
   2. Firebase Distribution (上傳 Firebase)
    ↓
QA 收到 Firebase 通知並測試
    ↓
測試通過,合併到 main
```

## 📁 已建立的檔案

```
.github/
├── workflows/
│   ├── android-tag-build.yml              # Tag 觸發建置
│   └── android-firebase-distribution.yml # Firebase 部署
├── scripts/
│   ├── setup-secrets.sh                  # 自動設定腳本
│   └── README.md                         # 腳本說明
├── README.md                             # 總覽文件
├── GITHUB_ACTIONS_SETUP.md               # 詳細設定指南
├── CHECKLIST.md                          # 檢查清單
└── SETUP_GUIDE.md                        # 本文件

android/
├── Gemfile                               # Ruby 依賴
├── .gitignore                            # 已更新排除敏感檔案
└── fastlane/
    └── Fastfile                          # 已更新支援環境變數
```

## 🔍 驗證設定

### 1. 檢查 Secrets

```bash
gh secret list
```

應該看到:
```
ANDROID_KEYSTORE_BASE64
KEYSTORE_PASSWORD
KEY_ALIAS
KEY_PASSWORD
FIREBASE_CREDENTIALS_BASE64
```

### 2. 本地測試

```bash
cd android
bundle install
bundle exec fastlane build_apk
```

### 3. 測試 CI/CD

```bash
# 測試 tag 觸發
git tag rc/android-1.0.0
git push origin rc/android-1.0.0

# 檢查:
# 1. GitHub Actions 頁面應該有 2 個 workflow 執行
# 2. Firebase Console 應該看到新版本
# 3. 下載 Artifacts 測試
```

## ⚠️ 重要注意事項

### 安全性檢查

確認以下檔案**沒有**被 Git 追蹤:

```bash
git ls-files | grep -E '\.(jks|keystore)$|local\.properties|credentials\.json'
```

如果有輸出,立即移除:
```bash
git rm --cached android/local.properties
git rm --cached android/app/*.keystore
git rm --cached android/fastlane/*.json
```

### .gitignore 確認

`android/.gitignore` 應包含:
```gitignore
local.properties
*.jks
*.keystore
fastlane/*.json
```

## 📚 延伸閱讀

- [README.md](README.md) - 完整功能說明
- [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) - 詳細設定步驟
- [CHECKLIST.md](CHECKLIST.md) - 完整檢查清單
- [scripts/README.md](scripts/README.md) - 腳本詳細說明

## 🎉 完成!

設定完成後,你的發布流程會是:

1. **開發** → 建立 feature 分支開發
2. **合併** → 合併到 develop 分支
3. **打 tag** → `git tag rc/android-1.3.0 && git push origin rc/android-1.3.0`
4. **自動化** → 自動建置 APK 並上傳到 Firebase
5. **測試** → QA 從 Firebase 下載測試
6. **通過** → 合併到 main

**一個 tag,全自動建置與分發!** 🚀

### 📝 Tag 命名規範

```bash
# 格式: rc/android-x.y.z
# 範例:
git tag rc/android-1.0.0   # 首次發布
git tag rc/android-1.1.0   # 新功能
git tag rc/android-1.1.1   # Bug 修復
git tag rc/android-2.0.0   # 重大更新

# 推送 tag
git push origin rc/android-1.3.0

# 刪除錯誤的 tag (如果需要)
git tag -d rc/android-1.3.0              # 本地刪除
git push origin :refs/tags/rc/android-1.3.0  # 遠端刪除
```

---

**日期**: 2025-01-10
**版本**: 簡化版 (僅到 Firebase)
