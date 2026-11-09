/// Coordinates asynchronous tab guards without applying stale decisions.
class AppTabChangeGuardController {
  int _generation = 0;

  void invalidate() => _generation++;

  Future<bool> requestChange({
    required int fromIndex,
    required int toIndex,
    required void Function() onAllowed,
    Future<bool> Function(int fromIndex, int toIndex)? guard,
  }) async {
    final generation = ++_generation;
    if (fromIndex == toIndex) return false;
    final allowed = guard == null || await guard(fromIndex, toIndex);
    if (!allowed || generation != _generation) return false;
    onAllowed();
    return true;
  }
}
