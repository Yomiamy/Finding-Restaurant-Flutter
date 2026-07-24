# Implementation Plan: Fix `build()` Side-effects Anti-pattern

## 1. 架構變更與實作策略 (How)
目前的 6 個核心頁面在 `build()` 中觸發了初始資料加載 (例如發送 `Fetch...Info` 事件) 或路由導覽。這違反了 UI 渲染應該是 pure function 的原則。
解法為：
- **方案 A (依生命週期初始化)**：對於需要立刻載入或具備所有參數的頁面，在 `initState()` 內觸發初始 `Bloc.add(...)`；若需依賴路由參數 (如 `RestaurantDetailPage`)，則使用 `didChangeDependencies()` 配合旗標來發送初始事件。
- **方案 B (可選：Provider 初始化)**：當所有必要參數皆能在 BLoC 創建當下取得時，才可選擇將事件放入 `BlocProvider(create: (context) => MyBloc()..add(MyEvent()))` 中。
- **方案 C (監聽副作用)**：針對導航或 Toast (如 SplashPage 的跳轉、RestaurantDetailPage 的 Favor Toast)，盡量以 `BlocListener` / `BlocConsumer` 的 `listener` 來反應狀態變更，絕不在 `build()` 直接呼叫 `Navigator.push` 或彈出 Toast。

## 2. 檔案異動清單 (Files to Change)
1. `lib/flow/signinup/view/sign_in_page.dart`
   - **修改**：移除 `build()` 中的 `AutoSignInEvent`，改為在注入 BLoC 或 `initState` 中觸發。
2. `lib/flow/main/view/main_page.dart`
   - **修改**：移除 `BlocBuilder` 中的 `FetchSearchInfo` 觸發，改至上層 Provider 或 `initState` 載入預設資料。
3. `lib/flow/restaurant/view/restaurant_detail_page.dart`
   - **修改**：
     1. 移除 `build()` 初始資料請求 `FetchDetailInfo`。
     2. 移除 `build()` 中的 `Toast` 顯示與強制重查。改用 `BlocListener` 來聽取 `ToggleFavorSuccess` 狀態並顯示 Toast。
4. `lib/flow/favor/view/favor_page.dart`
   - **修改**：將 `FetchFavorInfoEvent` 的觸發從 `build()` 移至 `initState` 或 `BlocProvider` 中。
5. `lib/flow/settings/view/settings_page.dart`
   - **修改**：將 `InitBioAuthSettingEvent` 移至正確的初始化生命週期。
6. `lib/flow/splash/view/splash_page.dart`
   - **修改**：將 `Future.delayed` 與 `Navigator.pushReplacementNamed` 完全移出 `build()`，放入 `initState` 的 `WidgetsBinding.instance.addPostFrameCallback` 中執行。

## 3. 任務拆分 (Tasks)
- **Task 1**: 修復 SignInPage、SplashPage 導航與生命週期側邊效應。
- **Task 2**: 修復 MainPage、FavorPage 的初始 API 請求 (Fetch Info) 側邊效應。
- **Task 3**: 修復 RestaurantDetailPage (API + Toast BlocListener 重構) 與 SettingsPage。
