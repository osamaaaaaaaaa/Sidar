window.SIDAR_CONFIG = {
  APP_NAME: 'SIDAR',
  DEFAULT_LANG: 'en',

  // Supabase
  SUPABASE_URL: 'https://YOUR-PROJECT.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
  SUPABASE_BUCKET: 'scan-images',
  AI_EDGE_FUNCTION_NAME: 'analyze-skin-scan',

  // Real analysis through Firebase AI Logic + Gemini
  USE_FIREBASE_AI_LOGIC: true,
  FIREBASE_GEMINI_MODEL: 'gemini-3.5-flash-lite',
  FIREBASE_CONFIG: {
    apiKey: 'YOUR_FIREBASE_WEB_API_KEY',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    appId: 'YOUR_FIREBASE_APP_ID',
    storageBucket: 'YOUR_PROJECT.firebasestorage.app',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  },
};
