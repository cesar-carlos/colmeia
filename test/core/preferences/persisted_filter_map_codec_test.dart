import 'package:checks/checks.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersistedFilterMapCodec', () {
    test('should sanitize supported values with schema rules', () {
      final schema = PersistedFilterMapSchema(
        rules: <PersistedFilterRule>[
          PersistedFilterMapSchema.trimmedString('search'),
          PersistedFilterMapSchema.stringIfAllowed(
            key: 'status',
            allowedValues: <String>{'active', 'inactive'},
          ),
          PersistedFilterMapSchema.boolean('premiumOnly'),
          PersistedFilterMapSchema.dateRangeFromEpoch(
            targetKey: 'period',
            startEpochKey: 'periodStartMs',
            endEpochKey: 'periodEndMs',
          ),
        ],
      );

      final result = schema.apply(<String, Object?>{
        'search': '  bakery  ',
        'status': 'active',
        'premiumOnly': true,
        'periodStartMs': DateTime(2026, 4).millisecondsSinceEpoch,
        'periodEndMs': DateTime(2026, 4, 7).millisecondsSinceEpoch,
        'ignored': 'value',
      });

      check(result['search']).equals('bakery');
      check(result['status']).equals('active');
      check(result['premiumOnly']).equals(true);
      check(result['ignored']).isNull();

      final period = result['period'];
      expect(period, isA<DateTimeRange>());
      if (period case final DateTimeRange range) {
        check(range.start).equals(DateTime(2026, 4));
        check(range.end).equals(DateTime(2026, 4, 7));
      }
    });

    test('should drop invalid values during sanitization', () {
      final schema = PersistedFilterMapSchema(
        rules: <PersistedFilterRule>[
          PersistedFilterMapSchema.trimmedString('search'),
          PersistedFilterMapSchema.stringIfAllowed(
            key: 'status',
            allowedValues: <String>{'active'},
          ),
        ],
      );

      final result = schema.apply(<String, Object?>{
        'search': '   ',
        'status': 'unknown',
      });

      check(result).isEmpty();
    });

    test('should encode date ranges to epoch keys', () {
      final schema = PersistedFilterMapSchema(
        rules: <PersistedFilterRule>[
          PersistedFilterMapSchema.dateRangeToEpoch(
            sourceKey: 'period',
            startEpochKey: 'periodStartMs',
            endEpochKey: 'periodEndMs',
          ),
        ],
      );

      final range = DateTimeRange(
        start: DateTime(2026, 4, 10),
        end: DateTime(2026, 4, 20),
      );

      final result = schema.apply(<String, Object?>{
        'period': range,
      });

      check(result['periodStartMs']).equals(range.start.millisecondsSinceEpoch);
      check(result['periodEndMs']).equals(range.end.millisecondsSinceEpoch);
    });
  });
}
