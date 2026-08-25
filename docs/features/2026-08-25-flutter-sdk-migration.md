# 需求規格：Flutter SDK 版本遷移 (≥ 3.44.1)

## What
將專案的 Flutter SDK 最低版本要求提升至 `3.44.1` 或以上。

## Why
作為基礎設施升級的一環，為了獲得最新的功能與修復，需要將目前 `pubspec.yaml` 中 `>=3.41.0` 的版本限制上調至 `>=3.44.1`。

## 範圍與驗收條件
- **Out of scope**: 其他依賴庫的版本升級（若無因 SDK 升級而造成的破壞性錯誤則不調整）。
- **驗收條件**: `pubspec.yaml` 中 `environment.flutter` 欄位的版本限制為 `>=3.44.1`，並且 `flutter pub get` 能正常通過。
