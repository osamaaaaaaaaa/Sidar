class SupabaseConfig {
  static const String _fallbackUrl = 'https://rextzhjhiktmylhwiqyk.supabase.co';
  static const String _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJleHR6aGpoaWt0bXlsaHdpcXlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1ODIyMzIsImV4cCI6MjA5MDE1ODIzMn0.3XOdM-ebYx7_9CqvnJ6sjVVRVTY7fnY-_tucOZhviKg';

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _fallbackUrl,
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _fallbackAnonKey,
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '627235334254-a10q4drgj1bi35pss0mtke4hrf20i924.apps.googleusercontent.com',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const String stripePublishableKey = String.fromEnvironment(
    'pk_live_51TWGow7GaOK6oqd4xla4lZk3QFwdNOvk5uWGYhHpeHIWYmuZ7tRSOYb2TVe9Uoadv5Jmg8Wrdyq9l7NiDMsfgCY300dfil6qQs',
    defaultValue:
        'pk_live_51TWGow7GaOK6oqd4xla4lZk3QFwdNOvk5uWGYhHpeHIWYmuZ7tRSOYb2TVe9Uoadv5Jmg8Wrdyq9l7NiDMsfgCY300dfil6qQs',
  );
}
