# DermIQ face analysis setup

The `analyze-skin-scan` Edge Function submits one full-face JPEG/PNG to DermIQ, polls for the result, then sends the returned analysis and user context to Gemini to compose the report. The image itself is not sent to Gemini. DermIQ consumes one credit for each submitted analysis. Its masks are not currently displayed or saved.

Set `DERMIQ_API_KEY` and `GEMINI_API_KEY` as Supabase Edge Function secrets, and configure `GEMINI_MODEL` for an available Gemini model. Deploy `analyze-skin-scan` with JWT verification enabled. Never put provider keys in the mobile app or Git. The existing authenticated `consume_analysis_quota` RPC must be deployed. After deploying, verify with a real authenticated account and a clear face photo; this incurs a DermIQ credit. Both providers receive sensitive personal data, so ensure the application's privacy notice and consent cover this processing.

The current integration supports one full-face photo only, not hair or other body areas. It maps DermIQ's overall, pore and wrinkle scores to the existing report; unsupported metrics and confidence are left unavailable. The service does not automatically retry a DermIQ submission because it may consume an additional credit.
