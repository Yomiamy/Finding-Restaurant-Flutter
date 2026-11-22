import { copyFile, mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { SITE_META } from '../src/data/site.ts';

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
    <text x="174" y="83" text-anchor="middle" font-family="${sansFont}" font-size="14" font-weight="700" fill="#FFFBF7">OPEN SOURCE · v${SITE_META.appVersion}</text>
    <text x="184" y="210" font-family="${sansFont}" font-size="48" font-weight="800" fill="#1F1713">Find Restaurant</text>
    <text x="184" y="248" font-family="${sansFont}" font-size="22" font-weight="600" fill="#D84A20">尋找餐廳 · Multimodal AI Dining</text>
    <text x="68" y="330" font-family="${sansFont}" font-size="26" font-weight="600" fill="#1F1713">GenUI Decision Canvas &amp; Menu Vision</text>
    <text x="68" y="372" font-family="${sansFont}" font-size="21" fill="#63544B">Clean Architecture · BLoC · GetIt · Gemini</text>
    <line x1="68" y1="428" x2="580" y2="428" stroke="#1F1713" stroke-opacity="0.14" stroke-width="1.5"/>
    <text x="68" y="476" font-family="${monoFont}" font-size="18" font-weight="600" fill="#1F1713">Android · iOS 15+ · macOS 14+ (Apple Silicon)</text>
    <text x="68" y="516" font-family="${monoFont}" font-size="16" fill="#63544B">${SITE_META.baseUrl}</text>
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
