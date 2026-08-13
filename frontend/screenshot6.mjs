import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));
page.on('console', (msg) => { if (msg.type() === 'error') errors.push('CONSOLE:' + msg.text()); });
page.on('response', (res) => { if (res.status() >= 400) errors.push(`HTTP ${res.status()} ${res.url()}`); });

await page.goto('http://localhost:4200/connexion', { waitUntil: 'networkidle' });
await page.fill('input[type="email"]', 'admin@pnlf.ga');
await page.fill('input[type="password"]', 'Test1234!');
await page.click('button[type="submit"]');
await page.waitForURL('**/app/tableau-de-bord', { timeout: 10000 });

await page.goto('http://localhost:4200/app/lots/nouveau', { waitUntil: 'networkidle' });
await page.waitForTimeout(800);

await page.fill('input[placeholder*="Rechercher"]', 'Producteur Test');
await page.waitForTimeout(800);
await page.click('text=Producteur Test');
await page.waitForTimeout(300);

await page.selectOption('select:near(:text("Produit"))', { index: 1 }).catch(async () => {
  const selects = await page.locator('select').all();
  console.log('select count', selects.length);
});

// fallback: pick first select that is the produit one (usually first select on page)
const produitSelect = page.locator('select').first();
await produitSelect.selectOption({ index: 1 });

await page.fill('input[type="number"]', '25');

await page.click('button:has-text("Déclarer le lot")');
await page.waitForTimeout(2500);
await page.screenshot({ path: 'shot-lot-created.png', fullPage: true });
console.log('url:', page.url());
console.log('ERRORS:', JSON.stringify(errors, null, 2));

await browser.close();
console.log('done');
