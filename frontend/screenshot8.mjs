import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));
page.on('response', (res) => { if (res.status() >= 400) errors.push(`HTTP ${res.status()} ${res.url()}`); });

await page.goto('http://localhost:4200/connexion', { waitUntil: 'networkidle' });
await page.fill('input[type="email"]', 'admin@pnlf.ga');
await page.fill('input[type="password"]', 'Test1234!');
await page.click('button[type="submit"]');
await page.waitForURL('**/app/tableau-de-bord', { timeout: 10000 });

await page.goto('http://localhost:4200/app/lots', { waitUntil: 'networkidle' });
await page.waitForTimeout(600);
// click the newest lot (first row)
await page.click('table tbody tr:first-child a');
await page.waitForTimeout(1000);
const url = page.url();
const lotId = url.split('/').pop();
console.log('lotId', lotId);

// logout by clearing storage then go to public verify with lot uuid_public — but we need uuid_public not id.
// We'll grab the public link button instead.
await page.click('text=Copier le lien public');
await page.waitForTimeout(300);
const clipboardText = await page.evaluate(() => navigator.clipboard.readText().catch(() => null));
console.log('clipboard:', clipboardText);

await browser.close();
console.log('done');
