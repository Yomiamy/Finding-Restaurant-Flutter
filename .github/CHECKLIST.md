# GitHub Actions CI/CD 設定檢查清單

使用這個檢查清單來確保所有設定都正確完成。

## 📋 前置準備

- [ ] 安裝 GitHub CLI (`brew install gh`)
- [ ] 登入 GitHub CLI (`gh auth login`)
- [ ] 準備 Android release keystore 檔案
- [ ] 準備 Firebase service account JSON
- [ ] 準備 Google Play Store service account JSON

## 🔐 GitHub Secrets 設定

### Android Signing

- [ ] `ANDROID_KEYSTORE_BASE64` - Keystore 檔案的 base64 編碼
  ```bash
  base64 -i your-release.jks | pbcopy
  ```

- [ ] `KEYSTORE_PASSWORD` - Keystore 密碼
- [ ] `KEY_ALIAS` - Key 別名
- [ ] `KEY_PASSWORD` - Key 密碼

### Firebase App Distribution

- [ ] `FIREBASE_CREDENTIALS_BASE64` - Firebase service account JSON 的 base64
  ```bash
  base64 -i android/fastlane/findrestaurant_credentials.json | pbcopy
  ```

### Google Play Store

- [ ] `PLAY_STORE_CREDENTIALS_BASE64` - Play Store service account JSON 的 base64
  ```bash
  base64 -i play-store-credentials.json | pbcopy
  ```

### 驗證 Secrets 設定

```bash
# 列出所有 secrets (不會顯示值,只顯示名稱)
gh secret list
```

應該看到:
```
ANDROID_KEYSTORE_BASE64
KEYSTORE_PASSWORD
KEY_ALIAS
KEY_PASSWORD
FIREBASE_CREDENTIALS_BASE64
PLAY_STORE_CREDENTIALS_BASE64
```

## 📱 Firebase 設定

- [ ] 到 [Firebase Console](https://console.firebase.google.com/)
- [ ] 確認專案已建立 (findrestaurant-c80ea)
- [ ] 確認 Android app 已註冊
- [ ] 確認 Firebase App Distribution 已啟用
- [ ] 確認 service account 有正確權限:
  - Firebase App Distribution Admin

## 🎮 Google Play Console 設定

- [ ] 到 [Google Play Console](https://play.google.com/console)
- [ ] 確認應用程式已建立
- [ ] 確認已完成首次手動上傳 (必須!)
- [ ] 設定 → API 存取
- [ ] 建立或連結 service account
- [ ] 授予 service account 權限:
  - ✅ Release to production, exclude devices, and use Play App Signing
  - ✅ Release apps to testing tracks
  - ✅ View app information and download bulk reports
- [ ] 下載 service account JSON 金鑰

## 🔧 本地環境測試

### 測試 Fastlane 建置

```bash
cd android

# 安裝 Ruby 依賴
bundle install

# 測試 APK 建置
bundle exec fastlane build_apk

# 測試 AAB 建置
bundle exec fastlane build_aab
```

- [ ] APK 建置成功
- [ ] AAB 建置成功
- [ ] 輸出檔案存在於 `build/app/outputs/` 目錄

### 測試 Firebase 部署 (選用)

```bash
# 注意: 這會真的上傳到 Firebase!
cd android
bundle exec fastlane deploy_firebase_app_distribution
```

- [ ] 上傳成功
- [ ] 在 Firebase Console 看到新版本

## 🚀 GitHub Actions 測試

### 測試 PR Build

- [ ] 建立測試分支
  ```bash
  git checkout -b test/ci-setup
  git push origin test/ci-setup
  ```

- [ ] 建立 PR 到 main 分支
- [ ] 檢查 Actions 頁面的執行狀態
- [ ] 確認建置成功
- [ ] 確認 PR 有留言
- [ ] 下載 artifact 並安裝測試

### 測試 Firebase Distribution

- [ ] 推送到 develop 分支
  ```bash
  git checkout develop
  git merge test/ci-setup
  git push origin develop
  ```

- [ ] 檢查 Actions 執行
- [ ] 確認部署成功
- [ ] 到 Firebase Console 確認新版本
- [ ] 測試人員收到通知 email

### 測試 Play Store Deploy

- [ ] 更新版本號
  - 修改 `pubspec.yaml` 的 `version`
  - 修改 `android/fastlane/Fastfile` 的 `versionCode` 和 `versionName`

- [ ] 建立並推送 tag
  ```bash
  git tag v1.3.0
  git push origin v1.3.0
  ```

- [ ] 檢查 Actions 執行
- [ ] 確認部署成功
- [ ] 到 Play Console 確認新版本
- [ ] 確認部署到正確的 track

## 📊 最終驗證

### Workflows 檔案檢查

- [ ] `.github/workflows/android-tag-build.yml` 存在
- [ ] `.github/workflows/android-firebase-distribution.yml` 存在
- [ ] `.github/workflows/android-play-store-deploy.yml` 存在

### 文件檢查

- [ ] `.github/README.md` 存在
- [ ] `.github/GITHUB_ACTIONS_SETUP.md` 存在
- [ ] `.github/CHECKLIST.md` 存在 (本文件)

### 設定檔檢查

- [ ] `android/Gemfile` 存在
- [ ] `android/fastlane/Fastfile` 已更新支援環境變數
- [ ] `android/.gitignore` 已更新排除敏感檔案
- [ ] `.github/.gitignore` 存在

### 安全性檢查

- [ ] ⚠️ **確認** `android/fastlane/*.json` 檔案沒有被提交到 Git
- [ ] ⚠️ **確認** `*.jks` 和 `*.keystore` 檔案沒有被提交到 Git
- [ ] ⚠️ **確認** `key.properties` 檔案沒有被提交到 Git
- [ ] ⚠️ **確認** 所有敏感資訊都在 `.gitignore` 中

檢查指令:
```bash
# 確認沒有敏感檔案被追蹤
git ls-files | grep -E '\.(jks|keystore|json)$|key\.properties'

# 應該沒有任何輸出!如果有,請立即移除:
git rm --cached <檔案名稱>
```

## 🎉 完成後的下一步

- [ ] 更新專案 README 加入 CI/CD 狀態徽章
- [ ] 通知團隊成員關於新的 CI/CD 流程
- [ ] 建立 Wiki 頁面說明部署流程
- [ ] 設定 Slack/Discord 通知 (選用)

## 📝 注意事項

### 重要提醒

1. **首次部署**: Google Play Store 必須先手動上傳一次 APK/AAB
2. **版本號**: 每次部署必須遞增 `versionCode`
3. **Keystore**: 絕對不能遺失,請妥善備份
4. **Secrets**: 定期更換密碼和金鑰
5. **測試**: 每次修改 workflow 後都要測試

### 常見問題

Q: 如何重新設定 secret?
```bash
# 刪除舊的
gh secret remove SECRET_NAME

# 設定新的
echo "new_value" | gh secret set SECRET_NAME
```

Q: 如何查看 Actions 日誌?
```bash
# 列出最近的 workflow runs
gh run list

# 查看特定 run 的日誌
gh run view RUN_ID --log
```

Q: 建置失敗如何偵錯?
1. 到 GitHub Actions 頁面查看詳細日誌
2. 本地執行對應的 Fastlane lane
3. 檢查 secrets 是否正確設定
4. 檢查版本號是否正確遞增

## ✅ 最終確認

完成所有檢查項目後,請在此簽名確認:

- 設定者: ________________
- 日期: ________________
- 確認所有項目: [ ]
- 已完成測試部署: [ ]
- 團隊已被通知: [ ]

---

**恭喜! 🎉 你已經完成 GitHub Actions CI/CD 的設定!**
