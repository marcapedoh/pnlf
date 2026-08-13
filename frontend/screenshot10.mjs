import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });

// Direct navigation (no router transition at all, fresh load)
await page.goto('http://localhost:4200/verifier', { waitUntil: 'networkidle' });
await page.waitForTimeout(4000);
await page.screenshot({ path: 'shot-verify-fresh.png' });

await browser.close();
console.log('done');
