// Legacy compatibility configuration. The deployed app loads public/js/config.js.
// Keep this copy key-free so old entry points cannot expose Gemini credentials.
window.SIDAR_CONFIG = {
  SUPABASE_URL: 'https://rextzhjhiktmylhwiqyk.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJleHR6aGpoaWt0bXlsaHdpcXlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1ODIyMzIsImV4cCI6MjA5MDE1ODIzMn0.3XOdM-ebYx7_9CqvnJ6sjVVRVTY7fnY-_tucOZhviKg',
  SUPABASE_BUCKET: 'scan-images',
  AI_EDGE_FUNCTION_NAME: 'analyze-skin-scan',
  APP_NAME: 'SIDAR',
  DEFAULT_LANG: 'ar',
  USE_FIREBASE_AI_LOGIC: false,
  FIREBASE_GEMINI_MODEL: 'gemini-3.5-flash-lite',
};
