# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1+34] - 2026-09-08

### Added
- **CI/CD Pipeline**: 引入基於 GitHub Actions 的自動化發布流水線，支援 Android (Google Play / Firebase APK) 與 iOS (TestFlight / Firebase IPA) 雙平台自動打包與分發 (#113)。
- **Map Locate Button**: 自訂地圖重新定位按鈕，並對齊 `ThemeSize` design token (#110)。

### Changed
- **Architecture**: 解構 `AccountType` 循環依賴，分離領域層 `AccountTypeModel` 與數據層 `AccountType` (#112)。

### Fixed
- **Map Camera**: 修正定位失敗或地圖 Controller 尚未就緒時的崩潰防護 (#110)。
