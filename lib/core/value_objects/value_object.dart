import 'package:flutter/foundation.dart';

@immutable
abstract class ValueObject<T> {
  const ValueObject(this.value);

  final T value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is ValueObject<T> &&
            other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$runtimeType($value)';
}
