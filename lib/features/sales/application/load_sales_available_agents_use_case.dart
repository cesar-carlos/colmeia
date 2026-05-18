import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';

class LoadSalesAvailableAgentsUseCase {
  LoadSalesAvailableAgentsUseCase(this._loadAvailableAgentsForSales);

  final LoadAvailableAgentsForSales _loadAvailableAgentsForSales;

  Future<List<OverviewAgentOption>> call(String userId) {
    return _loadAvailableAgentsForSales(userId);
  }
}
