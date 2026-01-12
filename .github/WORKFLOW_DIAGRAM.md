# CI/CD 工作流程圖

## 🔄 完整 CI/CD 流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                          開發流程                                    │
└─────────────────────────────────────────────────────────────────────┘

  開發者本地開發
       ↓
  feature/xxx 分支
       ↓
  git push origin feature/xxx
       ↓
  建立 Pull Request → main/develop
       ↓
  ┌──────────────────────────┐
  │  PR Build Workflow       │  ← 自動觸發
  │  - 建置 APK              │
  │  - 執行測試              │
  │  - 上傳 Artifact         │
  │  - PR 留言結果           │
  └──────────────────────────┘
       ↓
  Code Review & 測試
       ↓
  Merge to develop
       ↓
  ┌──────────────────────────┐
  │ Firebase Distribution    │  ← 自動觸發
  │  - 建置 Release APK      │
  │  - 上傳到 Firebase       │
  │  - 通知測試人員          │
  └──────────────────────────┘
       ↓
  QA 測試 & 驗證
       ↓
  Merge to release/vX.X.X
       ↓
  打上版本 Tag (vX.X.X)
       ↓
  ┌──────────────────────────┐
  │  Play Store Deploy       │  ← 自動觸發
  │  - 建置 Release AAB      │
  │  - 部署到 Play Store     │
  │  - 建立 GitHub Release   │
  └──────────────────────────┘
       ↓
  Production Release 🎉
```

## 📊 分支策略流程圖

```
┌────────────┐
│   main     │  ← Production (正式版本)
└────────────┘
       ↑
       │ merge + tag
       │
┌────────────┐
│  release/* │  ← Staging (預發布)
└────────────┘
       ↑
       │ merge
       │
┌────────────┐
│  develop   │  ← Testing (測試版)
└────────────┘
       ↑
       │ merge PR
       │
┌────────────┐
│ feature/*  │  ← Development (開發)
└────────────┘
```

## 🎯 Workflow 觸發條件

### 1. PR Build

```
事件: pull_request
條件:
  - branches: [main, develop]
  - paths: [android/**, lib/**, pubspec.yaml]

流程:
  PR 建立/更新
     ↓
  Checkout code
     ↓
  Setup Java/Flutter/Ruby
     ↓
  Install dependencies
     ↓
  Decode signing keys
     ↓
  Fastlane build_apk
     ↓
  Upload artifact
     ↓
  Comment on PR
```

### 2. Firebase Distribution

```
事件: push
條件:
  - branches: [develop, staging, release/*]
  - paths: [android/**, lib/**, pubspec.yaml]

OR

事件: workflow_dispatch (手動觸發)
輸入: release_notes (選填)

流程:
  Push to branch
     ↓
  Checkout code
     ↓
  Setup environment
     ↓
  Decode credentials
     ↓
  Fastlane build_apk
     ↓
  Fastlane deploy_firebase_app_distribution
     ↓
  Upload artifact
     ↓
  Cleanup sensitive files
```

### 3. Play Store Deploy

```
事件: push (tags)
條件:
  - tags: v*.*.*

OR

事件: workflow_dispatch (手動觸發)
輸入:
  - track: [internal, alpha, beta, production]

流程:
  Tag pushed / Manual trigger
     ↓
  Checkout code
     ↓
  Setup environment
     ↓
  Decode credentials
     ↓
  Fastlane build_aab
     ↓
  Fastlane deploy (to selected track)
     ↓
  Upload artifact
     ↓
  Create GitHub Release (if tag)
     ↓
  Cleanup sensitive files
```

## 🔐 Secrets 使用流程

```
GitHub Secrets (加密儲存)
        ↓
GitHub Actions 執行時
        ↓
環境變數注入
        ↓
Base64 解碼
        ↓
寫入臨時檔案
        ↓
Fastlane 使用
        ↓
執行完畢
        ↓
清除臨時檔案 (cleanup)
```

## 📦 建置產物流程

### APK 建置

```
Flutter 原始碼
     ↓
flutter pub get
     ↓
Fastlane prepare
     ↓
flutter clean
     ↓
Gradle assembleRelease
     ↓
簽名 (使用 keystore)
     ↓
build/app/outputs/flutter-apk/app-release.apk
     ↓
上傳為 GitHub Artifact
```

### AAB 建置

```
Flutter 原始碼
     ↓
flutter pub get
     ↓
Fastlane prepare
     ↓
flutter clean
     ↓
Gradle bundleRelease
     ↓
簽名 (使用 keystore)
     ↓
build/app/outputs/bundle/release/app-release.aab
     ↓
上傳為 GitHub Artifact
     ↓
部署到 Play Store
```

## 🚦 決策流程圖

### 選擇部署目標

```
需要部署?
    ↓
    ├─ 僅需測試 → PR Build
    │               ↓
    │          下載 Artifact 測試
    │
    ├─ 給測試人員 → Firebase Distribution
    │               ↓
    │          測試人員自動收到通知
    │
    └─ 正式發布 → Play Store Deploy
                   ↓
              選擇部署軌道:
                ├─ internal  (內部測試)
                ├─ alpha     (封閉測試)
                ├─ beta      (開放測試)
                └─ production (正式版)
```

### 版本號更新流程

```
開始發布新版本
     ↓
確認當前版本號
     ↓
決定更新類型:
  ├─ 重大更新 (Breaking Changes) → MAJOR +1
  ├─ 新功能 (New Features)       → MINOR +1
  └─ 錯誤修復 (Bug Fixes)        → PATCH +1
     ↓
更新 pubspec.yaml
  version: X.Y.Z+BUILD
     ↓
更新 Fastfile
  versionName: "X.Y.Z"
  versionCode: BUILD
     ↓
提交並推送
     ↓
建立 Tag: vX.Y.Z
     ↓
推送 Tag → 觸發 Play Store Deploy
```

## ⏱️ 預估執行時間

```
┌──────────────────────┬──────────────┬─────────────┐
│ Workflow             │ 平均執行時間  │ 最大時限    │
├──────────────────────┼──────────────┼─────────────┤
│ PR Build             │ 8-12 分鐘    │ 30 分鐘     │
│ Firebase Distribution│ 10-15 分鐘   │ 30 分鐘     │
│ Play Store Deploy    │ 15-25 分鐘   │ 45 分鐘     │
└──────────────────────┴──────────────┴─────────────┘

執行時間分解 (Firebase Distribution 範例):
  - Checkout & Setup     : 2-3 分鐘
  - Flutter dependencies : 1-2 分鐘
  - Gradle build        : 5-8 分鐘
  - Firebase upload     : 1-2 分鐘
  - Artifact upload     : 1 分鐘
```

## 🔄 錯誤處理流程

```
Workflow 執行
     ↓
  發生錯誤?
     ↓
  ├─ YES → 執行 cleanup (if: always())
  │         ↓
  │       刪除臨時檔案
  │         ↓
  │       workflow 失敗
  │         ↓
  │       發送通知 (可選)
  │         ↓
  │       開發者檢視日誌
  │         ↓
  │       修復問題
  │         ↓
  │       重新執行
  │
  └─ NO → 繼續執行
           ↓
        完成所有步驟
           ↓
        執行 cleanup
           ↓
        workflow 成功 ✅
```

## 📱 部署軌道說明

```
┌─────────────────────────────────────────────────────┐
│              Google Play Store Tracks               │
├─────────────┬───────────────┬───────────────────────┤
│ internal    │ 內部測試      │ 最多 100 位測試人員   │
│             │              │ 立即發布,不需審查     │
├─────────────┼───────────────┼───────────────────────┤
│ alpha       │ 封閉測試      │ 指定測試人員名單      │
│             │              │ 快速審查 (數小時)     │
├─────────────┼───────────────┼───────────────────────┤
│ beta        │ 開放測試      │ 任何人可加入測試      │
│             │              │ 需要審查             │
├─────────────┼───────────────┼───────────────────────┤
│ production  │ 正式發布      │ 所有用戶             │
│             │              │ 完整審查流程         │
└─────────────┴───────────────┴───────────────────────┘

建議發布流程:
  internal → alpha → beta → production
  (1-2天)   (3-5天)  (1-2週)  (正式發布)
```

## 🎨 視覺化執行狀態

### 成功執行

```
┌─────────────────────────────────────┐
│ ✅ PR Build                         │
│ ✅ Code Quality Check               │
│ ✅ Security Scan                    │
│ ✅ Build APK                        │
│ ✅ Upload Artifact                  │
│ ✅ Comment on PR                    │
└─────────────────────────────────────┘
     Status: ✅ Success
     Duration: 10m 23s
```

### 失敗執行

```
┌─────────────────────────────────────┐
│ ✅ PR Build                         │
│ ✅ Code Quality Check               │
│ ✅ Security Scan                    │
│ ❌ Build APK                        │  ← 失敗點
│ ⏭️  Upload Artifact                  │
│ ⏭️  Comment on PR                    │
└─────────────────────────────────────┘
     Status: ❌ Failed
     Error: Signing key not found
     Duration: 8m 15s
```

## 📊 使用統計範例

```
本月部署統計:
┌──────────────┬─────┬─────┬─────┬──────┐
│ Workflow     │ 成功 │ 失敗 │ 總計 │ 成功率 │
├──────────────┼─────┼─────┼─────┼──────┤
│ PR Build     │  45 │  3  │  48 │  94% │
│ Firebase     │  12 │  1  │  13 │  92% │
│ Play Store   │   4 │  0  │   4 │ 100% │
└──────────────┴─────┴─────┴─────┴──────┘

部署時間趨勢:
Week 1: ████████░░ 8 次
Week 2: ████████████ 12 次
Week 3: ██████░░░░ 6 次
Week 4: ██████████░░ 10 次
```

---

這個流程圖文件幫助你視覺化整個 CI/CD 流程,方便理解和向團隊說明。
