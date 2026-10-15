// Sinh icon ứng dụng cho mọi nền tảng từ branding/launcher_icon.svg.
// Cần Node + Playwright (Chromium) và ImageMagick (`convert`).
// Chạy từ thư mục gốc của app: node tool/gen_launcher_icons.js
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('playwright');

const root = path.join(__dirname, '..');
const svg = fs.readFileSync(path.join(root, 'branding/launcher_icon.svg'), 'utf8');
const tmp = fs.mkdtempSync(path.join(require('os').tmpdir(), 'icon-'));

// Các biến thể: full = vuông kín nền, rounded = bo góc nền trong suốt,
// mac = ô bo góc 824/1024 theo lưới icon macOS, fg = chỉ vô lăng (adaptive icon Android).
function variant(kind) {
  if (kind === 'full') return svg;
  if (kind === 'fg') return svg.replace(/<rect id="background"[^>]*\/>/, '').replace(/<circle cx="256" cy="268" r="34"[^>]*\/>/, '<circle cx="256" cy="268" r="24" fill="none" stroke="#fff" stroke-width="20"/>')
    .replace(/<circle[^>]*fill="#1B6E3A"\/>/, '');
  const r = kind === 'mac' ? 93 : 112;
  const inset = kind === 'mac' ? 50 : 0;
  const size = 512 - inset * 2;
  return svg
    .replace('<rect id="background"', `<clipPath id="clip"><rect x="${inset}" y="${inset}" width="${size}" height="${size}" rx="${r}"/></clipPath><g clip-path="url(#clip)"><rect id="background"`)
    .replace('<g id="foreground">', '</g><g id="foreground">')
    .replace('<g id="foreground">', kind === 'mac' ? `<g id="foreground" transform="translate(256 256) scale(${size / 512}) translate(-256 -256)">` : '<g id="foreground">');
}

const out = (p) => path.join(root, p);
const jobs = [];
const add = (kind, size, file, opaque = false) => jobs.push({ kind, size, file, opaque });

// Android: icon cũ (bo góc) + foreground cho adaptive icon (108dp).
const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, s] of Object.entries(dens)) {
  add('rounded', 48 * s, `android/app/src/main/res/mipmap-${d}/ic_launcher.png`);
  add('fg', 108 * s, `android/app/src/main/res/mipmap-${d}/ic_launcher_foreground.png`);
}
// iOS: vuông kín nền, không kênh alpha.
const ios = JSON.parse(fs.readFileSync(out('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'), 'utf8'));
for (const img of ios.images) {
  const px = Math.round(parseFloat(img.size) * parseInt(img.scale));
  add('full', px, `ios/Runner/Assets.xcassets/AppIcon.appiconset/${img.filename}`, true);
}
// macOS.
for (const s of [16, 32, 64, 128, 256, 512, 1024]) add('mac', s, `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${s}.png`);
// Web.
add('rounded', 192, 'web/icons/Icon-192.png');
add('rounded', 512, 'web/icons/Icon-512.png');
add('full', 192, 'web/icons/Icon-maskable-192.png');
add('full', 512, 'web/icons/Icon-maskable-512.png');
add('rounded', 32, 'web/favicon.png');
// Windows (.ico ghép từ nhiều cỡ).
const ico = [16, 32, 48, 256].map((s) => ({ s, f: path.join(tmp, `ico_${s}.png`) }));
for (const { s, f } of ico) jobs.push({ kind: 'rounded', size: s, file: f, abs: true });

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const j of jobs) {
    await page.setViewportSize({ width: j.size, height: j.size });
    await page.setContent(`<html><body style="margin:0">${variant(j.kind).replace('width="512" height="512"', `width="${j.size}" height="${j.size}"`)}</body></html>`);
    const dest = j.abs ? j.file : out(j.file);
    await page.screenshot({ path: dest, omitBackground: !j.opaque, clip: { x: 0, y: 0, width: j.size, height: j.size } });
    if (j.opaque) execFileSync('convert', [dest, '-alpha', 'off', dest]);
  }
  await browser.close();
  execFileSync('convert', [...ico.map((i) => i.f), out('windows/runner/resources/app_icon.ico')]);
  fs.rmSync(tmp, { recursive: true });
  console.log(`Đã sinh ${jobs.length} ảnh icon.`);
})();
