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
