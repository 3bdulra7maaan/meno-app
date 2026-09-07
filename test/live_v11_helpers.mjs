const sensitiveJsonField =
  /("(?:[^"\\]*token|password|authorization|api[_-]?key|secret|service_role)"\s*:\s*")[^"]*(")/gi;
const bearerToken = /\bBearer\s+[^\s",}]+/gi;
const jwtToken = /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g;
const emailAddress = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi;

export function safeSupabaseResponseBody(raw, maxLength = 2000) {
  if (!raw) return '<empty response body>';

  return String(raw)
    .replace(sensitiveJsonField, '$1[REDACTED]$2')
    .replace(bearerToken, 'Bearer [REDACTED]')
    .replace(jwtToken, '[REDACTED_TOKEN]')
    .replace(emailAddress, '[REDACTED_EMAIL]')
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

export function githubErrorAnnotation(message) {
  const escaped = String(message)
    .replaceAll('%', '%25')
    .replaceAll('\r', '%0D')
    .replaceAll('\n', '%0A');
  return `::error title=Supabase request failed::${escaped}`;
}
