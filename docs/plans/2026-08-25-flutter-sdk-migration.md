# 實作計畫：Flutter SDK 版本遷移 (≥ 3.44.1)

## 任務拆分

1. **更新 SDK 限制**
   - 檔案：`pubspec.yaml`
   - 修改內容：將 `environment` 區塊中的 `flutter: '>=3.41.0'` 替換為 `flutter: '>=3.44.1'`。

2. **驗證設定**
   - 指令：`flutter pub get`
   - 目的：確認相依套件解析無衝突。
