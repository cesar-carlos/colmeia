import 'package:checks/checks.dart';
import 'package:colmeia/core/value_objects/cnpj.dart';
import 'package:colmeia/core/value_objects/cpf.dart';
import 'package:colmeia/core/value_objects/date_range.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/core/value_objects/money_amount.dart';
import 'package:colmeia/core/value_objects/phone_number.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailAddress', () {
    test('should normalize email when value is valid', () {
      final email = EmailAddress('  CAMILA@EXAMPLE.COM  ');

      check(email.value).equals('camila@example.com');
    });

    test('should throw when email is invalid', () {
      expect(
        () => EmailAddress('invalid-email'),
        throwsA(isA<ValueObjectValidationException>()),
      );
    });
  });

  group('Cpf', () {
    test('should normalize cpf digits and expose formatted value', () {
      final cpf = Cpf('529.982.247-25');

      check(cpf.value).equals('52998224725');
      check(cpf.formatted).equals('529.982.247-25');
    });
  });

  group('Cnpj', () {
    test('should normalize cnpj digits and expose formatted value', () {
      final cnpj = Cnpj('11.444.777/0001-61');

      check(cnpj.value).equals('11444777000161');
      check(cnpj.formatted).equals('11.444.777/0001-61');
    });
  });

  group('PhoneNumber', () {
    test('should normalize and format brazilian phone number', () {
      final phone = PhoneNumber('(11) 99876-5432');

      check(phone.value).equals('11998765432');
      check(phone.formatted).equals('(11) 99876-5432');
    });
  });

  group('StoreId and ReportId', () {
    test('should trim identifiers', () {
      final storeId = StoreId(' 03 ');
      final reportId = ReportId(' vendas-por-vendedor ');

      check(storeId.value).equals('03');
      check(reportId.value).equals('vendas-por-vendedor');
    });
  });

  group('MoneyAmount', () {
    test('should format money values in pt-BR', () {
      final amount = MoneyAmount(1284.5);

      check(amount.value).equals(1284.5);
      check(amount.formatted).contains('1.284,50');
    });
  });

  group('DateRange', () {
    test('should normalize dates and include contained dates', () {
      final range = DateRange(
        start: DateTime(2026, 3, 1, 10),
        end: DateTime(2026, 3, 31, 8),
      );

      check(range.start).equals(DateTime(2026, 3));
      check(range.contains(DateTime(2026, 3, 15, 12))).isTrue();
      check(range.contains(DateTime(2026, 4))).isFalse();
      check(range.formatted).equals('01/03/2026 - 31/03/2026');
    });

    test('should throw when end date is before start date', () {
      expect(
        () => DateRange(
          start: DateTime(2026, 3, 31),
          end: DateTime(2026, 3),
        ),
        throwsA(isA<ValueObjectValidationException>()),
      );
    });
  });
}
