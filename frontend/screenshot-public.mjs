import { chromium } from 'playwright';
import { writeFileSync } from 'fs';

const BASE = 'http://localhost:4200';
const errors = [];

async function shot(page, path, url, waitMs = 1500) {
  console.log(`→ ${url}`);
  const consoleErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', (err) => consoleErrors.push(err.message));

  await page.goto(`${BASE}${url}`, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(waitMs);
  await page.screenshot({ path, fullPage: true });
  console.log(`  ✓ ${path}`);
  if (consoleErrors.length) {
    errors.push({ url, consoleErrors });
    console.log(`  ⚠ ${consoleErrors.length} erreur(s) console`);
  }
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  await shot(page, 'shot-home.png', '/');
  await shot(page, 'shot-annuaire.png', '/annuaire', 2000);

  // Fiche producteur — premier lien de l'annuaire
  await page.goto(`${BASE}/annuaire`, { waitUntil: 'networkidle' });
  const link = page.locator('a.producteur-card__link').first();
  if (await link.count()) {
    await link.click();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'shot-producteur-public.png', fullPage: true });
    console.log('  ✓ shot-producteur-public.png');
  } else {
    console.log('  ⚠ Aucun producteur dans l\'annuaire');
  }

  await shot(page, 'shot-verify.png', '/verifier');
  await shot(page, 'shot-login.png', '/connexion');
  await shot(page, 'shot-inscription.png', '/inscription', 1500);
  await shot(page, 'shot-inscription-cooperative.png', '/inscription?type=COOPERATIVE', 1500);

  await browser.close();

  writeFileSync('screenshot-public-report.json', JSON.stringify({ errors }, null, 2));
  console.log('\nTerminé. Erreurs console:', errors.length);
  if (errors.length) {
    errors.forEach((e) => console.log(JSON.stringify(e, null, 2)));
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
