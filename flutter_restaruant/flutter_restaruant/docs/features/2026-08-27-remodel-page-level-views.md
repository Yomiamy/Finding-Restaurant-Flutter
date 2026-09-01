# S3 — 頁面級視覺重塑 (登入頁 / 餐廳詳情頁 / 列表頁) 功能規格

> **文件狀態**：STAGE 0a 功能規格 (What & Why)  
> **依據文件**：`docs/brainstorm/2026-08-26-features-brainstorm.md` §6.6 & §6.7  
> **撰寫日期**：2026-08-27  

---

## 1. 背景與目標 (Background & Objectives)

在完成 S1（Design System 地基）與 S2（共用元件重塑）之後，應用程式已具備統一的 `ThemeData`、`ColorScheme`、`ThemeSize` 與重塑後的 `RestaurantItemCell` 及 `EmptyDataWidget`。

本階段（S3）為**頁面級視覺重塑**，全面覆蓋使用者互動最頻繁的三大核心畫面：
1. **登入頁 (`SignInPage`)**：修正品牌色衝突（移除硬編碼藍）、建立清晰的動作視覺階層、優化輸入框裝飾與小螢幕鍵盤彈出佈局。
2. **餐廳詳情頁 (`RestaurantDetailPage` & 5 個子 Cells)**：修正頂部頭圖變形與死圖撐爆、以 Material Icon 取代最愛 PNG 圖片、修正營業狀態紅底語意錯誤、電話點擊區域與顏色優化、地圖縮圖圓角化與區塊層級分明。
3. **餐廳列表頁 (`MainPage`)**：將頁面級容器（如 AppBar、Drawer）的文字與圖示顏色統一改為 `ThemeColor.colorffffff`。

---

## 2. 使用者故事與價值 (User Stories)

1. **作為初次使用的使用者**，我在登入頁看到與品牌一致的橘紅主按鈕、清晰的第三方登入與顯著的「訪客模式」入口，且在任何尺寸的手機上表單都不會被擠壓或溢出。
2. **作為探索美食的使用者**，我進入餐廳詳情頁時能看到高質感、不變形的餐廳封面圖，直覺的收藏圖示、清楚區分的營業狀態（營業中顯示醒目綠色而非紅色），並能輕鬆點擊電話或靜態地圖導航。
3. **作為常規瀏覽的使用者**，我在列表頁獲得整齊一致的間距與卡片排版體驗。

---

## 3. 範圍邊界 (Scope)

### ✅ 納入範圍 (In Scope)
* **登入頁 (`lib/flow/signinup/view/sign_in_page.dart`)**：
  - 移除硬編碼藍 `Color.fromARGB(255, 5, 97, 245)`，改由 `Theme.of(context).colorScheme.primary` 派生。
  - 建立三層動作階級：主操作（Email 登入，Filled/Elevated）、次操作（Google/Apple，標準 3rd-party 按鈕）、輔助操作（註冊與訪客模式，具備清晰層級與可見度）。
  - 輸入框整合 Material 3 `InputDecoration`（`filled: true`、`prefixIcon`、`OutlineInputBorder`）。
  - 佈局重構：以 `SingleChildScrollView` 與彈性約束取代 `Expanded(flex: 1)` 平分，避免鍵盤彈出時產生 RenderFlex overflow。
* **餐廳詳情頁 (`lib/flow/restaurant/view/`)**：
  - `RestaurantHeadCell`：圖片 `BoxFit.cover`；移除 `images/ic_favor_fill.png` 與 `images/ic_favor_empty.png`，改用 Flutter 向量 `Icons.favorite` / `Icons.favorite_border`。
  - `RestaurantInfoCell`：靜態地圖 `BoxFit.cover` + `ClipRRect(radius8)`；修正營業狀態（`isOpen` 為 true 顯示綠色系，false 顯示 `outline` 灰色/紅色）；電話改用 `colorScheme.primary` 並標示電話 icon；分類分隔改用 ` · `。
  - `RestaurantCommentCell` & `RestaurantBusinessHourCell`：文字樣式與間距對齊 Token，圖片與排版對齊 M3。
* **餐廳列表頁 (`lib/flow/main/view/`)**：
  - `MainPage`：間距與 padding 全量對齊 `ThemeSize`。

### ❌ 明確排除 (Out of Scope)
* 篩選頁重構、Splash 頁、清理未使用的廢棄常數（留在 S4 收尾階段）。
* 引入新的第三方套件或重構 BLoC 業務邏輯（保持純 UI/Presentation 層改造）。
* 深色模式切換（維持既有純 Light Token 規範）。

---

## 4. 驗收條件 (Acceptance Criteria)

1. **視覺與樣式規範**：
   - 登入頁主按鈕為品牌橘紅色，不再有任何硬編碼藍。
   - 詳情頁營業中標籤正確顯示綠色語意色，已打烊顯示灰/深色。
   - 移除 2 張收藏 PNG 圖檔，詳情頁收藏按鈕使用向量圖示並正常響應狀態切換與 Toast。
2. **小螢幕與防破版**：
   - 登入頁在 320pt~375pt 寬度螢幕與虛擬鍵盤彈出時零溢出（RenderFlex overflow 0 次）。
   - 詳情頁在無圖片（404/錯誤網址）時佔位圖保持固定比例，不影響收藏按鈕位置。
3. **品質與測試**：
   - `flutter analyze` 維持 `No issues found!` 零警告。
   - `dart format` 通過。
   - 全量測試（Unit + Widget tests）100% 全綠通過，並補齊詳情頁與登入頁的 UI 測試。
