# 🚀 Android CI/CD 使用指南

本專案使用 GitHub Actions 進行 Flutter Android 應用的自動化構建和發佈。

## 📋 目錄

- [功能概述](#功能概述)
- [前置需求](#前置需求)
- [GitHub Secrets 設置](#github-secrets-設置)
- [如何使用](#如何使用)
- [構建產物](#構建產物)
- [常見問題](#常見問題)

---

## 🎯 功能概述

當你創建一個新的 Git Tag 時（如 `v1.3.0`），GitHub Actions 會自動：

1. ✅ 設置 Flutter 和 Java 環境
2. ✅ 安裝專案依賴
3. ✅ 配置 Android 簽名
4. ✅ 構建 **Release APK**（用於測試和分發）
5. ✅ 構建 **Release AAB**（用於 Google Play Store 發佈）
6. ✅ 上傳構建產物到 GitHub Artifacts
7. ✅ 創建 GitHub Release 並附上 APK 和 AAB 文件

---

## 📦 前置需求

### 1. Android 簽名密鑰

你需要一個 Android release keystore 文件（`.jks` 或 `.keystore`）用於簽名。

如果沒有，可以使用以下命令生成：

```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias flutter-restaruant
```

生成過程中會要求設置：
- **Keystore 密碼** (Store Password)
- **密鑰密碼** (Key Password)
- **密鑰別名** (Key Alias)：建議使用 `flutter-restaruant`

⚠️ **重要**：請妥善保管 keystore 文件和密碼！丟失後無法恢復。

---

## 🔐 GitHub Secrets 設置

### 步驟 1: 準備 Keystore Base64 編碼

在終端執行（MacOS/Linux）：

```bash
base64 -i release-keystore.jks -o keystore-base64.txt
```

或在 Windows PowerShell：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-keystore.jks")) | Out-File keystore-base64.txt
```

這會生成 `keystore-base64.txt` 文件，包含 keystore 的 Base64 編碼內容。

### 步驟 2: 添加 GitHub Secrets

1. 前往你的 GitHub 倉庫
2. 點擊 **Settings** → **Secrets and variables** → **Actions**
3. 點擊 **New repository secret**
4. 添加以下 4 個 secrets：

| Secret 名稱 | 值 | 說明 |
|------------|-----|-----|
| `KEYSTORE_BASE64` | `keystore-base64.txt` 的內容 | Keystore 文件的 Base64 編碼 |
| `KEY_ALIAS` | `flutter-restaruant` | 密鑰別名 |
| `KEY_PASSWORD` | 你的密鑰密碼 | 創建 keystore 時設置的密鑰密碼 |
| `STORE_PASSWORD` | 你的 keystore 密碼 | 創建 keystore 時設置的 keystore 密碼 |

### 步驟 3: 驗證 Secrets

確保所有 4 個 secrets 都已正確添加：

```
✅ KEYSTORE_BASE64
✅ KEY_ALIAS
✅ KEY_PASSWORD
✅ STORE_PASSWORD
```

---

## 🚀 如何使用

### 方式 1: 創建新的版本標籤（推薦）

```bash
# 1. 確保代碼已提交
git add .
git commit -m "準備發佈 v1.3.1"

# 2. 創建並推送 tag
git tag v1.3.1
git push origin v1.3.1
```

### 方式 2: 直接在 GitHub 上創建 Release

1. 前往倉庫的 **Releases** 頁面
2. 點擊 **Create a new release**
3. 創建新的 tag（如 `v1.3.1`）
4. 填寫 Release 資訊
5. 點擊 **Publish release**

GitHub Actions 會自動開始構建流程。

---

## 📦 構建產物

### GitHub Artifacts（保留 7 天）

構建完成後，可以在 GitHub Actions 的 workflow 運行頁面下載：

- `flutter-restaruant-apk-v1.3.1.zip` - APK 文件
- `flutter-restaruant-aab-v1.3.1.zip` - AAB 文件

### GitHub Release（永久保存）

構建產物會自動附加到 GitHub Release 中：

- `flutter-restaruant-v1.3.1.apk` - 可直接安裝到設備
- `flutter-restaruant-v1.3.1.aab` - 上傳到 Google Play Console

---

## 🔍 查看構建狀態

1. 前往倉庫的 **Actions** 標籤
2. 查找你的 tag 對應的 workflow 運行
3. 點擊查看詳細日誌和構建狀態

構建過程通常需要 **5-10 分鐘**。

---

## ❓ 常見問題

### Q1: 構建失敗，提示簽名錯誤

**A**: 檢查以下項目：
- GitHub Secrets 是否都已正確設置
- `KEY_ALIAS` 是否與 keystore 中的別名一致
- 密碼是否正確（注意區分大小寫）

### Q2: 如何更新 Flutter 版本？

**A**: 編輯 `.github/workflows/android-build.yml` 文件：

```yaml
env:
  FLUTTER_VERSION: '3.24.5'  # 修改這裡
```

### Q3: 如何修改觸發條件？

**A**: 編輯 workflow 文件中的 `on` 部分：

```yaml
on:
  push:
    tags:
      - 'v*'        # 所有 v 開頭的標籤
      - 'release-*' # 或 release- 開頭的標籤
```

### Q4: 構建成功但找不到 APK/AAB

**A**: 檢查：
1. Workflow 是否成功完成所有步驟
2. 在 Actions 頁面的 Artifacts 部分下載
3. 或在對應的 GitHub Release 頁面查找

### Q5: 如何本地測試構建？

**A**: 在專案目錄執行：

```bash
cd flutter_restaruant

# 測試 APK 構建
flutter build apk --release

# 測試 AAB 構建
flutter build appbundle --release
```

### Q6: 如何修改 keystore 文件名？

**A**: 如果你的 keystore 文件名不是 `release-keystore.jks`，需要：

1. 更新 workflow 中的文件名：
   ```yaml
   echo "$KEYSTORE_BASE64" | base64 -d > app/your-keystore-name.jks
   ```

2. 更新 `key.properties` 中的 `storeFile`：
   ```yaml
   storeFile=your-keystore-name.jks
   ```

---

## 🛠️ 技術細節

### 使用的 GitHub Actions

- **actions/checkout@v4**: 檢出代碼
- **actions/setup-java@v4**: 設置 Java 17 環境
- **subosito/flutter-action@v2**: 設置 Flutter SDK
- **actions/upload-artifact@v4**: 上傳構建產物
- **softprops/action-gh-release@v1**: 創建 GitHub Release

### 構建環境

- **OS**: Ubuntu Latest
- **Java**: Temurin JDK 17
- **Flutter**: 3.24.5 (Stable Channel)
- **Gradle Cache**: 啟用

### 安全性

- Keystore 文件在構建完成後自動刪除
- 所有敏感資訊都通過 GitHub Secrets 加密存儲
- 不會在日誌中輸出密碼或密鑰

---

## 📚 相關資源

- [Flutter 官方文檔 - Android 發佈](https://docs.flutter.dev/deployment/android)
- [GitHub Actions 文檔](https://docs.github.com/en/actions)
- [Android 簽名指南](https://developer.android.com/studio/publish/app-signing)

---

## 📝 版本記錄

- **2025-10-26**: 初始版本，支援 APK 和 AAB 構建

---

💡 **提示**: 如果遇到問題，請查看 GitHub Actions 的詳細日誌，或在 Issues 中提問。
