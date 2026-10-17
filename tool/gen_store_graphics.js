// Sinh icon 512×512 và ảnh nổi bật 1024×500 cho Google Play từ branding/launcher_icon.svg.
// Cần Node + Playwright (Chromium). Chạy từ thư mục gốc của app: node tool/gen_store_graphics.js
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.join(__dirname, '..');
const svg = fs.readFileSync(path.join(root, 'branding/launcher_icon.svg'), 'utf8');
// Phông nhúng dạng data URL vì trang dựng bằng setContent không được đọc file:// .
const font = (w) => 'data:font/ttf;base64,' + fs.readFileSync(path.join(root, `assets/fonts/BeVietnamPro-${w}.ttf`)).toString('base64');

const icon = `<html><body style="margin:0">${svg}</body></html>`;

const feature = `<html><head><style>
@font-face { font-family: BVP; src: url(${font('Bold')}); font-weight: 700; }
@font-face { font-family: BVP; src: url(${font('Medium')}); font-weight: 500; }
body { margin: 0; width: 1024px; height: 500px; font-family: BVP;
  background: linear-gradient(135deg, #2E8B50, #124F29); color: #fff;
  display: flex; align-items: center; gap: 56px; padding: 0 72px; box-sizing: border-box; }
.icon svg { width: 260px; height: 260px; border-radius: 56px; box-shadow: 0 18px 40px rgba(0,0,0,.28); }
h1 { font-size: 76px; font-weight: 700; margin: 0 0 18px; letter-spacing: -1px; }
p { font-size: 32px; font-weight: 500; margin: 0; line-height: 1.45; opacity: .92; }
</style></head><body>
<div class="icon">${svg}</div>
<div><h1>Ôn thi GPLX</h1><p>600 câu lý thuyết mới<br>Đủ 15 hạng · Thi thử như thật</p></div>
</body></html>`;

(async () => {
  const browser = await chromium.launch();
  const shot = async (html, w, h, file) => {
    const page = await browser.newPage({ viewport: { width: w, height: h } });
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({ path: path.join(root, file), clip: { x: 0, y: 0, width: w, height: h } });
    await page.close();
  };
  await shot(icon, 512, 512, 'store/play/icon-512.png');
  await shot(feature, 1024, 500, 'store/play/feature-graphic-1024x500.png');
  await browser.close();
})();
