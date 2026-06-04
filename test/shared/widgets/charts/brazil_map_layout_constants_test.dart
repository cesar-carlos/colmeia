import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('footer reserve constants match prior layout estimates', () {
    expect(BrazilMapLayoutConstants.belowMapSingleStoreDetailReserve, 220);
    expect(BrazilMapLayoutConstants.belowMapClusterDetailReserve, 300);
    expect(BrazilMapLayoutConstants.belowMapStateDetailReserve, 96);
    expect(BrazilMapLayoutConstants.desktopSidebarMinHeight, 240);
  });
}
