// Bir sayfadaki birden çok tasarım yönünü (window.show(n)) ayrı ayrı çizer.
const puppeteer = require('puppeteer-core');
const path = require('path');
const { pathToFileURL } = require('url');
const [html, outDir, count] = process.argv.slice(2);
(async () => {
  const b = await puppeteer.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', headless: true });
  const p = await b.newPage();
  await p.setViewport({ width: 1080, height: 1920 });
  await p.goto(pathToFileURL(path.resolve(html)).href, { waitUntil: 'load' });
  await p.evaluate(async () => { await document.fonts.ready; });
  for (let i = 1; i <= +count; i++) {
    await p.evaluate((n) => window.show(n), i);
    await p.screenshot({ path: path.join(outDir, `yon-${i}.jpg`), type: 'jpeg', quality: 92 });
  }
  await b.close();
  console.log('ok');
})();
