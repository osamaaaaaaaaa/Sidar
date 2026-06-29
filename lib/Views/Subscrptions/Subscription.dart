import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/subscription_service.dart';
import 'package:skincare/Services/purchase_policy.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _isStartingCheckout = false;
  String? _activeCheckoutPlanId;
  String? _error;
  final List<Map<String, dynamic>> _plans = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('pricing_plans')
          .select('id,name,monthly_price,features,status')
          .eq('status', 'Active')
          .order('monthly_price', ascending: true);

      if (!mounted) return;
      setState(() {
        _plans
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(response));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plans.clear();
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _parseFeatures(dynamic raw) {
    if (raw == null) return const <String>[];
    final text = raw.toString().trim();
    if (text.isEmpty) return const <String>[];

    if (text.contains('\n')) {
      return text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (text.contains(',')) {
      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return <String>[text];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTheme.backgroundGradient(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 26),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _error != null
                    ? _buildErrorState()
                    : _plans.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadPlans,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            final p = _plans[index];
                            final name = (p['name'] ?? '').toString();
                            final status = (p['status'] ?? '').toString();
                            final rawPrice = p['monthly_price'];
                            final priceNumber = rawPrice is num
                                ? rawPrice.toDouble()
                                : double.tryParse(
                                        rawPrice?.toString() ?? '0',
                                      ) ??
                                      0;
                            final priceText = priceNumber % 1 == 0
                                ? priceNumber.toInt().toString()
                                : priceNumber.toStringAsFixed(2);
                            final features = _parseFeatures(p['features']);
                            final hasValidAmount = priceNumber > 0;

                            return _buildPlanCard(
                              planId: (p['id'] ?? '').toString(),
                              name: name,
                              status: status,
                              priceText: priceText,
                              features: features,
                              isCheckoutEnabled:
                                  hasValidAmount &&
                                  PurchasePolicy.subscriptionCheckoutEnabled,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AppTheme.circleBackButton(onTap: () => Get.back()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'subscriptions_title'.tr,
                style: AppTheme.headingStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.6,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _loadPlans,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glass,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String planId,
    required String name,
    required String status,
    required String priceText,
    required List<String> features,
    required bool isCheckoutEnabled,
  }) {
    final isThisPlanLoading =
        _isStartingCheckout && _activeCheckoutPlanId == planId;

    return AppTheme.glassPanel(
      borderRadius: 16,
      borderColor: AppColors.primary.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTheme.headingStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppTheme.statusBadge(
                label: status,
                color: AppColors.primary,
                icon: Icons.star_border_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$$priceText',
                style: AppTheme.headingStyle(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'subscriptions_month_suffix'.tr,
                  style: AppTheme.bodyStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.primary.withOpacity(0.15)),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTheme.bodyStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isCheckoutEnabled) ...[
            const SizedBox(height: 24),
            AppTheme.goldButton(
              text: isThisPlanLoading
                  ? 'subscriptions_loading_checkout'.tr
                  : 'subscriptions_subscribe_now'.tr,
              isLoading: isThisPlanLoading,
              onPressed: () {
                if (isThisPlanLoading) return;
                _startCheckout(planId: planId);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startCheckout({required String planId}) async {
    if (!PurchasePolicy.subscriptionCheckoutEnabled) return;
    if (!mounted) return;
    setState(() {
      _isStartingCheckout = true;
      _activeCheckoutPlanId = planId;
    });

    try {
      final locale = Get.locale?.languageCode ?? 'en';
      final session = await _subscriptionService.createPaymentSheetSession(
        planId: planId,
        locale: locale,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Sidar',
          paymentIntentClientSecret:
              (session['payment_intent_client_secret'] ?? '').toString(),
          customerId: (session['customer_id'] ?? '').toString(),
          customerEphemeralKeySecret: (session['ephemeral_key'] ?? '')
              .toString(),
          allowsDelayedPaymentMethods: false,

          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      await _loadPlans();
      AppFeedback.success(
        'subscriptions_payment_success'.tr,
        title: 'subscriptions_info_title'.tr,
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      AppFeedback.error(
        '${'subscriptions_checkout_failed'.tr}: ${e.error.localizedMessage ?? e.error.message}',
        title: 'subscriptions_error_title'.tr,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(
        '${'subscriptions_checkout_failed'.tr}: $e',
        title: 'subscriptions_error_title'.tr,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingCheckout = false;
          _activeCheckoutPlanId = null;
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: AppTheme.glassPanel(
        borderRadius: 16,
        child: Text(
          'subscriptions_empty'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.bodyStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: AppTheme.glassPanel(
        borderRadius: 16,
        borderColor: Colors.redAccent.withOpacity(0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'subscriptions_error_title'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.headingStyle(
                fontSize: 16,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'subscriptions_unknown_error'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
