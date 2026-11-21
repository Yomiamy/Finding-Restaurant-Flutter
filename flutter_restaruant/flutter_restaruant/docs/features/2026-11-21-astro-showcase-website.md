# 功能規格：Find Restaurant Astro 雙語靜態產品官網

- **日期**：2026-11-21
- **狀態**：草稿（STAGE 0a）
- **實查基線**：`main`（`843aaecc`）
- **需求來源**：使用者需求（已通過 `gen-grill` 兩輪盤問與確認）

---

## 1. 背景與問題

### 1.1 現況（`main` 基線與 repo 根目錄實查）

1. **產品與架構能力已完備，但缺乏獨立對外官網**：
   - 本專案（GitHub：`https://github.com/Yomiamy/Finding-Restaurant-Flutter`）於 `main` 基線版本為 `2.4.0+40`，採用 Clean Architecture + BLoC（`flutter_bloc ^9.1.1`）+ GetIt（`^8.0.0`）+ Firebase AI（`firebase_ai ^4.0.0`，Gemini）+ Yelp Fusion API + Cloud Firestore（`favors` / `ugc_notes` subcollection）。
   - App 已具備定位與多維餐廳探索、AI 智能覓食助理（GenUI / A2UI）、命運大轉盤、AI 菜單視覺翻譯與過敏原分析、UGC 探店筆記與跨平台支援（Android / iOS / macOS 14+，含 Developer ID 簽章、公證與 DMG 手動打包流程 [`scripts/release_macos.sh`](../../scripts/release_macos.sh) 及 [`docs/manuals/macos-release-guide.md`](../manuals/macos-release-guide.md)）。
   - 然而，外部開源開發者、技術審閱者或潛在體驗者目前只能直接閱讀 GitHub `README.md` / `README-tw.md`，缺少一個輕量、高質感、可對外展示產品功能與工程設計脈絡的雙語產品官網。
2. **Firebase Hosting 與現有設定現況**：
   - 現有 Firebase 專案為 `findrestaurant-c80ea`（參見 [`lib/app/firebase_options.dart`](../../lib/app/firebase_options.dart)），實查 `firebase hosting:sites:list --project findrestaurant-c80ea` 已存在預設 Hosting Site `findrestaurant-c80ea`（Default URL：`https://findrestaurant-c80ea.web.app`），計費維持 **Spark 免費方案**（每日下載頻寬上限約 360 MB）。
   - [`flutter_restaruant/flutter_restaruant/firebase.json`](../../firebase.json) 僅存放 FlutterFire 平台設定（`android`、`ios`、`macos` 與 `dart`），目前沒有 `hosting` 區段。
3. **視覺素材、品牌色票與發布現況**：
   - 專案主品牌色票定義於 [`lib/features/foundation/style/theme_color.dart`](../../lib/features/foundation/style/theme_color.dart)：主品牌橘 `ThemeColor.colord84a20`（`#D84A20`）、奶油白主背景 `ThemeColor.colorfffbf7`（`#FFFBF7`）。
   - repo 根目錄 `doc/screenshots/` 既有 6 張實測 PNG 截圖（合計約 4.5 MB）：
     - `Screenshot_home.png`（1.13 MB — 首頁餐廳探索）
     - `Screenshot_ai_assistant_recommand.png`（335 KB — AI 智能覓食助理 GenUI）
     - `Screenshot_roulette.png`（318 KB — 命運大轉盤）
     - `Screenshot_menu_vision.png`（315 KB — AI 菜單視覺翻譯與過敏原分析）
     - `Screenshot_navigation.png`（1.41 MB — 餐廳詳情、地圖導航與街景）
     - `Screenshot_login.png`（983 KB — 多元登入、生物辨識與訪客模式）
   - 實查 `gh release list --limit 5` 回傳 `no releases found`，目前尚無任何公開 GitHub Release 安裝檔。
4. **本機建置與工具環境實查**：
   - 本機已備妥 `node v26.5.0`、`npm 11.17.0`、`/opt/homebrew/bin/ffmpeg`（可將 PNG 轉為 `.webp`）與 `/opt/homebrew/bin/firebase` CLI。

### 1.2 為什麼需要獨立 Astro 靜態官網（而非 Flutter Web）

1. **展示型官網與應用程式的本質不同**：
   - 產品介紹頁的核心訴求是首屏秒開、完整的搜尋引擎索引（SEO）與社群分享卡片（Open Graph / Twitter Card），以及雙語工程敘事。使用 `flutter build web` 承載純展示頁會強制訪客下載並啟動整個渲染引擎，首屏沉重且對靜態爬蟲與無障礙語意支持度較差。
2. **避開 Flutter Web 的架構與計費硬性前置**：
   - 依據 [`docs/brainstorm/2026-11-21-features-brainstorm.md`](../brainstorm/2026-11-21-features-brainstorm.md) 第 9 章實查結論，Yelp Fusion API 不支援瀏覽器端 CORS，Flutter Web 版本必須以 P0「Server-side Broker（Cloud Functions）」並將 Firebase 由 Spark 升級為 Blaze 方案作為硬性前置。以 Astro 靜態網站獨立承載產品官網，可完全避開 CORS、API 金鑰暴露與計費升級限制。
3. **保護 Spark 方案每日 360 MB 頻寬上限**：
   - 若直接把總重約 4.5 MB 的 6 張未壓縮 PNG 放上 Spark Hosting，僅數十次完整載入或爬蟲抓取就會觸及每日 360 MB 免費額度上限。因此必須將展示圖資壓縮為 WebP 並搭配長效 `Cache-Control` 策略，確保極低單次頁面傳輸量。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**

- **資料結構與職責隔離**：產品官網的本質是「靜態雙語內容與實測圖資的純展示投影」，與 Flutter App 執行期狀態毫無耦合。將官網置於 repo 根目錄獨立的 `website/`（與 `flutter_restaruant/` 平級），可使依賴樹（npm vs pub）、建置工具（Astro vs Flutter）、Firebase Hosting 設定與 CI 觸發邊界完全正交。
- **消滅特殊情況**：
  - 全站靜態輸出 `/`（英文）與 `/zh-tw/`（繁體中文）兩套確定性 HTML，不依賴客戶端路由猜測語系或重導補丁。
  - Scrollytelling 功能鏡頭嚴格與 `doc/screenshots/` 既有 6 張實測截圖（轉檔為 WebP）一對一對應，不為尚無截圖的功能捏造佔位圖檔或偽路徑。
  - 因應目前無 GitHub Release，平台切換面板採「開源原始碼與建置指令導向」的誠實 CTA，消除「點下載卻 404」或「在 Spark Hosting 偷放二進位檔」的違規風險。
- **複雜度控制**：以 Astro 靜態單頁架構搭配原生 CSS、輕量原生 2D `<canvas>` 動畫與最小化無障礙互動腳本，不引入多餘前端狀態管理框架或重型動效依賴，對標 `https://syrtis.nyanako.com/` 的極簡質感與頁面節奏。
- **零破壞（Never break userspace）**：完全不更動 `flutter_restaruant/flutter_restaruant/` 內任何 Dart 程式碼、`pubspec.yaml`、測試檔案或 FlutterFire 的 `firebase.json`，現有 Android / iOS / macOS 開發與 PR CI 零影響。

---

## 2. 需求 Brief（gen-grill 產出）

- **Q1 問題定義**：Find Restaurant 已具備定位探索、AI 智能覓食助理（GenUI/A2UI）、命運大轉盤、AI 菜單視覺翻譯、UGC 探店筆記與跨平台支援（Android / iOS / macOS 14+），但缺少如 `https://syrtis.nyanako.com/` 般輕量、高質感、對外介紹能力與工程架構的雙語（英文／繁體中文）靜態官網；且不適合用 `flutter build web` 承載展示型官網。
- **Q2 觸發場景**：訪客（開源開發者、技術審閱者、潛在體驗者）透過瀏覽器開啟 `https://findrestaurant-c80ea.web.app`（或本地預覽），可切換英文 `/` 與繁中 `/zh-tw/`、在 Hero 區體驗輕量 2D `<canvas>` 互動視覺、透過滾動與點擊瀏覽 Scrollytelling 功能鏡頭（Lenses）、閱讀工程架構／隱私與 API 安全設計原則，並於平台面板切換 Mobile（iOS / Android）與 macOS Desktop 查看環境要求、複製原始碼取得與建置指令。
- **Q3 成功標準 (AC)**：
  1. **AC-1（獨立目錄與零侵入）**：於 repo 根目錄建立獨立 `website/` Astro 靜態網站專案（與 `flutter_restaruant/` 平級），配置 `.gitignore`（忽略 `node_modules/`、`dist/`、`.astro/`、`.firebase/`），完全不修改 `flutter_restaruant/flutter_restaruant/` 既有 App 程式碼、`pubspec.yaml` 或 FlutterFire 的 `firebase.json`。
  2. **AC-2（雙語路由、SEO/OG 與品牌視覺對齊）**：提供 `/`（英文）與 `/zh-tw/`（繁中）完整頁面，包含 `canonical`、`hreflang`（`en`、`zh-Hant-TW`、`x-default`）、Open Graph / Twitter Card、`SoftwareApplication` JSON-LD、淺／深色系統配色（融合 `#D84A20` 與 `#FFFBF7`），以及具備 `IntersectionObserver` 離屏暫停與 `prefers-reduced-motion: reduce` 降級保護的 Hero 輕量 2D `<canvas>` 動畫。
  3. **AC-3（Scrollytelling 功能展示區與 WebP 圖資輕量化）**：建置對標 `syrtis.nyanako.com` 的 `.scrolly` 功能鏡頭展示區（寬螢幕滾動同步 + 點擊／鍵盤方向鍵切換，嚴格具備 `role="tablist"`、`role="tab"`、`role="tabpanel"`、`aria-selected`、`aria-hidden`），並將 `doc/screenshots/` 既有 6 張 PNG 轉為 WebP 壓縮置於 `website/public/screenshots/`，不得偽造尚未拍攝的圖片檔。
  4. **AC-4（Mobile / macOS 平台切換與誠實 CTA）**：平台切換面板支援 Mobile（iOS / Android）與 macOS Desktop（Apple Silicon / macOS 14+，含 Developer ID DMG 分發說明），以 `localStorage` 記憶選擇與系統偵測預設值，內建一鍵 Copy CLI 指令按鈕與 `aria-live="polite"` 提示；CTA 誠實導向 GitHub Repo、文件與預留 Releases 入口，嚴禁偽造無效安裝檔連結或託管二進位檔。
  5. **AC-5（Firebase Hosting 配置與專屬 CI 工作流）**：於 `website/` 建立獨立 `.firebaserc`（指向 `findrestaurant-c80ea`）與 `firebase.json`（僅含 `hosting`、`public: "dist"`、`/_astro/*` 與 `/screenshots/*` Cache-Control 及 `ignore` 規則）；於 repo 根目錄 `.github/workflows/` 新增僅限 `website/**` 變動觸發的官網專屬 CI/CD 工作流。
  6. **AC-6（建置與自動化檢查全過）**：`npm run build` 0 error，附自動化靜態驗證腳本／測試確認 HTML、Metadata、圖資與站內連結（無 404）、尺寸控管全數通過；本次開發流程不對外執行實機 `firebase deploy --only hosting` 推上線。
- **Q4 範圍邊界 (Out of Scope)**：不啟用 Flutter Web；不在 Firebase Hosting 託管 `.apk`/`.ipa`/`.dmg`/`.exe` 二進位檔；不升級 Firebase Spark 計費方案；不直接推線上部署（停在 PR）；不捏造尚未截圖的畫面檔案；嚴禁改動 `flutter_restaruant/flutter_restaruant/` 內任何程式碼、設定或測試。
- **Q5 參考標竿結構實查**：對標 `https://syrtis.nyanako.com/` 之 Astro 靜態單頁結構（`/_astro/*.css`、雙語路由、頂部 `header.bar` 導覽列、`hero` 搭配 2D `<canvas>` + `os-switch` + copy 面板、`.strata` 分段標尺含 `stratum` 與 `.ruler` depth、`.scrolly` 滾動圖文瀏覽與 `footer` 版權／原始碼連結）。

---

## 3. 使用者故事與功能要求

### 3.1 使用者故事

1. **雙語瀏覽與視覺識別（US-1）**：身為來自台灣或國際的**開源開發者與技術審閱者**，我希望開啟 `https://findrestaurant-c80ea.web.app` 時能直接閱讀清晰流暢的英文首頁（`/`），或一鍵切換至繁體中文版（`/zh-tw/`），並感受到貼合 Find Restaurant 品牌色系（暖橘 `#D84A20` 與奶油白 `#FFFBF7`）與系統淺／深色模式的高質感介面，同時在社群轉貼連結時能正確顯示預覽卡片（OG / Twitter Card）。
2. **動態感與無障礙安全體驗（US-2）**：身為**網頁訪客（含開啟減少動態設定的使用者）**，我希望 Hero 區的輕量 2D `<canvas>` 視覺能呼應「城市美食雷達與座標探點」主題；當我向下捲動離開視窗時動畫自動暫停以節省電量，且若系統已啟用 `prefers-reduced-motion: reduce`，畫面會優雅降級為靜態呈現而不產生暈眩。
3. **互動式探索核心功能（US-3）**：身為**潛在體驗者**，我希望在 Scrollytelling 功能鏡頭區透過頁面滾動、滑鼠點擊或鍵盤方向鍵依序切換瀏覽 6 項實機畫面（首頁探索、AI 智能覓食助理 GenUI、命運大轉盤、AI 菜單視覺翻譯、餐廳詳情與導航、多元登入），並在螢幕閱讀器下仍具備清楚的 Tab / Tabpanel 焦點語意。
4. **檢視工程架構與設計權衡（US-4）**：身為**技術審閱者**，我希望透過分段式工程脈絡章節（對標 `.strata` / `.ruler` 深度標尺節奏），了解專案如何以 Clean Architecture + BLoC 組織狀態、以 Remote Config 與能力閘門保護跨平台與金鑰治理、以 Gemini 驅動多模態菜單翻譯與 GenUI，以及近期演進的 UGC 探店筆記與進階搜尋篩選能力。
5. **切換目標平台與取得原始碼（US-5）**：身為**想在本機編譯或評估支援平台的開發者**，我希望在平台面板切換 **Mobile（iOS / Android）** 與 **macOS Desktop（Apple Silicon / macOS 14+）**，讓頁面記住我的選擇、一鍵複製取得原始碼與建置指令，並透過明確的 GitHub Repo、文件與預留 Releases 連結誠實取得專案資訊（不碰上假下載或無效檔案連結）。

### 3.2 頁面資訊架構與雙語視覺規範

官網採用對標 `https://syrtis.nyanako.com/` 的單頁節奏設計，雙語頁面於資訊架構與互動行為上完全對等：

1. **雙語路由契約**：
   - `/`：預設英文版（`lang="en"`）。
   - `/zh-tw/`：繁體中文版（`lang="zh-Hant-TW"`）。
   - 兩語系頁面之頂部導覽列（`header.bar`）皆提供明確的語系切換連結，可直接在英文與繁體中文版本間雙向跳轉，並保留頁面錨點導覽。
2. **SEO、Metadata 與結構化資料契約**：
   - 基準網址（Base URL）定為 `https://findrestaurant-c80ea.web.app`。
   - 每一語系頁面必須輸出正確的 `<link rel="canonical">` 與完整 `<link rel="alternate" hreflang="...">`（包含 `en`、`zh-Hant-TW`、`x-default`）。
   - 必須具備完整 Open Graph（`og:title`、`og:description`、`og:type`、`og:url`、`og:image`、`og:locale`）與 Twitter Card metadata，且 `og:image` 指向真實存在於靜態輸出中的圖片資產。
   - 必須內嵌合法 JSON-LD（`@type: "SoftwareApplication"`），如實描述 Find Restaurant 的名稱、版本（`2.4.0+40`）、支援作業系統（Android、iOS、macOS 14+）、原始碼庫 URL 與開源定位。
3. **品牌視覺系統與淺／深色配色**：
   - 融合本專案既有色票 `ThemeColor.colord84a20`（`#D84A20` 主品牌橘）與 `ThemeColor.colorfffbf7`（`#FFFBF7` 奶油白背景），建立具溫度的飲食探索品牌辨識度。
   - 透過 CSS 系統配色媒體查詢（`prefers-color-scheme: light / dark`）提供一致且具足夠文字對比度的淺色與深色模式。
4. **Hero 區與輕量 2D `<canvas>` 互動視覺**：
   - Hero 區結合專案定位敘事、平台切換與一鍵複製面板，並於背景／主視覺承載原生 2D `<canvas>` 動態畫面，視覺隱喻呼應「美食探點／探索雷達／座標聚散」。
   - **資源與無障礙保護**：
     - 必須使用 `IntersectionObserver` 偵測 `<canvas>` 是否位於可視範圍內，離開視窗後立即暫停渲染迴圈，回到視窗再恢復。
     - 當使用者系統設定 `prefers-reduced-motion: reduce` 時，不得持續運行高頻動態繪製，應維持靜態構圖或初始一幀安全呈現。
5. **工程敘事分段（`.strata` + `.ruler` 深度標尺）與頁尾（`footer`）**：
   - 透過具層次標尺感（`stratum` + `.ruler`）的敘事區塊呈現專案工程核心：
     - **核心能力與技術棧**：Clean Architecture + BLoC (`flutter_bloc`) + GetIt 依賴注入、Yelp Fusion API 即時探索與進階篩選、UGC 探店筆記（雙排瀑布流與 15 秒短影片）。
     - **AI 與多模態體驗**：Firebase AI Logic（Gemini）驅動之 GenUI 對話式決策畫布（對比矩陣、命運大轉盤）與 Menu Vision 菜單視覺翻譯／過敏原拆解。
     - **架構治理、跨平台與安全原則**：平台能力閘門（`platformCapabilities` 隔離 Android / iOS / macOS 差異）、Remote Config 動態模型與參數治理、API 安全演進原則（含不直接由瀏覽器端直連 Yelp 造成金鑰暴露與 CORS 衝突的架構誠實說明）。
   - `footer` 必須包含專案版權／開源說明、GitHub 原始碼庫連結、相關文件入口與雙語切換。

### 3.3 Scrollytelling 鏡頭與實測圖資對應契約

功能鏡頭展示區（`.scrolly`）必須嚴格遵守「真實圖資一對一映射」與「完整無障礙互動」原則：

1. **WebP 輕量化轉換**：
   - 來源為 repo 根目錄 `doc/screenshots/` 既有 6 張實測截圖 PNG（原總計約 4.5 MB），須轉換為壓縮 `.webp` 置於 `website/public/screenshots/`，大幅壓低總體傳輸大小以符合 Spark 每日 360 MB 上限。
2. **6 大鏡頭與圖片檔嚴格對應表**（不得新增尚未拍攝之圖片路徑）：

| 鏡頭順序 | 功能主題 | 來源實測截圖（`doc/screenshots/`） | 展示重點（雙語敘事） |
| :--- | :--- | :--- | :--- |
| Lens 01 | 首頁餐廳探索 | `Screenshot_home.png` | 定位與關鍵字即時搜尋、評分與距離卡片流、動態篩選連動 |
| Lens 02 | AI 智能覓食助理（GenUI） | `Screenshot_ai_assistant_recommand.png` | 自然語言需求對話、A2UI 結構化推薦卡片與決策畫布 |
| Lens 03 | 命運大轉盤 | `Screenshot_roulette.png` | 自繪轉盤動畫收斂候選餐廳，解決聚餐選擇困難 |
| Lens 04 | AI 菜單視覺翻譯 | `Screenshot_menu_vision.png` | 多模態辨識外文菜單、翻譯菜名並自動標註食材過敏原 |
| Lens 05 | 餐廳詳情、地圖與街景 | `Screenshot_navigation.png` | 營業資訊、地圖導航／街景入口與收藏操作 |
| Lens 06 | 多元登入與訪客模式 | `Screenshot_login.png` | Google / Apple / Email 登入、生物辨識與低門檻訪客體驗 |

   > 註：近期完成但尚無截圖的 UGC 探店筆記（`Notes`）與進階篩選（`Filter`）不硬湊假圖檔，於工程敘事章節中如實說明即可，待後續補拍實測截圖後再擴充鏡頭。

3. **雙模互動與 WAI-ARIA 無障礙契約**：
   - 寬螢幕下隨頁面滾動位置自動同步高亮對應鏡頭；同時在所有視口尺寸支援使用者主動點擊鏡頭切換，以及於 Tab 清單聚焦時以鍵盤方向鍵（上／下或左／右）切換。
   - DOM 語意必須嚴格具備 `role="tablist"`、`role="tab"`、`role="tabpanel"`、`aria-selected` 與 `aria-hidden`（並正確配對 `aria-controls` / `aria-labelledby`），確保輔助科技能準確識別目前啟用與隱藏的鏡頭面板。

### 3.4 平台切換面板與誠實開源 CTA 規格

1. **雙平台切換（`os-switch`）**：
   - 支援 **Mobile（iOS / Android）** 與 **macOS Desktop（Apple Silicon / macOS 14+）** 兩種視圖。
   - **預設與記憶行為**：初次造訪依瀏覽器／作業系統環境偵測決定預設視圖（macOS 桌面環境預設顯示 macOS Desktop，其餘預設顯示 Mobile），使用者手動切換後寫入 `localStorage` 持久化記憶。
   - **內容覆蓋**：
     - **Mobile 視圖**：呈現 iOS / Android 支援說明、Google Maps / AdMob / FCM / 相機拍照完整原生體驗、取得原始碼與執行建置指令（`git clone` / `flutter pub get` / `flutter run`）。
     - **macOS Desktop 視圖**：呈現 macOS 14+（Apple Silicon / 原生桌面視窗）環境需求、平台能力差異說明（Static Maps + 外部地圖導航、無 AdMob 與無相機選圖降級）、Developer ID 簽章與 Apple 公證（Notarization）DMG 手動發布流程說明，以及對應建置／發布指令。
2. **一鍵 Copy 與無障礙提示**：
   - 每個平台視圖提供可直接複製的 CLI 指令面板與 Copy 按鈕。
   - 點擊 Copy 後將當前顯示平台的 CLI 指令寫入剪貼簿（含不支援 Clipboard API 時的安全降級提示），並在綁定 `aria-live="polite"` 的狀態區回報「已複製／Copied」回饋。
3. **誠實 CTA 原則（Zero Fake Downloads）**：
   - 由於實查確認目前 `gh release list --limit 5` 無任何公開 Release，頁面不得出現假的 `.dmg` / `.apk` / `.ipa` 下載按鈕或虛構檔名，亦不得在 Firebase Hosting 託管二進位安裝檔。
   - 主要行動呼籲（CTA）應清楚引導訪客前往：
     - GitHub 專案主頁（`https://github.com/Yomiamy/Finding-Restaurant-Flutter`）檢視完整原始碼。
     - 專案 `README.md` / `README-tw.md` 與 macOS 發布手冊了解建置與環境設定。
     - 預留 GitHub Releases 入口連結（`https://github.com/Yomiamy/Finding-Restaurant-Flutter/releases`），供日後正式發布版本時無縫承接。

### 3.5 託管與 CI 工作流規格

1. **獨立 Firebase Hosting 配置（位於 `website/`）**：
   - `website/.firebaserc`：綁定預設專案為 `findrestaurant-c80ea`。
   - `website/firebase.json`：僅包含 `hosting` 區段（不影響 Flutter App 根目錄的任何原生設定），設定 `public: "dist"`，明確配置 `ignore` 排除原始碼與 `node_modules/` 等非產物；針對 `/_astro/*` 與 `/screenshots/*` 設定長期瀏覽器快取標頭（`Cache-Control`），最大化減少 Spark 每日重複下載流量。
2. **專屬 GitHub Actions 工作流（位於 repo 根目錄 `.github/workflows/`）**：
   - 觸發路徑嚴格限定於 `website/**`（及該 workflow 檔案自身）的變動，確保修改 Flutter App 時不會誤跑官網流程，修改官網時亦不觸發額外雜訊。
   - 工作流須包含：安裝官網依賴、執行 `npm run build` 與自動化靜態驗證檢查；於 PR 時支援預覽建置驗證、於 `main` 分支提供 Firebase Hosting 部署步驟，並在尚未設定對應 Firebase 部署密鑰時給出明確設定步驟說明，不誤影響 Flutter App 主線 CI。
   - **執行邊界**：本任務完成開發與 PR 審查時，**不執行**實機 `firebase deploy --only hosting` 將內容推上線上網域。

---

## 4. 驗收條件 (Acceptance Criteria)

- **AC-1（獨立目錄與零侵入）**：
  - Repo 根目錄建立獨立 `website/` Astro 靜態專案（與 `flutter_restaruant/` 平級），附 `.gitignore` 忽略 `node_modules/`、`dist/`、`.astro/`、`.firebase/`。
  - 檢查 diff 確認 `flutter_restaruant/flutter_restaruant/` 內所有程式碼、`pubspec.yaml`、測試檔與 [`flutter_restaruant/flutter_restaruant/firebase.json`](../../firebase.json) 零變動。
- **AC-2（雙語路由、SEO/OG 與品牌視覺系統）**：
  - 產出完整英文版 `/`（`lang="en"`）與繁體中文版 `/zh-tw/`（`lang="zh-Hant-TW"`），並支援雙向語系切換。
  - 兩語系頁面皆具備正確 `canonical`、`hreflang`（`en`、`zh-Hant-TW`、`x-default`）、Open Graph / Twitter Card metadata 及合法 `SoftwareApplication` JSON-LD。
  - 設計系統融入 `#D84A20` 與 `#FFFBF7` 品牌識別並支援淺／深色系統配色；Hero 區含具主題辨識度的輕量 2D `<canvas>`，具備 `IntersectionObserver` 離屏暫停與 `prefers-reduced-motion: reduce` 降級保護。
- **AC-3（Scrollytelling 鏡頭與 WebP 圖資輕量化）**：
  - `.scrolly` 功能展示區支援滾動同步（寬螢幕）、滑鼠點擊與鍵盤方向鍵切換，且無障礙屬性 `role="tablist"`、`role="tab"`、`role="tabpanel"`、`aria-selected`、`aria-hidden` 齊備並隨切換正確更新。
  - `doc/screenshots/` 既有 6 張 PNG 轉為 WebP 壓縮置於 `website/public/screenshots/`，頁面僅引用真實存在的 6 張 WebP 圖資（總大小相較原始 4.5 MB PNG 大幅縮減），無任何偽造圖片路徑。
- **AC-4（Mobile / macOS 平台切換與誠實 CTA）**：
  - 平台切換面板支援 Mobile（iOS / Android）與 macOS Desktop（Apple Silicon / macOS 14+，含 Developer ID DMG 分發說明），依環境偵測預設並以 `localStorage` 記憶選擇。
  - 一鍵 Copy 按鈕可複製對應平台 CLI 指令並透過 `aria-live="polite"` 呈現提示。
  - 所有 CTA 誠實導向 GitHub Repo、文件與預留 Releases 頁面，不含無效 `.dmg`/`.apk` 假下載連結，亦無二進位安裝檔置於 Hosting 產物中。
- **AC-5（Firebase Hosting 與專屬 CI 工作流）**：
  - `website/.firebaserc` 指向 `findrestaurant-c80ea`；`website/firebase.json` 僅含 `hosting`（`public: "dist"`、`/_astro/*` 與 `/screenshots/*` Cache-Control、`ignore`）。
  - `.github/workflows/` 新增僅限 `website/**` 變動觸發之官網 CI/CD 工作流，涵蓋依賴安裝、建置、靜態檢查與密鑰未設時的明確部署指引。
- **AC-6（靜態建置與自動化品質驗證全過）**：
  - `npm run build` 通過且 0 error。
  - 自動化靜態檢查腳本／測試針對 `dist/` 全數通過：驗證 `/` 與 `/zh-tw/` 生成、SEO/OG/JSON-LD、`aria` 必要屬性與角色、全部圖片與站內連結真實存在（無 404 壞鏈）、外部 CTA 連結符合 GitHub 開源導向且無假二進位下載連結，以及單檔與總產物尺寸符合 Spark 輕量規範。
  - 不對外執行實機 `firebase deploy --only hosting`。

---

## 5. 範圍邊界 (Out of Scope)

1. **不啟用 Flutter Web**：不建立 `flutter_restaruant/flutter_restaruant/web/`，不在官網引入 `firebase_auth`、`cloud_firestore`、`dio` 或於瀏覽器端呼叫 Yelp API。
2. **不託管二進位安裝檔**：不在 Firebase Hosting 上傳或提供 `.apk`、`.ipa`、`.dmg`、`.exe` 安裝包（遵守 Spark 條款並避免耗盡每日 360 MB 頻寬）。
3. **不變更 Firebase 計費與不執行線上部署**：維持 Spark 免費方案，不升級 Blaze；本次開發收尾停在建立 PR，不對線上環境執行 `firebase deploy --only hosting`。
4. **不憑空捏造未拍攝截圖**：`Notes`（UGC 探店筆記）與 `Filter`（進階篩選）等尚未於 `doc/screenshots/` 留存實機截圖的頁面，本版不編造對應圖片檔案，留待日後補拍再擴充鏡頭。
5. **零侵入 App 既有檔案**：嚴禁修改 `flutter_restaruant/flutter_restaruant/` 下的任何程式碼、測試、`pubspec.yaml` 或 FlutterFire `firebase.json`。
6. **不含自訂網域與追蹤分析**：本版使用預設網域 `https://findrestaurant-c80ea.web.app`，不進行網域購買/DNS 設定，亦不導入第三方 Analytics 或 Cookie 同意橫幅。
