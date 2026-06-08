import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewSectionRequest', () {
    test('home runs main batch and monthly section batch only', () {
      const request = OverviewSectionRequest.home;

      expect(request.runMainBatch, isTrue);
      expect(
        request.sectionBatchSections,
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.monthlyParcels,
        }),
      );
      expect(request.isMainBatchOnly, isFalse);
      expect(request.isSectionBatchOnly, isFalse);
    });

    test('full includes all section-batch sections', () {
      const request = OverviewSectionRequest.full;

      expect(request.runMainBatch, isTrue);
      expect(request.sectionBatchSections, containsAll(<OverviewProgressiveSection>{
        OverviewProgressiveSection.dailySales,
        OverviewProgressiveSection.monthlyParcels,
        OverviewProgressiveSection.weekdaySales,
        OverviewProgressiveSection.weekdayUserSales,
        OverviewProgressiveSection.lucratividadePeriod,
        OverviewProgressiveSection.lucratividadeMensal,
      }));
      expect(request.isMainBatchOnly, isFalse);
    });

    test('forChartSection(dailySales) is section-batch only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.dailySales,
      );

      expect(request.runMainBatch, isFalse);
      expect(request.isSectionBatchOnly, isTrue);
      expect(
        request.sectionBatchSections,
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
        }),
      );
    });

    test('forChartSection(paymentMix) is main-batch only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.paymentMix,
      );

      expect(request.runMainBatch, isTrue);
      expect(request.isMainBatchOnly, isTrue);
      expect(request.sectionBatchSections, isEmpty);
    });

    test('forChartSection(userRanking) is main-batch only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.userRanking,
      );

      expect(request.runMainBatch, isTrue);
      expect(request.isMainBatchOnly, isTrue);
    });

    test('completedWhenFinal(home) includes main and monthly sections', () {
      expect(
        OverviewSectionRequest.home.completedWhenFinal(),
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.summary,
          OverviewProgressiveSection.paymentMix,
          OverviewProgressiveSection.agentRanking,
          OverviewProgressiveSection.userRanking,
          OverviewProgressiveSection.monthlyParcels,
        }),
      );
    });

    test('completedWhenFinal(forChartSection dailySales) is daily only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.dailySales,
      );

      expect(
        request.completedWhenFinal(),
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
        }),
      );
    });

    test('completedAfterMainBatch for section-only request is empty', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.weekdaySales,
      );

      expect(request.completedAfterMainBatch(), isEmpty);
    });
  });
}
