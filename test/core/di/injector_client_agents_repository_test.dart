import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/di/injector_cache_refresh.dart';
import 'package:colmeia/core/di/injector_client_agents.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/catalog_cache_refresh_presence.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCacheStore extends Mock implements AppCacheStore {}

void main() {
  test(
    'should resolve scheduler presence using the shared agents repository',
    () {
      dotenv.loadFromString(
        envString: 'SOCKET_PRESENCE_LISTENER_ENABLED=false',
      );
      addTearDown(dotenv.clean);
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      getIt
        ..registerSingleton<AppCacheStore>(_MockAppCacheStore())
        ..registerSingleton<Dio>(dio);

      registerInjectorClientAgents(getIt);
      registerInjectorCacheRefresh(getIt);

      expect(getIt<CacheRefreshPresence>(), isA<CatalogCacheRefreshPresence>());
      expect(
        getIt<ClientApprovedAgentsRepository>(),
        same(getIt<ClientAgentsRepository>()),
      );
    },
  );
}
