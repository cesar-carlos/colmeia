import 'dart:async';

/// Debounces rapid callbacks; each [run] schedules its callback after [duration].
class AppDebouncer {
  AppDebouncer({required this.duration});

  final Duration duration;
  Timer? _timer;
  int _generation = 0;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }

  /// Schedules [action]. Returns a generation token callers can compare to
  /// detect superseded debounce runs.
  int run(void Function() action) {
    cancel();
    final generation = ++_generation;
    _timer = Timer(duration, () {
      if (generation == _generation) {
        action();
      }
    });
    return generation;
  }
}
