import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_option_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fiveMinutes = AutoRefreshOption(
    id: 'fiveMinutes',
    duration: Duration(minutes: 5),
  );
  const tenMinutes = AutoRefreshOption(
    id: 'tenMinutes',
    duration: Duration(minutes: 10),
  );
  final optionSet = AutoRefreshOptionSet(
    values: const <AutoRefreshOption>[fiveMinutes, tenMinutes],
    defaultOption: fiveMinutes,
  );

  test('byId resolves known ids', () {
    expect(optionSet.byId('fiveMinutes'), fiveMinutes);
    expect(optionSet.byId('tenMinutes'), tenMinutes);
  });

  test('byId returns null for unknown ids', () {
    expect(optionSet.byId('unknown'), isNull);
    expect(optionSet.byId(null), isNull);
  });

  test('contains checks membership', () {
    expect(optionSet.contains(fiveMinutes), isTrue);
    expect(
      optionSet.contains(
        const AutoRefreshOption(
          id: 'thirtyMinutes',
          duration: Duration(minutes: 30),
        ),
      ),
      isFalse,
    );
  });

  test('values are exposed as an unmodifiable collection', () {
    expect(
      () => optionSet.values.add(
        const AutoRefreshOption(
          id: 'thirtyMinutes',
          duration: Duration(minutes: 30),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('throws when default option does not belong to the option set', () {
    expect(
      () => AutoRefreshOptionSet(
        values: const <AutoRefreshOption>[fiveMinutes],
        defaultOption: tenMinutes,
      ),
      throwsArgumentError,
    );
  });
}
