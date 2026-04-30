String buildContainsToken(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty) {
    return name;
  }

  final firstWord = normalized.split(RegExp(r'\s+')).first;
  if (firstWord.length <= 3) {
    return firstWord;
  }
  return firstWord.substring(0, 3);
}
