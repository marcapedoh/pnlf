import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));
page.on('console', (msg) => { if (msg.type() === 'error') errors.push(msg.text()); });

await page.goto('http://localhost:4200/connexion', { waitUntil: 'networkidle' });
await page.fill('input[type="email"]', 'admin@pnlf.ga');
await page.fill('input[type="password"]', 'Test1234!');
await page.click('button[type="submit"]');
await page.waitForURL('**/app/tableau-de-bord', { timeout: 10000 });

await page.goto('http://localhost:4200/app/lots/nouveau', { waitUntil: 'networkidle' });
await page.waitForTimeout(1000);
await page.screenshot({ path: 'shot-lot-form.png' });

console.log('ERRORS so far:', JSON.stringify(errors));
await browser.close();
console.log('done');
