import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_pool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

void main() {
  test('poolSize 1 routes everything through primary', () {
    final primary = _MockConnection();
    final pool = ConsumerSocketConnectionPool(
      primary: primary,
    );

    check(identical(pool.primary, primary)).isTrue();
    check(identical(pool.data, primary)).isTrue();
    check(identical(pool.control, primary)).isTrue();
    check(pool.isMultiConnection).isFalse();
  });

  test('poolSize > 1 without secondary still falls back to primary', () {
    final primary = _MockConnection();
    final pool = ConsumerSocketConnectionPool(
      primary: primary,
      poolSize: 2,
    );

    check(identical(pool.data, primary)).isTrue();
    check(pool.isMultiConnection).isFalse();
  });

  test('secondary wires data plane when provided', () {
    final primary = _MockConnection();
    final secondary = _MockConnection();
    final pool = ConsumerSocketConnectionPool(
      primary: primary,
      secondary: secondary,
      poolSize: 2,
    );

    check(identical(pool.data, secondary)).isTrue();
    check(identical(pool.control, primary)).isTrue();
    check(pool.isMultiConnection).isTrue();
  });
}
