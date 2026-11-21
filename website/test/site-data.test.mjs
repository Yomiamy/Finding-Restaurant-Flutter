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
