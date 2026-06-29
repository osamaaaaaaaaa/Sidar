import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const baseCorsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const maxRequestBytes = 22_000_000;
const maxImagePayloadBytes = 18_000_000;
const providerTimeoutMs = 25_000;

class PublicRequestError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

function corsHeaders(request: Request) {
  const origin = request.headers.get("origin") || "";
  const configuredOrigins = (Deno.env.get("ALLOWED_ORIGINS") || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  const allowedOrigins = new Set([
    "https://sidarai.com",
    "https://www.sidarai.com",
    "https://app.sidarai.com",
    ...configuredOrigins,
  ]);

  // Native clients do not send Origin; their JWT and the authenticated quota
  // RPC remain mandatory. Browser clients must use a trusted site origin.
  const isLoopbackDevelopmentOrigin = /^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/.test(origin);
  if (origin && !isLoopbackDevelopmentOrigin && !allowedOrigins.has(origin)) return null;
  return {
    ...baseCorsHeaders,
    "Access-Control-Allow-Origin": origin || "*",
    "Vary": "Origin",
  };
}

function json(request: Request, body: Record<string, unknown>, status = 200) {
  const headers = corsHeaders(request);
  if (!headers) return new Response(null, { status: 403 });
  return new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json" } });
}

// Internal telemetry only. Never store the image payload, prompt, generated
// result, or a user identifier in this developer-facing audit table.
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
        feature: "analysis",
        provider: "google",
        model_name: entry.modelName,
        status: entry.status,
        response_kind: entry.responseKind,
        provider_status: entry.providerStatus ?? null,
        latency_ms: entry.latencyMs,
        input_kind: "multimodal_image",
        input_count: entry.inputCount,
      }),
    });
  } catch (error) {
    console.warn("Unable to record analysis model audit", error);
  }
}

function extractJson(text: string) {
  const trimmed = text.trim();
  try {
    return JSON.parse(trimmed);
  } catch {
    const start = trimmed.indexOf("{");
    const end = trimmed.lastIndexOf("}");
    if (start >= 0 && end > start) return JSON.parse(trimmed.slice(start, end + 1));
    throw new Error("Gemini did not return JSON.");
  }
}

async function consumeQuota(request: Request) {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = request.headers.get("authorization");
  if (!url || !anonKey || !authorization) throw new PublicRequestError("Secure analysis quota is not configured.", 500);

  const response = await fetch(`${url}/rest/v1/rpc/consume_analysis_quota`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      authorization,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (!response.ok) {
    console.error("Analysis quota RPC failed", response.status, await response.text());
    throw new PublicRequestError("Could not verify your analysis quota. Please sign in again and retry.", 503);
  }
  return (await response.json()) === true;
}

serve(async (request) => {
  const headers = corsHeaders(request);
  if (!headers) return new Response(null, { status: 403 });
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") return json(request, { error: "Method not allowed" }, 405);
  if (!request.headers.get("content-type")?.toLowerCase().includes("application/json")) {
    return json(request, { error: "Content-Type must be application/json." }, 415);
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json(request, { error: "Gemini is not configured on the server." }, 500);
    const contentLength = Number(request.headers.get("content-length") || 0);
    if (contentLength > maxRequestBytes) return json(request, { error: "Images are too large for analysis." }, 413);

    const rawRequest = await request.text();
    if (rawRequest.length > maxRequestBytes) return json(request, { error: "Images are too large for analysis." }, 413);
    let requestPayload: { prompt?: unknown; images?: unknown };
    try {
      requestPayload = JSON.parse(rawRequest);
    } catch {
      return json(request, { error: "Invalid JSON request." }, 400);
    }
    const { prompt, images } = requestPayload;
    if (typeof prompt !== "string" || prompt.length < 40 || prompt.length > 30000) return json(request, { error: "Invalid analysis request." }, 400);
    if (!Array.isArray(images) || !images.length || images.length > 5) return json(request, { error: "Provide between 1 and 5 images." }, 400);

    let totalPayloadBytes = 0;
    const imageParts = images.map((image) => {
      const mimeType = String(image?.mimeType || "");
      const data = String(image?.data || "");
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(mimeType) || !data || data.length > 14_000_000 || !/^[A-Za-z0-9+/]+={0,2}$/.test(data)) {
        throw new PublicRequestError("Invalid image payload.", 400);
      }
      totalPayloadBytes += data.length;
      return { inline_data: { mime_type: mimeType, data } };
    });
    if (totalPayloadBytes > maxImagePayloadBytes) return json(request, { error: "Images are too large for analysis." }, 413);

    const isWithinQuota = await consumeQuota(request);
    if (!isWithinQuota) return json(request, { error: "Analysis limit reached. Please try again in an hour." }, 429);

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.5-flash-lite";
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
    const requestBody = JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }, ...imageParts] }],
      generationConfig: {
        temperature: 0.25,
        maxOutputTokens: 1400,
        responseMimeType: "application/json",
      },
    });

    const startedAt = Date.now();
    let response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: requestBody,
      signal: AbortSignal.timeout(providerTimeoutMs),
    });
    if ([500, 502, 503, 504].includes(response.status)) {
      await new Promise((resolve) => setTimeout(resolve, 900));
      response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: requestBody,
        signal: AbortSignal.timeout(providerTimeoutMs),
      });
    }

    const rawText = await response.text();
    let payload: Record<string, unknown> = {};
    try {
      payload = rawText ? JSON.parse(rawText) : {};
    } catch {
      payload = {};
    }

    if (!response.ok) {
      await recordModelAudit({
        modelName: model,
        status: "error",
        responseKind: "provider_error",
        providerStatus: response.status,
        latencyMs: Date.now() - startedAt,
        inputCount: images.length,
      });
      const apiError = (payload?.error as { message?: string } | undefined)?.message?.trim() || "";
      console.error("Gemini request failed", response.status, apiError || rawText.slice(0, 300));
      const isApiKeyIssue =
        response.status === 401 ||
        response.status === 403 ||
        /api key/i.test(apiError);
      const providerMessage = isApiKeyIssue
        ? "The server Gemini credential was rejected. Update GEMINI_API_KEY and retry."
        : response.status === 404
          ? "The configured Gemini model is unavailable. Update GEMINI_MODEL and retry."
          : response.status === 429
            ? "Gemini is temporarily rate-limited. Please retry in a few minutes."
            : "The analysis provider could not complete the request. Please retry shortly.";
      return json(request, { error: providerMessage }, 502);
    }
    const text = payload?.candidates?.[0]?.content?.parts?.map((part: { text?: string }) => part.text || "").join("") || "";
    const result = extractJson(text);
    await recordModelAudit({
      modelName: model,
      status: "success",
      responseKind: "structured_json",
      providerStatus: response.status,
      latencyMs: Date.now() - startedAt,
      inputCount: images.length,
    });
    return json(request, result);
  } catch (error) {
    console.error("analyze-skin-scan", error instanceof Error ? error.message : error);
    if (error instanceof PublicRequestError) return json(request, { error: error.message }, error.status);
    return json(request, { error: "Unable to analyze the images." }, 500);
  }
});
