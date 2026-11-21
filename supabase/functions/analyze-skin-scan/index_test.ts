import { analyzeWithDermiq, dermiqScore } from "./dermiq.ts";
import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("submits a face photo and polls until DermIQ completes", async () => {
  const original = globalThis.fetch;
  const calls: string[] = [];
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    calls.push(String(input));
    assertEquals((init?.headers as Record<string, string>).Authorization, "Bearer test-key");
    if (calls.length === 1) {
      assertEquals(init?.method, "POST");
      assertEquals((init?.body as FormData).get("file") instanceof Blob, true);
      return Promise.resolve(Response.json({ analysis_id: "abc-123" }, { status: 202 }));
    }
    return Promise.resolve(Response.json({ status: "completed", result_json: { all: { score: 78 } } }));
  }) as typeof fetch;
  try {
    const result = await analyzeWithDermiq({ mimeType: "image/jpeg", data: "AQID" }, "test-key");
    assertEquals(result.result_json.all.score, 78);
    assertEquals(calls[1], "https://dev.dermiq.cloud/v1/results/abc-123");
  } finally { globalThis.fetch = original; }
});

Deno.test("rejects failed DermIQ results and invalid scores", async () => {
  const original = globalThis.fetch;
  let count = 0;
  globalThis.fetch = (() => Promise.resolve(Response.json(++count === 1
    ? { analysis_id: "abc-123" } : { status: "failed" }))) as typeof fetch;
  try {
    await assertRejects(() => analyzeWithDermiq({ mimeType: "image/png", data: "AQID" }, "key"));
    assertEquals(dermiqScore(80), 80);
    assertEquals(dermiqScore(101), null);
    assertEquals(dermiqScore("80"), null);
  } finally { globalThis.fetch = original; }
});
