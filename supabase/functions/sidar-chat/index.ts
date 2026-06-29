import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const baseCorsHeaders = {
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function corsHeaders(request: Request) {
  const origin = request.headers.get("origin") || "";
  const configuredOrigins = (Deno.env.get("ALLOWED_ORIGINS") || "").split(",").map((item) => item.trim()).filter(Boolean);
  const allowedOrigins = new Set(["https://sidarai.com", "https://www.sidarai.com", "https://app.sidarai.com", ...configuredOrigins]);
  const isLocal = /^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/.test(origin);
  if (origin && !isLocal && !allowedOrigins.has(origin)) return null;
  return { ...baseCorsHeaders, "Access-Control-Allow-Origin": origin || "*", Vary: "Origin" };
}

const json = (headers: Record<string, string>, body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, "Content-Type": "application/json" },
  });

/// Developer-only telemetry: no chat text, prompt, image, or user identifier
/// is persisted here. Failures to write telemetry never affect the chat.
async function recordModelAudit(entry: {
  modelName: string;
  status: "success" | "error";
  responseKind: string;
  providerStatus?: number;
  latencyMs: number;
  inputCount: number;
}) {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceRoleKey) return;
  try {
    await fetch(`${url}/rest/v1/ai_model_audit`, {
      method: "POST",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        feature: "chat",
        provider: "google",
        model_name: entry.modelName,
        status: entry.status,
        response_kind: entry.responseKind,
        provider_status: entry.providerStatus ?? null,
        latency_ms: entry.latencyMs,
        input_kind: "text_history",
        input_count: entry.inputCount,
      }),
    });
  } catch (error) {
    console.warn("Unable to record chat model audit", error);
  }
}

const systemInstructions = `You are SIDAR, a warm beauty-care assistant for a skin and hair care app.
Give concise, practical, and culturally respectful guidance in the user's language.
You provide general educational care guidance only, never diagnosis or a replacement for a clinician.
Do not prescribe medication or claim certainty from symptoms. Encourage urgent clinical care for severe pain, breathing difficulty, facial swelling, eye involvement, fever, spreading rash, infection signs, or sudden significant hair loss.
Do not request or expose sensitive personal data. Keep answers under 220 words unless the user asks for more.`;

Deno.serve(async (req) => {
  const headers = corsHeaders(req);
  if (!headers) return new Response(null, { status: 403 });
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return json(headers, { error: "Method not allowed" }, 405);
  if (!req.headers.get("content-type")?.toLowerCase().includes("application/json")) {
    return json(headers, { error: "Content-Type must be application/json" }, 415);
  }

  try {
    const authorization = req.headers.get("Authorization");
    if (!authorization) return json(headers, { error: "Missing auth token" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    const model = Deno.env.get("GEMINI_CHAT_MODEL") ?? "gemini-3.5-flash-lite";
    if (!supabaseUrl || !supabaseAnonKey || !geminiKey) {
      return json(headers, { error: "Chat service is not configured" }, 500);
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) return json(headers, { error: "Unauthorized user" }, 401);

    const body = await req.json();
    const message = String(body?.message ?? "").trim();
    const language = body?.language === "ar" ? "Arabic" : "English";
    if (!message || message.length > 1200) {
      return json(headers, { error: "message must be between 1 and 1200 characters" }, 400);
    }

    const history = Array.isArray(body?.history) ? body.history : [];
    const contents: Array<{
      role: "user" | "model";
      parts: Array<{ text: string }>;
    }> = history
      .slice(-6)
      .map((item: unknown) => {
        const entry = item as Record<string, unknown>;
        const role: "user" | "model" = entry?.role === "assistant"
          ? "model"
          : "user";
        const content = String(entry?.content ?? "").trim().slice(0, 1200);
        return content ? { role, parts: [{ text: content }] } : null;
      })
      .filter((item): item is { role: "user" | "model"; parts: Array<{ text: string }> } => item !== null);

    // The app's local greeting is visual-only. Gemini conversation history must
    // begin with a user turn, so do not forward a leading assistant greeting.
    while (contents.first?.role === "model") contents.shift();
    contents.push({ role: "user", parts: [{ text: message }] });

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(geminiKey)}`;
    const startedAt = Date.now();
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: `${systemInstructions}\nReply in ${language}.` }],
        },
        contents,
        generationConfig: {
          temperature: 0.35,
          // Enough for a complete Arabic care answer while keeping the chat
          // bounded; 240 can end a response mid-sentence.
          maxOutputTokens: 360,
        },
      }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      await recordModelAudit({
        modelName: model,
        status: "error",
        responseKind: "provider_error",
        providerStatus: response.status,
        latencyMs: Date.now() - startedAt,
        inputCount: contents.length,
      });
      console.error("Gemini chat request failed", response.status, payload?.error?.message ?? "");
      return json(headers, { error: "AI service request failed. Please retry shortly." }, 502);
    }

    const outputText = (payload?.candidates?.[0]?.content?.parts ?? [])
      .map((part: Record<string, unknown>) => String(part?.text ?? ""))
      .join("\n")
      .trim();
    if (!outputText) return json(headers, { error: "AI service returned an empty reply" }, 502);
    await recordModelAudit({
      modelName: model,
      status: "success",
      responseKind: "text",
      providerStatus: response.status,
      latencyMs: Date.now() - startedAt,
      inputCount: contents.length,
    });
    return json(headers, { reply: outputText });
  } catch (error) {
    console.error(error);
    return json(headers, { error: "Unable to process the chat request" }, 500);
  }
});
