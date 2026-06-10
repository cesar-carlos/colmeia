import 'package:colmeia/core/constants/app_version.g.dart';
import 'package:flutter/foundation.dart';

/// Optional key/value lines attached to support clipboard bundles.
class AgentQueryFailureSupportContext {
  const AgentQueryFailureSupportContext({
    this.lines = const <String, String>{},
  });

  factory AgentQueryFailureSupportContext.environment({
    String? localeName,
    Map<String, String> extra = const <String, String>{},
  }) {
    return AgentQueryFailureSupportContext(
      lines: <String, String>{
        'appVersion': appVersion,
        'platform': _platformLabel(),
        if (localeName != null && localeName.isNotEmpty) 'locale': localeName,
        ...extra,
      },
    );
  }

  final Map<String, String> lines;

  AgentQueryFailureSupportContext merge(
    AgentQueryFailureSupportContext? other,
  ) {
    if (other == null || other.lines.isEmpty) {
      return this;
    }
    return AgentQueryFailureSupportContext(
      lines: <String, String>{...lines, ...other.lines},
    );
  }
}

String _platformLabel() {
  if (kIsWeb) {
    return 'web';
  }
  return defaultTargetPlatform.name;
}
