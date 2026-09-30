window.SIDAR_CONFIG = {
  APP_NAME: 'SIDAR',
  DEFAULT_LANG: 'en',

  // Supabase
  SUPABASE_URL: 'https://YOUR-PROJECT.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
  SUPABASE_BUCKET: 'scan-images',
  AI_EDGE_FUNCTION_NAME: 'analyze-skin-scan',

  // Gemini is called by the Supabase Edge Function only.
  // Never add a Gemini/Firebase key to browser-side configuration.
  USE_FIREBASE_AI_LOGIC: false,
  FIREBASE_GEMINI_MODEL: 'gemini-3.5-flash-lite',
};
