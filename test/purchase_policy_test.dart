import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Services/purchase_policy.dart';
import 'package:skincare/Services/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS checkout is blocked before auth or a payment request', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(PurchasePolicy.subscriptionsEnabled, isFalse);
    final client = SupabaseClient('https://example.invalid', 'test-public-key');
    addTearDown(client.dispose);
    await expectLater(
      SubscriptionService(client: client).createPaymentSheetSession(
        planId: 'premium', locale: 'en',
      ),
      throwsUnsupportedError,
    );
  });

  test('Android purchase policy is unchanged', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(PurchasePolicy.subscriptionsEnabled, isTrue);
  });
}
