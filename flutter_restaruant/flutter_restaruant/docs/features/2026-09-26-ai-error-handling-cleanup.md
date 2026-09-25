# Feature: AI 路徑錯誤處理收尾——移除 i18n fallback 的 `Error` 捕捉、補 `Error` 外拋測試與 Menu Vision Logger

> 建立日期：2026-09-26
> 來源：`docs/brainstorm/2026-09-25-features-brainstorm.md` §[E-8.5]（Issue #126／PR #127 review 留下的後續事項）
> 範圍：`lib/domain/entities/a2ui_fallback_strings.dart`、`lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart`、`lib/flow/menu_vision/bloc/menu_vision_bloc.dart` 及對應測試
> 狀態：草稿 v1（待確認）

---

## 1. 使用者故事

身為維護者，我希望：

1. AI 路徑**不再捕捉 `Error`**（flutter-styles §6.1）。目前 8 處 i18n fallback 用裸 `catch` 接住 `S.current` 未載入時丟出的 `AssertionError`（release 模式下 assert 被移除，會變成 `_current!` 的 null-check `TypeError`），兩者都是 `Error`。
2. 有測試**鎖住「`Error` 會往外拋出」**：之後若有人把 `on Exception catch` 改回裸 `catch`，測試會失敗。
3. Menu Vision 辨識或重試失敗時，**會留下帶 stack trace 的 log**，排查時不用再猜。

**前提**：使用者看到的畫面、文字與互動行為，要和現在完全一樣。

---

## 2. 背景（已求證的現況）

### 2.1 i18n fallback 為何存在、為何可以拿掉

| 事實 | 證據 |
|------|------|
| `S.current` 在 `_current == null` 時 debug 丟 `AssertionError`、release 丟 null-check `TypeError`，都是 `Error` | `lib/generated/l10n.dart:20-26` |
| 生產環境在 `runApp` 前就 `await S.load(PlatformDispatcher.instance.locale)`；`Future.wait` 預設 `eagerError: false`，即使 Firebase 初始化失敗也會等 `S.load` 完成 | `lib/main.dart:35-42` |
| `lib/` 其他 33 個檔、131 處直接讀 `S.current`，**完全沒有 fallback**。若 `S` 真的沒載入，App 早就在別處崩潰；這 8 處 fallback 沒有保護到任何生產情境 | `rtk proxy grep -rn "S\.current" lib`（排除 `generated/`） |
| fallback 真正保護的是**沒載入 `S` 的單元測試**：fallback 回傳 `[Err:...]` 字串，測試又拿同一個 getter 比對，所以一直是綠的 | 見 §2.2 |

結論：拿掉 catch 對生產環境零影響；會壞的只有測試。

### 2.2 移除 catch 後會壞的測試（實測）

在 repo 的暫存複本拿掉 8 處 catch 後跑 `flutter test`：**+242 −27**。27 個失敗全部是 `S.current` 的 `AssertionError`，分布在 5 個「沒有載入 `S`」的檔案：

| 檔案 | 失敗數 | 觸發路徑 |
|------|--------|----------|
| `test/domain/entities/a2ui_characterization_test.dart` | 16 | `A2UIComponent.fromJson` 降級分支（`_firstText` 的預設值參數是**立即求值**，只要走到降級就會讀 `S.current`，即使有 `text`） |
| `test/data_layer/ai_foodie_repo_test.dart` | 4 | `_parseResponse` → `A2UIComponent.fromJson` 降級 |
| `test/domain/entities/a2ui_component_test.dart` | 3 | 分派器降級 |
| `test/flow/ai_foodie/ai_foodie_model_test.dart` | 3 | `ComparisonMatrixModel`／`DecisionRouletteModel`／`ComparisonItemModel.fromEntity` 缺值預設 |
| `test/domain/entities/entity_nullability_test.dart` | 1 | 分派器降級 |

`ai_foodie_bloc_test.dart`、`menu_vision_bloc_test.dart`、兩個 view characterization test、`menu_vision_sheet_test.dart`、`decision_roulette_test.dart` **已經有載入 `S`**，不受影響。

### 2.3 BLoC 的例外處理現況

| 位置 | 現況 | 本次處理 |
|------|------|----------|
| `menu_vision_bloc.dart:64`、`:103` | `on Exception catch (e)`，沒綁 stack trace、沒 log | 改 `on Exception catch (e, st)` 並加 `Logger().e(...)`。**`on Exception` 必須保留**，否則變成吞 `Error` 的裸 catch |
| `ai_foodie_bloc.dart:44`、`:92` | `on Exception catch (e)`，沒 log | **不動**：`ai_foodie_repo.dart::askAssistant` 已在自己的 `on Exception catch (e, st)` 內 `Logger().e` 並降級為本地推薦（`:181-187`），`getInitialSuggestions` 是本地靜態資料。BLoC 再 log 一次只會重複 |

Menu Vision 不同：PR #127 起 `menu_vision_repo.dart` 完全不捕捉例外，BLoC 是唯一接住的地方，所以 log 要加在 BLoC。

---

## 3. 驗收條件

1. **零 `Error` 捕捉**：`lib/domain/entities/a2ui_fallback_strings.dart` 與 `lib/flow/ai_foodie/bloc/ai_foodie_bloc.dart` 不再有 `try`／`catch`；`lib/flow/menu_vision/bloc/menu_vision_bloc.dart` 的兩處都是 `on Exception catch (e, st)`。
2. **行為不變**：所有既有測試全綠，且既有測試檔的**斷言一條都不改**；`test/domain/entities/a2ui_characterization_test.dart`（檔頭標明「禁止修改」）零 diff。
3. **`Error` 外拋測試**：
   - `MenuVisionBloc`：repo 丟 `StateError` 時，只 emit `[MenuVisionLoading]`，錯誤經 `onError` 往外拋出，**不 emit `MenuVisionFailure`**。
   - `AiFoodieBloc`：repo 丟 `StateError` 時，只 emit 送出使用者訊息的 loading 狀態，錯誤往外拋出，**不設定 `errorMessage`**。
   - 兩個案例都要能抓到回歸：暫時把對應的 `on Exception catch` 改成裸 `catch` 時必須失敗（計畫已實測）。
4. **Menu Vision log**：兩處 `on Exception catch` 綁定 `st`，並呼叫 `Logger().e('<英文訊息>', error: e, stackTrace: st)`，寫法與 `ai_foodie_repo.dart` 一致；訊息為英文（flutter-styles §Y.4）。
5. **測試環境比照生產**：所有測試在執行前 `S` 已載入（和 `main()` 在 `runApp` 前載入的前提相同）。
6. `flutter analyze` 零 issue；不新增任何依賴。

---

## 4. 範圍邊界

### In scope
- 移除 8 處 i18n fallback 的裸 `catch`（`a2ui_fallback_strings.dart` 6 處、`ai_foodie_bloc.dart` 2 處）。
- 新增 `test/flutter_test_config.dart`，在所有測試前 `S.load`（理由與替代方案比較見計畫 §1）。
- `menu_vision_bloc.dart` 2 處補 stack trace 與 `Logger().e`。
- 兩個 BLoC 測試各補一個 `Error` 外拋案例（沿用既有手寫 fake repository，使用已安裝的 `bloc_test`）。

### Out of scope
- **不刪除 `A2UIFallbackStrings`**：拿掉 catch 後它只剩 `S.current.x` 的薄包裝，但 lib 有 2 個呼叫檔（8 處）、test 有 5 個檔引用（其中 `a2ui_characterization_test.dart`、`ai_foodie_view_characterization_test.dart`、`menu_vision_view_characterization_test.dart` 三個檔頭都標明禁止修改）；刪掉就必須改這些檔。保留 6 個一行 getter，diff 最小。
- 不在 `AiFoodieBloc` 加 Logger（repo 已經 log，見 §2.3）。
- 不改任何 i18n key、ARB 檔、畫面文字。
- 不引入 `mocktail`／`mockito`，不重構既有 fake repository。
- 不處理 `lib/` 其他檔案的 `S.current`，也不改 `main.dart` 的初始化流程。
- **同樣模式、backlog 沒列到的 3 處 i18n fallback 裸 `catch (_)`**：`lib/domain/entities/dish_item_entity.dart:41`（`DishCategory` 顯示名稱）、`lib/domain/entities/allergen_info.dart:30`（`AllergenRiskLevel` 顯示名稱）、`lib/domain/entities/restaurant_business_time_entity.dart:47`（星期名稱）。T1 之後拿掉它們一樣安全，但不在 backlog 範圍內，待確認是否一併納入（見計畫 §7-6）。另 `lib/flow/main/view/map_widget.dart:161` 的裸 `catch (e)` 與 AI 路徑無關。

---

## 5. 風險

| 風險 | 影響 | 緩解 |
|------|------|------|
| `flutter_test_config.dart` 把 `Intl.defaultLocale` 全域設為 `zh_TW`，改到依賴預設 locale 的測試 | 日期／數字格式相關測試改變 | 已在暫存複本實測：加入後全套 271 個測試全綠。需要其他 locale 的測試本來就在自己的 `setUp` 裡 `S.load`，會覆蓋全域設定 |
| 日後有人新增「沒有 `S`」的純 Dart 測試並用 `dart test` 執行 | `flutter_test_config.dart` 只有 `flutter test` 會讀 | `Makefile:101` 與 `.github/workflows/pr-check.yml:46` 都用 `flutter test` |
| `catch (e, st)` 誤寫成沒有 `on Exception` | 開始吞 `Error`，違反 §6.1 | 驗收條件 3 的 `Error` 外拋測試會直接失敗 |
