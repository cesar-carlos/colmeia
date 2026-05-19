import 'package:flutter/foundation.dart';

@immutable
class AutoRefreshOption {
  const AutoRefreshOption({
    required this.id,
    required this.duration,
  });

  final String id;
  final Duration duration;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AutoRefreshOption &&
        other.id == id &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(id, duration);
}
