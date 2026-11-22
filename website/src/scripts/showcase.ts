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
