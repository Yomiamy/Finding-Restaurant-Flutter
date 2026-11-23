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

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function assertNoBinaryStrings(value, context) {
  if (typeof value === 'string') {
    assert.doesNotMatch(value, /\.(dmg|apk|ipa|exe)([?#]|$)/i, context);
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) assertNoBinaryStrings(item, context);
    return;
  }
  if (value && typeof value === 'object') {
    for (const child of Object.values(value)) assertNoBinaryStrings(child, context);
  }
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
    const escapedCanonical = escapeRegExp(c.canonical);

    assert.match(html, new RegExp(`<html[^>]+lang="${escapeRegExp(c.lang)}"`));
    assert.match(html, new RegExp(`<link[^>]+rel="canonical"[^>]+href="${escapedCanonical}"`));
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
    assert.match(html, new RegExp(`<meta[^>]+property="og:url"[^>]+content="${escapedCanonical}"`));
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
    assert.equal(jsonLd.softwareVersion, '2.4.0+40');
    assert.equal(jsonLd.codeRepository, 'https://github.com/Yomiamy/Finding-Restaurant-Flutter');
    assert.equal('downloadUrl' in jsonLd, false);
    assertNoBinaryStrings(jsonLd, `Forbidden binary extension in JSON-LD of ${c.file}`);
  }
});

test('AC-3 & AC-4: Scrolly WAI-ARIA contract, OS switcher, honest CTAs, and 0 broken internal assets', () => {
  assertDistExists();

  for (const rel of ['index.html', 'zh-tw/index.html']) {
    const html = readFileSync(path.join(DIST_DIR, rel), 'utf8');

    // WAI-ARIA tabs and tabpanels: verify element-level pairing and initial state for all 6 lenses
    assert.match(html, /role="tablist"[^>]*aria-orientation="vertical"/);
    const tabs = html.match(/role="tab"/g) ?? [];
    const panels = html.match(/role="tabpanel"/g) ?? [];
    assert.equal(tabs.length, 6, `${rel} must contain 6 role="tab" elements`);
    assert.equal(panels.length, 6, `${rel} must contain 6 role="tabpanel" elements`);
    const colHeaders = html.match(/<th scope="col">/g) ?? [];
    assert.equal(colHeaders.length, 4, `${rel} capability table must define 4 <th scope="col"> headers`);

    for (let i = 1; i <= 6; i += 1) {
      const id = `lens-0${i}`;
      const tabTag = html.match(new RegExp(`<button\\b[^>]*\\bid="tab-${id}"[^>]*>`))?.[0];
      assert.ok(tabTag, `${rel} missing tab element id="tab-${id}"`);
      assert.match(tabTag, /\brole="tab"/);
      assert.match(tabTag, new RegExp(`\\baria-controls="panel-${id}"`));
      assert.match(tabTag, new RegExp(`\\baria-selected="${i === 1 ? 'true' : 'false'}"`));

      const panelTag = html.match(new RegExp(`<figure\\b[^>]*\\bid="panel-${id}"[^>]*>`))?.[0];
      assert.ok(panelTag, `${rel} missing tabpanel element id="panel-${id}"`);
      assert.match(panelTag, /\brole="tabpanel"/);
      assert.match(panelTag, new RegExp(`\\baria-labelledby="tab-${id}"`));
      assert.match(panelTag, new RegExp(`\\baria-hidden="${i === 1 ? 'false' : 'true'}"`));
      assert.match(panelTag, new RegExp(`\\btabindex="${i === 1 ? '0' : '-1'}"`));
    }

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
    const footerHtml = html.match(/<footer\b[\s\S]*?<\/footer>/)?.[0];
    assert.ok(footerHtml, `Missing <footer> element in ${rel}`);
    assert.match(footerHtml, /<div class="lang-switch" role="group"/);
    assert.doesNotMatch(footerHtml, /<nav\b/i, `Footer must not contain duplicate <nav> in ${rel}`);

    // Visible HTML text must not leak raw Markdown backticks (outside <script> / <pre>)
    const visibleHtml = html
      .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
      .replace(/<pre\b[^>]*>[\s\S]*?<\/pre>/gi, '');
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
