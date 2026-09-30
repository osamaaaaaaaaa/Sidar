import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const baseCorsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const maxRequestBytes = 22_000_000;
const maxImagePayloadBytes = 18_000_000;

class PublicRequestError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

function corsHeaders(request: Request) {
  const origin = request.headers.get("origin") || "";
  const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  // Vite may choose the next free localhost port during development. Accept only loopback
  // origins in addition to the explicit production allowlist, never arbitrary websites.
  const isLoopbackDevelopmentOrigin = /^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/.test(origin);
  const isSidarProductionOrigin = origin === "https://sidarai.com" || origin === "https://www.sidarai.com";
  if (allowedOrigins.length && !isLoopbackDevelopmentOrigin && !isSidarProductionOrigin && (!origin || !allowedOrigins.includes(origin))) return null;
  return {
    ...baseCorsHeaders,
    "Access-Control-Allow-Origin": allowedOrigins.length ? origin : "*",
    "Vary": "Origin",
  };
}

function json(request: Request, body: Record<string, unknown>, status = 200) {
  const headers = corsHeaders(request);
  if (!headers) return new Response(null, { status: 403 });
  return new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json" } });
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

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json(request, { error: "Gemini is not configured on the server." }, 500);
    const contentLength = Number(request.headers.get("content-length") || 0);
    if (contentLength > maxRequestBytes) return json(request, { error: "Images are too large for analysis." }, 413);

    const { prompt, images } = await request.json();
    if (typeof prompt !== "string" || prompt.length < 40 || prompt.length > 30000) return json(request, { error: "Invalid analysis request." }, 400);
    if (!Array.isArray(images) || !images.length || images.length > 5) return json(request, { error: "Provide between 1 and 5 images." }, 400);

    let totalPayloadBytes = 0;
    const imageParts = images.map((image) => {
      const mimeType = String(image?.mimeType || "");
      const data = String(image?.data || "");
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(mimeType) || !data || data.length > 14_000_000) throw new Error("Invalid image payload.");
      totalPayloadBytes += data.length;
      return { inline_data: { mime_type: mimeType, data } };
    });
    if (totalPayloadBytes > maxImagePayloadBytes) return json(request, { error: "Images are too large for analysis." }, 413);

    const isWithinQuota = await consumeQuota(request);
    if (!isWithinQuota) return json(request, { error: "Analysis limit reached. Please try again in an hour." }, 429);

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.5-flash-lite";
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }, ...imageParts] }],
        generationConfig: { temperature: 0.4, responseMimeType: "application/json" },
      }),
    });
    const payload = await response.json();
    if (!response.ok) {
      console.error("Gemini request failed", response.status, payload?.error?.message);
      const providerMessage = response.status === 401 || response.status === 403
        ? "The server Gemini credential was rejected. Update GEMINI_API_KEY and retry."
        : response.status === 404
          ? "The configured Gemini model is unavailable. Update GEMINI_MODEL and retry."
          : response.status === 429
            ? "Gemini is temporarily rate-limited. Please retry in a few minutes."
            : "The analysis provider could not complete the request.";
      return json(request, { error: providerMessage }, 502);
    }
    const text = payload?.candidates?.[0]?.content?.parts?.map((part: { text?: string }) => part.text || "").join("") || "";
    return json(request, extractJson(text));
  } catch (error) {
    console.error("analyze-skin-scan", error instanceof Error ? error.message : error);
    if (error instanceof PublicRequestError) return json(request, { error: error.message }, error.status);
    return json(request, { error: "Unable to analyze the images." }, 500);
  }
});
