// Guards the Colmeia bootstrap pattern: GetIt lazy singletons exposed through
// Provider must use a noop dispose so remounts do not kill shared listenables.
import 'package:colmeia/app/bootstrap.dart' show ColmeiaBootstrap;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// Mirrors [ColmeiaBootstrap]'s noop dispose for GetIt-owned listenables.
void _noopProviderDispose<T>(BuildContext _, T _) {}

class _ProbeListenable extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  final getIt = GetIt.asNewInstance();

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'noop Provider dispose keeps GetIt singleton listenable across remounts',
    (tester) async {
      getIt.registerLazySingleton<_ProbeListenable>(_ProbeListenable.new);

      Widget buildHost() {
        return ListenableProvider<_ProbeListenable>(
          create: (_) => getIt<_ProbeListenable>(),
          dispose: _noopProviderDispose,
          child: const SizedBox(),
        );
      }

      await tester.pumpWidget(buildHost());
      final probe = getIt<_ProbeListenable>();
      expect(probe.disposed, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(probe.disposed, isFalse);

      await tester.pumpWidget(buildHost());
      expect(probe.disposed, isFalse);
      expect(probe.notifyListeners, returnsNormally);
    },
  );
}
