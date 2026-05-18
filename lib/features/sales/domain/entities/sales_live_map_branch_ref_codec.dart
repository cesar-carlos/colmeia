import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';

abstract final class SalesLiveMapBranchRefCodec {
  static SalesLiveMapBranchRef decode(String raw) {
    final value = raw.trim();
    final lastDash = value.lastIndexOf('-');
    if (lastDash <= 0 || lastDash == value.length - 1) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }
    final secondLastDash = value.lastIndexOf('-', lastDash - 1);
    if (secondLastDash <= 0 || secondLastDash == lastDash - 1) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }

    final codEmpresa = int.tryParse(
      value.substring(secondLastDash + 1, lastDash),
    );
    final codFilial = int.tryParse(value.substring(lastDash + 1));
    final agentId = value.substring(0, secondLastDash).trim();
    if (agentId.isEmpty || codEmpresa == null || codFilial == null) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }

    return SalesLiveMapBranchRef(
      agentId: agentId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  static String encode(SalesLiveMapBranchRef ref) {
    return '${ref.agentId}-${ref.codEmpresa}-${ref.codFilial}';
  }
}
