# 實作計畫：Find Restaurant Astro 雙語靜態產品官網

> **給執行者（For agentic workers）：** 本計畫於 STAGE 1 依 `main`（`new-main/main` @ `843aaecc`，App 版本 `2.4.0+40`）建立的獨立 worktree 內執行，建議使用 `subagent-driven-development`（依批次與寫入路徑互斥規則派發）或 `executing-plans` 逐任務執行。步驟以核取方塊（`- [ ]`）追蹤進度；寫入前請勿改動計畫外檔案。

- **建立日期**：2026-11-21
- **對應規格**：[`docs/features/2026-11-21-astro-showcase-website.md`](../features/2026-11-21-astro-showcase-website.md)
- **實查基線**：`main`（`new-main/main` @ `843aaecc`，App 版本 `2.4.0+40`）
- **狀態**：🟡 修訂版 5（STAGE 0b，依 plan-verifier Rev 4 意見消滅 Grid Blowout）

**Goal：** 在 repo 根目錄（`<WORKTREE_ROOT>/website/`，與 `flutter_restaruant/` 平級）建置並驗證 Find Restaurant 的雙語（英文 `/` 與繁體中文 `/zh-tw/`）Astro 靜態產品官網，同時配置獨立 Firebase Hosting（`findrestaurant-c80ea`）與專屬 GitHub Actions CI/CD 工作流（`.github/workflows/website.yml`）。

**Architecture：** 以單一型別化雙語資料模型 `src/data/site.ts` 驅動共用的 `src/layouts/BaseLayout.astro` 與 `src/components/LandingPage.astro`，將 `/` 與 `/zh-tw/` 收斂為零模板重複的純靜態輸出；互動層僅由一個漸進增強模組 `src/scripts/showcase.ts` 統一管理 Hero 2D `<canvas>`（含 `IntersectionObserver` 離屏暫停與 `prefers-reduced-motion: reduce` 降級）、Scrollytelling WAI-ARIA 鏡頭同步，以及 `localStorage` 記憶的 Mobile / macOS 平台切換與 CLI 複製面板。既有 6 張 `doc/screenshots/*.png` 於事前以 `sharp` 轉為 `720x1600` WebP 與合成 `og-card.png`，確保單次訪問傳輸量遠低於 Firebase Spark 每日 360 MB 額度上限。

**Tech Stack：** `astro ^7.4.13`（靜態輸出 `output: 'static'`）、`sharp ^0.35.4`（WebP 轉檔與 `og-card.png` 合成）、TypeScript（erasable syntax）、原生 CSS Custom Properties + Grid/Sticky、原生 HTML5 2D `<canvas>`、Node.js `>=22.23.4`（實測本機 `v26.5.0` / `npm 11.17.0`）內建 `node:test` + `node:assert/strict`、Firebase Hosting（`findrestaurant-c80ea` Spark）、GitHub Actions

**Spec：** [`docs/features/2026-11-21-astro-showcase-website.md`](../features/2026-11-21-astro-showcase-website.md)

## Global Constraints

- 所有實作與驗證必須於 STAGE 1 依 `main`（`new-main/main` @ `843aaecc`）建立之 worktree 根目錄（`<WORKTREE_ROOT>`）執行。
- **App 零侵入鐵律**：嚴禁修改 `flutter_restaruant/flutter_restaruant/` 內任何 Dart 程式碼、`pubspec.yaml`、`pubspec.lock`、測試檔案或 FlutterFire 的 [`flutter_restaruant/flutter_restaruant/firebase.json`](../../firebase.json)；最終 `git diff -- flutter_restaruant/` 與 `git status --short -- flutter_restaruant/` 必須皆為空。
- **基線純淨**：網站文案與技術敘事僅得依據 `main`（`843aaecc`，`2.4.0+40`）既有架構與套件（`flutter_bloc ^9.1.1`、`get_it ^8.0.0`、`firebase_ai ^4.0.0`、`firebase_remote_config ^6.7.0` 等），禁止引用任何非 `main` 分支之實驗性或未合入套件。
- **誠實資產與零假下載**：Scrollytelling 6 鏡頭必須 1:1 對應 `doc/screenshots/` 既有 6 張截圖轉出的 `.webp`；尚無截圖的 UGC `Notes` 與進階 `Filter` 僅於 Stratum III 以文字誠實說明，不得捏造假圖檔；不得於 HTML/JS/Hosting 產物中出現假 `.dmg`/`.apk`/`.ipa`/`.exe` 下載連結或二進位安裝檔。
- **雙語對等與視覺規範**：`/` 輸出 `lang="en"`，`/zh-tw/` 輸出 `lang="zh-Hant-TW"`；融合 `ThemeColor.colord84a20`（`#D84A20`）與 `ThemeColor.colorfffbf7`（`#FFFBF7`），支援系統淺／深色模式及 `<meta name="theme-color" media="(prefers-color-scheme: ...)">`。
- **Spark 頻寬與品質門檻**：`npm run build` 0 error；每張 `/screenshots/*.webp` ≤ 150 KB、6 張總和 ≤ 600 KB、`og-card.png` ≤ 450 KB、`dist/` 總產物 ≤ 1.5 MB；`npm test` 100% 通過。
- **部署禁止紅線**：工作流開發與驗證期間**嚴禁**在任何本地或 CI 指令對線上網域執行實機 `firebase deploy --only hosting`。

---

## 1. 設計取捨分析（Approaches & Trade-offs）

| 實作方向 | 作法 | 優點 | 缺點 / 風險 | 結論 |
|---|---|---|---|---|
| **方案 A：純 Astro 靜態雙語單頁 + 單一資料模型 + 原生 CSS/JS + `sharp` + `node:test`** | 以 `src/data/site.ts` 統一承載 `en` / `zh-tw` 內容，單一 `BaseLayout.astro` + `LandingPage.astro` 渲染雙語頁面；`src/scripts/showcase.ts` 以 `data-*` 與 WAI-ARIA 驅動互動；`sharp` 預轉 WebP 與 `og-card.png`；Node 內建 `node:test` 驗證 `dist/` | 1. **零前端依賴膨脹**：執行期 0 框架 runtime，僅數 KB 原生 bundle<br>2. **實機工具鏈實證相容**：實查本機 `ffmpeg 9.0.2` 僅支援 `webp` 解碼（無 `libwebp` 編碼器亦無 `drawtext`）、`sips` 讀寫 WebP 僅支援讀取；`sharp` 自帶 `libwebp` 與 `librsvg` 且即為 Astro 預設圖片引擎，零系統套件安裝前置<br>3. **零模板重複**：`en` / `zh-tw` 共用結構，無散落語系 `if/else` 補丁<br>4. **測試零外掛**：Node `v26.5.0` 原生 `node --test` + type stripping 免裝 Jest/Vitest/Playwright | 複雜動態排版需手寫 CSS Grid/Custom Properties，但本案為單頁展示型網站，原生 CSS 更可控且產物極小 | **採用** |
| **方案 B：Astro + Tailwind CSS + React Islands + Vitest/Playwright** | 引入 `@astrojs/tailwind`、`@astrojs/react`、`vitest`、`playwright` 實作 Tabs 與 Canvas | 元件開發語法熟悉 | 1. 違反 YAGNI：僅為 6 個 Tab、1 個 OS 切換與 1 個 `<canvas>` 引入 React runtime 與 CSS 編譯層，增加包體積與依賴維護面<br>2. Playwright 瀏覽器下載大幅拖慢 CI 與 Spark 驗證速度 | **不採用** |
| **方案 C：Flutter Web (`flutter build web`) + Cloud Functions Proxy** | 直接編譯 Flutter App 為 Web SPA 作為產品介紹頁 | 可復用既有 Flutter Widget | 1. Yelp Fusion API 不支援瀏覽器 CORS，須先建置 Cloud Functions Proxy 並強制升級 Firebase 至 Blaze 方案（違反 Spark 邊界）<br>2. CanvasKit/Skwasm 首屏沉重、對 SEO / OG 爬蟲與弱網訪客極不友善，且違反 AC-1 零侵入要求 | **不採用** |

**工具鏈實查註記（關鍵環境證據）：**
實地檢查開發環境確認 `/opt/homebrew/bin/ffmpeg`（9.0.2）的 codec 清單中 `webp` 標記為 `D.VILS`（僅 Decoder、無 `libwebp` Encoder），且設定未編譯 `--enable-libfreetype`（不支援 `drawtext`）；`sips --formats` 亦標註 `org.webmproject.webp` 僅可讀取。因此放棄對本機 `ffmpeg`/`sips` 編碼 WebP 的假設，改由 `website` 專案開發依賴 `sharp ^0.35.4`（內含 prebuilt `libvips`/`libwebp`/`librsvg`）於 `scripts/prepare-assets.mjs` 一次性完成 6 張 WebP 壓縮、`favicon.png` 複製與 `1200x630` `og-card.png` 合成並提交靜態成品，使 CI（`ubuntu-latest`）建置不依賴本機外部媒體二進位工具。

---

## 2. 檔案異動清單（File Changes）

### 2.1 資料流向與模組邊界

```text
  [doc/screenshots/*.png] + [macos/.../app_icon_*.png]
           │ (Task 1: scripts/prepare-assets.mjs + sharp，一次性轉檔)
           ▼
  website/public/{favicon.png, og-card.png, screenshots/*.webp}
           │
  website/src/data/site.ts  (單一雙語型別化資料來源: SITE_META, SITE_DATA['en'|'zh-tw'])
      ├──► website/src/pages/index.astro        (locale='en')
      └──► website/src/pages/zh-tw/index.astro  (locale='zh-tw')
                │
                ▼
      website/src/components/LandingPage.astro (+ OsSwitcherBox.astro)
         └── wraps website/src/layouts/BaseLayout.astro (+ src/styles/global.css)
         └── hydrates website/src/scripts/showcase.ts (Canvas + Scrolly + OS Switch)
                │
                ▼ (astro build)
      website/dist/{index.html, zh-tw/index.html, _astro/*, screenshots/*.webp, og-card.png, favicon.png}
                │
                ├──► website/test/{site-data,verify-dist}.test.mjs (AC 靜態與不變量門檻)
                └──► .github/workflows/website.yml (PR build/test; main conditional deploy)
```

### 2.2 新增檔案清單（全數位於 `website/` 與 `.github/workflows/`）

| 檔案路徑（相對於 `<WORKTREE_ROOT>`） | 負責任務 | 用途 |
|---|---|---|
| `website/.gitignore` | Task 1 | 忽略 `node_modules/`、`dist/`、`.astro/`、`.firebase/`、`.DS_Store` |
| `website/package.json` | Task 1 | 定義專案腳本（`dev`/`build`/`preview`/`prepare:assets`/`test`）與 `astro`/`sharp` 依賴 |
| `website/package-lock.json` | Task 1 | 由 `npm install` 產生的鎖定檔，供 CI `npm ci` 使用 |
| `website/astro.config.mjs` | Task 1 | 配置 `site: 'https://findrestaurant-c80ea.web.app'` 與 `output: 'static'` |
| `website/tsconfig.json` | Task 1 | 繼承 `astro/tsconfigs/strict` 並涵蓋 `.astro/types.d.ts` 與 `src/**/*` |
| `website/scripts/prepare-assets.mjs` | Task 1 | 將 6 張實測截圖轉為 `720x1600` WebP、複製 `favicon.png`、合成 `1200x630` `og-card.png` |
| `website/public/favicon.png` | Task 1 | 複製自 `app_icon_128.png`（5,680 B） |
| `website/public/og-card.png` | Task 1 | 品牌社群分享預覽圖（`1200x630` PNG） |
| `website/public/screenshots/{home,ai-assistant,roulette,menu-vision,navigation,login}.webp` | Task 1 | 6 張實測截圖之壓縮 WebP |
| `website/src/data/site.ts` | Task 2 | 全站唯一雙語內容與結構化資料定義 |
| `website/src/styles/global.css` | Task 2 | `#D84A20` / `#FFFBF7` 設計系統、淺／深色配色、`.bar` / `.hero` / `.strata` / `.scrolly` / `.os-switch` 樣式 |
| `website/src/layouts/BaseLayout.astro` | Task 2 | 共用 HTML 骨架、SEO/OG/Twitter/hreflang/JSON-LD 及零閃爍 OS 偵測 inline script |
| `website/test/site-data.test.mjs` | Task 2 | 驗證雙語資料契約、1:1 WebP 路徑、無假下載連結與欄位完備性 |
| `website/.firebaserc` | Task 3 | 預設專案綁定 `findrestaurant-c80ea` |
| `website/firebase.json` | Task 3 | 僅含 `hosting`（`public: "dist"`、`/_astro/**` 與 `/screenshots/**` 長效快取與 `ignore`） |
| `.github/workflows/website.yml` | Task 3 | 僅限 `website/**` 變動觸發之建置、測試與 `main` 條件部署工作流 |
| `website/src/scripts/showcase.ts` | Task 4 | Hero 2D `<canvas>` 動畫（含離屏暫停與減動保護）、`.scrolly` WAI-ARIA 雙模切換、`os-switch` + `localStorage` + Copy CLI |
| `website/src/components/OsSwitcherBox.astro` | Task 4 | 共用 Mobile / macOS 平台切換與 CLI 複製區塊元件（Hero 與 Closing 共用） |
| `website/src/components/LandingPage.astro` | Task 4 | 單一頁面元件（`header.bar`、`hero`、Stratum I–III、`closing`、`footer`） |
| `website/src/pages/index.astro` | Task 4 | 英文版入口頁（`/`） |
| `website/src/pages/zh-tw/index.astro` | Task 4 | 繁體中文版入口頁（`/zh-tw/`） |
| `website/test/verify-dist.test.mjs` | Task 5 | 針對 `dist/` 與 `showcase.ts` 純函式之完整 AC 自動化測試門檻 |

### 2.3 Spark 每日 360 MB 頻寬預算控制

- **6 張 WebP 截圖**：`720x1600` (`quality: 82`, `effort: 6`)，單張預期 ~35–75 KB，合計上限鎖定 **≤ 600 KB**（相較原始 4.5 MB PNG 縮減 > 85%）。
- **HTML + CSS + JS bundle**：無外部 WebFont 與重型 JS 框架，首次載入網頁全產物（HTML + `/_astro/*` + 6 WebP + favicon）預期 **< 650 KB**。
- **快取標頭**：`/_astro/**` 設定 `max-age=31536000, immutable`、`/screenshots/**` 設定 `max-age=2592000, stale-while-revalidate=86400`，大幅抑制重複請求流量。

### 2.4 唯讀／零觸碰邊界（禁止修改）

- `flutter_restaruant/flutter_restaruant/**`（含 `lib/`、`test/`、`pubspec.yaml`、`firebase.json`）
- `doc/screenshots/*.png`（僅作為 `prepare-assets.mjs` 唯讀輸入）
- `.github/workflows/{pr-check.yml,release.yml,android-tag-build.yml}`

---

## 3. 實作任務拆分（Tasks）

> **並行與執行依賴拓撲：**
> - **Batch 1（序列前置）**：Task 1（建立專案骨架、安裝依賴並轉出 WebP / `og-card.png` / `favicon.png`）
> - **Batch 2（🟢 可並行）**：Task 2（資料模型、設計系統與 `BaseLayout`）∥ Task 3（Firebase Hosting 配置與 GitHub Actions 工作流）——兩者寫入路徑 100% 互斥且無資料依賴
> - **Batch 3（序列整合）**：Task 4（`showcase.ts`、`LandingPage.astro`、雙語路由與 `astro build`）——依賴 Task 1 + Task 2
> - **Batch 4（序列收斂驗證）**：Task 5（`dist/` 端到端測試套件與 App 零侵入隔離稽核）——依賴 Tasks 1–4

| Task | 複雜度 / 派發建議 | 依賴 | 寫入範圍（嚴格互斥） |
|---|---|---|---|
| Task 1 | `[標準]` | 無 | `website/{.gitignore,package.json,package-lock.json,astro.config.mjs,tsconfig.json,scripts/prepare-assets.mjs,public/**}` |
| Task 2 | `[標準]`（可與 Task 3 並行） | Task 1 | `website/{src/data/site.ts,src/styles/global.css,src/layouts/BaseLayout.astro,test/site-data.test.mjs}` |
| Task 3 | `[快/便宜]`（可與 Task 2 並行） | Task 1（僅需確認目錄約定，無程式碼依賴） | `website/{.firebaserc,firebase.json}`, `.github/workflows/website.yml` |
| Task 4 | `[標準]` | Task 1, Task 2 | `website/{src/scripts/showcase.ts,src/components/OsSwitcherBox.astro,src/components/LandingPage.astro,src/pages/index.astro,src/pages/zh-tw/index.astro}` |
| Task 5 | `[標準]` | Task 1–4 | `website/test/verify-dist.test.mjs` |

---

### Task 1：初始化 Astro 專案骨架與多媒體資產轉檔管線 `[標準]`

**Files:**
- Create: `website/.gitignore`
- Create: `website/package.json`
- Generated: `website/package-lock.json`
- Create: `website/astro.config.mjs`
- Create: `website/tsconfig.json`
- Create: `website/scripts/prepare-assets.mjs`
- Generated: `website/public/favicon.png`, `website/public/og-card.png`, `website/public/screenshots/{home,ai-assistant,roulette,menu-vision,navigation,login}.webp`

**Interfaces:**
- Consumes: `<WORKTREE_ROOT>/doc/screenshots/*.png`（6 張 `1080x2400` 實測截圖）與 `<WORKTREE_ROOT>/flutter_restaruant/flutter_restaruant/macos/Runner/Assets.xcassets/AppIcon.appiconset/{app_icon_128.png,app_icon_1024.png}`（唯讀）
- Produces:
  - `website/package.json` scripts：`dev`、`build`、`preview`、`prepare:assets`、`test`（`node --test test/*.test.mjs`）
  - 靜態圖片產物契約：
    - `/favicon.png`
    - `/og-card.png`（`1200x630`）
    - `/screenshots/home.webp`
    - `/screenshots/ai-assistant.webp`
    - `/screenshots/roulette.webp`
    - `/screenshots/menu-vision.webp`
    - `/screenshots/navigation.webp`
    - `/screenshots/login.webp`

- [ ] **Step 1：確認 worktree 根目錄與唯讀素材檔案皆就緒**

於 `<WORKTREE_ROOT>` 執行：

```bash
pwd
node -v
npm -v
ls -lh doc/screenshots/
ls -lh flutter_restaruant/flutter_restaruant/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{128,1024}.png
```

**預期輸出：** `node >= v22.23.4`、`npm >= 9.6.5`，6 張 `Screenshot_*.png` 與兩張 `app_icon_*.png` 均存在且非空。

- [ ] **Step 2：建立 `website/.gitignore`、`website/package.json`、`website/astro.config.mjs` 與 `website/tsconfig.json`**

建立 `website/.gitignore`：

```gitignore
node_modules/
dist/
.astro/
.firebase/
.DS_Store
```

建立 `website/package.json`：

```json
{
  "name": "find-restaurant-website",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "description": "Bilingual static product showcase website for Find Restaurant (Flutter + Firebase)",
  "engines": {
    "node": ">=22.23.4",
    "npm": ">=9.6.5"
  },
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "prepare:assets": "node scripts/prepare-assets.mjs",
    "test": "node --test test/*.test.mjs"
  },
  "dependencies": {
    "astro": "^7.4.13"
  },
  "devDependencies": {
    "sharp": "^0.35.4"
  }
}
```

建立 `website/astro.config.mjs`：

```js
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://findrestaurant-c80ea.web.app',
  output: 'static',
  trailingSlash: 'ignore',
});
```

建立 `website/tsconfig.json`：

```json
{
  "extends": "astro/tsconfigs/strict",
  "include": [".astro/types.d.ts", "src/**/*"],
  "exclude": ["dist", "node_modules"]
}
```

- [ ] **Step 3：安裝 npm 依賴並產生 `website/package-lock.json`**

```bash
cd website && npm install
```

**預期輸出：** `npm install` exit code `0`，產生 `website/package-lock.json`，且 `npx astro --version` 輸出 `7.4.x`，`node -e "import('sharp').then(m => console.log('sharp ok', typeof m.default))"` 輸出 `sharp ok function`。

- [ ] **Step 4：撰寫 `website/scripts/prepare-assets.mjs` 執行 WebP 壓縮、Favicon 複製與 OG Card 合成**

建立 `website/scripts/prepare-assets.mjs`：

```javascript
import { copyFile, mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const WEBSITE_ROOT = path.resolve(SCRIPT_DIR, '..');
const REPO_ROOT = path.resolve(WEBSITE_ROOT, '..');

const SCREENSHOTS_SRC_DIR = path.join(REPO_ROOT, 'doc', 'screenshots');
const APP_ICON_DIR = path.join(
  REPO_ROOT,
  'flutter_restaruant',
  'flutter_restaruant',
  'macos',
  'Runner',
  'Assets.xcassets',
  'AppIcon.appiconset',
);

const PUBLIC_DIR = path.join(WEBSITE_ROOT, 'public');
const SCREENSHOTS_OUT_DIR = path.join(PUBLIC_DIR, 'screenshots');

const SCREENSHOT_MAP = [
  { src: 'Screenshot_home.png', out: 'home.webp' },
  { src: 'Screenshot_ai_assistant_recommand.png', out: 'ai-assistant.webp' },
  { src: 'Screenshot_roulette.png', out: 'roulette.webp' },
  { src: 'Screenshot_menu_vision.png', out: 'menu-vision.webp' },
  { src: 'Screenshot_navigation.png', out: 'navigation.webp' },
  { src: 'Screenshot_login.png', out: 'login.webp' },
];

const MAX_WEBP_BYTES = 153_600; // 150 KB per screenshot
const MAX_TOTAL_WEBP_BYTES = 614_400; // 600 KB combined
const MAX_OG_BYTES = 460_800; // 450 KB for 1200x630 PNG

async function buildRoundedMask(width, height, radius) {
  const svg = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <rect x="0" y="0" width="${width}" height="${height}" rx="${radius}" ry="${radius}" fill="#ffffff"/>
  </svg>`;
  return Buffer.from(svg);
}

async function renderPhoneFrame(srcPath, targetWidth, targetHeight) {
  const innerW = targetWidth - 8;
  const innerH = targetHeight - 8;
  const imgBuf = await sharp(srcPath)
    .resize(innerW, innerH, { fit: 'cover' })
    .ensureAlpha()
    .composite([{ input: await buildRoundedMask(innerW, innerH, 16), blend: 'dest-in' }])
    .png()
    .toBuffer();

  const frameSvg = `<svg width="${targetWidth}" height="${targetHeight}" xmlns="http://www.w3.org/2000/svg">
    <rect x="0" y="0" width="${targetWidth}" height="${targetHeight}" rx="20" ry="20" fill="#1F1713" stroke="#D84A20" stroke-opacity="0.45" stroke-width="2"/>
  </svg>`;

  return sharp(Buffer.from(frameSvg))
    .composite([{ input: imgBuf, left: 4, top: 4 }])
    .png()
    .toBuffer();
}

async function generateOgCard() {
  const width = 1200;
  const height = 630;
  const sansFont = "'PingFang TC', 'Noto Sans TC', 'Helvetica Neue', Arial, sans-serif";
  const monoFont = "'SF Mono', Menlo, Monaco, Consolas, monospace";
  const bgSvg = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="glow" cx="76%" cy="46%" r="55%">
        <stop offset="0%" stop-color="#D84A20" stop-opacity="0.18"/>
        <stop offset="100%" stop-color="#FFFBF7" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="pill" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#D84A20"/>
        <stop offset="100%" stop-color="#B83B16"/>
      </linearGradient>
    </defs>
    <rect width="1200" height="630" fill="#FFFBF7"/>
    <rect width="1200" height="630" fill="url(#glow)"/>
    <circle cx="910" cy="315" r="250" fill="none" stroke="#D84A20" stroke-opacity="0.14" stroke-width="1.5"/>
    <circle cx="910" cy="315" r="185" fill="none" stroke="#D84A20" stroke-opacity="0.20" stroke-width="1.5" stroke-dasharray="6 8"/>
    <circle cx="910" cy="315" r="120" fill="none" stroke="#1F1713" stroke-opacity="0.10" stroke-width="1"/>
    <rect x="68" y="62" width="212" height="32" rx="16" fill="url(#pill)"/>
    <text x="174" y="83" text-anchor="middle" font-family="${sansFont}" font-size="14" font-weight="700" fill="#FFFBF7">OPEN SOURCE · v2.4.0+40</text>
    <text x="184" y="210" font-family="${sansFont}" font-size="48" font-weight="800" fill="#1F1713">Find Restaurant</text>
    <text x="184" y="248" font-family="${sansFont}" font-size="22" font-weight="600" fill="#D84A20">尋找餐廳 · Multimodal AI Dining</text>
    <text x="68" y="330" font-family="${sansFont}" font-size="26" font-weight="600" fill="#1F1713">GenUI Decision Canvas &amp; Menu Vision</text>
    <text x="68" y="372" font-family="${sansFont}" font-size="21" fill="#63544B">Clean Architecture · BLoC · GetIt · Gemini</text>
    <line x1="68" y1="428" x2="580" y2="428" stroke="#1F1713" stroke-opacity="0.14" stroke-width="1.5"/>
    <text x="68" y="476" font-family="${monoFont}" font-size="18" font-weight="600" fill="#1F1713">Android · iOS 15+ · macOS 14+ (Apple Silicon)</text>
    <text x="68" y="516" font-family="${monoFont}" font-size="16" fill="#63544B">https://findrestaurant-c80ea.web.app</text>
  </svg>`;

  const iconPath = path.join(APP_ICON_DIR, 'app_icon_1024.png');
  const iconBuf = await sharp(iconPath)
    .resize(96, 96)
    .ensureAlpha()
    .composite([{ input: await buildRoundedMask(96, 96, 22), blend: 'dest-in' }])
    .png()
    .toBuffer();

  const frameLeft = await renderPhoneFrame(
    path.join(SCREENSHOTS_SRC_DIR, 'Screenshot_ai_assistant_recommand.png'),
    172,
    372,
  );
  const frameRight = await renderPhoneFrame(
    path.join(SCREENSHOTS_SRC_DIR, 'Screenshot_menu_vision.png'),
    172,
    372,
  );
  const frameCenter = await renderPhoneFrame(
    path.join(SCREENSHOTS_SRC_DIR, 'Screenshot_home.png'),
    196,
    426,
  );

  const outPath = path.join(PUBLIC_DIR, 'og-card.png');
  await sharp(Buffer.from(bgSvg))
    .composite([
      { input: iconBuf, left: 68, top: 158 },
      { input: frameLeft, left: 650, top: 150 },
      { input: frameRight, left: 974, top: 150 },
      { input: frameCenter, left: 800, top: 102 },
    ])
    .png({ compressionLevel: 9, palette: true, quality: 90, effort: 8 })
    .toFile(outPath);

  const ogStat = await stat(outPath);
  const meta = await sharp(outPath).metadata();
  if (meta.width !== 1200 || meta.height !== 630) {
    throw new Error(`Invalid og-card.png dimensions: ${meta.width}x${meta.height}`);
  }
  if (ogStat.size > MAX_OG_BYTES) {
    throw new Error(`og-card.png (${ogStat.size} B) exceeds ${MAX_OG_BYTES} B limit`);
  }
  console.log(`og-card.png: ${meta.width}x${meta.height}, ${ogStat.size} B`);
}

async function main() {
  await mkdir(SCREENSHOTS_OUT_DIR, { recursive: true });

  // 1. Copy favicon
  const faviconSrc = path.join(APP_ICON_DIR, 'app_icon_128.png');
  const faviconOut = path.join(PUBLIC_DIR, 'favicon.png');
  await copyFile(faviconSrc, faviconOut);
  const favStat = await stat(faviconOut);
  console.log(`favicon.png: ${favStat.size} B`);

  // 2. Convert 6 real screenshots to 720x1600 WebP
  let totalWebpBytes = 0;
  for (const item of SCREENSHOT_MAP) {
    const srcPath = path.join(SCREENSHOTS_SRC_DIR, item.src);
    const outPath = path.join(SCREENSHOTS_OUT_DIR, item.out);
    await sharp(srcPath)
      .resize({ width: 720, withoutEnlargement: true })
      .webp({ quality: 82, effort: 6 })
      .toFile(outPath);

    const fileStat = await stat(outPath);
    const meta = await sharp(outPath).metadata();
    totalWebpBytes += fileStat.size;
    console.log(`${item.out}: ${meta.width}x${meta.height} (${meta.format}), ${fileStat.size} B`);

    if (meta.format !== 'webp' || meta.width !== 720 || meta.height !== 1600) {
      throw new Error(`Unexpected WebP output for ${item.out}: ${JSON.stringify(meta)}`);
    }
    if (fileStat.size > MAX_WEBP_BYTES) {
      throw new Error(`${item.out} (${fileStat.size} B) exceeds ${MAX_WEBP_BYTES} B budget`);
    }
  }

  if (totalWebpBytes > MAX_TOTAL_WEBP_BYTES) {
    throw new Error(`Total WebP size (${totalWebpBytes} B) exceeds ${MAX_TOTAL_WEBP_BYTES} B budget`);
  }
  console.log(`Total WebP screenshots: ${totalWebpBytes} B`);

  // 3. Composite brand OG preview image
  await generateOgCard();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 5：執行資產轉檔並驗證輸出尺寸與格式**

```bash
cd website && npm run prepare:assets && ls -lh public/ public/screenshots/
```

**預期輸出：** exit code `0`，`public/favicon.png`、`public/og-card.png`（`1200x630`，≤ 450 KB）與 6 個 `public/screenshots/*.webp`（均為 `720x1600` `webp`，單檔 ≤ 150 KB、合計 ≤ 600 KB）。

---

### Task 2：雙語型別化內容模型、設計系統 CSS 與基礎 SEO Layout `[標準]`

> **並行註記：** Task 2 與 Task 3 寫入路徑完全互斥且零資料依賴，可於 Task 1 完成後**並行執行**。

**Files:**
- Create: `website/test/site-data.test.mjs`
- Create: `website/src/data/site.ts`
- Create: `website/src/styles/global.css`
- Create: `website/src/layouts/BaseLayout.astro`

**Interfaces:**
- Consumes: Task 1 建立之 `website/tsconfig.json` 與 `website/public/` 靜態資產路徑約定
- Produces:
  - `website/src/data/site.ts`:
    - `export type Locale = 'en' | 'zh-tw'`
    - `export type OsKind = 'mobile' | 'macos'`
    - `export const SITE_META`: `{ baseUrl, repoUrl, releasesUrl, readmeEnUrl, readmeZhUrl, macosGuideUrl, appVersion, projectId, ogImagePath, faviconPath }`
    - `export const ALLOWED_SCREENSHOTS`: `readonly string[]`（嚴格 6 個 `/screenshots/*.webp`）
    - `export const SITE_DATA: Record<Locale, SiteLocaleData>`
    - `export function buildSoftwareApplicationJsonLd(locale: Locale): Record<string, unknown>`
  - `website/src/layouts/BaseLayout.astro`: `Props { locale: Locale; data: SiteLocaleData }`，提供 `.bar` 外層 `<slot />` 結構、完整 `<head>` SEO/OG/Twitter/JSON-LD、零閃爍 OS `data-os` 初始化腳本及 `global.css` 導入
  - `website/src/styles/global.css`: 定義 CSS variables（`--bg`, `--surface`, `--surface-alt`, `--ink`, `--ink-muted`, `--accent`, `--accent-ink`, `--accent-fill`, `--accent-fill-hover`, `--on-accent`, `--accent-soft`, `--border`）與所有語意類別（`.bar`, `.hero`, `.os-switch`, `.os-panel`, `.shoal`, `.strata`, `.stratum`, `.ruler`, `.depth`, `.scrolly`, `.lenses`, `.lens`, `.lens-stack`, `.lens-panel`, `.closing`, `.foot`）

- [ ] **Step 1：先撰寫失敗測試 `website/test/site-data.test.mjs`（TDD Red）**

建立 `website/test/site-data.test.mjs`：

```javascript
import assert from 'node:assert/strict';
import test from 'node:test';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  ALLOWED_SCREENSHOTS,
  SITE_DATA,
  SITE_META,
  buildSoftwareApplicationJsonLd,
} from '../src/data/site.ts';

const TEST_DIR = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.resolve(TEST_DIR, '..', 'public');

test('SITE_META enforces honest repo/releases URLs and base version', () => {
  assert.equal(SITE_META.baseUrl, 'https://findrestaurant-c80ea.web.app');
  assert.equal(SITE_META.appVersion, '2.4.0+40');
  assert.equal(
    SITE_META.repoUrl,
    'https://github.com/Yomiamy/Finding-Restaurant-Flutter',
  );
  assert.equal(
    SITE_META.releasesUrl,
    'https://github.com/Yomiamy/Finding-Restaurant-Flutter/releases',
  );
  assert.ok(existsSync(path.join(PUBLIC_DIR, SITE_META.ogImagePath.replace(/^\//, ''))));
  assert.ok(existsSync(path.join(PUBLIC_DIR, SITE_META.faviconPath.replace(/^\//, ''))));
});

test('Both en and zh-tw locales provide complete parity and valid 1:1 WebP lenses', () => {
  assert.deepEqual(Object.keys(SITE_DATA).sort(), ['en', 'zh-tw']);
  assert.equal(SITE_DATA.en.htmlLang, 'en');
  assert.equal(SITE_DATA['zh-tw'].htmlLang, 'zh-Hant-TW');

  for (const locale of ['en', 'zh-tw']) {
    const d = SITE_DATA[locale];
    assert.ok(d.seo.title.length > 10);
    assert.ok(d.seo.description.length > 30);
    assert.equal(d.stratum1.lenses.length, 6, `${locale} must define exactly 6 lenses`);

    const seenImages = new Set();
    for (const lens of d.stratum1.lenses) {
      assert.ok(
        ALLOWED_SCREENSHOTS.includes(lens.image),
        `${locale} lens ${lens.id} uses unapproved image: ${lens.image}`,
      );
      assert.ok(!seenImages.has(lens.image), `${locale} duplicate lens image: ${lens.image}`);
      seenImages.add(lens.image);

      const diskPath = path.join(PUBLIC_DIR, lens.image.replace(/^\//, ''));
      assert.ok(existsSync(diskPath), `Missing WebP file on disk: ${diskPath}`);
      assert.ok(lens.alt.trim().length > 10);
    }

    assert.equal(d.hero.osPanels.mobile.id, 'mobile');
    assert.equal(d.hero.osPanels.macos.id, 'macos');
    for (const panel of Object.values(d.hero.osPanels)) {
      assert.ok(panel.cliCommand.trim().length > 10);
      assert.doesNotMatch(panel.cliCommand, /\.(dmg|apk|ipa|exe)\b/i);
    }
  }
});

test('JSON-LD outputs valid SoftwareApplication without fake binary downloadUrl', () => {
  for (const locale of ['en', 'zh-tw']) {
    const ld = buildSoftwareApplicationJsonLd(locale);
    assert.equal(ld['@type'], 'SoftwareApplication');
    assert.equal(ld.softwareVersion, '2.4.0+40');
    assert.equal(ld.codeRepository, SITE_META.repoUrl);
    assert.equal('downloadUrl' in ld, false);
    assert.match(String(ld.operatingSystem), /Android/);
    assert.match(String(ld.operatingSystem), /iOS/);
    assert.match(String(ld.operatingSystem), /macOS 14\+/);
  }
});
```

- [ ] **Step 2：執行測試確認尚未實作前如期失敗**

```bash
cd website && node --test test/site-data.test.mjs
```

**預期輸出：** 非零 exit code，失敗訊息包含 `ERR_MODULE_NOT_FOUND`（找不到 `src/data/site.ts`）。

- [ ] **Step 3：實作單一型別化雙語資料模型 `website/src/data/site.ts`**

建立 `website/src/data/site.ts`：

```typescript
export type Locale = 'en' | 'zh-tw';
export type OsKind = 'mobile' | 'macos';

export interface NavLink {
  label: string;
  href: string;
}

export interface OsPanelContent {
  id: OsKind;
  tabLabel: string;
  eyebrow: string;
  heading: string;
  summary: string;
  specs: readonly string[];
  cliLabel: string;
  cliCommand: string;
  copyLabel: string;
  copiedLabel: string;
  fallbackLabel: string;
}

export interface LensItem {
  id: string;
  code: string;
  title: string;
  subtitle: string;
  description: string;
  image: string;
  alt: string;
  caption: string;
}

export interface AiFeatureCard {
  tag: string;
  title: string;
  symbol: string;
  description: string;
  bullets: readonly string[];
}

export interface ArchitectureLayer {
  layer: string;
  title: string;
  summary: string;
}

export interface CapabilityRow {
  capability: string;
  mobile: string;
  macos: string;
  reason: string;
}

export interface SecurityPrinciple {
  title: string;
  detail: string;
}

export interface SiteLocaleData {
  locale: Locale;
  htmlLang: 'en' | 'zh-Hant-TW';
  ogLocale: 'en_US' | 'zh_TW';
  ogLocaleAlternate: 'zh_TW' | 'en_US';
  canonicalPath: '/' | '/zh-tw/';
  alternatePath: '/zh-tw/' | '/';
  skipToContent: string;
  nav: {
    brandName: string;
    brandSub: string;
    links: readonly NavLink[];
    githubLabel: string;
    langSwitchLabel: string;
    langLinks: {
      en: string;
      zhTw: string;
    };
  };
  seo: {
    title: string;
    description: string;
    ogTitle: string;
    ogDescription: string;
    ogImageAlt: string;
  };
  hero: {
    badge: string;
    title: string;
    titleAccent: string;
    lead: string;
    osGroupLabel: string;
    osPanels: Record<OsKind, OsPanelContent>;
    ctaSource: string;
    ctaGuide: string;
    ctaReleases: string;
    canvasCaption: string;
    canvasTitle: string;
  };
  stratum1: {
    depth: string;
    eyebrow: string;
    title: string;
    lead: string;
    tablistLabel: string;
    lenses: readonly LensItem[];
  };
  stratum2: {
    depth: string;
    eyebrow: string;
    title: string;
    lead: string;
    cards: readonly AiFeatureCard[];
  };
  stratum3: {
    depth: string;
    eyebrow: string;
    title: string;
    lead: string;
    archHeading: string;
    archLayers: readonly ArchitectureLayer[];
    matrixHeading: string;
    matrixColumns: {
      capability: string;
      mobile: string;
      macos: string;
      reason: string;
    };
    capabilities: readonly CapabilityRow[];
    securityHeading: string;
    securityPrinciples: readonly SecurityPrinciple[];
    evolutionHeading: string;
    evolutionBadge: string;
    evolutionBody: string;
  };
  closing: {
    eyebrow: string;
    title: string;
    lead: string;
    ctaRepo: string;
    ctaMacGuide: string;
    ctaReleases: string;
  };
  footer: {
    tagline: string;
    versionText: string;
    licenseNote: string;
    links: readonly NavLink[];
  };
}

export const SITE_META = {
  baseUrl: 'https://findrestaurant-c80ea.web.app',
  projectId: 'findrestaurant-c80ea',
  appVersion: '2.4.0+40',
  repoUrl: 'https://github.com/Yomiamy/Finding-Restaurant-Flutter',
  releasesUrl: 'https://github.com/Yomiamy/Finding-Restaurant-Flutter/releases',
  readmeEnUrl: 'https://github.com/Yomiamy/Finding-Restaurant-Flutter/blob/main/README.md',
  readmeZhUrl: 'https://github.com/Yomiamy/Finding-Restaurant-Flutter/blob/main/README-tw.md',
  macosGuideUrl:
    'https://github.com/Yomiamy/Finding-Restaurant-Flutter/blob/main/flutter_restaruant/flutter_restaruant/docs/manuals/macos-release-guide.md',
  ogImagePath: '/og-card.png',
  faviconPath: '/favicon.png',
} as const;

export const ALLOWED_SCREENSHOTS = [
  '/screenshots/home.webp',
  '/screenshots/ai-assistant.webp',
  '/screenshots/roulette.webp',
  '/screenshots/menu-vision.webp',
  '/screenshots/navigation.webp',
  '/screenshots/login.webp',
] as const;

export const SITE_DATA: Record<Locale, SiteLocaleData> = {
  en: {
    locale: 'en',
    htmlLang: 'en',
    ogLocale: 'en_US',
    ogLocaleAlternate: 'zh_TW',
    canonicalPath: '/',
    alternatePath: '/zh-tw/',
    skipToContent: 'Skip to main content',
    nav: {
      brandName: 'Find Restaurant',
      brandSub: 'v2.4.0+40',
      links: [
        { label: 'Experience', href: '#experience' },
        { label: 'Multimodal AI', href: '#ai' },
        { label: 'Architecture', href: '#architecture' },
        { label: 'Build & Source', href: '#install' },
      ],
      githubLabel: 'GitHub',
      langSwitchLabel: 'Language selector',
      langLinks: {
        en: 'EN',
        zhTw: '繁中',
      },
    },
    seo: {
      title: 'Find Restaurant — Multimodal AI Dining Discovery in Flutter',
      description:
        'Open-source restaurant discovery built with Clean Architecture, BLoC, GetIt, Yelp Fusion API, and Firebase AI Logic (Gemini) for Android, iOS, and macOS 14+.',
      ogTitle: 'Find Restaurant — Multimodal AI Dining Discovery in Flutter',
      ogDescription:
        'Explore GenUI decision canvases, Menu Vision allergen parsing, Decision Roulette, and clean cross-platform architecture across Mobile and macOS 14+.',
      ogImageAlt: 'Find Restaurant product preview showcasing AI Assistant, Menu Vision, and Discovery screens',
    },
    hero: {
      badge: 'Open Source · v2.4.0+40 · Flutter + Firebase AI',
      title: 'Dining discovery shaped by ',
      titleAccent: 'multimodal AI & clean craft.',
      lead: 'An engineering-first Flutter application pairing real Yelp Fusion spatial search and Cloud Firestore favorites with Gemini-powered GenUI decision canvases, menu allergen vision, and graceful Mobile/macOS capability gating.',
      osGroupLabel: 'Target platform instructions',
      osPanels: {
        mobile: {
          id: 'mobile',
          tabLabel: 'Mobile (iOS / Android)',
          eyebrow: 'iOS 15.0+ & Android',
          heading: 'Full native mobile dining experience',
          summary:
            'Includes interactive Google Maps pins, GPS-assisted discovery, camera capture for Menu Vision, FCM notifications, biometric sign-in, and AdMob compliance.',
          specs: ['iOS 15.0+ / Android', 'Google Maps SDK', 'Camera + Biometrics', 'FCM + AdMob'],
          cliLabel: 'Clone & run on mobile emulator or device',
          cliCommand:
            'git clone https://github.com/Yomiamy/Finding-Restaurant-Flutter.git\ncd Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant\nflutter pub get && flutter run',
          copyLabel: 'Copy CLI',
          copiedLabel: 'Copied Mobile CLI to clipboard',
          fallbackLabel: 'Clipboard unavailable — command selected for manual copy',
        },
        macos: {
          id: 'macos',
          tabLabel: 'macOS Desktop (14+)',
          eyebrow: 'Apple Silicon · macOS 14+',
          heading: 'Desktop workspace with capability-gated degradation',
          summary:
            'Built natively for macOS 14+ with Static Maps + external browser navigation, photo library Menu Vision input, and Developer ID signing + Apple Notarization DMG tooling via scripts/release_macos.sh.',
          specs: ['macOS 14.0+ / Apple Silicon', 'Static Maps + External Nav', 'Developer ID Notarized DMG', 'No AdMob / Camera Fallback'],
          cliLabel: 'Build macOS or package signed DMG locally',
          cliCommand:
            'git clone https://github.com/Yomiamy/Finding-Restaurant-Flutter.git\ncd Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant\nflutter pub get && flutter run -d macos\n# Optional DMG release: ./scripts/release_macos.sh -p "notary-profile"',
          copyLabel: 'Copy CLI',
          copiedLabel: 'Copied macOS CLI to clipboard',
          fallbackLabel: 'Clipboard unavailable — command selected for manual copy',
        },
      },
      ctaSource: 'View Source on GitHub',
      ctaGuide: 'README & Setup',
      ctaReleases: 'Releases Portal',
      canvasCaption: '25.048°N, 121.517°E · Live Coordinate Radar',
      canvasTitle: 'Urban Culinary Radar',
    },
    stratum1: {
      depth: 'STRATUM 01 // CORE EXPERIENCE',
      eyebrow: 'Six Real Captures · Interactive Lenses',
      title: 'Every interaction backed by verified app captures.',
      lead: 'Scroll through the experience column on desktop, click any lens, or navigate with arrow keys. Each panel maps 1:1 to a real screenshot captured from the running Flutter app.',
      tablistLabel: 'Product feature lenses',
      lenses: [
        {
          id: 'lens-01',
          code: '01',
          title: 'Home Spatial Discovery',
          subtitle: 'Live Yelp Fusion search & map toggle',
          description:
            'Switch smoothly between card feeds and spatial map markers, jump directly via remote Yelp term autocomplete, and inspect ratings, pricing, and open status at a glance.',
          image: '/screenshots/home.webp',
          alt: 'Find Restaurant home screen displaying nearby restaurant cards, rating stars, and search bar',
          caption: 'Lens 01 — Home exploration feed powered by MainBloc & Yelp Fusion API.',
        },
        {
          id: 'lens-02',
          code: '02',
          title: 'AI Foodie GenUI Canvas',
          subtitle: 'Grounded A2UI component responses',
          description:
            'Describe group size, mood, or budget in natural language. Gemini grounds recommendations strictly against loaded nearby venues and renders structured comparison matrices.',
          image: '/screenshots/ai-assistant.webp',
          alt: 'AI Foodie assistant screen showing conversational recommendation and structured comparison cards',
          caption: 'Lens 02 — Structured A2UI comparison_matrix & action chips grounded to real Yelp IDs.',
        },
        {
          id: 'lens-03',
          code: '03',
          title: 'Decision Roulette',
          subtitle: 'Custom-painted randomizer wheel',
          description:
            'End group indecision when two or more venues look equally tempting. Triggered directly from AI Foodie action chips or manually seeded from shortlisted candidates.',
          image: '/screenshots/roulette.webp',
          alt: 'Decision Roulette spinning wheel screen selecting between shortlisted restaurants',
          caption: 'Lens 03 — decision_roulette GenUI payload rendered as an animated spin wheel.',
        },
        {
          id: 'lens-04',
          code: '04',
          title: 'Menu Vision & Allergens',
          subtitle: 'Multimodal foreign menu parser',
          description:
            'Snap or upload a foreign-language menu photo. Gemini extracts dish names, pricing, and ingredient breakdowns while flagging nuts, dairy, gluten, shellfish, and soy.',
          image: '/screenshots/menu-vision.webp',
          alt: 'Menu Vision screen translating dishes and highlighting allergen badges',
          caption: 'Lens 04 — Multimodal schema output mapped to DishItemEntity & AllergenInfo.',
        },
        {
          id: 'lens-05',
          code: '05',
          title: 'Detail, Navigation & Street View',
          subtitle: 'Firestore favorites & maps handoff',
          description:
            'Review opening hours, formatted phone numbers, static/interactive map previews, external Google Maps routing, street view, and per-user Cloud Firestore favorites.',
          image: '/screenshots/navigation.webp',
          alt: 'Restaurant detail page with map preview, navigation actions, and favorite toggle',
          caption: 'Lens 05 — FavorDataSource subcollection sync + external Maps & Street View launch.',
        },
        {
          id: 'lens-06',
          code: '06',
          title: 'Multi-Provider Auth & Guest Mode',
          subtitle: 'Google, Apple, Email & Biometrics',
          description:
            'Low-friction onboarding with Google Sign-In, conditional Sign in with Apple, Email/Password, biometric auto-login, and an instant guest mode for zero-signup browsing.',
          image: '/screenshots/login.webp',
          alt: 'Login screen offering Email, Google, Apple, Biometric, and Guest access options',
          caption:
            'Lens 06 — SignInBloc delegates via SignInRepository to SignInManager, orchestrating 6 auth sub-managers (Google / Apple / Facebook / Mail / Biometric / Auto; 9 Managers app-wide).',
        },
      ],
    },
    stratum2: {
      depth: 'STRATUM 02 // MULTIMODAL AI',
      eyebrow: 'Firebase AI Logic · Gemini Structured Output',
      title: 'Deterministic JSON envelopes instead of fragile prompt prose.',
      lead: 'Every AI surface enforces strict schema constraints and strict domain entity mapping, eliminating hallucinated venue IDs and unparsed markdown from reaching Flutter UI.',
      cards: [
        {
          tag: 'GenUI / A2UI',
          title: 'Grounded Decision Canvas',
          symbol: 'A2UIComponent (sealed)',
          description:
            'Conversational replies separate short natural introductions from typed component envelopes (comparison_matrix, action_chip_group, decision_roulette), strictly constrained to loaded nearby Yelp business IDs.',
          bullets: [
            'Zero hallucinated IDs — cards link directly to detail routes',
            'Hard payload caps prevent token bloat and repeated prose',
            'Typed sealed-class dispatching in domain entities',
          ],
        },
        {
          tag: 'Decision Support',
          title: 'Interactive Roulette Handoff',
          symbol: 'decision_roulette',
          description:
            'When comparison highlights narrow choices down to 2–4 contenders, AI Foodie emits a ready-to-spin roulette payload so groups lock in dinner in seconds.',
          bullets: [
            'Minimum 2-option validation guard before rendering wheel',
            'Synchronized action chips allow one-tap re-query or spin',
            'Maintains deterministic fallback to plain text on sparse results',
          ],
        },
        {
          tag: 'Multimodal Vision',
          title: 'Menu Vision & Allergen Parsing',
          symbol: 'DishItemEntity + AllergenInfo',
          description:
            'Analyzes menu photographs with structured output schemas to translate dish titles, estimate ingredients, and surface dietary allergen alerts across 7 major categories.',
          bullets: [
            'Platform-aware input: live camera on Mobile, photo picker on macOS',
            'Explicit allergen badges for nuts, peanuts, egg, dairy, gluten, shellfish, soy',
            'Clean nullable-to-non-null UI model projection inside MenuVisionBloc',
          ],
        },
        {
          tag: 'Review Intelligence',
          title: 'Prompt-Isolated Review Summary',
          symbol: 'ReviewSummaryEntity',
          description:
            'Condenses customer reviews into balanced Pros, Cons, Signature Highlights, and a 40-character takeaway with explicit zero-review short-circuiting and injection fencing.',
          bullets: [
            'User reviews wrapped in isolation tags to mitigate prompt injection',
            'Skips Gemini calls completely when zero reviews exist',
            'Independent ReviewSummaryCard state machine with skeleton & retry',
          ],
        },
      ],
    },
    stratum3: {
      depth: 'STRATUM 03 // ARCHITECTURE & GOVERNANCE',
      eyebrow: 'Clean Architecture · Cross-Platform · Honest Trade-offs',
      title: 'Designed for maintainability, platform honesty, and key safety.',
      lead: 'A clear one-way dependency boundary keeps business logic portable while isolating platform differences, remote configuration, and security constraints.',
      archHeading: 'Strict Layering & State Discipline',
      archLayers: [
        {
          layer: 'Presentation',
          title: 'BLoC vs. setState Hard Boundary',
          summary:
            'Every screen, sheet, or card touching Repositories runs an isolated Bloc (flutter_bloc ^9.1.1) wired at routesTable or optional local injection; setState is restricted strictly to ephemeral UI state.',
        },
        {
          layer: 'Domain',
          title: 'Pure Interfaces & Sealed States',
          summary:
            'Thirteen Repository contracts (12 abstract interface classes plus abstract class UgcNoteRepository covering Yelp, AI, Favorites, Auth, Settings, and UGC Notes) contain zero Dio, Firestore, or SharedPreferences imports, paired with Dart 3 sealed states and GetIt lazy singletons.',
        },
        {
          layer: 'Data',
          title: 'DTO Containment & Single Access Points',
          summary:
            'Retrofit + Dio (dio ^5.6.0) handle Yelp REST APIs while FavorDataSource (favors/{uid}/items) and UgcNoteDataSource (ugc_notes) isolate all Firestore mutations.',
        },
      ],
      matrixHeading: 'Single-Source platformCapabilities() Matrix',
      matrixColumns: {
        capability: 'Capability',
        mobile: 'iOS 15+ & Android',
        macos: 'macOS 14+ (DMG / App)',
        reason: 'Architectural Basis',
      },
      capabilities: [
        {
          capability: 'Interactive Maps & Mode Switch',
          mobile: 'Full Google Maps SDK',
          macos: 'Static Maps + Browser Handoff',
          reason: 'google_maps_flutter targets mobile natively; desktop stays crisp via Static Maps & URL launch',
        },
        {
          capability: 'Camera Capture (Menu Vision)',
          mobile: 'Camera + Photo Library',
          macos: 'Photo Library Picker Only',
          reason: 'Avoids macOS cameraDelegate StateError while keeping full AI menu analysis intact',
        },
        {
          capability: 'Sign in with Apple',
          mobile: 'Enabled on iOS',
          macos: 'Hidden on Developer ID DMG',
          reason: 'Apple restricts com.apple.developer.applesignin to App Store profiles (DEVELOPER_ID_BUILD=true)',
        },
        {
          capability: 'AdMob & Push Notifications',
          mobile: 'Enabled (50dp CLS-safe banner)',
          macos: 'Gracefully Disabled',
          reason: 'AdMob supports mobile targets only; desktop workspace remains distraction-free',
        },
      ],
      securityHeading: 'Remote Config & API Security Principles',
      securityPrinciples: [
        {
          title: 'Zero Hardcoded Secrets + Remote Model Governance',
          detail:
            'AiModelConfig reads Gemini model IDs, temperature, system prompts, yelp_api_auth_token, and static_map_api_key from Firebase Remote Config with safe local defaults for AI parameters.',
        },
        {
          title: 'Why This Website Is Astro (Not Flutter Web)',
          detail:
            'Yelp Fusion API rejects browser-origin CORS requests and would expose bearer tokens in client bundles. Hosting a static Astro showcase avoids server-side proxy complexity and keeps Firebase on the free Spark tier.',
        },
      ],
      evolutionHeading: 'Recent Codebase Evolution (Honest Uncaptured Features)',
      evolutionBadge: 'Verified in main · Screenshots Pending',
      evolutionBody:
        'Recent releases on main also shipped two-column UGC Food Notes (NotesFeedPage / NoteDetailPage with 15-second video playback and location check-in summary sheets) and extended Yelp Filter controls (FilterCuisineBloc, search radius chips up to 40 km, and open-now toggle). Dedicated device screenshots for these flows are intentionally omitted here until real captures are added to doc/screenshots/.',
    },
    closing: {
      eyebrow: 'Build From Source · Open Architecture',
      title: 'Inspect every layer, run locally, or package for macOS.',
      lead: 'No binary installers are hosted on Firebase Spark to respect bandwidth quotas and avoid stale artifacts. Clone the repository directly or track tagged builds on GitHub Releases.',
      ctaRepo: 'Browse GitHub Repository',
      ctaMacGuide: 'macOS Release & Notarization Guide',
      ctaReleases: 'GitHub Releases (Future Binaries)',
    },
    footer: {
      tagline: 'Find Restaurant — Clean Architecture Flutter Showcase',
      versionText: 'Baseline main @ 843aaecc · App v2.4.0+40',
      licenseNote: 'Static showcase hosted on Firebase Hosting (Spark). Source code available on GitHub.',
      links: [
        { label: 'Repository', href: SITE_META.repoUrl },
        { label: 'README', href: SITE_META.readmeEnUrl },
        { label: 'macOS Guide', href: SITE_META.macosGuideUrl },
        { label: 'Releases', href: SITE_META.releasesUrl },
      ],
    },
  },
  'zh-tw': {
    locale: 'zh-tw',
    htmlLang: 'zh-Hant-TW',
    ogLocale: 'zh_TW',
    ogLocaleAlternate: 'en_US',
    canonicalPath: '/zh-tw/',
    alternatePath: '/',
    skipToContent: '跳至主要內容',
    nav: {
      brandName: 'Find Restaurant',
      brandSub: 'v2.4.0+40',
      links: [
        { label: '核心體驗', href: '#experience' },
        { label: '多模態 AI', href: '#ai' },
        { label: '工程架構', href: '#architecture' },
        { label: '原始碼與建置', href: '#install' },
      ],
      githubLabel: 'GitHub',
      langSwitchLabel: '切換語言',
      langLinks: {
        en: 'EN',
        zhTw: '繁中',
      },
    },
    seo: {
      title: 'Find Restaurant（尋找餐廳）— Flutter 多模態 AI 美食探索開源專案',
      description:
        '採用 Clean Architecture、BLoC、GetIt、Yelp Fusion API 與 Firebase AI Logic (Gemini) 打造之跨平台美食探索 App，支援 Android、iOS 與 macOS 14+。',
      ogTitle: 'Find Restaurant（尋找餐廳）— Flutter 多模態 AI 美食探索官網',
      ogDescription:
        '探索 GenUI 決策畫布、Menu Vision 菜單過敏原翻譯、命運大轉盤與橫跨 Mobile／macOS 14+ 的單一能力閘門工程設計。',
      ogImageAlt: 'Find Restaurant 產品預覽圖，展示 AI 智能覓食助理、Menu Vision 與首頁探索畫面',
    },
    hero: {
      badge: '開源專案 · v2.4.0+40 · Flutter + Firebase AI',
      title: '以多模態 AI 與簡潔架構，',
      titleAccent: '重新定義日常覓食決策。',
      lead: '將即時 Yelp Fusion 空間搜尋與 Cloud Firestore 收藏清單，結合 Gemini 驅動的 GenUI 決策畫布、菜單視覺過敏原拆解與跨平台能力閘門，打造橫跨行動裝置與 macOS 桌面的工程示範級 Flutter 應用。',
      osGroupLabel: '目標平台切換與建置指令',
      osPanels: {
        mobile: {
          id: 'mobile',
          tabLabel: 'Mobile（iOS / Android）',
          eyebrow: 'iOS 15.0+ 與 Android 原生體驗',
          heading: '完整行動端探索、地圖與相機視覺流程',
          summary:
            '完整啟用互動式 Google Maps 地圖模式、GPS 定位探索、Menu Vision 即時相機拍菜單、FCM 推播、生物辨識快速登入與符合防誤觸規範的底部 AdMob 版位。',
          specs: ['iOS 15.0+ / Android', 'Google Maps SDK', '相機拍照 + 生物辨識', 'FCM + AdMob'],
          cliLabel: '複製原始碼並於手機或模擬器執行',
          cliCommand:
            'git clone https://github.com/Yomiamy/Finding-Restaurant-Flutter.git\ncd Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant\nflutter pub get && flutter run',
          copyLabel: '複製指令',
          copiedLabel: '已複製 Mobile 建置指令至剪貼簿',
          fallbackLabel: '瀏覽器不支援自動寫入剪貼簿，已為您反白指令',
        },
        macos: {
          id: 'macos',
          tabLabel: 'macOS Desktop（14+）',
          eyebrow: 'Apple Silicon · macOS 14+',
          heading: '原生桌面視窗與優雅能力降級設計',
          summary:
            '專為 macOS 14+ 打造：以 Static Maps 預覽結合外部瀏覽器地圖導航／街景、相簿選圖支援 Menu Vision 解析，並提供 Developer ID 簽章與 Apple Notarization 公證 DMG 打包腳本。',
          specs: ['macOS 14.0+ / Apple Silicon', 'Static Maps + 外部導航', 'Developer ID 公證 DMG', '無廣告 / 相簿選圖降級'],
          cliLabel: '於 macOS 執行或打包簽章公證 DMG',
          cliCommand:
            'git clone https://github.com/Yomiamy/Finding-Restaurant-Flutter.git\ncd Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant\nflutter pub get && flutter run -d macos\n# 選配打包公證 DMG：./scripts/release_macos.sh -p "notary-profile"',
          copyLabel: '複製指令',
          copiedLabel: '已複製 macOS 建置指令至剪貼簿',
          fallbackLabel: '瀏覽器不支援自動寫入剪貼簿，已為您反白指令',
        },
      },
      ctaSource: '前往 GitHub 檢視原始碼',
      ctaGuide: '閱讀繁中說明文件',
      ctaReleases: 'Releases 發布頁',
      canvasCaption: '25.048°N, 121.517°E · 城市美食探索雷達',
      canvasTitle: '城市美食探索座標網',
    },
    stratum1: {
      depth: 'STRATUM 01 // 核心體驗',
      eyebrow: '6 組實測畫面 · 互動功能鏡頭',
      title: '每個鏡頭皆一對一對應真實 App 實機截圖。',
      lead: '在寬螢幕捲動頁面時畫面將自動隨閱讀深度切換；於任何裝置皆可直接點擊鏡頭標籤或以鍵盤方向鍵瀏覽 6 大核心能力。',
      tablistLabel: '產品核心功能鏡頭切換',
      lenses: [
        {
          id: 'lens-01',
          code: '01',
          title: '首頁餐廳空間探索',
          subtitle: 'Yelp Fusion 即時搜尋與地圖切換',
          description:
            '結合定位探索、Yelp Autocomplete 即時搜尋補全、卡片流與地圖標記雙模切換，一眼掌握距離、消費價位、營業狀態與評分星等。',
          image: '/screenshots/home.webp',
          alt: 'Find Restaurant 首頁餐廳探索畫面，展示附近店家列表、星等評分與搜尋框',
          caption: 'Lens 01 — 由 MainBloc 與 Yelp Fusion API 驅動的探索首頁。',
        },
        {
          id: 'lens-02',
          code: '02',
          title: 'AI 智能覓食助理（GenUI）',
          subtitle: '接地真實候選店的 A2UI 決策畫布',
          description:
            '以自然語言描述聚餐人數、氛圍或預算，Gemini 嚴格從已載入的周邊真實店家挑選比對，輸出結構化對比矩陣與快捷行動標籤，杜絕憑空編造店名。',
          image: '/screenshots/ai-assistant.webp',
          alt: 'AI 智能覓食助理畫面，顯示自然語言推薦與結構化餐廳對比卡片',
          caption: 'Lens 02 — 以 comparison_matrix 與 action_chip_group 直接連動真實 Yelp 店家 ID。',
        },
        {
          id: 'lens-03',
          code: '03',
          title: '命運大轉盤',
          subtitle: '終結聚餐選擇困難的自繪轉盤',
          description:
            '當候選名單勢均力敵時，可由 AI 助理的快捷按鈕一鍵帶入或手動挑選 2 至 4 間餐廳，透過流暢轉盤動畫拍板最終目的地。',
          image: '/screenshots/roulette.webp',
          alt: '命運大轉盤畫面，將多間候選餐廳置入轉盤進行隨機抽選',
          caption: 'Lens 03 — 解析 decision_roulette 元件酬載並渲染自繪抽選轉盤。',
        },
        {
          id: 'lens-04',
          code: '04',
          title: 'AI 菜單視覺翻譯',
          subtitle: '多模態菜色翻譯與過敏原標註',
          description:
            '拍下或挑選外文菜單照片，Gemini 透過結構化 Schema 辨識菜名、價格與食材組成，主動標出堅果、花生、蛋、奶、麩質、甲殼類與大豆等 7 大過敏原。',
          image: '/screenshots/menu-vision.webp',
          alt: 'AI 菜單視覺翻譯畫面，顯示翻譯後菜名與高亮顯示的過敏原標籤',
          caption: 'Lens 04 — 多模態 JSON 輸出嚴格映射為 DishItemEntity 與 AllergenInfo。',
        },
        {
          id: 'lens-05',
          code: '05',
          title: '餐廳詳情、導航與街景',
          subtitle: 'Firestore 口袋收藏與外部地圖連動',
          description:
            '完整檢視營業時間、電話、預覽地圖與一鍵跳轉 Google Maps 導航／街景，並透過 Firestore Subcollection 原子化同步個人收藏清單。',
          image: '/screenshots/navigation.webp',
          alt: '餐廳詳情畫面，展示地圖預覽、導航街景按鈕與收藏操作',
          caption: 'Lens 05 — FavorDataSource Subcollection 收藏同步與外部地圖街景啟動。',
        },
        {
          id: 'lens-06',
          code: '06',
          title: '多元登入與訪客模式',
          subtitle: 'Google、Apple、Email 與生物辨識',
          description:
            '整合 Google、條件式 Sign in with Apple、Email 註冊與 Face ID／指紋自動登入，並提供免登入訪客模式以零門檻體驗完整探索功能。',
          image: '/screenshots/login.webp',
          alt: '多元登入畫面，提供 Email、Google、Apple、生物辨識與訪客體驗入口',
          caption:
            'Lens 06 — SignInBloc 透過 SignInRepository 委派 SignInManager 協調 6 個子認證 Manager（Google / Apple / Facebook / Mail / Biometric / Auto；全 App 共 9 個 Manager）。',
        },
      ],
    },
    stratum2: {
      depth: 'STRATUM 02 // 多模態 AI 引擎',
      eyebrow: 'Firebase AI Logic · Gemini 結構化輸出',
      title: '以型別契約取代脆弱的自然語言提示詞解析。',
      lead: '所有 AI 功能皆採強制 Schema 與領域 Entity 映射，從源頭消滅幻覺 ID、冗長複讀與未定義欄位污染 UI。',
      cards: [
        {
          tag: 'GenUI / A2UI',
          title: '真實店家接地決策畫布',
          symbol: 'A2UIComponent (sealed)',
          description:
            '將對話回覆拆分為 80 字內情境引言與結構化元件外殼（comparison_matrix、action_chip_group、decision_roulette），嚴格限定僅能引用當下真實載入的周邊店家 ID。',
          bullets: [
            '零幻覺 ID：每張推薦卡片皆可直接跳轉店家詳情頁',
            '硬性元件數量與字數上限，防止傳輸酬載超限與自我複讀',
            '以 Dart 3 sealed class 分派器確保型別窮盡安全',
          ],
        },
        {
          tag: '決策收斂',
          title: '互動式命運轉盤接力',
          symbol: 'decision_roulette',
          description:
            '當橫向對比收斂出 2～4 家高匹配候選店時，AI 助理可直接生成轉盤酬載，讓同桌夥伴在幾秒內完成最終拍板。',
          bullets: [
            '渲染前強制檢查至少 2 個有效非空選項',
            '與 action_chip_group 連動，支援一鍵追問或開轉',
            '資料不足時安全退回純文字建議，不硬產出空元件',
          ],
        },
        {
          tag: '多模態視覺',
          title: '菜單成分拆解與過敏原偵測',
          symbol: 'DishItemEntity + AllergenInfo',
          description:
            '針對外語菜單照片執行結構化視覺分析，同時產出菜名翻譯、預估價位與 7 類常見致敏食材警示，降低異地用餐風險。',
          bullets: [
            '跨平台輸入隔離：行動端支援相機直拍，macOS 優雅降級相簿選圖',
            '明確標示堅果、花生、蛋、牛奶、小麥麩質、甲殼類與大豆',
            '由 MenuVisionBloc 集中完成 nullable entity 至 UI model 投影',
          ],
        },
        {
          tag: '評論情報',
          title: '防注入顧客短評智慧摘要',
          symbol: 'ReviewSummaryEntity',
          description:
            '從顧客短評客觀提煉優點（Pros）、避雷點（Cons）、招牌亮點與 40 字內總結，搭配零評論短路與隔離標籤防護。',
          bullets: [
            '外來評論文本包覆安全隔離標籤，防範間接 Prompt Injection',
            '無評論店家直接短路，不浪費多餘推論成本',
            '獨立 ReviewSummaryCard 狀態機支援骨架屏與失敗重試',
          ],
        },
      ],
    },
    stratum3: {
      depth: 'STRATUM 03 // 架構與治理原則',
      eyebrow: 'Clean Architecture · 跨平台閘門 · 誠實邊界',
      title: '單向依賴、能力閘門與金鑰安全的務實取捨。',
      lead: '將領域契約與平台實作細節清楚切分，讓 Android、iOS、macOS 共享同一核心業務模型，同時誠實面對 Web 與金鑰邊界。',
      archHeading: '清晰分層與狀態管理邊界',
      archLayers: [
        {
          layer: 'Presentation',
          title: 'BLoC vs. setState 硬性邊界',
          summary:
            '凡存取 Repository 或處理非同步狀態機的頁面與 BottomSheet 一律使用 BLoC（flutter_bloc ^9.1.1），由 routesTable 統一注入或支援可選本地注入（MenuVisionSheet／AiFoodieSheet／NoteRestaurantSummarySheet）；setState 僅限純本地表單與控制器狀態。',
        },
        {
          layer: 'Domain',
          title: '純淨介面與 Sealed 狀態機',
          summary:
            '13 個領域 Repository 介面契約（涵蓋 Yelp、AI、收藏、認證、設定與 UGC 筆記，包含 12 個 abstract interface class 與 UgcNoteRepository 抽象基底類）完全不依賴 Dio、Firestore 或 SharedPreferences，配合 Dart 3 sealed class 與 GetIt 懶載入單例反轉依賴方向。',
        },
        {
          layer: 'Data',
          title: 'DTO 封裝與單一資料存取點',
          summary:
            'Retrofit + Dio（dio ^5.6.0）對接 Yelp Fusion REST API，FavorDataSource（favors/{uid}/items）與 UgcNoteDataSource（ugc_notes）隔離所有 Firestore 讀寫。',
        },
      ],
      matrixHeading: '單一事實來源 platformCapabilities() 跨平台矩陣',
      matrixColumns: {
        capability: '系統能力',
        mobile: 'iOS 15+ 與 Android',
        macos: 'macOS 14+（DMG / App）',
        reason: '架構判斷依據',
      },
      capabilities: [
        {
          capability: '互動地圖與列表／地圖模式切換',
          mobile: '完整 Google Maps SDK',
          macos: 'Static Maps + 外部地圖跳轉',
          reason: 'google_maps_flutter 主打行動平台，桌面端改以靜態地圖預覽結合瀏覽器導航與街景',
        },
        {
          capability: 'Menu Vision 相機拍照',
          mobile: '即時相機 + 相簿選圖',
          macos: '僅限相簿選圖',
          reason: '規避 macOS 未設 cameraDelegate 的 StateError，同時完整保留 AI 菜單翻譯能力',
        },
        {
          capability: 'Sign in with Apple',
          mobile: 'iOS 原生啟用',
          macos: 'Developer ID DMG 自動隱藏',
          reason: 'Apple 僅授權 Mac App Store 分發啟用 applesignin capability（DEVELOPER_ID_BUILD=true）',
        },
        {
          capability: 'AdMob 廣告與 FCM 推播',
          mobile: '完整啟用（50dp 防突跳底部橫幅）',
          macos: '優雅停用',
          reason: 'AdMob 套件僅支援行動端，桌面版保持無廣告干擾工作流',
        },
      ],
      securityHeading: 'Remote Config 治理與不直連 Web 的誠實原因',
      securityPrinciples: [
        {
          title: '無硬編碼金鑰 ＋ 遠端 AI 模型治理',
          detail:
            'AiModelConfig 啟動時透過 Firebase Remote Config 取得 Gemini 模型名稱、temperature、系統提示詞以及 yelp_api_auth_token / static_map_api_key，AI 參數並內建安全本地預設值。',
        },
        {
          title: '為何以 Astro 承載官網（而非直接編譯 Flutter Web）',
          detail:
            'Yelp Fusion API 不支援瀏覽器端 CORS，若於前端直連將導致請求被擋且暴露 API Token；在尚未建置 Server-side Broker 前，採用純靜態 Astro 官網能兼顧首屏速度、SEO 與 Spark 免費方案。',
        },
      ],
      evolutionHeading: '近期主幹演進（誠實揭露尚無截圖之新能力）',
      evolutionBadge: '已合入 main · 待補拍實機截圖',
      evolutionBody:
        '近期 main 主幹亦已落地雙排瀑布流 UGC 探店筆記（NotesFeedPage／NoteDetailPage，支援 15 秒短影片與地點打卡摘要彈窗）以及擴充版搜尋篩選器（FilterCuisineBloc、40 公里搜尋半徑晶片與「僅看營業中」開關）。為堅持不捏造假圖原則，本版暫於工程脈絡章節如實說明，待後續補拍實機截圖後再擴充鏡頭。',
    },
    closing: {
      eyebrow: '原始碼驅動 · 誠實開源分發',
      title: '查閱每一層設計、在本機建置，或親自打包 macOS DMG。',
      lead: '為遵守 Firebase Spark 每日 360 MB 頻寬上限並避免過期二進位檔誤導，本站不託管 .apk 或 .dmg 安裝檔；請直接複製 GitHub 原始碼建置，或關注未來 GitHub Releases 正式版本。',
      ctaRepo: '前往 GitHub Repository',
      ctaMacGuide: 'macOS 簽章與公證發布手冊',
      ctaReleases: 'GitHub Releases 發布入口',
    },
    footer: {
      tagline: 'Find Restaurant（尋找餐廳）— Clean Architecture Flutter 產品官網',
      versionText: '基線 main @ 843aaecc · App v2.4.0+40',
      licenseNote: '本靜態官網託管於 Firebase Hosting（Spark 方案），完整原始碼公開於 GitHub。',
      links: [
        { label: 'GitHub 專案', href: SITE_META.repoUrl },
        { label: '繁中 README', href: SITE_META.readmeZhUrl },
        { label: 'macOS 發布手冊', href: SITE_META.macosGuideUrl },
        { label: 'Releases', href: SITE_META.releasesUrl },
      ],
    },
  },
};

export function buildSoftwareApplicationJsonLd(locale: Locale): Record<string, unknown> {
  const data = SITE_DATA[locale];
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'Find Restaurant',
    applicationCategory: 'LifestyleApplication',
    operatingSystem: 'Android, iOS, macOS 14+',
    softwareVersion: SITE_META.appVersion,
    description: data.seo.description,
    url: `${SITE_META.baseUrl}${data.canonicalPath}`,
    codeRepository: SITE_META.repoUrl,
    isAccessibleForFree: true,
    inLanguage: data.htmlLang,
    offers: {
      '@type': 'Offer',
      price: '0',
      priceCurrency: 'USD',
    },
  };
}
```

- [ ] **Step 4：執行測試確認通過（TDD Green）**

```bash
cd website && node --test test/site-data.test.mjs
```

**預期輸出：** exit code `0`，3 項測試全數通過（`pass 3, fail 0`）。

- [ ] **Step 5：建立設計系統樣式表 `website/src/styles/global.css` 與共用排版 `website/src/layouts/BaseLayout.astro`**

建立 `website/src/styles/global.css`：

```css
:root {
  --bg: #fffbf7;
  --surface: #ffffff;
  --surface-alt: #f7efe7;
  --ink: #1f1713;
  --ink-muted: #63544b;
  --accent: #d84a20;
  --accent-ink: #b83b16;
  --accent-fill: #b83b16;
  --accent-fill-hover: #992e0f;
  --on-accent: #fffbf7;
  --accent-soft: rgba(216, 74, 32, 0.1);
  --border: rgba(31, 23, 19, 0.12);
  --code-bg: #231915;
  --code-ink: #faf4ee;
  --shadow: 0 20px 48px rgba(31, 23, 19, 0.08);
  --radius-lg: 20px;
  --radius-md: 12px;
  --max-w: 1160px;
  --font-sans: ui-sans-serif, system-ui, -apple-system, 'PingFang TC', 'Noto Sans TC',
    'Segoe UI', sans-serif;
  --font-mono: ui-monospace, 'SF Mono', Menlo, Monaco, Consolas, monospace;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #14100e;
    --surface: #1e1714;
    --surface-alt: #281f1b;
    --ink: #faf4ee;
    --ink-muted: #c0b1a7;
    --accent: #f06a3e;
    --accent-ink: #ff835b;
    --accent-fill: #f06a3e;
    --accent-fill-hover: #ff835b;
    --on-accent: #14100e;
    --accent-soft: rgba(240, 106, 62, 0.16);
    --border: rgba(250, 244, 238, 0.14);
    --code-bg: #0f0b0a;
    --code-ink: #faf4ee;
    --shadow: 0 22px 52px rgba(0, 0, 0, 0.42);
  }
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
  background-color: var(--bg);
  color: var(--ink);
  font-family: var(--font-sans);
  line-height: 1.65;
  -webkit-font-smoothing: antialiased;
}

@media (prefers-reduced-motion: reduce) {
  html {
    scroll-behavior: auto;
  }
}

body {
  margin: 0;
  background-color: var(--bg);
  color: var(--ink);
}

a {
  color: var(--accent-ink);
  text-underline-offset: 3px;
}

a:focus-visible,
button:focus-visible {
  outline: 2px solid var(--accent-ink);
  outline-offset: 3px;
}

.skip-link {
  position: absolute;
  left: -9999px;
  top: 0;
  background: var(--accent-fill);
  color: var(--on-accent);
  padding: 0.65rem 1rem;
  font-weight: 700;
  z-index: 100;
}

.skip-link:focus {
  left: 1rem;
  top: 1rem;
  border-radius: 8px;
}

.wrap {
  width: 100%;
  max-width: var(--max-w);
  margin: 0 auto;
  padding-inline: 1.5rem;
}

/* Header Navigation Bar */
.bar {
  position: sticky;
  top: 0;
  z-index: 50;
  border-bottom: 1px solid var(--border);
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(12px);
}

.bar-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  min-height: 4rem;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  text-decoration: none;
  color: var(--ink);
  font-weight: 800;
  letter-spacing: -0.02em;
  white-space: nowrap;
}

.brand img {
  width: 30px;
  height: 30px;
  border-radius: 8px;
}

.brand-sub {
  font-family: var(--font-mono);
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--accent-ink);
  background: var(--accent-soft);
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
}

.bar-nav {
  display: flex;
  align-items: center;
  gap: clamp(0.75rem, 1.4vw, 1.25rem);
}

.bar-nav a {
  text-decoration: none;
  color: var(--ink-muted);
  font-size: 0.92rem;
  font-weight: 600;
  white-space: nowrap;
}

.bar-nav a:hover {
  color: var(--ink);
}

.bar-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-shrink: 0;
}

.lang-switch {
  display: inline-flex;
  flex-shrink: 0;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 2px;
  background: var(--surface);
}

.lang-switch a {
  padding: 0.25rem 0.65rem;
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 700;
  text-decoration: none;
  color: var(--ink-muted);
  white-space: nowrap;
}

.lang-switch a[aria-current='page'] {
  background: var(--accent-fill);
  color: var(--on-accent);
}

.gh-pill {
  padding: 0.35rem 0.85rem;
  border-radius: 999px;
  border: 1px solid var(--border);
  font-size: 0.85rem;
  font-weight: 700;
  text-decoration: none;
  color: var(--ink);
  background: var(--surface);
  white-space: nowrap;
}

.gh-pill:hover {
  border-color: var(--accent);
  color: var(--accent-ink);
}

/* Hero Section */
.hero {
  padding-block: 3.5rem 4rem;
}

.hero-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
  gap: 2.5rem;
  align-items: center;
}

.hero-copy,
.stratum-body,
.os-box,
.card {
  min-width: 0;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-family: var(--font-mono);
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--accent-ink);
  background: var(--accent-soft);
  padding: 0.3rem 0.8rem;
  border-radius: 999px;
  margin-bottom: 1rem;
}

.hero h1 {
  margin: 0 0 1rem;
  font-size: clamp(2rem, 4vw, 3.15rem);
  line-height: 1.14;
  letter-spacing: -0.03em;
}

.hero h1 span {
  color: var(--accent);
}

.lead {
  margin: 0 0 1.75rem;
  color: var(--ink-muted);
  font-size: 1.08rem;
  max-width: 60ch;
}

/* OS Switcher & CLI Card */
.os-box {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  box-shadow: var(--shadow);
}

.os-switch {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  padding: 0.3rem;
  background: var(--surface-alt);
  border-radius: 12px;
  margin-bottom: 1rem;
}

.os-btn {
  appearance: none;
  border: 0;
  background: transparent;
  color: var(--ink-muted);
  font-family: var(--font-sans);
  font-size: 0.9rem;
  font-weight: 700;
  padding: 0.5rem 0.95rem;
  border-radius: 9px;
  cursor: pointer;
  transition: background-color 0.16s ease, color 0.16s ease;
}

html[data-js='1'][data-os='mobile'] .os-btn[data-os='mobile'],
html[data-js='1'][data-os='macos'] .os-btn[data-os='macos'],
html:not([data-js='1']) .os-btn[aria-pressed='true'] {
  background: var(--accent-fill);
  color: var(--on-accent);
}

html[data-js='1'][data-os='mobile'] [data-os-panel='macos'],
html[data-js='1'][data-os='macos'] [data-os-panel='mobile'] {
  display: none;
}

.os-panel + .os-panel {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px dashed var(--border);
}

html[data-js='1'] .os-panel + .os-panel {
  margin-top: 0;
  padding-top: 0;
  border-top: 0;
}

.os-panel-meta {
  font-family: var(--font-mono);
  font-size: 0.78rem;
  color: var(--accent-ink);
  font-weight: 700;
  margin: 0 0 0.25rem;
}

.os-panel h2,
.os-panel h3 {
  margin: 0 0 0.4rem;
  font-size: 1.12rem;
}

.os-panel p {
  margin: 0 0 0.85rem;
  font-size: 0.94rem;
  color: var(--ink-muted);
}

.spec-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.45rem;
  list-style: none;
  padding: 0;
  margin: 0 0 1rem;
}

.spec-chips li {
  font-family: var(--font-mono);
  font-size: 0.76rem;
  font-weight: 600;
  padding: 0.25rem 0.6rem;
  border-radius: 999px;
  background: var(--surface-alt);
  border: 1px solid var(--border);
}

.cli-label {
  display: block;
  font-size: 0.82rem;
  font-weight: 700;
  color: var(--ink-muted);
  margin-bottom: 0.4rem;
}

.cli-wrap {
  background: var(--code-bg);
  color: var(--code-ink);
  border-radius: var(--radius-md);
  padding: 0.85rem 1rem;
}

.cli-wrap pre {
  margin: 0;
  overflow-x: auto;
  font-family: var(--font-mono);
  font-size: 0.82rem;
  line-height: 1.55;
}

.cli-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: 0.75rem;
}

.copy-btn {
  appearance: none;
  border: 1px solid rgba(250, 244, 238, 0.24);
  background: rgba(250, 244, 238, 0.08);
  color: var(--code-ink);
  font-family: var(--font-mono);
  font-size: 0.8rem;
  font-weight: 700;
  padding: 0.4rem 0.85rem;
  border-radius: 8px;
  cursor: pointer;
}

.copy-btn:hover {
  background: var(--accent-fill);
  border-color: var(--accent-fill);
  color: var(--on-accent);
}

.copy-btn:focus-visible {
  outline: 2px solid #ff9c7d;
  outline-offset: 3px;
}

.copy-status {
  font-size: 0.82rem;
  color: #ff9c7d;
  min-height: 1.2em;
}

.hero-cta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.btn-primary,
.btn-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.72rem 1.2rem;
  border-radius: 12px;
  font-weight: 700;
  font-size: 0.94rem;
  text-decoration: none;
}

.btn-primary {
  background: var(--accent-fill);
  color: var(--on-accent);
}

.btn-primary:hover {
  background: var(--accent-fill-hover);
  color: var(--on-accent);
}

.btn-secondary {
  background: var(--surface);
  color: var(--ink);
  border: 1px solid var(--border);
}

.btn-secondary:hover {
  border-color: var(--accent);
  color: var(--accent-ink);
}

/* Shoal Canvas */
.shoal {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 1rem;
  box-shadow: var(--shadow);
}

.shoal-head {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: 0.25rem 0.75rem;
  font-family: var(--font-mono);
  font-size: 0.76rem;
  color: var(--ink-muted);
  margin-bottom: 0.65rem;
}

.shoal-canvas {
  display: block;
  width: 100%;
  aspect-ratio: 4 / 3.6;
  border-radius: 14px;
  background: var(--surface-alt);
}

/* Strata Dividers & Rulers */
.strata {
  border: 0;
  border-top: 1px solid var(--border);
  margin: 0;
}

.stratum {
  padding-block: 4.25rem;
}

.stratum-shell {
  display: grid;
  grid-template-columns: 200px minmax(0, 1fr);
  gap: 2.25rem;
  align-items: start;
}

.ruler {
  position: sticky;
  top: 5.5rem;
  border-left: 2px solid var(--accent);
  padding-left: 0.9rem;
}

.depth {
  display: block;
  font-family: var(--font-mono);
  font-size: 0.76rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: var(--accent-ink);
}

.stratum-head h2 {
  margin: 0.35rem 0 0.75rem;
  font-size: clamp(1.55rem, 2.8vw, 2.2rem);
  line-height: 1.22;
  letter-spacing: -0.02em;
}

.stratum-head p {
  margin: 0 0 2rem;
  color: var(--ink-muted);
  max-width: 66ch;
}

/* Scrollytelling Showcase */
.scrolly {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(260px, 340px);
  gap: 2.25rem;
  align-items: start;
}

.lenses {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}

.lens {
  appearance: none;
  text-align: left;
  width: 100%;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: 1.25rem 1.35rem;
  cursor: pointer;
  color: var(--ink);
  transition: border-color 0.18s ease, background-color 0.18s ease, transform 0.18s ease;
}

.lens:hover {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
}

.lens[aria-selected='true'] {
  border-color: var(--accent);
  background: var(--surface-alt);
  box-shadow: 0 10px 26px rgba(216, 74, 32, 0.12);
}

.lens-top {
  display: flex;
  align-items: baseline;
  gap: 0.65rem;
  margin-bottom: 0.35rem;
}

.lens-code {
  font-family: var(--font-mono);
  font-size: 0.8rem;
  font-weight: 800;
  color: var(--accent-ink);
}

.lens-title {
  font-size: 1.08rem;
  font-weight: 800;
}

.lens-sub {
  display: block;
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--accent-ink);
  margin-bottom: 0.45rem;
}

.lens-desc {
  display: block;
  font-size: 0.93rem;
  color: var(--ink-muted);
}

.lens-stack {
  position: sticky;
  top: 5.5rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 26px;
  padding: 0.95rem;
  box-shadow: var(--shadow);
}

.lens-viewport {
  position: relative;
  width: 100%;
  aspect-ratio: 9 / 20;
  border-radius: 18px;
  overflow: hidden;
  background: #14100e;
}

.lens-panel {
  margin: 0;
  position: absolute;
  inset: 0;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.22s ease;
}

.lens-panel[aria-hidden='false'] {
  opacity: 1;
  visibility: visible;
  z-index: 2;
}

.lens-panel img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.lens-caption {
  margin-top: 0.75rem;
  font-size: 0.82rem;
  color: var(--ink-muted);
  min-height: 2.6em;
}

/* AI & Architecture Cards */
.card-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1.25rem;
}

.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 1.4rem;
}

.card-tag {
  font-family: var(--font-mono);
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--accent-ink);
  text-transform: uppercase;
}

.card h3,
.card h4 {
  margin: 0.35rem 0 0.35rem;
  font-size: 1.15rem;
}

.card-symbol {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 0.78rem;
  background: var(--surface-alt);
  padding: 0.18rem 0.5rem;
  border-radius: 6px;
  margin-bottom: 0.75rem;
}

.card p {
  margin: 0 0 0.85rem;
  font-size: 0.94rem;
  color: var(--ink-muted);
}

.card ul {
  margin: 0;
  padding-left: 1.15rem;
  font-size: 0.9rem;
  color: var(--ink);
}

.card li + li {
  margin-top: 0.35rem;
}

.arch-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.sub-heading {
  margin: 0 0 1rem;
  font-size: 1.25rem;
}

.table-wrap {
  overflow-x: auto;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  margin-bottom: 2rem;
}

.cap-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
  text-align: left;
}

.cap-table th,
.cap-table td {
  padding: 0.9rem 1rem;
  border-bottom: 1px solid var(--border);
  vertical-align: top;
}

.cap-table th {
  background: var(--surface-alt);
  font-weight: 800;
}

.cap-table tr:last-child td {
  border-bottom: 0;
}

.evolution-box {
  margin-top: 1.75rem;
  background: var(--surface-alt);
  border: 1px solid color-mix(in srgb, var(--accent) 40%, var(--border));
  border-radius: var(--radius-lg);
  padding: 1.35rem 1.5rem;
}

.evolution-box p {
  margin: 0.5rem 0 0;
  color: var(--ink-muted);
}

/* Closing & Footer */
.closing {
  padding-block: 4rem;
  background: var(--surface-alt);
  border-top: 1px solid var(--border);
}

.closing-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 2rem;
  align-items: start;
}

.closing h2 {
  margin: 0.35rem 0 0.75rem;
  font-size: clamp(1.5rem, 2.6vw, 2.1rem);
  line-height: 1.24;
}

.foot {
  border-top: 1px solid var(--border);
  padding-block: 2.25rem;
  font-size: 0.88rem;
  color: var(--ink-muted);
}

.foot-inner {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: 1.25rem;
}

.foot-links {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1.15rem;
}

.foot-links a {
  color: var(--ink);
  font-weight: 600;
  text-decoration: none;
}

.foot-links a:hover {
  color: var(--accent-ink);
}

@media (max-width: 960px) {
  .bar-nav {
    display: none;
  }

  .hero-grid,
  .stratum-shell,
  .scrolly,
  .closing-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .ruler {
    position: static;
    border-left: 0;
    border-bottom: 2px solid var(--accent);
    padding-left: 0;
    padding-bottom: 0.5rem;
  }

  .lens-stack {
    position: static;
    order: -1;
    max-width: 340px;
    width: 100%;
    margin-inline: auto;
  }

  .lens-viewport {
    width: min(100%, calc(46vh * 9 / 20));
    aspect-ratio: 9 / 20;
    margin-inline: auto;
  }

  .card-grid,
  .arch-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 560px) {
  .wrap {
    padding-inline: 1rem;
  }

  .bar-inner {
    min-height: 3.5rem;
    gap: 0.5rem;
  }

  .brand {
    min-width: 0;
    font-size: 0.94rem;
  }

  .brand-sub,
  .gh-pill {
    display: none;
  }
}
```

建立 `website/src/layouts/BaseLayout.astro`：

```astro
---
import '../styles/global.css';
import {
  SITE_META,
  buildSoftwareApplicationJsonLd,
  type Locale,
  type SiteLocaleData,
} from '../data/site';

interface Props {
  locale: Locale;
  data: SiteLocaleData;
}

const { locale, data } = Astro.props;
const canonicalUrl = `${SITE_META.baseUrl}${data.canonicalPath}`;
const enUrl = `${SITE_META.baseUrl}/`;
const zhTwUrl = `${SITE_META.baseUrl}/zh-tw/`;
const ogImageUrl = `${SITE_META.baseUrl}${SITE_META.ogImagePath}`;

const safeJsonLd = JSON.stringify(buildSoftwareApplicationJsonLd(locale))
  .replace(/</g, '\\u003c')
  .replace(/>/g, '\\u003e')
  .replace(/&/g, '\\u0026');
---

<!doctype html>
<html lang={data.htmlLang}>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{data.seo.title}</title>
    <meta name="description" content={data.seo.description} />
    <meta name="theme-color" content="#FFFBF7" media="(prefers-color-scheme: light)" />
    <meta name="theme-color" content="#14100E" media="(prefers-color-scheme: dark)" />
    <link rel="icon" type="image/png" href={SITE_META.faviconPath} />
    <link rel="canonical" href={canonicalUrl} />
    <link rel="alternate" hreflang="en" href={enUrl} />
    <link rel="alternate" hreflang="zh-Hant-TW" href={zhTwUrl} />
    <link rel="alternate" hreflang="x-default" href={enUrl} />

    <meta property="og:type" content="website" />
    <meta property="og:site_name" content="Find Restaurant" />
    <meta property="og:title" content={data.seo.ogTitle} />
    <meta property="og:description" content={data.seo.ogDescription} />
    <meta property="og:url" content={canonicalUrl} />
    <meta property="og:locale" content={data.ogLocale} />
    <meta property="og:locale:alternate" content={data.ogLocaleAlternate} />
    <meta property="og:image" content={ogImageUrl} />
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta property="og:image:alt" content={data.seo.ogImageAlt} />

    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={data.seo.ogTitle} />
    <meta name="twitter:description" content={data.seo.ogDescription} />
    <meta name="twitter:image" content={ogImageUrl} />

    <script type="application/ld+json" set:html={safeJsonLd}></script>
    <script is:inline>
      (() => {
        // Single OS detection rule (kept aligned with src/scripts/showcase.ts detectOsFromAgent;
        // inline script only prevents first-paint FOUC).
        const root = document.documentElement;
        root.dataset.js = '1';
        let os = '';
        try {
          const saved = localStorage.getItem('fr-os-pref');
          if (saved === 'mobile' || saved === 'macos') os = saved;
        } catch {}
        if (!os) {
          const plat =
            (navigator.userAgentData && navigator.userAgentData.platform) ||
            navigator.platform ||
            '';
          const ua = navigator.userAgent || '';
          const isMobile =
            /iPhone|iPad|iPod|Android/i.test(plat) ||
            /iPhone|iPad|iPod|Android|Mobile/i.test(ua) ||
            (/Mac/i.test(plat) && navigator.maxTouchPoints > 1);
          os =
            !isMobile &&
            (/macOS|MacIntel|MacPPC|MacArm/i.test(plat) || /Macintosh|Mac OS X/i.test(ua))
              ? 'macos'
              : 'mobile';
        }
        root.dataset.os = os;
      })();
    </script>
  </head>
  <body>
    <a class="skip-link" href="#main-content">{data.skipToContent}</a>
    <slot />
  </body>
</html>
```

- [ ] **Step 6：檢查檔案結構並再跑資料測試**

```bash
cd website && node --test test/site-data.test.mjs
```

**預期輸出：** exit code `0`，3 項測試全數通過。

---

### Task 3：Firebase Hosting 獨立配置與專屬 GitHub Actions 工作流 `[快/便宜]`

> **並行註記：** Task 3 與 Task 2 寫入路徑完全互斥且無程式碼依賴，可於 Task 1 完成後**並行執行**。

**Files:**
- Create: `website/.firebaserc`
- Create: `website/firebase.json`
- Create: `.github/workflows/website.yml`

**Interfaces:**
- Consumes: Task 1 確立之產物目錄 `website/dist/`、`/_astro/*` 及 `/screenshots/*` 路徑約定
- Produces:
  - Firebase Hosting 設定（專案 ID `findrestaurant-c80ea`、Spark 長效快取 header、不包含任何 `flutter` 平台鍵）
  - CI/CD 工作流 `.github/workflows/website.yml`（僅於 `website/**` 或自身變動觸發；PR 與 push 執行 `npm ci` + `npm run build` + `npm test`；僅 `push` `main` 且具備 `FIREBASE_SERVICE_ACCOUNT_FINDRESTAURANT_C80EA` secret 時才執行 `npx --yes firebase-tools@15 deploy --only hosting --project findrestaurant-c80ea`，未設定時輸出指引至 `GITHUB_STEP_SUMMARY`）

- [ ] **Step 1：建立 `website/.firebaserc` 與 `website/firebase.json`**

建立 `website/.firebaserc`：

```json
{
  "projects": {
    "default": "findrestaurant-c80ea"
  }
}
```

建立 `website/firebase.json`：

```json
{
  "hosting": {
    "public": "dist",
    "ignore": [
      "firebase.json",
      ".firebaserc",
      "**/.*",
      "**/node_modules/**",
      "src/**",
      "scripts/**",
      "test/**"
    ],
    "headers": [
      {
        "source": "/_astro/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "/screenshots/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=2592000, stale-while-revalidate=86400"
          }
        ]
      },
      {
        "source": "/favicon.png",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=604800"
          }
        ]
      },
      {
        "source": "/og-card.png",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=604800"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2：建立專屬 CI/CD 工作流 `.github/workflows/website.yml`**

建立 `.github/workflows/website.yml`：

```yaml
name: Website CI & Hosting

on:
  pull_request:
    branches: [main]
    paths:
      - 'website/**'
      - '.github/workflows/website.yml'
  push:
    branches: [main]
    paths:
      - 'website/**'
      - '.github/workflows/website.yml'

permissions:
  contents: read

concurrency:
  group: website-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  build-and-verify:
    name: Build & Verify Static Site
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: website
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5

      - name: Setup Node.js
        uses: actions/setup-node@v5
        with:
          node-version: '24'
          cache: 'npm'
          cache-dependency-path: website/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Build Astro static site
        run: npm run build

      - name: Run static verification tests
        run: npm test

      - name: Deploy to Firebase Hosting (main only)
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        env:
          FIREBASE_SA_JSON: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_FINDRESTAURANT_C80EA }}
        run: |
          if [ -z "$FIREBASE_SA_JSON" ]; then
            {
              echo "### Firebase Hosting Deploy Skipped"
              echo ""
              echo "Secret \`FIREBASE_SERVICE_ACCOUNT_FINDRESTAURANT_C80EA\` is not configured."
              echo ""
              echo "To enable automated deployment on \`main\`:"
              echo "1. Create a Service Account JSON with **Firebase Hosting Admin** (\`roles/firebasehosting.admin\`) and **API Keys Viewer** (\`roles/serviceusage.apiKeysViewer\`) permissions for project \`findrestaurant-c80ea\`."
              echo "2. Save it in GitHub **Settings → Secrets and variables → Actions** as \`FIREBASE_SERVICE_ACCOUNT_FINDRESTAURANT_C80EA\`."
            } >> "$GITHUB_STEP_SUMMARY"
            exit 0
          fi

          CRED_FILE="$(mktemp)"
          chmod 600 "$CRED_FILE"
          trap 'rm -f "$CRED_FILE"' EXIT
          printf '%s' "$FIREBASE_SA_JSON" > "$CRED_FILE"
          export GOOGLE_APPLICATION_CREDENTIALS="$CRED_FILE"
          npx --yes firebase-tools@15 deploy --only hosting --project findrestaurant-c80ea --non-interactive
```

- [ ] **Step 3：驗證 JSON/YAML 語法與關鍵契約（嚴禁執行 `firebase deploy`）**

於 `<WORKTREE_ROOT>` 執行：

```bash
node -e "
  import('node:fs').then(fs => {
    const rc = JSON.parse(fs.readFileSync('website/.firebaserc', 'utf8'));
    const fb = JSON.parse(fs.readFileSync('website/firebase.json', 'utf8'));
    if (rc.projects?.default !== 'findrestaurant-c80ea') throw new Error('bad .firebaserc');
    if (fb.hosting?.public !== 'dist' || 'flutter' in fb) throw new Error('bad firebase.json');
    const sources = fb.hosting.headers.map(h => h.source);
    for (const req of ['/_astro/**', '/screenshots/**', '/favicon.png', '/og-card.png']) {
      if (!sources.includes(req)) throw new Error('missing cache header: ' + req);
    }
    console.log('Firebase config validated OK');
  });
"
ruby -ryaml -e "
  wf = YAML.load_file('.github/workflows/website.yml');
  triggers = wf['on'] || wf[true];
  pr_paths = triggers&.dig('pull_request', 'paths');
  push_paths = triggers&.dig('push', 'paths');
  raise 'missing pull_request paths filter' unless pr_paths&.include?('website/**');
  raise 'missing push paths filter' unless push_paths&.include?('website/**');
  puts 'Workflow YAML validated OK: ' + pr_paths.join(', ');
"
```

**預期輸出：** 兩行均為 `... validated OK`，exit code `0`。

---

### Task 4：互動腳本、共用元件與雙語靜態入口建置 `[標準]`

**Files:**
- Create: `website/src/scripts/showcase.ts`
- Create: `website/src/components/OsSwitcherBox.astro`
- Create: `website/src/components/LandingPage.astro`
- Create: `website/src/pages/index.astro`
- Create: `website/src/pages/zh-tw/index.astro`

**Interfaces:**
- Consumes:
  - `website/src/data/site.ts` (`SITE_DATA`, `SITE_META`, `type Locale`, `type OsKind`, `type SiteLocaleData`)
  - `website/src/layouts/BaseLayout.astro`
  - `website/src/styles/global.css` 定義之全部語意 class 與 `data-*` 選擇器
- Produces:
  - `website/src/scripts/showcase.ts`:
    - Pure exports: `export function parseStoredOs(value: string | null): OsKind | null`, `export function detectOsFromAgent(platform: string, userAgent: string, maxTouchPoints?: number): OsKind`, `export function computeNextLensIndex(current: number, total: number, key: string): number | null`, `export function initShowcase(): void`
  - `website/src/components/OsSwitcherBox.astro`: `Props { data: SiteLocaleData; headingTag?: 'h2' | 'h3'; showDetails?: boolean }`
  - 建置產物 `website/dist/index.html`（`/`）與 `website/dist/zh-tw/index.html`（`/zh-tw/`）

- [ ] **Step 1：撰寫互動控制模組 `website/src/scripts/showcase.ts`**

建立 `website/src/scripts/showcase.ts`：

```typescript
export type OsKind = 'mobile' | 'macos';

const OS_STORAGE_KEY = 'fr-os-pref';

export function parseStoredOs(value: string | null): OsKind | null {
  return value === 'mobile' || value === 'macos' ? value : null;
}

export function detectOsFromAgent(
  platform: string,
  userAgent: string,
  maxTouchPoints = 0,
): OsKind {
  // 單一 OS 偵測規則（與 BaseLayout.astro inline script 完全對齊；inline 僅用於消除首屏 FOUC）。
  // 必須先判斷行動平台，因 iPhone/iPad Safari UA 內含 "like Mac OS X"。
  const isMobile =
    /iPhone|iPad|iPod|Android/i.test(platform) ||
    /iPhone|iPad|iPod|Android|Mobile/i.test(userAgent) ||
    (/Mac/i.test(platform) && maxTouchPoints > 1);
  if (isMobile) return 'mobile';
  return /macOS|MacIntel|MacPPC|MacArm/i.test(platform) ||
    /Macintosh|Mac OS X/i.test(userAgent)
    ? 'macos'
    : 'mobile';
}

export function computeNextLensIndex(
  current: number,
  total: number,
  key: string,
): number | null {
  if (total <= 0) return null;
  switch (key) {
    case 'ArrowDown':
    case 'ArrowRight':
      return (current + 1) % total;
    case 'ArrowUp':
    case 'ArrowLeft':
      return (current - 1 + total) % total;
    case 'Home':
      return 0;
    case 'End':
      return total - 1;
    default:
      return null;
  }
}

function initOsSwitchers(): void {
  const buttons = Array.from(
    document.querySelectorAll<HTMLButtonElement>('[data-os-switch]'),
  );
  if (buttons.length === 0) return;

  const setOs = (os: OsKind, persist: boolean): void => {
    document.documentElement.dataset.os = os;
    for (const btn of buttons) {
      btn.setAttribute('aria-pressed', btn.dataset.os === os ? 'true' : 'false');
    }
    if (persist) {
      try {
        localStorage.setItem(OS_STORAGE_KEY, os);
      } catch {
        // Ignore storage errors in private browsing modes.
      }
    }
  };

  let initialOs: OsKind | null = parseStoredOs(
    document.documentElement.dataset.os ?? null,
  );
  if (!initialOs) {
    try {
      initialOs = parseStoredOs(localStorage.getItem(OS_STORAGE_KEY));
    } catch {
      initialOs = null;
    }
  }
  if (!initialOs) {
    const navAny = navigator as Navigator & {
      userAgentData?: { platform?: string };
    };
    initialOs = detectOsFromAgent(
      navAny.userAgentData?.platform || navigator.platform || '',
      navigator.userAgent || '',
      navigator.maxTouchPoints || 0,
    );
  }
  setOs(initialOs, false);

  for (const btn of buttons) {
    btn.addEventListener('click', () => {
      const next = parseStoredOs(btn.dataset.os ?? null);
      if (next) setOs(next, true);
    });
  }
}

function initCopyButtons(): void {
  const buttons = Array.from(
    document.querySelectorAll<HTMLButtonElement>('[data-copy-btn]'),
  );

  for (const btn of buttons) {
    btn.addEventListener('click', async () => {
      const panel = btn.closest<HTMLElement>('[data-os-panel]');
      const codeEl = panel?.querySelector<HTMLElement>('[data-cli-code]');
      const statusEl = panel?.querySelector<HTMLElement>('[data-copy-status]');
      const text = codeEl?.textContent?.trim() ?? '';
      if (!text) return;

      let copied = false;
      if (window.isSecureContext && navigator.clipboard?.writeText) {
        try {
          await navigator.clipboard.writeText(text);
          copied = true;
        } catch {
          copied = false;
        }
      }

      if (!copied) {
        try {
          const area = document.createElement('textarea');
          area.value = text;
          area.setAttribute('readonly', '');
          area.style.position = 'fixed';
          area.style.opacity = '0';
          document.body.appendChild(area);
          area.select();
          copied = document.execCommand('copy');
          document.body.removeChild(area);
        } catch {
          copied = false;
        }
      }

      if (statusEl) {
        statusEl.textContent = copied
          ? btn.dataset.copiedLabel || 'Copied'
          : btn.dataset.fallbackLabel || 'Select code to copy';
      }

      if (!copied && codeEl && window.getSelection) {
        const range = document.createRange();
        range.selectNodeContents(codeEl);
        const sel = window.getSelection();
        sel?.removeAllRanges();
        sel?.addRange(range);
      }
    });
  }
}

function initScrollyLenses(): void {
  const tablist = document.querySelector<HTMLElement>('[data-lenses-tablist]');
  const tabs = Array.from(
    document.querySelectorAll<HTMLButtonElement>('[data-lens-tab]'),
  );
  const panels = Array.from(
    document.querySelectorAll<HTMLElement>('[data-lens-panel]'),
  );
  const captionEl = document.querySelector<HTMLElement>('[data-lens-caption]');
  if (!tablist || tabs.length === 0 || tabs.length !== panels.length) return;

  let activeIndex = 0;
  let manualLockUntil = 0;
  const wideQuery = window.matchMedia('(min-width: 961px)');

  const activate = (nextIndex: number, focusTab: boolean): void => {
    if (nextIndex < 0 || nextIndex >= tabs.length) return;
    activeIndex = nextIndex;
    for (let i = 0; i < tabs.length; i += 1) {
      const selected = i === nextIndex;
      tabs[i].setAttribute('aria-selected', selected ? 'true' : 'false');
      tabs[i].setAttribute('tabindex', selected ? '0' : '-1');
      panels[i].setAttribute('aria-hidden', selected ? 'false' : 'true');
    }
    if (captionEl) {
      const activeCaption =
        panels[nextIndex].querySelector<HTMLElement>('figcaption')?.textContent ?? '';
      captionEl.textContent = activeCaption;
    }
    if (focusTab) tabs[nextIndex].focus();
  };

  for (let i = 0; i < tabs.length; i += 1) {
    tabs[i].addEventListener('click', () => {
      manualLockUntil = Date.now() + 650;
      activate(i, false);
    });
  }

  tablist.addEventListener('keydown', (event: KeyboardEvent) => {
    const next = computeNextLensIndex(activeIndex, tabs.length, event.key);
    if (next === null) return;
    event.preventDefault();
    manualLockUntil = Date.now() + 650;
    activate(next, true);
  });

  let rafPending = false;
  const syncFromScroll = (): void => {
    rafPending = false;
    if (!wideQuery.matches || Date.now() < manualLockUntil) return;
    const scrollyRect = tablist.getBoundingClientRect();
    if (scrollyRect.bottom < 80 || scrollyRect.top > window.innerHeight - 80) {
      return;
    }

    const focalY = window.innerHeight * 0.42;
    let bestIndex = activeIndex;
    let bestDist = Number.POSITIVE_INFINITY;
    for (let i = 0; i < tabs.length; i += 1) {
      const rect = tabs[i].getBoundingClientRect();
      const center = rect.top + rect.height * 0.5;
      const dist = Math.abs(center - focalY);
      if (dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
      }
    }
    if (bestIndex !== activeIndex) {
      activate(bestIndex, false);
    }
  };

  window.addEventListener(
    'scroll',
    () => {
      if (rafPending || !wideQuery.matches) return;
      rafPending = true;
      window.requestAnimationFrame(syncFromScroll);
    },
    { passive: true },
  );

  activate(0, false);
}

interface RadarNode {
  x: number;
  y: number;
  vx: number;
  vy: number;
  r: number;
  featured: boolean;
}

function initShoalCanvas(): void {
  const canvas = document.getElementById('shoal-canvas') as HTMLCanvasElement | null;
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const reduceMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
  const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');

  const nodes: RadarNode[] = Array.from({ length: 30 }, (_, idx) => {
    const angle = (idx / 30) * Math.PI * 2;
    const ring = 0.2 + ((idx * 17) % 72) / 100;
    return {
      x: 0.5 + Math.cos(angle) * ring * 0.44,
      y: 0.5 + Math.sin(angle) * ring * 0.44,
      vx: Math.cos(angle + 1.3) * 0.00055,
      vy: Math.sin(angle + 1.3) * 0.00055,
      r: idx % 7 === 0 ? 4.4 : 2.6,
      featured: idx % 7 === 0,
    };
  });

  let width = 440;
  let height = 396;
  let sweep = 0;
  let rafId = 0;
  let inViewport = true;
  let pointerX: number | null = null;
  let pointerY: number | null = null;

  const resize = (): void => {
    const rect = canvas.getBoundingClientRect();
    width = Math.max(260, Math.round(rect.width));
    height = Math.max(220, Math.round(rect.height));
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  };

  const drawFrame = (animate: boolean): void => {
    const dark = darkQuery.matches;
    const bg = dark ? '#281F1B' : '#F7EFE7';
    const accent = dark ? '#F06A3E' : '#D84A20';
    const inkMuted = dark ? 'rgba(250,244,238,0.22)' : 'rgba(31,23,19,0.16)';
    const ringSoft = dark ? 'rgba(240,106,62,0.20)' : 'rgba(216,74,32,0.16)';

    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, width, height);

    const cx = width * 0.5;
    const cy = height * 0.5;
    const maxR = Math.min(width, height) * 0.42;

    // Radar concentric rings and crosshairs
    ctx.strokeStyle = ringSoft;
    ctx.lineWidth = 1;
    for (const ratio of [0.34, 0.66, 1.0]) {
      ctx.beginPath();
      ctx.arc(cx, cy, maxR * ratio, 0, Math.PI * 2);
      ctx.stroke();
    }

    ctx.strokeStyle = inkMuted;
    ctx.beginPath();
    ctx.moveTo(cx - maxR * 1.08, cy);
    ctx.lineTo(cx + maxR * 1.08, cy);
    ctx.moveTo(cx, cy - maxR * 1.08);
    ctx.lineTo(cx, cy + maxR * 1.08);
    ctx.stroke();

    // Subtle radar sweep sector
    if (animate) {
      ctx.fillStyle = dark ? 'rgba(240,106,62,0.10)' : 'rgba(216,74,32,0.08)';
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, maxR, sweep - 0.36, sweep);
      ctx.closePath();
      ctx.fill();
    }

    for (const node of nodes) {
      if (animate) {
        node.x += node.vx;
        node.y += node.vy;
        if (node.x < 0.08 || node.x > 0.92) node.vx *= -1;
        if (node.y < 0.08 || node.y > 0.92) node.vy *= -1;
      }

      const px = node.x * width;
      const py = node.y * height;
      let nearPointer = false;
      if (pointerX !== null && pointerY !== null) {
        const dx = px - pointerX;
        const dy = py - pointerY;
        nearPointer = dx * dx + dy * dy < 3200;
      }

      if (node.featured || nearPointer) {
        ctx.strokeStyle = accent;
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.arc(px, py, node.r + 5, 0, Math.PI * 2);
        ctx.stroke();
      }

      ctx.fillStyle = node.featured || nearPointer ? accent : inkMuted;
      ctx.beginPath();
      ctx.arc(px, py, node.r, 0, Math.PI * 2);
      ctx.fill();
    }
  };

  const stopLoop = (): void => {
    if (rafId !== 0) {
      window.cancelAnimationFrame(rafId);
      rafId = 0;
    }
  };

  const tick = (): void => {
    if (!inViewport || document.hidden || reduceMotionQuery.matches) {
      rafId = 0;
      return;
    }
    sweep = (sweep + 0.015) % (Math.PI * 2);
    drawFrame(true);
    rafId = window.requestAnimationFrame(tick);
  };

  const syncAnimationState = (): void => {
    stopLoop();
    if (reduceMotionQuery.matches) {
      drawFrame(false);
      return;
    }
    if (inViewport && !document.hidden) {
      rafId = window.requestAnimationFrame(tick);
    }
  };

  resize();
  syncAnimationState();

  const observer = new IntersectionObserver(
    (entries) => {
      inViewport = entries.some((e) => e.isIntersecting);
      syncAnimationState();
    },
    { threshold: 0.05 },
  );
  observer.observe(canvas);

  window.addEventListener('resize', () => {
    resize();
    if (!inViewport || document.hidden || reduceMotionQuery.matches) {
      drawFrame(false);
    }
  });
  document.addEventListener('visibilitychange', syncAnimationState);
  reduceMotionQuery.addEventListener('change', syncAnimationState);
  darkQuery.addEventListener('change', () => {
    if (!inViewport || document.hidden || reduceMotionQuery.matches) {
      drawFrame(false);
    }
  });

  canvas.addEventListener('pointermove', (e: PointerEvent) => {
    const rect = canvas.getBoundingClientRect();
    pointerX = e.clientX - rect.left;
    pointerY = e.clientY - rect.top;
    if (reduceMotionQuery.matches) drawFrame(false);
  });

  canvas.addEventListener('pointerleave', () => {
    pointerX = null;
    pointerY = null;
    if (reduceMotionQuery.matches) drawFrame(false);
  });
}

export function initShowcase(): void {
  initOsSwitchers();
  initCopyButtons();
  initScrollyLenses();
  initShoalCanvas();
}
```

- [ ] **Step 2：建立共用平台切換元件 `website/src/components/OsSwitcherBox.astro` 與頁面元件 `website/src/components/LandingPage.astro`**

建立 `website/src/components/OsSwitcherBox.astro`：

```astro
---
import type { SiteLocaleData } from '../data/site';

interface Props {
  data: SiteLocaleData;
  headingTag?: 'h2' | 'h3';
  showDetails?: boolean;
}

const { data: d, headingTag = 'h2', showDetails = true } = Astro.props;
---

<div class="os-box">
  <div class="os-switch" role="group" aria-label={d.hero.osGroupLabel}>
    <button
      type="button"
      class="os-btn"
      data-os-switch
      data-os="mobile"
      aria-pressed="true"
    >
      {d.hero.osPanels.mobile.tabLabel}
    </button>
    <button
      type="button"
      class="os-btn"
      data-os-switch
      data-os="macos"
      aria-pressed="false"
    >
      {d.hero.osPanels.macos.tabLabel}
    </button>
  </div>

  {(['mobile', 'macos'] as const).map((osKey) => {
    const panel = d.hero.osPanels[osKey];
    return (
      <div class="os-panel" data-os-panel={osKey}>
        <p class="os-panel-meta">{panel.eyebrow}</p>
        {headingTag === 'h2' ? <h2>{panel.heading}</h2> : <h3>{panel.heading}</h3>}
        {showDetails && (
          <>
            <p>{panel.summary}</p>
            <ul class="spec-chips">
              {panel.specs.map((spec) => <li>{spec}</li>)}
            </ul>
            <span class="cli-label">{panel.cliLabel}</span>
          </>
        )}
        <div class="cli-wrap">
          <pre><code data-cli-code>{panel.cliCommand}</code></pre>
          <div class="cli-actions">
            <button
              type="button"
              class="copy-btn"
              data-copy-btn
              data-copied-label={panel.copiedLabel}
              data-fallback-label={panel.fallbackLabel}
            >
              {panel.copyLabel}
            </button>
            <span class="copy-status" data-copy-status aria-live="polite"></span>
          </div>
        </div>
      </div>
    );
  })}
</div>
```

建立 `website/src/components/LandingPage.astro`：

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import OsSwitcherBox from './OsSwitcherBox.astro';
import { SITE_DATA, SITE_META, type Locale } from '../data/site';

interface Props {
  locale: Locale;
}

const { locale } = Astro.props;
const d = SITE_DATA[locale];
const enActive = locale === 'en';
const zhActive = locale === 'zh-tw';
const readmeUrl = enActive ? SITE_META.readmeEnUrl : SITE_META.readmeZhUrl;
---

<BaseLayout locale={locale} data={d}>
  <header class="bar">
    <div class="wrap bar-inner">
      <a class="brand" href={d.canonicalPath}>
        <img src={SITE_META.faviconPath} alt="" width="30" height="30" />
        <span>{d.nav.brandName}</span>
        <span class="brand-sub">{d.nav.brandSub}</span>
      </a>

      <nav class="bar-nav" aria-label={d.nav.brandName}>
        {d.nav.links.map((item) => <a href={item.href}>{item.label}</a>)}
      </nav>

      <div class="bar-actions">
        <a
          class="gh-pill"
          href={SITE_META.repoUrl}
          target="_blank"
          rel="noopener noreferrer"
        >
          {d.nav.githubLabel}
        </a>
        <nav class="lang-switch" aria-label={d.nav.langSwitchLabel}>
          <a href="/" aria-current={enActive ? 'page' : undefined}>
            {d.nav.langLinks.en}
          </a>
          <a href="/zh-tw/" aria-current={zhActive ? 'page' : undefined}>
            {d.nav.langLinks.zhTw}
          </a>
        </nav>
      </div>
    </div>
  </header>

  <main id="main-content">
    <section class="hero">
      <div class="wrap hero-grid">
        <div class="hero-copy">
          <span class="eyebrow">{d.hero.badge}</span>
          <h1>
            {d.hero.title}
            <span>{d.hero.titleAccent}</span>
          </h1>
          <p class="lead">{d.hero.lead}</p>

          <OsSwitcherBox data={d} headingTag="h2" showDetails={true} />

          <div class="hero-cta">
            <a
              class="btn-primary"
              href={SITE_META.repoUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.hero.ctaSource}
            </a>
            <a
              class="btn-secondary"
              href={readmeUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.hero.ctaGuide}
            </a>
            <a
              class="btn-secondary"
              href={SITE_META.releasesUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.hero.ctaReleases}
            </a>
          </div>
        </div>

        <aside class="shoal" aria-label={d.hero.canvasTitle}>
          <div class="shoal-head">
            <span>{d.hero.canvasTitle}</span>
            <span>{d.hero.canvasCaption}</span>
          </div>
          <canvas class="shoal-canvas" id="shoal-canvas" aria-hidden="true"></canvas>
        </aside>
      </div>
    </section>

    <hr class="strata" />

    <section class="stratum" id="experience">
      <div class="wrap stratum-shell">
        <div class="ruler">
          <span class="depth">{d.stratum1.depth}</span>
        </div>
        <div class="stratum-body">
          <div class="stratum-head">
            <span class="eyebrow">{d.stratum1.eyebrow}</span>
            <h2>{d.stratum1.title}</h2>
            <p>{d.stratum1.lead}</p>
          </div>

          <div class="scrolly">
            <div
              class="lenses"
              role="tablist"
              aria-label={d.stratum1.tablistLabel}
              data-lenses-tablist
            >
              {d.stratum1.lenses.map((lens, index) => (
                <button
                  type="button"
                  class="lens"
                  role="tab"
                  id={`tab-${lens.id}`}
                  aria-controls={`panel-${lens.id}`}
                  aria-selected={index === 0 ? 'true' : 'false'}
                  tabindex={index === 0 ? 0 : -1}
                  data-lens-tab={String(index)}
                >
                  <span class="lens-top">
                    <span class="lens-code">{lens.code}</span>
                    <span class="lens-title">{lens.title}</span>
                  </span>
                  <span class="lens-sub">{lens.subtitle}</span>
                  <span class="lens-desc">{lens.description}</span>
                </button>
              ))}
            </div>

            <div class="lens-stack" id="lensstack">
              <div class="lens-viewport">
                {d.stratum1.lenses.map((lens, index) => (
                  <figure
                    class="lens-panel"
                    role="tabpanel"
                    id={`panel-${lens.id}`}
                    aria-labelledby={`tab-${lens.id}`}
                    aria-hidden={index === 0 ? 'false' : 'true'}
                    data-lens-panel={String(index)}
                  >
                    <img
                      src={lens.image}
                      alt={lens.alt}
                      width="720"
                      height="1600"
                      decoding="async"
                      loading="eager"
                    />
                    <figcaption hidden>{lens.caption}</figcaption>
                  </figure>
                ))}
              </div>
              <p class="lens-caption" data-lens-caption>
                {d.stratum1.lenses[0].caption}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <hr class="strata" />

    <section class="stratum" id="ai">
      <div class="wrap stratum-shell">
        <div class="ruler">
          <span class="depth">{d.stratum2.depth}</span>
        </div>
        <div class="stratum-body">
          <div class="stratum-head">
            <span class="eyebrow">{d.stratum2.eyebrow}</span>
            <h2>{d.stratum2.title}</h2>
            <p>{d.stratum2.lead}</p>
          </div>

          <div class="card-grid">
            {d.stratum2.cards.map((card) => (
              <article class="card">
                <span class="card-tag">{card.tag}</span>
                <h3>{card.title}</h3>
                <code class="card-symbol">{card.symbol}</code>
                <p>{card.description}</p>
                <ul>
                  {card.bullets.map((bullet) => <li>{bullet}</li>)}
                </ul>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>

    <hr class="strata" />

    <section class="stratum" id="architecture">
      <div class="wrap stratum-shell">
        <div class="ruler">
          <span class="depth">{d.stratum3.depth}</span>
        </div>
        <div class="stratum-body">
          <div class="stratum-head">
            <span class="eyebrow">{d.stratum3.eyebrow}</span>
            <h2>{d.stratum3.title}</h2>
            <p>{d.stratum3.lead}</p>
          </div>

          <h3 class="sub-heading">{d.stratum3.archHeading}</h3>
          <div class="arch-grid">
            {d.stratum3.archLayers.map((layer) => (
              <article class="card">
                <span class="card-tag">{layer.layer}</span>
                <h4>{layer.title}</h4>
                <p>{layer.summary}</p>
              </article>
            ))}
          </div>

          <h3 class="sub-heading">{d.stratum3.matrixHeading}</h3>
          <div class="table-wrap">
            <table class="cap-table">
              <thead>
                <tr>
                  <th>{d.stratum3.matrixColumns.capability}</th>
                  <th>{d.stratum3.matrixColumns.mobile}</th>
                  <th>{d.stratum3.matrixColumns.macos}</th>
                  <th>{d.stratum3.matrixColumns.reason}</th>
                </tr>
              </thead>
              <tbody>
                {d.stratum3.capabilities.map((row) => (
                  <tr>
                    <td><strong>{row.capability}</strong></td>
                    <td>{row.mobile}</td>
                    <td>{row.macos}</td>
                    <td>{row.reason}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h3 class="sub-heading">{d.stratum3.securityHeading}</h3>
          <div class="card-grid">
            {d.stratum3.securityPrinciples.map((item) => (
              <article class="card">
                <h4>{item.title}</h4>
                <p>{item.detail}</p>
              </article>
            ))}
          </div>

          <aside class="evolution-box">
            <span class="eyebrow">{d.stratum3.evolutionBadge}</span>
            <h3>{d.stratum3.evolutionHeading}</h3>
            <p>{d.stratum3.evolutionBody}</p>
          </aside>
        </div>
      </div>
    </section>

    <section class="closing" id="install">
      <div class="wrap closing-grid">
        <div>
          <span class="eyebrow">{d.closing.eyebrow}</span>
          <h2>{d.closing.title}</h2>
          <p class="lead">{d.closing.lead}</p>
          <div class="hero-cta">
            <a
              class="btn-primary"
              href={SITE_META.repoUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.closing.ctaRepo}
            </a>
            <a
              class="btn-secondary"
              href={SITE_META.macosGuideUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.closing.ctaMacGuide}
            </a>
            <a
              class="btn-secondary"
              href={SITE_META.releasesUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              {d.closing.ctaReleases}
            </a>
          </div>
        </div>

        <OsSwitcherBox data={d} headingTag="h3" showDetails={false} />
      </div>
    </section>
  </main>

  <footer class="foot">
    <div class="wrap foot-inner">
      <div>
        <strong>{d.footer.tagline}</strong>
        <div>{d.footer.versionText}</div>
        <div>{d.footer.licenseNote}</div>
      </div>

      <div class="foot-links">
        {d.footer.links.map((link) => (
          <a href={link.href} target="_blank" rel="noopener noreferrer">
            {link.label}
          </a>
        ))}
        <div class="lang-switch" role="group" aria-label={d.nav.langSwitchLabel}>
          <a href="/" aria-current={enActive ? 'page' : undefined}>
            {d.nav.langLinks.en}
          </a>
          <a href="/zh-tw/" aria-current={zhActive ? 'page' : undefined}>
            {d.nav.langLinks.zhTw}
          </a>
        </div>
      </div>
    </div>
  </footer>

  <script>
    import { initShowcase } from '../scripts/showcase';
    initShowcase();
  </script>
</BaseLayout>
```

- [ ] **Step 3：建立雙語路由入口 `website/src/pages/index.astro` 與 `website/src/pages/zh-tw/index.astro`**

建立 `website/src/pages/index.astro`：

```astro
---
import LandingPage from '../components/LandingPage.astro';
---

<LandingPage locale="en" />
```

建立 `website/src/pages/zh-tw/index.astro`：

```astro
---
import LandingPage from '../../components/LandingPage.astro';
---

<LandingPage locale="zh-tw" />
```

- [ ] **Step 4：執行靜態建置並檢查輸出結構**

```bash
cd website && npm run build && ls -la dist/ dist/zh-tw/ dist/_astro/ dist/screenshots/
```

**預期輸出：** `astro build` exit code `0`（0 error），成功產生 `dist/index.html`、`dist/zh-tw/index.html`、`dist/_astro/*.css`、`dist/_astro/*.js`、`dist/og-card.png`、`dist/favicon.png` 及 6 個 `dist/screenshots/*.webp`。

---

### Task 5：端到端靜態產物驗證測試與零侵入／回滾稽核 `[標準]`

**Files:**
- Create: `website/test/verify-dist.test.mjs`

**Interfaces:**
- Consumes: Task 1–4 產生的 `website/dist/` 完整靜態產物與 `website/src/scripts/showcase.ts` 匯出的純邏輯函式（`detectOsFromAgent`、`parseStoredOs`、`computeNextLensIndex`）
- Produces: 可在 CI (`npm test`) 與本機重複執行的 AC-1 ～ AC-6 自動化驗證測試檔

- [ ] **Step 1：撰寫完整 `dist/` 靜態驗證與純邏輯測試 `website/test/verify-dist.test.mjs`**

建立 `website/test/verify-dist.test.mjs`：

```javascript
import assert from 'node:assert/strict';
import test from 'node:test';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  computeNextLensIndex,
  detectOsFromAgent,
  parseStoredOs,
} from '../src/scripts/showcase.ts';
import { ALLOWED_SCREENSHOTS, SITE_META } from '../src/data/site.ts';

const TEST_DIR = path.dirname(fileURLToPath(import.meta.url));
const WEBSITE_ROOT = path.resolve(TEST_DIR, '..');
const DIST_DIR = path.join(WEBSITE_ROOT, 'dist');

function walkFiles(dir) {
  const results = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkFiles(full));
    } else {
      results.push(full);
    }
  }
  return results;
}

function assertDistExists() {
  assert.ok(
    existsSync(DIST_DIR),
    'website/dist/ not found — run `npm run build` before `npm test`',
  );
}

test('Pure client logic: OS detection, storage parser, and WAI-ARIA tab wrapping', () => {
  assert.equal(parseStoredOs('mobile'), 'mobile');
  assert.equal(parseStoredOs('macos'), 'macos');
  assert.equal(parseStoredOs('windows'), null);
  assert.equal(parseStoredOs(null), null);

  assert.equal(
    detectOsFromAgent('MacIntel', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5)', 0),
    'macos',
  );
  assert.equal(
    detectOsFromAgent(
      'iPhone',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      5,
    ),
    'mobile',
  );
  assert.equal(
    detectOsFromAgent(
      'iPad',
      'Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      5,
    ),
    'mobile',
  );
  assert.equal(
    detectOsFromAgent(
      'MacIntel',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
      5,
    ),
    'mobile',
  );
  assert.equal(detectOsFromAgent('Linux armv8l', 'Android 14', 5), 'mobile');

  assert.equal(computeNextLensIndex(0, 6, 'ArrowRight'), 1);
  assert.equal(computeNextLensIndex(0, 6, 'ArrowDown'), 1);
  assert.equal(computeNextLensIndex(5, 6, 'ArrowRight'), 0);
  assert.equal(computeNextLensIndex(0, 6, 'ArrowLeft'), 5);
  assert.equal(computeNextLensIndex(0, 6, 'ArrowUp'), 5);
  assert.equal(computeNextLensIndex(3, 6, 'Home'), 0);
  assert.equal(computeNextLensIndex(2, 6, 'End'), 5);
  assert.equal(computeNextLensIndex(2, 6, 'Escape'), null);
});

test('AC-2: Bilingual HTML, canonical, hreflang, OG/Twitter, theme-color, and JSON-LD', () => {
  assertDistExists();

  const cases = [
    {
      file: path.join(DIST_DIR, 'index.html'),
      lang: 'en',
      canonical: 'https://findrestaurant-c80ea.web.app/',
      ogLocale: 'en_US',
    },
    {
      file: path.join(DIST_DIR, 'zh-tw', 'index.html'),
      lang: 'zh-Hant-TW',
      canonical: 'https://findrestaurant-c80ea.web.app/zh-tw/',
      ogLocale: 'zh_TW',
    },
  ];

  for (const c of cases) {
    assert.ok(existsSync(c.file), `Missing built HTML: ${c.file}`);
    const html = readFileSync(c.file, 'utf8');

    assert.match(html, new RegExp(`<html[^>]+lang="${c.lang}"`));
    assert.match(html, new RegExp(`<link[^>]+rel="canonical"[^>]+href="${c.canonical}"`));
    assert.match(
      html,
      /<link[^>]+rel="alternate"[^>]+hreflang="en"[^>]+href="https:\/\/findrestaurant-c80ea\.web\.app\/"/,
    );
    assert.match(
      html,
      /<link[^>]+rel="alternate"[^>]+hreflang="zh-Hant-TW"[^>]+href="https:\/\/findrestaurant-c80ea\.web\.app\/zh-tw\/"/,
    );
    assert.match(
      html,
      /<link[^>]+rel="alternate"[^>]+hreflang="x-default"[^>]+href="https:\/\/findrestaurant-c80ea\.web\.app\/"/,
    );
    assert.match(html, /<meta[^>]+property="og:title"/);
    assert.match(html, /<meta[^>]+property="og:description"/);
    assert.match(html, /<meta[^>]+property="og:type"[^>]+content="website"/);
    assert.match(html, new RegExp(`<meta[^>]+property="og:url"[^>]+content="${c.canonical}"`));
    assert.match(html, new RegExp(`<meta[^>]+property="og:locale"[^>]+content="${c.ogLocale}"`));
    assert.match(
      html,
      /<meta[^>]+property="og:image"[^>]+content="https:\/\/findrestaurant-c80ea\.web\.app\/og-card\.png"/,
    );
    assert.match(html, /<meta[^>]+name="twitter:card"[^>]+content="summary_large_image"/);
    assert.match(
      html,
      /<meta[^>]+name="theme-color"[^>]+content="#FFFBF7"[^>]+media="\(prefers-color-scheme: light\)"/,
    );
    assert.match(
      html,
      /<meta[^>]+name="theme-color"[^>]+content="#14100E"[^>]+media="\(prefers-color-scheme: dark\)"/,
    );

    const ldMatch = html.match(
      /<script type="application\/ld\+json">([\s\S]*?)<\/script>/,
    );
    assert.ok(ldMatch, `Missing JSON-LD in ${c.file}`);
    const jsonLd = JSON.parse(ldMatch[1]);
    assert.equal(jsonLd['@type'], 'SoftwareApplication');
    assert.equal(jsonLd.softwareVersion, SITE_META.appVersion);
    assert.equal(jsonLd.codeRepository, SITE_META.repoUrl);
    assert.equal('downloadUrl' in jsonLd, false);
    for (const val of Object.values(jsonLd)) {
      if (typeof val === 'string') {
        assert.doesNotMatch(val, /\.(dmg|apk|ipa|exe)([?#]|$)/i);
      }
    }
  }
});

test('AC-3 & AC-4: Scrolly WAI-ARIA contract, OS switcher, honest CTAs, and 0 broken internal assets', () => {
  assertDistExists();

  for (const rel of ['index.html', 'zh-tw/index.html']) {
    const html = readFileSync(path.join(DIST_DIR, rel), 'utf8');

    // WAI-ARIA tabs and tabpanels
    assert.match(html, /role="tablist"/);
    const tabs = html.match(/role="tab"/g) ?? [];
    const panels = html.match(/role="tabpanel"/g) ?? [];
    assert.equal(tabs.length, 6, `${rel} must contain 6 role="tab" elements`);
    assert.equal(panels.length, 6, `${rel} must contain 6 role="tabpanel" elements`);

    for (let i = 1; i <= 6; i += 1) {
      const id = `lens-0${i}`;
      assert.match(html, new RegExp(`id="tab-${id}"`));
      assert.match(html, new RegExp(`aria-controls="panel-${id}"`));
      assert.match(html, new RegExp(`id="panel-${id}"`));
      assert.match(html, new RegExp(`aria-labelledby="tab-${id}"`));
    }
    assert.match(html, /id="tab-lens-01"[^>]*aria-selected="true"/);
    assert.match(html, /id="panel-lens-01"[^>]*aria-hidden="false"/);
    assert.match(html, /id="tab-lens-02"[^>]*aria-selected="false"/);
    assert.match(html, /id="panel-lens-02"[^>]*aria-hidden="true"/);

    // Every approved WebP referenced, no fake image placeholders
    for (const img of ALLOWED_SCREENSHOTS) {
      assert.ok(html.includes(img), `${rel} missing screenshot ${img}`);
    }

    // OS switchers and aria-live feedback
    assert.match(html, /data-os-switch[^>]*data-os="mobile"/);
    assert.match(html, /data-os-switch[^>]*data-os="macos"/);
    assert.match(html, /data-os-panel="mobile"/);
    assert.match(html, /data-os-panel="macos"/);
    assert.match(html, /data-copy-btn/);
    assert.match(html, /aria-live="polite"/);

    // Canvas protection markers
    assert.match(html, /<canvas[^>]+id="shoal-canvas"[^>]+aria-hidden="true"/);

    // Honest CTA and zero fake binary URLs in attributes (allows honest prose mentioning .dmg/.apk policy)
    assert.ok(html.includes(SITE_META.repoUrl));
    assert.ok(html.includes(SITE_META.releasesUrl));
    for (const m of html.matchAll(/(?:href|src|action|data-url)="([^"]+)"/g)) {
      const attrUrl = m[1];
      assert.doesNotMatch(
        attrUrl,
        /\.(dmg|apk|ipa|exe)([?#]|$)/i,
        `Forbidden binary link/asset attribute in ${rel}: ${attrUrl}`,
      );
    }

    // In-page anchor links must resolve to existing IDs in the same document
    const ids = new Set(Array.from(html.matchAll(/\bid="([^"]+)"/g), (m) => m[1]));
    for (const m of html.matchAll(/\bhref="#([^"]+)"/g)) {
      const anchor = m[1];
      assert.ok(ids.has(anchor), `Broken in-page anchor #${anchor} in ${rel}`);
    }

    // Footer uses group rather than duplicate <nav> landmark for language switch
    assert.match(html, /<footer\b[\s\S]*<div class="lang-switch" role="group"/);

    // Visible HTML text must not leak raw Markdown backticks (outside <script> / <pre>)
    const visibleHtml = html
      .replace(/<script[\s\S]*?<\/script>/g, '')
      .replace(/<pre>[\s\S]*?<\/pre>/g, '');
    assert.doesNotMatch(visibleHtml, /`/, `Raw markdown backtick leaked into visible HTML in ${rel}`);

    // Every local href/src resolves to a built file in dist/ (0 internal 404s)
    const attrMatches = html.matchAll(/(?:href|src)="(\/[^"#]*)/g);
    for (const m of attrMatches) {
      const rawPath = m[1];
      if (rawPath.startsWith('//')) continue;
      const normalized = rawPath.endsWith('/') ? `${rawPath}index.html` : rawPath;
      const target = path.join(DIST_DIR, normalized.replace(/^\//, ''));
      assert.ok(
        existsSync(target),
        `Broken internal asset/link in ${rel}: ${rawPath} -> ${target}`,
      );
    }
  }
});

test('AC-2 & AC-6: Bundled client JS includes IntersectionObserver, reduced-motion, and WebP/Spark budgets', () => {
  assertDistExists();

  const files = walkFiles(DIST_DIR);
  const jsFiles = files.filter((f) => f.endsWith('.js'));
  assert.ok(jsFiles.length >= 1, 'Expected at least 1 bundled JS file in dist/_astro/');

  const combinedJs = jsFiles.map((f) => readFileSync(f, 'utf8')).join('\n');
  assert.match(combinedJs, /IntersectionObserver/);
  assert.match(combinedJs, /prefers-reduced-motion/);
  assert.match(combinedJs, /localStorage/);
  assert.match(combinedJs, /aria-selected/);
  assert.match(combinedJs, /aria-hidden/);

  // Bundled CSS prevents Grid blowout (no bare `grid-template-columns: 1fr`)
  const cssFiles = files.filter((f) => f.endsWith('.css'));
  assert.ok(cssFiles.length >= 1, 'Expected at least 1 bundled CSS file in dist/_astro/');
  const combinedCss = cssFiles.map((f) => readFileSync(f, 'utf8')).join('\n');
  assert.doesNotMatch(
    combinedCss,
    /grid-template-columns\s*:\s*1fr(?:\s*[;}])/,
    'Bundled CSS must use minmax(0, 1fr) instead of bare 1fr to prevent Grid blowout',
  );
  assert.match(combinedCss, /minmax\(0,\s*1fr\)/);

  // Zero binary installers anywhere in dist/
  for (const f of files) {
    assert.doesNotMatch(f, /\.(dmg|apk|ipa|exe)$/i, `Forbidden binary artifact in dist: ${f}`);
  }

  // Verify dist/screenshots/ directory contains exact 6 approved WebP files (no ghost files)
  const expectedWebpNames = ALLOWED_SCREENSHOTS.map((p) => path.basename(p)).sort();
  const actualWebpNames = readdirSync(path.join(DIST_DIR, 'screenshots')).sort();
  assert.deepEqual(
    actualWebpNames,
    expectedWebpNames,
    'dist/screenshots/ must match the exact 6 approved WebP files without extra or missing images',
  );

  // Verify WebP headers and Spark bandwidth budgets
  let webpTotal = 0;
  for (const relWebp of ALLOWED_SCREENSHOTS) {
    const abs = path.join(DIST_DIR, relWebp.replace(/^\//, ''));
    assert.ok(existsSync(abs), `Missing screenshot in dist/: ${abs}`);
    const buf = readFileSync(abs);
    assert.equal(buf.subarray(0, 4).toString('ascii'), 'RIFF');
    assert.equal(buf.subarray(8, 12).toString('ascii'), 'WEBP');
    assert.ok(buf.byteLength <= 153_600, `${relWebp} exceeds 150 KB: ${buf.byteLength}`);
    webpTotal += buf.byteLength;
  }
  assert.ok(webpTotal <= 614_400, `Combined WebP exceeds 600 KB: ${webpTotal}`);

  const ogSize = statSync(path.join(DIST_DIR, 'og-card.png')).size;
  assert.ok(ogSize <= 460_800, `og-card.png exceeds 450 KB: ${ogSize}`);

  const totalDistBytes = files.reduce((sum, f) => sum + statSync(f).size, 0);
  assert.ok(
    totalDistBytes <= 1_572_864,
    `Total dist/ exceeds 1.5 MB Spark ceiling: ${totalDistBytes}`,
  );
});
```

- [ ] **Step 2：執行完整建置與全套自動化測試**

於 `<WORKTREE_ROOT>/website` 執行：

```bash
cd website && npm run build && npm test
```

**預期輸出：** `astro build` exit code `0`，`npm test` 執行 `test/site-data.test.mjs` 與 `test/verify-dist.test.mjs` 全數通過（0 failed）。

- [ ] **Step 3：驗證 `flutter_restaruant/flutter_restaruant/` 零異動與工作區範圍邊界（AC-1）**

於 `<WORKTREE_ROOT>` 執行：

```bash
git status --short
git status --short -- flutter_restaruant/
git diff -- flutter_restaruant/
git diff --name-only 843aaecc..HEAD -- flutter_restaruant/ \
  ':(exclude)flutter_restaruant/flutter_restaruant/docs/features/2026-11-21-astro-showcase-website.md' \
  ':(exclude)flutter_restaruant/flutter_restaruant/docs/plans/2026-11-21-astro-showcase-website.md'
```

**預期輸出：**
- `git diff -- flutter_restaruant/`、`git status --short -- flutter_restaruant/` 與對照基線 `843aaecc..HEAD` 的 `git diff --name-only`（排除 STAGE 1 核准的兩份規格／計畫文件）**皆完全無輸出**（exit code `0`，確保無已提交或未提交之 App 變更，亦無 untracked 污染；既有 Flutter App 程式碼、`pubspec.yaml`、測試檔與 FlutterFire `firebase.json` 零變動）。
- `git status --short` 僅出現 `website/` 與 `.github/workflows/website.yml`，且不含 `website/node_modules/`、`website/dist/`、`.astro/`（已被 `.gitignore` 忽略）。

**失敗／需放棄變更時的可執行回滾指令：**
因本次所有新增檔案與 Flutter App 完全正交，可依目前是否已建立 commit 選擇對應回滾方式：

- **尚未 `git commit`（僅本地未追蹤檔案）**：
  ```bash
  rm -rf website .github/workflows/website.yml
  ```
- **已 `git commit` 至任務分支**：
  - 若僅需還原工作區檔案狀態：
    ```bash
    git restore --source=main --worktree --staged -- website .github/workflows/website.yml
    ```
  - 若需保留歷史並反向撤銷特定 commit（於任務分支執行）：
    ```bash
    git revert --no-edit <commit-sha>
    ```

---

## 4. 執行方式選項（Execution Options）

**推薦執行方式：STAGE 2 依任務依賴分批實作**（使用 `subagent-driven-development` 逐批派發，寫入路徑嚴格互斥；或以 `executing-plans` 依 Batch 順序於 worktree 內執行）：

1. **Batch 1（序列先行）**：執行 **Task 1**，完成 `website/` 骨架、`npm install` 與 `prepare-assets.mjs` WebP／OG 圖資轉檔驗證。
2. **Batch 2（平行派發）**：**Task 2**（`site.ts`、`global.css`、`BaseLayout.astro`、`site-data.test.mjs`）與 **Task 3**（`.firebaserc`、`firebase.json`、`.github/workflows/website.yml`）寫入路徑零重疊，可並行執行並於批次結束點合併檢查。
3. **Batch 3（序列整合）**：執行 **Task 4**，實作 `showcase.ts`、`OsSwitcherBox.astro`、`LandingPage.astro` 與雙語入口路由並通過 `npm run build`。
4. **Batch 4（序列收斂）**：執行 **Task 5**，通過 `npm run build && npm test` 全套 AC 門檻與 `flutter_restaruant/` 零侵入稽核。

> **流程紀律提醒：** 全部任務完成且通過 `verifier` 驗收後，依 `gen-dev-workflow` 進入 STAGE 3 由 `reviewer` 審查，且不得於本地或 CI 實機執行 `firebase deploy --only hosting`。

---

## 5. 最終驗收核對表（對應規格 AC-1 ～ AC-6）

- [ ] **AC-1（獨立目錄與零侵入）**：`<WORKTREE_ROOT>/website/` 獨立建立且 `.gitignore` 正確忽略 `node_modules/`、`dist/`、`.astro/`、`.firebase/`；`git diff -- flutter_restaruant/` 與 `git status --short -- flutter_restaruant/` 皆為空。
- [ ] **AC-2（雙語路由、SEO/OG 與品牌視覺系統）**：產出 `/`（`lang="en"`）與 `/zh-tw/`（`lang="zh-Hant-TW"`），具備 `canonical`、`hreflang`（`en` / `zh-Hant-TW` / `x-default`）、OG/Twitter Card、`SoftwareApplication` JSON-LD、`#D84A20` + `#FFFBF7` 淺／深色 `theme-color` 及受 `IntersectionObserver` 與 `prefers-reduced-motion: reduce` 保護的 2D `<canvas>`。
- [ ] **AC-3（Scrollytelling 鏡頭與 WebP 圖資輕量化）**：`.scrolly` 支援寬螢幕滾動同步 + 點擊 + 方向鍵切換並齊備 `role="tablist"` / `role="tab"` / `role="tabpanel"` / `aria-selected` / `aria-hidden`；6 張 `doc/screenshots/*.png` 已壓縮為 `720x1600` WebP（單檔 ≤ 150 KB、合計 ≤ 600 KB）且無任何假圖檔。
- [ ] **AC-4（Mobile / macOS 平台切換與誠實 CTA）**：`.os-switch` 支援 Mobile 與 macOS Desktop（Apple Silicon / macOS 14+）、系統偵測預設 + `localStorage` 記憶、一鍵 Copy CLI + `aria-live="polite"`；全站無假 `.dmg`/`.apk`/`.ipa`/`.exe` 下載連結。
- [ ] **AC-5（Firebase Hosting 與專屬 CI 工作流）**：`website/.firebaserc` 指向 `findrestaurant-c80ea`；`website/firebase.json` 僅含 `hosting`（`public: "dist"`、`/_astro/**` 與 `/screenshots/**` Cache-Control）；`.github/workflows/website.yml` 嚴格限定 `website/**` 變動觸發且具備未設 secret 時之 `GITHUB_STEP_SUMMARY` 引導。
- [ ] **AC-6（靜態建置與自動化檢查全過）**：`npm run build` 0 error，`npm test`（`site-data.test.mjs` + `verify-dist.test.mjs`）全數通過，全 `dist/` ≤ 1.5 MB，且未執行實機 `firebase deploy --only hosting`。
