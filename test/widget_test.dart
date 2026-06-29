import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Services/supabase_config.dart';

void main() {
  test('release services have public client configuration', () {
    expect(Uri.tryParse(SupabaseConfig.url)?.hasScheme, isTrue);
    expect(SupabaseConfig.anonKey, isNotEmpty);
    expect(
      SupabaseConfig.googleWebClientId,
      endsWith('.apps.googleusercontent.com'),
    );
    expect(SupabaseConfig.stripePublishableKey, startsWith('pk_'));
  });
}
