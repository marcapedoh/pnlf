import { chromium } from 'playwright';

const BASE = 'http://localhost:4200';

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const consoleErrors = [];
  page.on('console', (msg) => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
  page.on('pageerror', (err) => consoleErrors.push(err.message));

  await page.goto(`${BASE}/connexion`, { waitUntil: 'networkidle' });
  await page.fill('input[type="email"]', 'admin@pnlf.ga');
  await page.fill('input[type="password"]', 'Staeel16@');
  await page.click('button[type="submit"]');
  await page.waitForURL(/tableau-de-bord/, { timeout: 15000 });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'shot-admin-dashboard.png', fullPage: true });
  console.log('✓ shot-admin-dashboard.png');

  // Cloche de notifications
  await page.click('.app-header__bell');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'shot-admin-notif-bell.png' });
  console.log('✓ shot-admin-notif-bell.png');

  // Formulaire de déclaration de lot (photo picker)
  await page.goto(`${BASE}/app/lots/nouveau`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'shot-admin-lot-form.png', fullPage: true });
  console.log('✓ shot-admin-lot-form.png');

  await browser.close();
  console.log('Erreurs console:', consoleErrors.length);
  if (consoleErrors.length) console.log(consoleErrors);
}

main().catch((e) => { console.error(e); process.exit(1); });
