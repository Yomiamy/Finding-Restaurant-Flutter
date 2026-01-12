# 🔄 CI/CD 觸發方式變更總結

## 📋 變更概述

**變更日期**: 2025-01-10

**主要變更**: 將 CI/CD 觸發方式從「PR + 分支推送」改為「Git Tag」

## 🎯 變更原因

更精確的版本控制與發布管理:
- ✅ 明確的版本號對應
- ✅ 避免不必要的自動觸發
- ✅ 更好的發布控制權
- ✅ 清晰的版本歷史追蹤

## 📊 變更對照表

### 觸發方式對照

| Workflow | 舊觸發方式 | 新觸發方式 |
|----------|-----------|-----------|
| **APK Build** | PR 建立/更新 → main/develop | 推送 tag: `rc/android-x.y.z` |
| **Firebase Distribution** | Push → develop/staging/release/* | 推送 tag: `rc/android-x.y.z` |

### 工作流程對照

#### ❌ 舊流程
```
開發 → 建立 PR → 自動建置 APK
      ↓
   合併到 develop → 自動上傳 Firebase
      ↓
   QA 測試
```

**問題**:
- 每次 push 到 develop 都會觸發
- 無明確版本對應
- 難以追蹤特定版本

#### ✅ 新流程
```
開發 → 合併到 develop
      ↓
   打 tag: rc/android-1.3.0
      ↓
   推送 tag → 自動建置 APK + 上傳 Firebase
      ↓
   QA 測試
```

**優點**:
- 明確的版本號
- 可控的觸發時機
- 清晰的版本歷史

## 🔧 技術變更細節

### 1. `android-tag-build.yml` 變更

**檔案**: `.github/workflows/android-tag-build.yml`

**Before**:
```yaml
on:
  pull_request:
    branches:
      - main
      - develop
```

**After**:
```yaml
on:
  push:
    tags:
      - 'rc/android-*.*.*'
  workflow_dispatch:
```

**主要變更**:
- ✅ 改為 tag 觸發
- ✅ 新增 workflow_dispatch (手動觸發)
- ✅ 提取版本號並用於 artifact 命名
- ✅ 保留時間延長: 7天 → 30天

### 2. `android-firebase-distribution.yml` 變更

**檔案**: `.github/workflows/android-firebase-distribution.yml`

**Before**:
```yaml
on:
  push:
    branches:
      - develop
      - staging
      - 'release/**'
```

**After**:
```yaml
on:
  push:
    tags:
      - 'rc/android-*.*.*'
  workflow_dispatch:
```

**主要變更**:
- ✅ 改為 tag 觸發
- ✅ 新增版本資訊提取
- ✅ Release notes 包含版本號
- ✅ 更清晰的完成訊息

## 📝 使用方式變更

### 舊方式 (已廢棄)

```bash
# 建立 PR
git push origin feature/xxx
# 到 GitHub 建立 PR → 自動建置

# 合併後自動上傳 Firebase
git checkout develop
git merge feature/xxx
git push origin develop  # 自動觸發!
```

### 新方式 (現行)

```bash
# 開發完成,合併到 develop
git checkout develop
git merge feature/xxx
git push origin develop

# 準備發布時,打 tag
git tag rc/android-1.3.0
git push origin rc/android-1.3.0  # 觸發建置 + Firebase!
```

## 🏷️ Tag 命名規範

### 格式
```
rc/android-x.y.z
```

### 範例
```bash
rc/android-1.0.0   # 首次發布
rc/android-1.1.0   # 新功能
rc/android-1.1.1   # Bug 修復
rc/android-2.0.0   # 重大更新
```

### 版本號規則

| 類型 | 版本變更 | 範例 |
|------|---------|------|
| 重大更新 | x+1.0.0 | 1.2.3 → 2.0.0 |
| 新功能 | x.y+1.0 | 1.2.3 → 1.3.0 |
| Bug 修復 | x.y.z+1 | 1.2.3 → 1.2.4 |

## 📚 更新的文件

已更新以下文件以反映新的觸發方式:

1. **`.github/SETUP_GUIDE.md`** - 快速開始指南
   - ✅ 更新工作流程說明
   - ✅ 新增 tag 命名規範
   - ✅ 更新測試步驟

2. **`.github/TAG_RELEASE_GUIDE.md`** - Tag 發布完整指南 (新建)
   - ✅ Tag 命名規範
   - ✅ 完整發布流程
   - ✅ 版本號決策樹
   - ✅ Tag 管理指令
   - ✅ 疑難排解

3. **Workflow 檔案**
   - ✅ `android-tag-build.yml` (已更名實際作用)
   - ✅ `android-firebase-distribution.yml`

## 🎯 遷移步驟

### 對於正在進行的開發

```bash
# 1. 完成當前開發
git add .
git commit -m "feat: complete feature xxx"

# 2. 合併到 develop (不會觸發 CI/CD)
git checkout develop
git merge feature/xxx
git push origin develop

# 3. 當準備發布測試版時,打 tag
git tag rc/android-1.3.0
git push origin rc/android-1.3.0  # 觸發!
```

### 第一次使用新流程

```bash
# 1. 確認當前狀態
git status
git log --oneline -5

# 2. 確定版本號
# 查看現有 tag
git tag -l "rc/android-*"

# 3. 打新 tag (假設當前沒有 tag,從 1.0.0 開始)
git tag rc/android-1.0.0

# 4. 推送 tag
git push origin rc/android-1.0.0

# 5. 檢查 GitHub Actions
# 應該看到 2 個 workflow 開始執行
```

## ⚠️ 注意事項

### 1. 不再自動觸發
- ❌ Push 到 develop **不會**自動觸發
- ❌ 建立 PR **不會**自動觸發
- ✅ 只有推送符合格式的 tag 才會觸發

### 2. 版本號管理
- 需要手動維護版本號遞增
- 建議與 `pubspec.yaml` 的版本保持一致
- Tag 一旦推送,不應修改或刪除

### 3. 發布控制
- 更多控制權意味著更多責任
- 記得在準備好時才打 tag
- 打 tag 前確保程式碼已測試

## 🔍 驗證新流程

### 測試步驟

```bash
# 1. 打測試 tag
git tag rc/android-1.0.0-test
git push origin rc/android-1.0.0-test

# 2. 檢查 GitHub Actions
# 前往: https://github.com/YOUR_REPO/actions
# 應該看到 2 個 workflow:
#   - Android Build APK
#   - Android Firebase App Distribution

# 3. 等待完成 (~10-15 分鐘)

# 4. 驗證結果
#   - Actions 頁面下載 APK
#   - Firebase Console 檢查新版本

# 5. 清理測試 tag (如果需要)
git tag -d rc/android-1.0.0-test
git push origin :refs/tags/rc/android-1.0.0-test
```

## 📖 相關文件

- [TAG_RELEASE_GUIDE.md](TAG_RELEASE_GUIDE.md) - Tag 發布完整指南
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - 快速開始指南
- [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) - 詳細設定說明

## 🎉 優勢總結

新的 Tag 觸發方式帶來:

1. **版本控制** - 明確的版本號對應
2. **發布控制** - 決定何時觸發建置
3. **歷史追蹤** - Git tag 提供清晰的版本歷史
4. **避免誤觸** - 不會因為日常開發而觸發
5. **標準化** - 遵循業界標準的發布流程

---

**變更日期**: 2025-01-10
**影響範圍**: CI/CD 觸發機制
**向下相容**: 否 (需要採用新的 tag 流程)
