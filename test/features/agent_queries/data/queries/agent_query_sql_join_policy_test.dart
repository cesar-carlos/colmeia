import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TipoOperacaoSaida joins do not constrain CodFilial',
    () {
      final queryDirectory = Directory(
        'lib/features/agent_queries/data/queries',
      );
      final dartFiles = queryDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final forbiddenJoin = RegExp(
        r'\btos\s*\.\s*CodFilial\s*=\s*pv\s*\.\s*CodFilial\b',
        caseSensitive: false,
      );

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          forbiddenJoin.hasMatch(content),
          isFalse,
          reason: '${file.path} must not join TipoOperacaoSaida by CodFilial.',
        );
      }
    },
  );
}
