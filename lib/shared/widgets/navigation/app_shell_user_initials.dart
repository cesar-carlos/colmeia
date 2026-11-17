import 'package:flutter/widgets.dart' show StringCharacters;

String appShellUserInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.single.characters.take(2).toString().toUpperCase();
  }
  final first = parts.first;
  final last = parts.last;
  return '${first.characters.first}${last.characters.first}'.toUpperCase();
}
