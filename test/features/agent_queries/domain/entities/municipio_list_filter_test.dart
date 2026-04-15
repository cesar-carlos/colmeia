import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startRow and endRow are 1-based inclusive window', () {
    const filter = MunicipioListFilter(page: 2, pageSize: 10);
    check(filter.offset).equals(10);
    check(filter.startRow).equals(11);
    check(filter.endRow).equals(20);
  });
}
