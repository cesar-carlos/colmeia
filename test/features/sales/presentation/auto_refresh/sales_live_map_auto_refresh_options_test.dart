import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live map option set starts at 15 minutes in 10-minute steps', () {
    final options = SalesLiveMapAutoRefreshOptions.optionSet;
    expect(
      options.defaultOption,
      SalesLiveMapAutoRefreshOptions.fifteenMinutes,
    );
    expect(
      options.values.map((o) => o.duration.inMinutes).toList(),
      <int>[15, 25, 35],
    );
  });
}
