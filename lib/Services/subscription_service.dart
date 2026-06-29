import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Services/purchase_policy.dart';

class SubscriptionService {
  SubscriptionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> createPaymentSheetSession({
    required String planId,
    required String locale,
  }) async {
    if (!PurchasePolicy.subscriptionCheckoutEnabled) {
      throw UnsupportedError(
        'Subscription checkout is temporarily unavailable.',
      );
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client.functions.invoke(
      'create-subscription-payment-sheet',
      body: <String, dynamic>{'plan_id': planId, 'locale': locale},
    );

    if (response.data == null || response.data is! Map) {
      throw Exception('Invalid payment sheet response');
    }

    final payload = Map<String, dynamic>.from(response.data as Map);
    final clientSecret = (payload['payment_intent_client_secret'] ?? '')
        .toString();
    final customerId = (payload['customer_id'] ?? '').toString();
    final ephemeralKey = (payload['ephemeral_key'] ?? '').toString();

    if (clientSecret.isEmpty || customerId.isEmpty || ephemeralKey.isEmpty) {
      throw Exception(
        (payload['error'] ?? 'Missing payment sheet fields').toString(),
      );
    }

    return payload;
  }
}
