class StartupConfigurationException implements Exception {
  const StartupConfigurationException();
}

class BackendConfig {
  const BackendConfig({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;
}

String normalizeSupabaseUrl(String value) {
  var url = value.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.endsWith('/rest/v1')) {
    url = url.substring(0, url.length - '/rest/v1'.length);
  }
  return url;
}

BackendConfig? resolveBackendConfig({
  required String url,
  required String publishableKey,
  required bool allowInMemory,
  required bool isRelease,
}) {
  if (allowInMemory && !isRelease) return null;
  final normalized = normalizeSupabaseUrl(url);
  final uri = Uri.tryParse(normalized);
  final key = publishableKey.trim();
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      key.length < 20 ||
      key.startsWith('sb_secret_') ||
      key.contains('service_role')) {
    throw const StartupConfigurationException();
  }
  return BackendConfig(url: normalized, publishableKey: key);
}
