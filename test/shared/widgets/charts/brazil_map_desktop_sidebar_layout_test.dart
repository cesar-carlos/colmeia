import 'package:colmeia/shared/widgets/charts/brazil_map_desktop_sidebar_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapDesktopSidebarLayout.maxHeight', () {
    test('does not throw when available height is below 240', () {
      const mapTileHeight = 200.0;
      const topInset = 12.0;
      const availableHeight = mapTileHeight - topInset - 24.0;

      expect(
        BrazilMapDesktopSidebarLayout.maxHeight(
          mapTileHeight: mapTileHeight,
          topInset: topInset,
        ),
        availableHeight,
      );
    });

    test('returns 200 when map tile leaves exactly 200px available', () {
      const mapTileHeight = 236.0;
      const topInset = 12.0;

      expect(
        BrazilMapDesktopSidebarLayout.maxHeight(
          mapTileHeight: mapTileHeight,
          topInset: topInset,
        ),
        200.0,
      );
    });

    test('respects 240 minimum when enough vertical space exists', () {
      const mapTileHeight = 900.0;
      const topInset = 50.0;

      expect(
        BrazilMapDesktopSidebarLayout.maxHeight(
          mapTileHeight: mapTileHeight,
          topInset: topInset,
        ),
        greaterThanOrEqualTo(240.0),
      );
    });

    test('returns zero when insets consume all map tile height', () {
      expect(
        BrazilMapDesktopSidebarLayout.maxHeight(
          mapTileHeight: 30,
          topInset: 12,
        ),
        0,
      );
    });

    test('returns zero when available height would be negative', () {
      expect(
        BrazilMapDesktopSidebarLayout.maxHeight(
          mapTileHeight: 20,
          topInset: 12,
        ),
        0,
      );
    });
  });
}
