import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_selection_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapSelectionPolicy', () {
    late BrazilMapSelectionPolicy policy;

    const storeMt = AppBrazilStoreSalesPoint(
      id: 'store-1',
      name: 'Casa do Mel',
      uf: 'MT',
      city: 'Tangara',
      latitude: -14.62,
      longitude: -57.49,
      salesAmount: 100,
      salesCount: 10,
    );

    AppBrazilStoreSalesPoint? pointById(String id) {
      if (id == storeMt.id) {
        return storeMt;
      }
      return null;
    }

    setUp(() {
      policy = BrazilMapSelectionPolicy();
    });

    test('resolveSelectedStoreId prefers controlled id when not dismissed', () {
      policy.internalSelectedStoreId = 'internal';
      expect(
        policy.resolveSelectedStoreId('controlled'),
        'controlled',
      );
    });

    test('resolveSelectedStoreId uses internal when controlled dismissed', () {
      policy
        ..internalSelectedStoreId = 'internal'
        ..dismissedControlledSelectedStoreId = 'controlled';
      expect(
        policy.resolveSelectedStoreId('controlled'),
        'internal',
      );
    });

    test('blocksViewportDrivenClustering when any store is selected', () {
      expect(policy.blocksViewportDrivenClustering(null), isFalse);
      policy.internalSelectedStoreId = 'store-1';
      expect(policy.blocksViewportDrivenClustering(null), isTrue);
    });

    test('shouldPreserveStoreSelectionForRegionTap only for same UF', () {
      policy.internalSelectedStoreId = storeMt.id;
      expect(
        policy.shouldPreserveStoreSelectionForRegionTap(
          regionKey: 'MT',
          controlledSelectedStoreId: null,
          pointById: pointById,
        ),
        isTrue,
      );
      expect(
        policy.shouldPreserveStoreSelectionForRegionTap(
          regionKey: 'SP',
          controlledSelectedStoreId: null,
          pointById: pointById,
        ),
        isFalse,
      );
    });

    test('applyRegionTap clears store when not preserving', () {
      policy
        ..applyStoreSelection(storeMt, focusStore: true)
        ..applyRegionTap(regionKey: 'SP', preserveStoreSelection: false);
      expect(policy.internalSelectedStoreId, isNull);
      expect(policy.focusCameraOnSelectedStore, isFalse);
      expect(policy.internalSelectedStateKey, 'SP');
    });

    test('applyStoreSelection with focusStore false keeps camera unfocused', () {
      policy.applyStoreSelection(storeMt, focusStore: false);
      expect(policy.focusCameraOnSelectedStore, isFalse);
      expect(policy.internalSelectedStoreId, storeMt.id);
    });

    test(
      'applyStoreSelection without linkRegionHighlight keeps prior UF highlight',
      () {
        policy
          ..applyRegionTap(regionKey: 'SP', preserveStoreSelection: false)
          ..applyStoreSelection(
            storeMt,
            focusStore: false,
            linkRegionHighlight: false,
          );
        expect(policy.internalSelectedStateKey, 'SP');
        expect(policy.internalSelectedStoreId, storeMt.id);
      },
    );

    test('consumeCameraFocus clears one-shot camera focus flag', () {
      policy.applyStoreSelection(storeMt, focusStore: true);
      expect(policy.focusCameraOnSelectedStore, isTrue);

      policy.consumeCameraFocus();

      expect(policy.focusCameraOnSelectedStore, isFalse);
      expect(policy.internalSelectedStoreId, storeMt.id);
      expect(
        policy.shouldFocusCameraOnSelectedStore(
          controlledSelectedStoreId: null,
          autoFocusSelectedStore: true,
        ),
        isFalse,
      );
    });

    test('cluster selection blocks viewport clustering without camera focus', () {
      policy.applyStoreSelection(storeMt, focusStore: false);
      expect(policy.blocksViewportDrivenClustering(null), isTrue);
      expect(
        policy.shouldFocusCameraOnSelectedStore(
          controlledSelectedStoreId: null,
          autoFocusSelectedStore: true,
        ),
        isFalse,
      );
    });

    test('shouldSkipRedundantRegionTap when store selected on same UF', () {
      policy
        ..applyStoreSelection(storeMt, focusStore: true)
        ..applyRegionTap(regionKey: 'MT', preserveStoreSelection: true);
      expect(
        policy.shouldSkipRedundantRegionTap(
          regionKey: 'MT',
          preserveStoreSelection: true,
          controlledSelectedStoreId: null,
        ),
        isTrue,
      );
      expect(
        policy.shouldSkipRedundantRegionTap(
          regionKey: 'SP',
          preserveStoreSelection: true,
          controlledSelectedStoreId: null,
        ),
        isFalse,
      );
    });
  });
}
