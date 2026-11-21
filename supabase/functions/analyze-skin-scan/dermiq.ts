export class PublicRequestError extends Error {
  constructor(message: string, readonly status: number) { super(message); }
}

export async function analyzeWithDermiq(image: { mimeType: string; data: string }, apiKey: string) {
  const bytes = Uint8Array.from(atob(image.data), (character) => character.charCodeAt(0));
  if (bytes.length > 10 * 1024 * 1024) throw new PublicRequestError("DermIQ accepts images up to 10 MB.", 413);
  const form = new FormData();
  form.append("file", new Blob([bytes], { type: image.mimeType }), image.mimeType === "image/png" ? "face.png" : "face.jpg");
  const headers = { Authorization: `Bearer ${apiKey}` };
  // Do not retry this POST: an accepted request consumes a credit.
  const submitted = await fetch("https://dev.dermiq.cloud/v1/analyze", {
    method: "POST", headers, body: form, signal: AbortSignal.timeout(25_000),
  });
  if (!submitted.ok) {
    console.error("DermIQ submission failed", submitted.status);
    throw new PublicRequestError(submitted.status === 429 ? "The skin analysis service is busy. Please try again later." : "The skin analysis service could not process the image.", 502);
  }
  const queued = await submitted.json();
  if (typeof queued.analysis_id !== "string" || !/^[a-zA-Z0-9-]{1,100}$/.test(queued.analysis_id)) throw new PublicRequestError("Invalid skin analysis response.", 502);
  const deadline = Date.now() + 45_000;
  while (Date.now() < deadline) {
    const response = await fetch(`https://dev.dermiq.cloud/v1/results/${encodeURIComponent(queued.analysis_id)}`, { headers, signal: AbortSignal.timeout(10_000) });
    if (!response.ok) throw new PublicRequestError("Unable to retrieve the skin analysis result.", 502);
    const result = await response.json();
    if (result.status === "failed") throw new PublicRequestError("The skin analysis failed. Please use a clear face photo and try again.", 422);
    if (result.status === "completed") {
      if (!result.result_json || typeof result.result_json !== "object" || Array.isArray(result.result_json)) throw new PublicRequestError("Incomplete skin analysis result.", 502);
      return result;
    }
    if (!["pending", "processing"].includes(result.status)) throw new PublicRequestError("Unknown skin analysis status.", 502);
    await new Promise((resolve) => setTimeout(resolve, 1500));
  }
  throw new PublicRequestError("The skin analysis took too long. Please try again later.", 504);
}

export function dermiqScore(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 && value <= 100 ? value : null;
}

