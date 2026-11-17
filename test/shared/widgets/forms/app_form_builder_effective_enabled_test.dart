import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_dropdown_field.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final context = _UnusedContext();

  for (final disable in [true, false]) {
    test(
      'late date result is ignored after ${disable ? 'disable' : 'dispose'}',
      () {
        final events = <DateTime?>[];
        final field = AppFormBuilderDatePickerField(
          name: 'date',
          onChanged: events.add,
        ).build(context) as FormBuilderField<DateTime?>;
        final state = _FieldState<DateTime?>(true);
        final child = field.builder(state) as AppDatePickerField;
        if (disable) {
          state.enabled = false;
        } else {
          state.mounted = false;
        }
        child.onChanged(DateTime(2026, 11, 17));
        child.onChanged(null);
        expect(state.changes, isEmpty);
        expect(events, isEmpty);
      },
    );

    test(
      'late period result is ignored after ${disable ? 'disable' : 'dispose'}',
      () {
        final events = <DateTimeRange?>[];
        final field = AppFormBuilderDateRangePickerField(
          name: 'period',
          onChanged: events.add,
        ).build(context) as FormBuilderField<DateTimeRange?>;
        final state = _FieldState<DateTimeRange?>(true);
        final child = field.builder(state) as AppDateRangePickerField;
        if (disable) {
          state.enabled = false;
        } else {
          state.mounted = false;
        }
        child.onChanged(
          DateTimeRange(start: DateTime(2026), end: DateTime(2026, 2)),
        );
        child.onChanged(null);
        expect(state.changes, isEmpty);
        expect(events, isEmpty);
      },
    );
  }

  test('active date field applies selections and clearing once', () {
    final events = <DateTime?>[];
    final field = AppFormBuilderDatePickerField(
      name: 'date',
      onChanged: events.add,
    ).build(context) as FormBuilderField<DateTime?>;
    final state = _FieldState<DateTime?>(true);
    final child = field.builder(state) as AppDatePickerField;
    final date = DateTime(2026, 11, 17);
    child.onChanged(date);
    child.onChanged(null);
    expect(state.changes, [date, null]);
    expect(events, [date, null]);
  });

  test('active period field applies selections and clearing once', () {
    final events = <DateTimeRange?>[];
    final field = AppFormBuilderDateRangePickerField(
      name: 'period',
      onChanged: events.add,
    ).build(context) as FormBuilderField<DateTimeRange?>;
    final state = _FieldState<DateTimeRange?>(true);
    final child = field.builder(state) as AppDateRangePickerField;
    final period = DateTimeRange(start: DateTime(2026), end: DateTime(2026, 2));
    child.onChanged(period);
    child.onChanged(null);
    expect(state.changes, [period, null]);
    expect(events, [period, null]);
  });

  for (final enabled in [false, true]) {
    test('dropdown follows effective form enabled=$enabled', () {
      final field = const AppFormBuilderDropdownField<String>(
        name: 'store',
        options: [],
      ).build(context) as FormBuilderField<String>;
      final child = field.builder(
        _FieldState<String>(enabled),
      ) as AppDropdownField<String>;
      expect(child.enabled, enabled);
    });

    test('multiselect follows effective form enabled=$enabled', () {
      final field = const AppFormBuilderMultiSelectSearchField<String>(
        name: 'stores',
        options: [],
      ).build(context) as FormBuilderField<List<String>>;
      final child = field.builder(
        _FieldState<List<String>>(enabled),
      ) as AppMultiSelectSearchField<String>;
      expect(child.enabled, enabled);
    });

    test('date follows effective form enabled=$enabled', () {
      final field = const AppFormBuilderDatePickerField(
        name: 'date',
      ).build(context) as FormBuilderField<DateTime?>;
      final child =
          field.builder(_FieldState<DateTime?>(enabled)) as AppDatePickerField;
      expect(child.enabled, enabled);
    });

    test('date range follows effective form enabled=$enabled', () {
      final field = const AppFormBuilderDateRangePickerField(
        name: 'period',
      ).build(context) as FormBuilderField<DateTimeRange?>;
      final child = field.builder(
        _FieldState<DateTimeRange?>(enabled),
      ) as AppDateRangePickerField;
      expect(child.enabled, enabled);
    });
  }
}

class _FieldState<T> extends FormBuilderFieldState<FormBuilderField<T>, T> {
  _FieldState(this.enabled);

  @override
  bool enabled;

  @override
  bool mounted = true;

  final changes = <T?>[];

  @override
  void didChange(T? value) => changes.add(value);

  @override
  T? get value => null;

  @override
  String? get errorText => null;
}

class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected context access: ${invocation.memberName}',
  );
}
