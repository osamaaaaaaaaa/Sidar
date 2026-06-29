import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  // Browser checkout is permitted only from the customer portal; native
  // clients are not subject to CORS enforcement.
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
    const appUrl = Deno.env.get("APP_BASE_URL") ?? "https://example.com";

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
    const locale = String(body.locale ?? "en").toLowerCase();
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

    const stripePriceId = String(plan.stripe_price_id ?? "").trim();
    if (!stripePriceId) {
      return new Response(
        JSON.stringify({ error: "Plan is missing stripe_price_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const params = new URLSearchParams();
    params.append("mode", "subscription");
    params.append("line_items[0][price]", stripePriceId);
    params.append("line_items[0][quantity]", "1");
    params.append("success_url", `${appUrl}/subscription-success?session_id={CHECKOUT_SESSION_ID}`);
    params.append("cancel_url", `${appUrl}/subscription-cancelled`);
    params.append("customer_email", user.email ?? "");
    params.append("client_reference_id", user.id);
    params.append("metadata[user_id]", user.id);
    params.append("metadata[plan_id]", String(plan.id));
    params.append("metadata[plan_name]", String(plan.name ?? ""));
    params.append("locale", locale === "ar" ? "ar" : "en");

    const stripeRes = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });

    const stripePayload = await stripeRes.json();
    if (!stripeRes.ok) {
      return new Response(JSON.stringify({ error: stripePayload?.error?.message ?? "Stripe error" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        checkout_url: stripePayload.url,
        session_id: stripePayload.id,
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

