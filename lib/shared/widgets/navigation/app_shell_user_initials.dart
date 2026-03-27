String appShellUserInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final word = parts.single;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  final first = parts.first;
  final last = parts.last;
  final a = first.runes.isEmpty ? 0x3f : first.runes.first;
  final b = last.runes.isEmpty ? 0x3f : last.runes.first;
  return '${String.fromCharCode(a)}${String.fromCharCode(b)}'.toUpperCase();
}
