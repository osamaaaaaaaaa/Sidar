import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

async function hmacSha256(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload),
  );
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(left: string, right: string) {
  if (left.length !== right.length) return false;
  let mismatch = 0;
  for (let index = 0; index < left.length; index += 1) mismatch |= left.charCodeAt(index) ^ right.charCodeAt(index);
  return mismatch === 0;
}

function getStripeSignature(header: string | null): { t: string; v1: string } | null {
  if (!header) return null;
  const parts = header.split(",").map((p) => p.trim());
  const t = parts.find((p) => p.startsWith("t="))?.slice(2) ?? "";
  const v1 = parts.find((p) => p.startsWith("v1="))?.slice(3) ?? "";
  if (!t || !v1) return null;
  return { t, v1 };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  try {
    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!webhookSecret || !supabaseUrl || !supabaseServiceRoleKey) {
      return new Response("Missing server config", { status: 500 });
    }

    const rawBody = await req.text();
    const sigParts = getStripeSignature(req.headers.get("stripe-signature"));
    if (!sigParts) return new Response("Invalid signature header", { status: 400 });
    const timestamp = Number(sigParts.t);
    if (!Number.isSafeInteger(timestamp) || Math.abs(Date.now() / 1000 - timestamp) > 300) {
      return new Response("Expired signature", { status: 400 });
    }

    const signedPayload = `${sigParts.t}.${rawBody}`;
    const expected = await hmacSha256(webhookSecret, signedPayload);
    if (!timingSafeEqual(expected, sigParts.v1)) {
      return new Response("Signature verification failed", { status: 400 });
    }

    const event = JSON.parse(rawBody);
    const eventType = String(event?.type ?? "");
    const object = event?.data?.object ?? {};

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    if (eventType === "checkout.session.completed") {
      const userId = String(
        object?.metadata?.user_id ?? object?.client_reference_id ?? "",
      );
      const planId = String(object?.metadata?.plan_id ?? "");
      const planName = String(object?.metadata?.plan_name ?? "");
      const customerId = String(object?.customer ?? "");
      const subscriptionId = String(object?.subscription ?? "");
      if (!userId || !planId) {
        return new Response("Missing metadata", { status: 400 });
      }

      const { error } = await supabase.from("user_subscriptions").upsert(
        {
          user_id: userId,
          plan_id: planId,
          plan_name: planName,
          stripe_customer_id: customerId,
          stripe_subscription_id: subscriptionId,
          status: "active",
          current_period_end: null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );
      if (error) throw new Error("Subscription update failed");
    }

    if (eventType === "payment_intent.succeeded") {
      const userId = String(object?.metadata?.user_id ?? "");
      const planId = String(object?.metadata?.plan_id ?? "");
      const planName = String(object?.metadata?.plan_name ?? "");
      const customerId = String(object?.customer ?? "");
      if (!userId || !planId) {
        return new Response("Missing metadata", { status: 400 });
      }

      const periodEnd = new Date();
      periodEnd.setMonth(periodEnd.getMonth() + 1);

      const { error } = await supabase.from("user_subscriptions").upsert(
        {
          user_id: userId,
          plan_id: planId,
          plan_name: planName,
          stripe_customer_id: customerId,
          stripe_subscription_id: null,
          status: "active",
          current_period_end: periodEnd.toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );
      if (error) throw new Error("Subscription update failed");
    }

    if (eventType === "customer.subscription.updated" || eventType === "customer.subscription.deleted") {
      const subscriptionId = String(object?.id ?? "");
      if (subscriptionId) {
        const status = eventType === "customer.subscription.deleted"
          ? "canceled"
          : String(object?.status ?? "active");
        const currentPeriodEndUnix = Number(object?.current_period_end ?? 0);
        const currentPeriodEnd = currentPeriodEndUnix > 0
          ? new Date(currentPeriodEndUnix * 1000).toISOString()
          : null;

        const { error } = await supabase
          .from("user_subscriptions")
          .update({
            status,
            current_period_end: currentPeriodEnd,
            updated_at: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscriptionId);
        if (error) throw new Error("Subscription update failed");
      }
    }

    return new Response("ok", { status: 200 });
  } catch (error) {
    console.error("stripe-webhook", error instanceof Error ? error.message : error);
    return new Response("Webhook processing failed", { status: 500 });
  }
});
