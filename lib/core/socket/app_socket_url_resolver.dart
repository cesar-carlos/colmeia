import 'package:colmeia/core/network/app_dio_client.dart';

/// Converts the configured `apiBaseUrl` (e.g.
/// `https://hub.example.com/api/v1`) into the URL used by `socket_io_client`
/// for the `/consumers` namespace.
///
/// The hub exposes Socket.IO at the **root** (no `/api/v1` prefix); the
/// namespace is appended to the host/scheme.
///
/// See `docs/Features/consumer_socket_connection_design.md` §3.
class AppSocketUrlResolver {
  AppSocketUrlResolver({
    required String rawApiBaseUrl,
    String namespace = '/consumers',
  }) : _rawApiBaseUrl = rawApiBaseUrl,
       _namespace = namespace;

  final String _rawApiBaseUrl;
  final String _namespace;

  String get _normalizedApiBase =>
      AppDioClient.normalizeBaseUrl(_rawApiBaseUrl);

  /// URL ready to be passed to `IO.io('<consumersUrl>', ...)`.
  String get consumersUrl {
    final base = _normalizedApiBase;
    if (base.isEmpty) {
      return '';
    }
    final uri = Uri.parse(base);
    final stripped = uri.replace(path: '');
    return '$stripped$_namespace';
  }

  /// Origin (scheme + host + port) without the namespace, useful for logs.
  String get hubOrigin {
    final base = _normalizedApiBase;
    if (base.isEmpty) {
      return '';
    }
    final uri = Uri.parse(base);
    return uri.replace(path: '').toString();
  }

  String get namespace => _namespace;
}
