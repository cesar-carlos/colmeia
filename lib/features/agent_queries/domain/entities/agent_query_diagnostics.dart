class AgentQueryDiagnostics {
  AgentQueryDiagnostics() : _clock = Stopwatch()..start();
  final Stopwatch _clock;
  final Map<String, double> _phases = {};
  final List<String> _routes = [];
  final Map<String, double> _agentPhases = {};
  bool _sealed = false;
  int _attempts = 0;
  bool _cacheHit = false;
  bool _cancelled = false;
  int get attempts => _attempts;
  set attempts(int value) {
    if (!_sealed) _attempts = value;
  }

  bool get cacheHit => _cacheHit;
  set cacheHit(bool value) {
    if (!_sealed) _cacheHit = value;
  }

  bool get cancelled => _cancelled;
  set cancelled(bool value) {
    if (!_sealed) _cancelled = value;
  }

  void agentPhases(Map<String, double> phases) {
    if (!_sealed) _agentPhases.addAll(phases);
  }

  /// Freezes the logical operation before late responses or scope disposal.
  void complete() {
    mark('complete');
    _sealed = true;
    _clock.stop();
  }

  void mark(String phase) {
    if (!_sealed) _phases.putIfAbsent(phase, () => elapsedMs);
  }

  double get elapsedMs => _clock.elapsedMicroseconds / 1000;
  void addDuration(String phase, Duration duration) {
    if (_sealed) return;
    _phases.update(
      phase,
      (v) => v + duration.inMicroseconds / 1000,
      ifAbsent: () => duration.inMicroseconds / 1000,
    );
  }

  void route(String route) {
    if (_sealed) return;
    if (_routes.isEmpty || _routes.last != route) _routes.add(route);
  }

  Map<String, Object?> toJson() => {
    'phasesMs': Map<String, double>.of(_phases),
    'routes': List<String>.of(_routes),
    'attempts': attempts,
    'transport': _routes.isEmpty ? null : _routes.last,
    'fallback':
        _routes
            .map((route) => route.startsWith('relay') ? 'relay' : route)
            .toSet()
            .length >
        1,
    if (_agentPhases.isNotEmpty)
      'agentPhasesMs': Map<String, double>.of(_agentPhases),
    'cacheHit': cacheHit,
    'cancelled': cancelled,
  };
}
