import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));

await page.goto('http://localhost:4200/connexion', { waitUntil: 'networkidle' });
await page.fill('input[type="email"]', 'admin@pnlf.ga');
await page.fill('input[type="password"]', 'Test1234!');
await page.click('button[type="submit"]');
await page.waitForURL('**/app/tableau-de-bord', { timeout: 10000 });

await page.goto('http://localhost:4200/app/lots', { waitUntil: 'networkidle' });
await page.click('table tbody tr:first-child a');
await page.waitForTimeout(1200);
await page.screenshot({ path: 'shot-lot-detail.png', fullPage: true });

const lotUrl = page.url();
console.log('lot url', lotUrl);

await page.goto('http://localhost:4200/verifier', { waitUntil: 'networkidle' });
await page.waitForTimeout(800);
await page.screenshot({ path: 'shot-verify.png' });

console.log('ERRORS:', JSON.stringify(errors, null, 2));
await browser.close();
console.log('done');
