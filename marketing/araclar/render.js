// Kareleri başsız Edge ile çizer: her kare zamanın saf fonksiyonu.
// node render.js <video.html> <çıkış klasörü> [still t1,t2,...]
const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');

const [html, out, mode, list] = process.argv.slice(2);
const FPS = 30; let DUR = 22;

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    headless: true,
    args: ['--hide-scrollbars', '--force-device-scale-factor=1'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1080, height: 1920, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(path.resolve(html)).href, { waitUntil: 'load' });
  await page.evaluate(async () => { await document.fonts.ready; });

  DUR = await page.evaluate(() => window.DUR || 22);
  const times = mode === 'still'
    ? list.split(',').map(Number)
    : Array.from({ length: FPS * DUR }, (_, i) => i / FPS);
  for (const [i, t] of times.entries()) {
    await page.evaluate((t) => window.render(t), t);
    const name = mode === 'still' ? `still_${t.toFixed(2)}.jpg` : `f${String(i).padStart(4, '0')}.jpg`;
    await page.screenshot({ path: path.join(out, name), type: 'jpeg', quality: 93 });
    if (mode !== 'still' && i % 90 === 0) console.log('kare', i);
  }
  await browser.close();
  console.log('bitti', times.length);
})().catch((e) => { console.error(e); process.exit(1); });
