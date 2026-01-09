# Setup Secrets 腳本說明

## 📋 功能特色

`setup-secrets.sh` 是一個智能化的 GitHub Secrets 設定工具,具有以下特色:

### 🔍 自動讀取 local.properties

腳本會自動讀取 `android/local.properties` 中的配置:

```properties
keyAlias=find_restaurant
keyPassword=yomiamy
storeFile=find_restaurant.keystore
storePassword=yomiamy
```

### 🎯 自動搜尋 Keystore 檔案

根據 `local.properties` 中的 `storeFile` 設定,自動在以下位置搜尋:

1. `android/find_restaurant.keystore`
2. `android/app/find_restaurant.keystore`
3. `專案根目錄/find_restaurant.keystore`

### 💡 智能提示與確認

- 如果找到 local.properties 中的配置,會顯示並詢問是否使用
- 如果找到 keystore 檔案,會顯示路徑並詢問是否使用
- 所有敏感資料輸入都會隱藏顯示

## 🚀 使用方式

### 前置需求

```bash
# 1. 安裝 GitHub CLI
brew install gh

# 2. 登入 GitHub
gh auth login
```

### 執行腳本

```bash
cd .github/scripts
./setup-secrets.sh
```

### 執行流程範例

```
🔐 GitHub Actions Secrets 設定輔助工具
==========================================

✅ GitHub CLI 已就緒

📖 正在讀取 android/local.properties...
✅ 找到現有配置:
  - Key Alias: find_restaurant
  - Store File: find_restaurant.keystore

📱 Android Signing Secrets
------------------------
🔍 自動找到 Keystore: /path/to/android/app/find_restaurant.keystore
使用此檔案? [Y/n]: y
✅ 已設定 ANDROID_KEYSTORE_BASE64

💡 在 local.properties 找到 storePassword
使用此密碼? [Y/n]: y
✅ 已設定 KEYSTORE_PASSWORD

💡 在 local.properties 找到 keyAlias: find_restaurant
使用此 alias? [Y/n]: y
✅ 已設定 KEY_ALIAS

💡 在 local.properties 找到 keyPassword
使用此密碼? [Y/n]: y
✅ 已設定 KEY_PASSWORD

🔥 Firebase App Distribution Secrets
-----------------------------------
Firebase credentials JSON 檔案路徑: android/fastlane/findrestaurant_credentials.json
✅ 已設定 FIREBASE_CREDENTIALS_BASE64

🎮 Google Play Store Secrets
---------------------------
Play Store service account JSON 檔案路徑: [輸入路徑]
✅ 已設定 PLAY_STORE_CREDENTIALS_BASE64

🎉 設定完成!

你可以到以下網址查看已設定的 secrets:
https://github.com/Yomiamy/flutter_restaruant/settings/secrets/actions

⚠️  注意: 請確保這些敏感檔案不要提交到 Git!
```

## 🔐 設定的 Secrets 清單

腳本會設定以下 5 個 GitHub Secrets:

| Secret 名稱 | 來源 | 說明 |
|------------|------|------|
| `ANDROID_KEYSTORE_BASE64` | 自動搜尋或手動輸入 | Keystore 檔案的 base64 編碼 |
| `KEYSTORE_PASSWORD` | local.properties 或手動輸入 | Keystore 密碼 |
| `KEY_ALIAS` | local.properties 或手動輸入 | Key 別名 |
| `KEY_PASSWORD` | local.properties 或手動輸入 | Key 密碼 |
| `FIREBASE_CREDENTIALS_BASE64` | 自動搜尋或手動輸入 | Firebase service account JSON |

## 📁 專案配置對應

### Android Build 配置

你的專案使用以下配置結構:

```
android/
├── local.properties          # 本地配置 (不會提交到 Git)
│   ├── keyAlias              → KEY_ALIAS
│   ├── keyPassword           → KEY_PASSWORD
│   ├── storeFile             → 用於搜尋 keystore
│   └── storePassword         → KEYSTORE_PASSWORD
│
├── app/
│   ├── build.gradle          # 讀取 local.properties
│   └── find_restaurant.keystore  → ANDROID_KEYSTORE_BASE64
│
└── fastlane/
    └── findrestaurant_credentials.json  → FIREBASE_CREDENTIALS_BASE64
```

### build.gradle 配置

```gradle
android {
    signingConfigs {
        release {
            keyAlias localProperties['keyAlias']
            keyPassword localProperties['keyPassword']
            storeFile file(localProperties['storeFile'])
            storePassword localProperties['storePassword']
        }
    }
}
```

## 🔄 工作原理

### 1. 讀取 local.properties

```bash
read_local_property() {
    local key=$1
    if [ -f "$LOCAL_PROPERTIES" ]; then
        grep "^${key}=" "$LOCAL_PROPERTIES" | cut -d'=' -f2-
    fi
}
```

### 2. 搜尋 Keystore 檔案

```bash
POTENTIAL_PATHS=(
    "${ANDROID_DIR}/${STORED_STORE_FILE}"
    "${ANDROID_DIR}/app/${STORED_STORE_FILE}"
    "${PROJECT_ROOT}/${STORED_STORE_FILE}"
)
```

### 3. Base64 編碼並上傳

```bash
base64 -i "$keystore_path" | gh secret set ANDROID_KEYSTORE_BASE64
```

## ⚠️ 安全性注意事項

### 1. local.properties 不應提交

確認 `android/.gitignore` 包含:

```gitignore
local.properties
```

### 2. Keystore 檔案不應提交

確認 `android/.gitignore` 包含:

```gitignore
*.jks
*.keystore
```

### 3. 驗證 Git 狀態

執行腳本前,確認敏感檔案未被追蹤:

```bash
# 檢查是否有敏感檔案被 Git 追蹤
git ls-files | grep -E '\.(jks|keystore)$|local\.properties'

# 如果有輸出,表示有檔案被追蹤,需要移除:
git rm --cached android/local.properties
git rm --cached android/app/*.keystore
```

## 🔧 疑難排解

### 問題 1: 找不到 local.properties

**原因**: 檔案不存在或路徑錯誤

**解決**:
```bash
# 檢查檔案是否存在
ls -la android/local.properties

# 如果不存在,手動建立
cat > android/local.properties << EOF
keyAlias=your_alias
keyPassword=your_password
storeFile=your_keystore.jks
storePassword=your_password
EOF
```

### 問題 2: 找不到 Keystore 檔案

**原因**: 檔案名稱或路徑與 local.properties 不符

**解決**:
```bash
# 搜尋所有 keystore 檔案
find android -name "*.keystore" -o -name "*.jks"

# 更新 local.properties 中的 storeFile
vim android/local.properties
```

### 問題 3: gh CLI 未安裝

**解決**:
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### 問題 4: 權限錯誤

**解決**:
```bash
# 確保腳本有執行權限
chmod +x .github/scripts/setup-secrets.sh
```

## 📊 手動設定 (不使用腳本)

如果你想手動設定 Secrets:

### 方法 1: GitHub CLI

```bash
# Keystore (base64)
base64 -i android/app/find_restaurant.keystore | gh secret set ANDROID_KEYSTORE_BASE64

# Keystore 密碼
gh secret set KEYSTORE_PASSWORD -b "yomiamy"

# Key Alias
gh secret set KEY_ALIAS -b "find_restaurant"

# Key 密碼
gh secret set KEY_PASSWORD -b "yomiamy"

# Firebase credentials
base64 -i android/fastlane/findrestaurant_credentials.json | gh secret set FIREBASE_CREDENTIALS_BASE64
```

### 方法 2: GitHub Web UI

1. 前往: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. 點擊 "New repository secret"
3. 輸入名稱和值
4. 點擊 "Add secret"

## 🎓 延伸閱讀

- [GitHub CLI 官方文件](https://cli.github.com/manual/)
- [GitHub Secrets 文件](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Android 簽名指南](https://developer.android.com/studio/publish/app-signing)
- [Fastlane 文件](https://docs.fastlane.tools/)

## 📝 更新記錄

- **2025-01-10**: 初始版本
  - 自動讀取 local.properties
  - 自動搜尋 keystore 檔案
  - 智能提示與確認
