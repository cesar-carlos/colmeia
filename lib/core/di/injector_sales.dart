import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorSales(GetIt getIt) {
  getIt
    ..registerSingleton<SalesPreferences>(
      SalesPreferences(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<LoadAvailableAgentsForSales>(
      () => LoadAvailableAgentsForSales(getIt<ClientAgentsRepository>()),
    );
}
