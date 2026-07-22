import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewSectionRequest', () {
    test('home runs slim main batch and monthly section batch only', () {
      const request = OverviewSectionRequest.home;

      expect(request.runMainBatch, isTrue);
      expect(request.mainBatchIncludePaymentResumo, isFalse);
      expect(request.mainBatchIncludeUserRanking, isTrue);
      expect(
        request.sectionBatchSections,
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.monthlyParcels,
        }),
      );
      expect(request.isMainBatchOnly, isFalse);
      expect(request.isSectionBatchOnly, isFalse);
      expect(request.mainBatchCommandCount, 1);
    });

    test('full includes expected section batch sections', () {
      const request = OverviewSectionRequest.full;

      expect(request.runMainBatch, isTrue);
      expect(
        request.sectionBatchSections,
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
          OverviewProgressiveSection.monthlyParcels,
          OverviewProgressiveSection.weekdaySales,
          OverviewProgressiveSection.weekdayUserSales,
          OverviewProgressiveSection.lucratividadePeriod,
        }),
      );
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

    test('forChartSection(paymentMix) loads payment resumo only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.paymentMix,
      );

      expect(request.runMainBatch, isTrue);
      expect(request.mainBatchIncludePaymentResumo, isTrue);
      expect(request.mainBatchIncludeUserRanking, isFalse);
      expect(request.isMainBatchOnly, isTrue);
      expect(request.sectionBatchSections, isEmpty);
      expect(request.mainBatchCommandCount, 1);
    });

    test('forChartSection(userRanking) loads user ranking only', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.userRanking,
      );

      expect(request.runMainBatch, isTrue);
      expect(request.mainBatchIncludePaymentResumo, isFalse);
      expect(request.mainBatchIncludeUserRanking, isTrue);
      expect(request.isMainBatchOnly, isTrue);
      expect(request.mainBatchCommandCount, 1);
    });

    test('completedWhenFinal(home) excludes payment mix', () {
      expect(
        OverviewSectionRequest.home.completedWhenFinal(),
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.summary,
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

    test('completedAfterMainBatch(paymentMix) marks payment and summary', () {
      final request = OverviewSectionRequest.forChartSection(
        OverviewProgressiveSection.paymentMix,
      );

      expect(
        request.completedAfterMainBatch(),
        equals(<OverviewProgressiveSection>{
          OverviewProgressiveSection.summary,
          OverviewProgressiveSection.paymentMix,
        }),
      );
    });
  });
}
