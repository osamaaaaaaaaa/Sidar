const url = String(process.env.SIDAR_SUPABASE_URL || '').replace(/\/$/, '');
const anonKey = String(process.env.SIDAR_SUPABASE_ANON_KEY || '');

if (!url || !anonKey) {
  console.error('Set SIDAR_SUPABASE_URL and SIDAR_SUPABASE_ANON_KEY before running this audit.');
  process.exitCode = 1;
} else {
  const headers = { apikey: anonKey, Authorization: `Bearer ${anonKey}` };
  const protectedResources = ['profiles', 'scan_sessions', 'scan_images', 'scan_findings', 'wellness_plans'];
  let failed = false;

  for (const resource of protectedResources) {
    try {
      const response = await fetch(`${url}/rest/v1/${resource}?select=id&limit=1`, { headers });
      const data = await response.json();
      if (!response.ok || !Array.isArray(data) || data.length !== 0) {
        console.error(`✗ anon access audit failed for ${resource} (status ${response.status}).`);
        failed = true;
      } else {
        console.log(`✓ anon cannot read ${resource}`);
      }
    } catch {
      console.error(`✗ anon access audit could not reach ${resource}.`);
      failed = true;
    }
  }

  if (failed) process.exitCode = 1;
}
