# Feature: 刪除死碼 `PlatformWidget` (Remove Dead `platform_widget.dart`)

> 項目編號：**UI-8.2**  
> 優先級別：**P1（技術債清理）**，effort 0.1d  
> 建立日期：2026-09-25  
> 參考文檔：`docs/brainstorm/2026-09-25-features-brainstorm.md` §8.3.2 [UI-8.2]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

- `lib/component/platform_widget.dart` 只定義 `abstract class PlatformWidget<I, A>`，在 `lib/` 與 `test/` 中**無任何子類或呼叫端**（0 處引用），屬死碼。
- 第三方套件 `package:flutter_platform_widgets` 也匯出同名的 `PlatformWidget`。`lib/flow/main/view/main_page.dart` 同時 import 了該套件與 `component_barrel.dart`，形成潛在名稱衝突——目前沒炸只是因為沒人用；一旦有人用到 `PlatformWidget` 就會出現 ambiguous import 編譯錯誤。刪掉它，這個坑就消失了。

## 2. 使用者故事

身為**開發者**，我希望 `component` 模組只保留實際在用的元件，這樣讀程式碼時不會被沒用的抽象誤導，也不會撞上與 `flutter_platform_widgets` 的同名衝突。

## 3. 規格需求 (What)

1. 刪除 `lib/component/platform_widget.dart`。
2. 刪除 `lib/component/component_barrel.dart` 中的 `export 'platform_widget.dart';`（第 5 行）。
   - brainstorm 的影響範圍**漏列**這一項：只刪檔不刪 export 會直接編譯失敗。

## 4. 範圍邊界 (Out of Scope)

- **不動** `flutter_platform_widgets` 相依（`pubspec.yaml` 及 `main.dart`、`main_page.dart`、`settings_page.dart`、`photo_viewer.dart`、`view_utils.dart` 等使用處皆不變）。
- **不重構** `component_barrel.dart` 的其他 export，也不調整任何 barrel 結構。
- 不新增測試（純刪除，既有 analyze + test 即足以驗證）。

## 5. 驗收條件 (Verification)

1. `lib/component/platform_widget.dart` 不存在。
2. `grep -rn "platform_widget.dart" lib test` 無結果（barrel 已無該 export）。
3. `flutter analyze` 零 issue。
4. `flutter test` 全綠。
