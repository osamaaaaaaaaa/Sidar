/// Membership plans remain visible on every platform. Checkout is deliberately
/// paused while the store purchase flow is being finalized.
class PurchasePolicy {
  static bool get membershipsEnabled => true;

  /// Keep plans discoverable, but do not expose a payment CTA yet.
  static bool get subscriptionCheckoutEnabled => false;

  // Kept as a compatibility alias for existing membership visibility checks.
  static bool get subscriptionsEnabled => membershipsEnabled;
}
