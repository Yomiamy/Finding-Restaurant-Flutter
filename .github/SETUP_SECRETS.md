# 🔐 GitHub Secrets 快速設置指南

完成 CI/CD 配置的最後一步！

## 📝 需要設置的 4 個 Secrets

| Secret 名稱 | 說明 |
|------------|-----|
| `KEYSTORE_BASE64` | Keystore 文件的 Base64 編碼 |
| `KEY_ALIAS` | 密鑰別名（通常是 `flutter-restaruant`） |
| `KEY_PASSWORD` | 密鑰密碼 |
| `STORE_PASSWORD` | Keystore 密碼 |

---

## 🚀 快速設置步驟

### 步驟 1: 準備 Keystore 文件

如果你已經有 keystore 文件，跳到步驟 2。

如果沒有，使用以下命令生成：

```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias flutter-restaruant
```

記錄下：
- ✏️ Keystore 密碼（Store Password）
- ✏️ 密鑰密碼（Key Password）
- ✏️ 密鑰別名（Key Alias）

---

### 步驟 2: 轉換 Keystore 為 Base64

**MacOS/Linux:**
```bash
base64 -i release-keystore.jks -o keystore-base64.txt
```

**Windows PowerShell:**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-keystore.jks")) | Out-File keystore-base64.txt
```

這會生成 `keystore-base64.txt` 文件。

---

### 步驟 3: 添加到 GitHub

1. **打開你的 GitHub 倉庫**

2. **前往 Settings**
   ```
   倉庫頁面 → Settings → Secrets and variables → Actions
   ```

3. **點擊 "New repository secret"**

4. **添加 4 個 secrets：**

   #### Secret 1: KEYSTORE_BASE64
   - Name: `KEYSTORE_BASE64`
   - Value: 複製 `keystore-base64.txt` 的全部內容
   - 點擊 "Add secret"

   #### Secret 2: KEY_ALIAS
   - Name: `KEY_ALIAS`
   - Value: `flutter-restaruant` （或你創建時使用的別名）
   - 點擊 "Add secret"

   #### Secret 3: KEY_PASSWORD
   - Name: `KEY_PASSWORD`
   - Value: 你的密鑰密碼
   - 點擊 "Add secret"

   #### Secret 4: STORE_PASSWORD
   - Name: `STORE_PASSWORD`
   - Value: 你的 keystore 密碼
   - 點擊 "Add secret"

---

### 步驟 4: 驗證設置

前往 **Settings → Secrets and variables → Actions**，確認看到 4 個 secrets：

```
✅ KEYSTORE_BASE64
✅ KEY_ALIAS
✅ KEY_PASSWORD
✅ STORE_PASSWORD
```

---

## 🧪 測試 CI/CD

設置完成後，測試構建：

```bash
# 創建測試標籤
git tag v1.3.1-test
git push origin v1.3.1-test
```

前往 GitHub Actions 查看構建進度。

---

## ⚠️ 安全提示

1. **不要將 keystore 文件提交到 Git**
   - 已在 `.gitignore` 中排除 `*.jks` 和 `key.properties`

2. **妥善保管 keystore 和密碼**
   - 建議將 keystore 備份到安全的地方
   - 丟失後無法恢復，所有已發佈的應用都需要重新簽名

3. **定期更換密碼**
   - 如果懷疑密碼洩露，立即更新 GitHub Secrets

---

## 🆘 遇到問題？

### 問題 1: Secrets 設置後構建仍然失敗

**檢查清單：**
- [ ] 確認所有 4 個 secrets 名稱完全匹配（區分大小寫）
- [ ] 確認 Base64 編碼是完整的（沒有截斷或換行）
- [ ] 確認密鑰別名與 keystore 中的一致
- [ ] 確認密碼正確無誤

**驗證方法：**
```bash
# 測試 keystore 是否正常
keytool -list -v -keystore release-keystore.jks -alias flutter-restaruant
```

### 問題 2: 不確定 keystore 的別名

```bash
# 列出 keystore 中的所有別名
keytool -list -keystore release-keystore.jks
```

### 問題 3: 忘記了 keystore 密碼

⚠️ **無法恢復**。需要創建新的 keystore 並重新配置。

---

## 📞 需要幫助？

查看完整文檔：[ANDROID_CI_README.md](./ANDROID_CI_README.md)

或在 GitHub Issues 中提問。

---

**完成設置後，你的 Flutter Android 應用將實現自動化構建和發佈！** 🎉
