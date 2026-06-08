import 'package:colmeia/shared/utils/sanitize_report_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replaces unsafe characters and spaces', () {
    expect(
      sanitizeReportFileName('Sales Report (Q1)'),
      'Sales_Report_Q1',
    );
  });
}
