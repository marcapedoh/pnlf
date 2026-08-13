import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));
page.on('response', (res) => { if (res.status() >= 400) errors.push(`HTTP ${res.status()} ${res.url()}`); });

await page.goto('http://localhost:4200/verifier/d2c7dfb2-0b3c-44af-b9db-1d9c0528485e', { waitUntil: 'networkidle' });
await page.waitForTimeout(1500);
await page.screenshot({ path: 'shot-verify-result.png', fullPage: true });
console.log('ERRORS:', JSON.stringify(errors, null, 2));

await browser.close();
console.log('done');
