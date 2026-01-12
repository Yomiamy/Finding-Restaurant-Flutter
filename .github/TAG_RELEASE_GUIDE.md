# 🏷️ Tag 發布指南

## 📋 概述

本專案使用 **Git Tag** 來觸發自動化建置與發布流程。

當你推送符合格式 `rc/android-x.y.z(code)` 的 tag 時,會自動觸發:
1. ✅ APK 建置 (使用 Tag 中的 Version Name 和 Version Code)
2. ✅ Firebase App Distribution 上傳

## 🎯 Tag 命名格式

### 格式規範
```
rc/android-x.y.z(code)
```

- `rc` = Release Candidate (發布候選版本)
- `android` = 平台識別
- `x.y.z` = Version Name (遵循語意化版本: 主版本.次版本.修訂版本)
- `code` = Version Code (整數,必須比上一個版本大)

**⚠️ 注意**: 格式中的括號 `()` 是必須的,且 Version Code 必須為數字。

### 版本號說明

```
Version Name (x.y.z):
  - MAJOR (x): 重大更新,不向下相容
  - MINOR (y): 新功能,向下相容
  - PATCH (z): Bug 修復,向下相容

Version Code (code):
  - Android 系統用來判斷更新的依據
  - 必須是整數 (例如: 12, 13, 101)
  - 每次發布(包含測試版)都必須遞增,否則無法安裝或上傳
```

## 📝 使用範例

**⚠️ 重要: 在終端機中使用包含括號的 Tag 時,請務必使用單引號 `'` 包裹,避免 Shell 解析錯誤。**

### 範例 1: 首次發布

```bash
# 確保在正確的分支
git checkout develop
git pull origin develop

# 打 tag (Version: 1.0.0, Code: 1)
git tag 'rc/android-1.0.0(1)'

# 推送 tag (觸發 CI/CD)
git push origin 'rc/android-1.0.0(1)'
```

**結果**:
- ✅ 自動建置 APK (VersionName: 1.0.0, VersionCode: 1)
- ✅ 自動上傳到 Firebase
- ✅ 測試人員收到通知

### 範例 2: 新功能發布

```bash
# 開發完成新功能
git checkout develop
git pull origin develop

# 遞增次版本號, 並遞增 Version Code (假設上一版是 1)
git tag 'rc/android-1.1.0(2)'
git push origin 'rc/android-1.1.0(2)'
```

### 範例 3: Bug 修復

```bash
# 修復 bug
git checkout develop
git pull origin develop

# 遞增修訂版本號, 並遞增 Version Code
git tag 'rc/android-1.0.1(3)'
git push origin 'rc/android-1.0.1(3)'
```

### 範例 4: 重大更新

```bash
# 重大架構改變
git checkout develop
git pull origin develop

# 遞增主版本號, Version Code 繼續遞增
git tag 'rc/android-2.0.0(4)'
git push origin 'rc/android-2.0.0(4)'
```

## 🔄 完整發布流程

### Step 1: 開發與測試

```bash
# 1. 建立功能分支
git checkout -b feature/awesome-feature

# 2. 開發...
# 3. 本地測試
cd android
bundle exec fastlane build_apk

# 4. 提交變更
git add .
git commit -m "feat: add awesome feature"
git push origin feature/awesome-feature
```

### Step 2: 合併到 develop

```bash
# 5. 合併到 develop (透過 PR 或直接合併)
git checkout develop
git merge feature/awesome-feature
git push origin develop
```

### Step 3: 打 tag 並發布

```bash
# 6. 確認版本號
# 假設當前版本是 1.2.0(10),新增功能,版本 Name 變為 1.3.0, Code 變為 11

# 7. 打 tag (注意引號)
git tag 'rc/android-1.3.0(11)'

# 8. 推送 tag (這會觸發 CI/CD!)
git push origin 'rc/android-1.3.0(11)'
```

### Step 4: 驗證發布

```bash
# 9. 檢查 GitHub Actions
# 前往: https://github.com/YOUR_REPO/actions
# 應該看到 workflow 正在執行: "Android Build & Deploy"

# 10. 等待完成 (約 10-15 分鐘)

# 11. 驗證結果
#   - Actions 頁面下載 APK artifact
#   - Firebase Console 檢查新版本 (包含正確的 Version Name 和 Code)
#   - 測試人員收到 email 通知
```

### Step 5: QA 測試

```bash
# 12. QA 從 Firebase 下載並測試

# 13. 如果測試通過,合併到 main
git checkout main
git merge develop
git push origin main
```

## 🛠️ Tag 管理指令

### 查看所有 tag

```bash
# 列出所有 tag
git tag

# 列出符合特定模式的 tag
git tag -l "rc/android-*"

# 查看 tag 詳細資訊
git show 'rc/android-1.3.0(11)'
```

### 刪除 tag

```bash
# 刪除本地 tag (注意引號)
git tag -d 'rc/android-1.3.0(11)'

# 刪除遠端 tag
git push origin :refs/tags/'rc/android-1.3.0(11)'

# 或使用這個命令刪除遠端 tag
git push origin --delete 'rc/android-1.3.0(11)'
```

### 重新打 tag

```bash
# 如果打錯了,需要重新打
# 1. 刪除本地和遠端的錯誤 tag
git tag -d 'rc/android-1.3.0(11)'
git push origin :refs/tags/'rc/android-1.3.0(11)'

# 2. 重新打正確的 tag
git tag 'rc/android-1.3.0(11)'
git push origin 'rc/android-1.3.0(11)'
```

### 帶註解的 tag

```bash
# 建立帶註解的 tag (推薦用於重要發布)
git tag -a 'rc/android-1.3.0(11)' -m "Release 1.3.0 - Add awesome features"
git push origin 'rc/android-1.3.0(11)'
```

## 📊 版本號決策範例

```
目前版本: 1.2.3(10)

情況                    | New Version Name | New Version Code | Tag
------------------------|------------------|------------------|-------------------------
Bug 修復                | 1.2.4            | 11               | rc/android-1.2.4(11)
新功能                  | 1.3.0            | 11               | rc/android-1.3.0(11)
重大更新                | 2.0.0            | 11               | rc/android-2.0.0(11)
測試版 Build 1          | 1.3.0            | 11               | rc/android-1.3.0(11)
測試版 Build 2 (Fix)    | 1.3.0            | 12               | rc/android-1.3.0(12)
```
*註: Version Code 只要是遞增整數即可,不一定要連號(雖然通常是連號),但絕不能重複或回頭。*

## ⚠️ 注意事項

### 1. Tag 不可變
一旦推送 tag 到遠端,**不應該修改或刪除**,除非:
- 打錯 tag (立即發現並修正)
- 發現嚴重問題需要撤回

### 2. Version Code 至關重要
- 如果 `Version Code` 沒有遞增,**Google Play 和 Firebase 都會拒絕上傳**。
- 請在打 tag 前確認上一個版本的 code。

### 3. Tag 與分支對應
```bash
# 確保 tag 是打在正確的 commit 上
git log --oneline -5  # 查看最近的 commit
git tag 'rc/android-1.3.0(11)'  # 在當前 commit 打 tag
```

## 🔍 疑難排解

### 問題 1: Tag 推送後沒有觸發 workflow

**檢查**:
```bash
# 1. 確認 tag 格式正確 (必須包含括號和 code)
git tag -l "rc/android-*"

# 正確: rc/android-1.0.0(1)
# 錯誤: rc/android-1.0.0

# 2. 確認 tag 已推送到遠端
git ls-remote --tags origin
```

**可能原因**:
- Tag 格式不符合 `rc/android-x.y.z(code)`
- Tag 只在本地,沒有推送到遠端

### 問題 2: Workflow 提取版本資訊失敗

**檢查**:
- Tag 中是否包含空格? (不應包含)
- Version Code 是否為純數字?

### 問題 3: Firebase 上傳失敗 "Version code has already been used"

**解決**:
- 這表示該 Version Code 已經使用過了。
- 請刪除該 tag,增加 Version Code,然後重新打 tag。
```bash
git tag -d 'rc/android-1.2.3(10)'
# 改用 11
git tag 'rc/android-1.2.3(11)'
git push origin 'rc/android-1.2.3(11)'
```

---

**最後更新**: 2026-01-13
**適用專案**: Finding Restaurant Flutter
**觸發格式**: `rc/android-x.y.z(code)`
