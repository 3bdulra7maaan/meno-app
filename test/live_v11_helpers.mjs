const sensitiveJsonField =
  /("(?:access_token|refresh_token|token|password|authorization|apikey)"\s*:\s*")[^"]*(")/gi;
const bearerToken = /\bBearer\s+[^\s",}]+/gi;
const jwtToken = /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g;

export function safeSupabaseResponseBody(raw, maxLength = 2000) {
  if (!raw) return '<empty response body>';

  return String(raw)
    .replace(sensitiveJsonField, '$1[REDACTED]$2')
    .replace(bearerToken, 'Bearer [REDACTED]')
    .replace(jwtToken, '[REDACTED_TOKEN]')
    .slice(0, maxLength);
}

export function supabaseRequestError({method, path, status, responseBody}) {
  const safePath = String(path).split('?')[0];
  const safeBody = safeSupabaseResponseBody(responseBody);
  return new Error(
    `Live check failed: ${method} ${safePath} returned ${status}; ` +
      `Supabase response: ${safeBody}`,
  );
}
