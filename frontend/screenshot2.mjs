import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on('pageerror', (err) => errors.push(err.message));
page.on('console', (msg) => {
  if (msg.type() === 'error') errors.push(msg.text());
});

await page.goto('http://localhost:4200/connexion', { waitUntil: 'networkidle' });
await page.fill('input[type="email"]', 'admin@pnlf.ga');
await page.fill('input[type="password"]', 'Test1234!');
await page.click('button[type="submit"]');
await page.waitForURL('**/app/tableau-de-bord', { timeout: 10000 });

const routes = [
  ['producteurs', '/app/producteurs'],
  ['lots', '/app/lots'],
  ['cooperatives', '/app/cooperatives'],
  ['certifications', '/app/certifications'],
  ['zones', '/app/zones-collecte'],
  ['annuaire', '/app/marketplace/annuaire'],
  ['offres', '/app/marketplace/offres'],
  ['utilisateurs', '/app/utilisateurs'],
  ['rapports', '/app/rapports'],
  ['synchronisation', '/app/synchronisation'],
  ['notifications', '/app/notifications'],
  ['parametres', '/app/parametres'],
];

for (const [name, path] of routes) {
  await page.goto(`http://localhost:4200${path}`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(800);
  await page.screenshot({ path: `shot-${name}.png` });
}

console.log('ERRORS:', JSON.stringify(errors, null, 2));
await browser.close();
console.log('done');
