class ValueObjectValidationException implements Exception {
  const ValueObjectValidationException({
    required this.objectName,
    required this.messages,
  });

  final String objectName;
  final List<String> messages;

  @override
  String toString() => '$objectName validation failed: ${messages.join(', ')}';
}
