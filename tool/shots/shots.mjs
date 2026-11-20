// يصوّر شاشات التطبيق (نسخة الويب) بحسابين تجريبيين لصفحة المتجر
import { chromium } from 'playwright';
import fs from 'fs';

const api = fs.readFileSync('../../lib/data/api.dart', 'utf8');
const URL_ = api.match(/supabaseUrl = '([^']+)'/)[1];
const ANON = api.match(/supabaseAnonKey =\s*'([^']+)'/)[1];
fs.mkdirSync('raw', { recursive: true });

async function login(phone) {
  const r = await fetch(`${URL_}/functions/v1/phone-login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', apikey: ANON, Authorization: `Bearer ${ANON}` },
    body: JSON.stringify({ phone, code: '1234' }),
  });
  const j = await r.json();
  if (!j.refresh_token) throw new Error('login failed ' + phone + ' ' + JSON.stringify(j));
  return j;
}

async function rest(path, token) {
  const r = await fetch(`${URL_}/rest/v1/${path}`, { headers: { apikey: ANON, Authorization: `Bearer ${token}` } });
  return r.json();
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function shoot(browser, phone, shots) {
  const s = await login(phone);
  const ctx = await browser.newContext({ viewport: { width: 430, height: 885 }, deviceScaleFactor: 3, locale: 'ar-SA', timezoneId: 'Asia/Riyadh' });
  const page = await ctx.newPage();
  await page.goto(`http://localhost:8080/?rt=${encodeURIComponent(s.refresh_token)}#/`, { waitUntil: 'load' });
  await sleep(12000);
  for (const [name, hash] of shots) {
    const h = typeof hash === 'function' ? await hash(s.access_token) : hash;
    await page.evaluate((x) => { location.hash = x; }, h);
    await sleep(6000);
    await page.screenshot({ path: `raw/${name}.png` });
    console.log('📸', name, h);
  }
  await ctx.close();
}

const browser = await chromium.launch();
await shoot(browser, '+966500000009', [
  ['1-home', '#/home'],
  ['2-search', '#/search'],
  ['3-part', async (t) => {
    const l = await rest('listings?select=id&status=eq.active&images=neq.{}&title=ilike.*%D8%AD%D9%88%D8%B6*&limit=1', t);
    return `#/part/${l[0]?.id}`;
  }],
  ['4-request', '#/request-part'],
  ['5-orders', '#/orders'],
]);
await shoot(browser, '+966500000001', [['6-merchant', '#/m/dashboard']]);
await browser.close();
