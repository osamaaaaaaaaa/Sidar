# Stripe + Supabase Setup

## 1) DB migration
Run migration so plans can store Stripe price IDs and user subscriptions can be tracked:

```bash
supabase db push
```

Migration file:
- `supabase/migrations/20260601_add_stripe_subscriptions.sql`

## 2) Fill `pricing_plans.stripe_price_id`
Each active row in `pricing_plans` must have a real Stripe recurring price id (example: `price_...`).

## 3) Deploy edge functions

```bash
supabase functions deploy create-subscription-payment-sheet
supabase functions deploy stripe-webhook
```

## 4) Set function secrets

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxx
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx
supabase secrets set APP_BASE_URL=https://your-app-domain.com
```

## 5) App runtime key (public)
Run app with publishable key:

```bash
flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx
```

## 6) Configure Stripe webhook
In Stripe dashboard, create endpoint:

- URL: `https://<PROJECT-REF>.functions.supabase.co/stripe-webhook`
- Events:
  - `payment_intent.succeeded`
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`

Use the generated webhook signing secret as `STRIPE_WEBHOOK_SECRET`.

## 7) Flutter app side
Subscription screen now calls:
- `create-subscription-payment-sheet` function
- receives `payment_intent_client_secret`, `customer_id`, `ephemeral_key`
- opens Stripe Payment Sheet inside the app

No hardcoded payment flow remains in the subscribe action.
