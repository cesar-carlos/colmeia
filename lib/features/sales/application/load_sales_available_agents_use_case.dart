import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

class LoadSalesAvailableAgentsUseCase {
  LoadSalesAvailableAgentsUseCase(this._loadAvailableAgentsForSales);

  final LoadAvailableAgentsForSales _loadAvailableAgentsForSales;

  Future<List<DashboardAgentOption>> call(String userId) {
    return _loadAvailableAgentsForSales(userId);
  }
}
