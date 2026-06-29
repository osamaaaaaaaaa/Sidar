import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  // Native clients are not subject to CORS. Browser payment requests must
  // originate from the isolated customer portal.
  "Access-Control-Allow-Origin": "https://app.sidarai.com",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
  if (!req.headers.get("content-type")?.toLowerCase().includes("application/json")) {
    return new Response(JSON.stringify({ error: "Content-Type must be application/json" }), { status: 415, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!supabaseUrl || !supabaseAnonKey || !stripeSecretKey) {
      return new Response(JSON.stringify({ error: "Missing server config" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const planId = String(body.plan_id ?? "").trim();
    if (!planId) {
      return new Response(JSON.stringify({ error: "plan_id is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: plan, error: planError } = await supabase
      .from("pricing_plans")
      .select("id,name,monthly_price,status,stripe_price_id")
      .eq("id", planId)
      .eq("status", "Active")
      .maybeSingle();
    if (planError || !plan) {
      return new Response(JSON.stringify({ error: "Plan not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const customerSearchParams = new URLSearchParams();
    customerSearchParams.append("email", user.email ?? "");
    customerSearchParams.append("limit", "1");
    const customerSearch = await fetch(
      `https://api.stripe.com/v1/customers?${customerSearchParams.toString()}`,
      {
        headers: { Authorization: `Bearer ${stripeSecretKey}` },
      },
    );
    const customerSearchPayload = await customerSearch.json();
    if (!customerSearch.ok) {
      return new Response(
        JSON.stringify({
          error: customerSearchPayload?.error?.message ?? "Stripe customer fetch failed",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    let customerId = String(customerSearchPayload?.data?.[0]?.id ?? "");
    if (!customerId) {
      const createCustomerBody = new URLSearchParams();
      createCustomerBody.append("email", user.email ?? "");
      createCustomerBody.append("metadata[user_id]", user.id);
      const createCustomer = await fetch("https://api.stripe.com/v1/customers", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${stripeSecretKey}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: createCustomerBody.toString(),
      });
      const createCustomerPayload = await createCustomer.json();
      if (!createCustomer.ok) {
        return new Response(
          JSON.stringify({
            error: createCustomerPayload?.error?.message ?? "Stripe customer create failed",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
      customerId = String(createCustomerPayload?.id ?? "");
    }

    const amount = Number(plan.monthly_price ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      return new Response(JSON.stringify({ error: "Invalid plan amount" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const paymentIntentBody = new URLSearchParams();
    paymentIntentBody.append("amount", Math.round(amount * 100).toString());
    paymentIntentBody.append("currency", "usd");
    paymentIntentBody.append("customer", customerId);
    paymentIntentBody.append("automatic_payment_methods[enabled]", "true");
    paymentIntentBody.append("metadata[user_id]", user.id);
    paymentIntentBody.append("metadata[plan_id]", String(plan.id));
    paymentIntentBody.append("metadata[plan_name]", String(plan.name ?? ""));

    const paymentIntentRes = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: paymentIntentBody.toString(),
    });
    const paymentIntentPayload = await paymentIntentRes.json();
    if (!paymentIntentRes.ok) {
      return new Response(
        JSON.stringify({
          error: paymentIntentPayload?.error?.message ?? "Stripe payment intent failed",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const ephemeralKeyRes = await fetch("https://api.stripe.com/v1/ephemeral_keys", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "Stripe-Version": "2023-10-16",
      },
      body: new URLSearchParams({ customer: customerId }).toString(),
    });
    const ephemeralKeyPayload = await ephemeralKeyRes.json();
    if (!ephemeralKeyRes.ok) {
      return new Response(
        JSON.stringify({
          error: ephemeralKeyPayload?.error?.message ?? "Stripe ephemeral key failed",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        payment_intent_client_secret: paymentIntentPayload?.client_secret ?? "",
        payment_intent_id: paymentIntentPayload?.id ?? "",
        customer_id: customerId,
        ephemeral_key: ephemeralKeyPayload?.secret ?? "",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

