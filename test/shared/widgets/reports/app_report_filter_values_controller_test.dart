import 'package:colmeia/shared/widgets/reports/app_report_filter_values_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const delay = Duration(milliseconds: 300);

  test('rapid edits emit one complete filter snapshot', () {
    fakeAsync((clock) {
      final controller = AppReportFilterValuesController({});
      final emitted = <Map<String, Object?>>[];
      controller.change('name', 'Ana', delay: delay, onChanged: emitted.add);
      clock.elapse(const Duration(milliseconds: 100));
      controller.change('city', 'Cuiaba', delay: delay, onChanged: emitted.add);
      clock.elapse(delay);
      expect(emitted, [
        {'name': 'Ana', 'city': 'Cuiaba'},
      ]);
      controller.dispose();
    });
  });

  test('immediate selection includes drafts and cancels delayed emissions', () {
    fakeAsync((clock) {
      final controller = AppReportFilterValuesController({});
      final emitted = <Map<String, Object?>>[];
      controller
        ..change('name', 'Ana', delay: delay, onChanged: emitted.add)
        ..change('status', 'active', onChanged: emitted.add);
      clock.elapse(delay);
      expect(emitted, [
        {'name': 'Ana', 'status': 'active'},
      ]);
      controller.dispose();
    });
  });

  test('equal parent values preserve drafts; new values cancel old work', () {
    fakeAsync((clock) {
      final controller = AppReportFilterValuesController({'name': 'old'});
      final emitted = <Map<String, Object?>>[];
      controller.change('name', 'draft', delay: delay, onChanged: emitted.add);
      expect(controller.synchronize({'name': 'old'}), isFalse);
      expect(controller.values, {'name': 'draft'});
      expect(controller.synchronize({'name': 'external'}), isTrue);
      clock.elapse(delay);
      expect(emitted, isEmpty);
      expect(controller.values, {'name': 'external'});
      controller.dispose();
    });
  });

  test('clear and dispose prevent delayed callbacks', () {
    fakeAsync((clock) {
      final controller = AppReportFilterValuesController({});
      final emitted = <Map<String, Object?>>[];
      controller
        ..change('name', 'Ana', delay: delay, onChanged: emitted.add)
        ..clear();
      clock.elapse(delay);
      expect(emitted, isEmpty);
      expect(controller.values, isEmpty);
      controller
        ..change('name', 'Ana', delay: delay, onChanged: emitted.add)
        ..dispose();
      clock.elapse(delay);
      expect(emitted, isEmpty);
    });
  });

  test(
    'patches preserve latest filters and emitted snapshots are isolated',
    () {
      final controller = AppReportFilterValuesController({'city': 'Cuiaba'});
      final emitted = <Map<String, Object?>>[];
      controller
        ..change('name', 'Ana', onChanged: emitted.add)
        ..change('date', DateTime(2026), onChanged: emitted.add);
      expect(emitted.first, {'city': 'Cuiaba', 'name': 'Ana'});
      emitted.last.clear();
      expect(controller.values['date'], DateTime(2026));
      controller.change('name', '  ', onChanged: emitted.add);
      expect(controller.values.containsKey('name'), isFalse);
      controller.dispose();
    },
  );
}
