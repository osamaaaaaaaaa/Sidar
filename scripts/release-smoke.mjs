import { readFile } from 'node:fs/promises';

const url = String(process.env.SIDAR_SUPABASE_URL || '').replace(/\/$/, '');
const anonKey = String(process.env.SIDAR_SUPABASE_ANON_KEY || '');
const email = String(process.env.SIDAR_TEST_EMAIL || '');
const password = String(process.env.SIDAR_TEST_PASSWORD || '');
const imagePath = process.argv.find((argument) => argument.startsWith('--image='))?.slice('--image='.length);

function required(value, name) {
  if (!value) throw new Error(`Missing ${name}.`);
  return value;
}

async function request(path, options = {}) {
  const response = await fetch(`${url}${path}`, options);
  const text = await response.text();
  let body = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  return { response, body };
}

function headers(accessToken, extra = {}) {
  return {
    apikey: anonKey,
    Authorization: `Bearer ${accessToken}`,
    ...extra,
  };
}

function imageMimeType(path) {
  const extension = path.split('.').pop()?.toLowerCase();
  return ({ jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp' })[extension] || '';
}

async function main() {
  required(url, 'SIDAR_SUPABASE_URL');
  required(anonKey, 'SIDAR_SUPABASE_ANON_KEY');
  required(email, 'SIDAR_TEST_EMAIL');
  required(password, 'SIDAR_TEST_PASSWORD');

  const signIn = await request('/auth/v1/token?grant_type=password', {
    method: 'POST',
    headers: { apikey: anonKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!signIn.response.ok || !signIn.body?.access_token || !signIn.body?.user?.id) {
    throw new Error(`Authentication failed (${signIn.response.status}).`);
  }
  const accessToken = signIn.body.access_token;
  console.log('✓ authenticated test user');

  const catalog = await request('/rest/v1/products?select=id,name,brand,price,currency&is_active=eq.true&limit=1', {
    headers: headers(accessToken),
  });
  if (!catalog.response.ok || !Array.isArray(catalog.body)) {
    throw new Error(`Product catalog query failed (${catalog.response.status}).`);
  }
  console.log(`✓ verified product catalog reachable (${catalog.body.length} active sample)`);

  // This validates the deployed endpoint, JWT forwarding, and request validation
  // without consuming Gemini quota or sending an image.
  const edgeValidation = await request('/functions/v1/analyze-skin-scan', {
    method: 'POST',
    headers: headers(accessToken, { 'Content-Type': 'application/json' }),
    body: JSON.stringify({ prompt: 'Release smoke validation request with no image payload.', images: [] }),
  });
  if (edgeValidation.response.status !== 400) {
    throw new Error(`Edge Function validation expected 400, received ${edgeValidation.response.status}.`);
  }
  console.log('✓ authenticated Edge Function validation reached');

  if (!imagePath) {
    console.log('✓ safe smoke test complete; pass --image=PATH for a paid real-Gemini analysis test.');
    return;
  }

  const mimeType = imageMimeType(imagePath);
  if (!mimeType) throw new Error('Smoke image must be JPG, PNG, or WEBP.');
  const image = await readFile(imagePath);
  if (image.byteLength > 8 * 1024 * 1024) throw new Error('Smoke image must be 8 MB or smaller.');
  const deepTest = await request('/functions/v1/analyze-skin-scan', {
    method: 'POST',
    headers: headers(accessToken, { 'Content-Type': 'application/json' }),
    body: JSON.stringify({
      prompt: 'Return the approved structured SIDAR educational skin-analysis JSON for this image. Do not diagnose or prescribe medication.',
      images: [{ mimeType, data: image.toString('base64') }],
    }),
  });
  if (!deepTest.response.ok || typeof deepTest.body !== 'object' || !deepTest.body?.title || !deepTest.body?.disclaimer) {
    throw new Error(`Real Gemini analysis failed (${deepTest.response.status}).`);
  }
  console.log('✓ real Gemini response has required structured fields');
}

main().catch((error) => {
  console.error(`Release smoke test failed: ${error.message}`);
  process.exitCode = 1;
});
