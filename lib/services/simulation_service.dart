import '../components/buffalo_family_tree/models.dart';

class SimulationService {
  static Map<String, dynamic> runSimulation({
    required num units, // Changed from int to num
    required int years,
    required int startYear,
    required int startMonth,
  }) {
    final List<Buffalo> herd = [];
    int nextId = 1;

    // Create initial buffaloes
    // 1 Unit = 2 Buffaloes (Mothers)
    // 0.5 Unit = 1 Buffalo (Mother)
    final int totalMothers = (units * 2).round();

    for (int i = 0; i < totalMothers; i++) {
      // Determine unit number: 0,1 -> Unit 1; 2,3 -> Unit 2...
      final int currentUnit = (i ~/ 2) + 1;

      // Determine acquisition (Type A vs Type B logic)
      // Even indices (0, 2...) are Type A (Start Month)
      // Odd indices (1, 3...) are Type B (Start Month + 6)
      final bool isTypeA = (i % 2) == 0;
      final int acquisitionMonth = isTypeA ? startMonth : (startMonth + 6) % 12;

      herd.add(
        Buffalo(
          id: nextId++,
          age: 3,
          mature: true,
          parentId: null,
          generation: 0,
          birthYear: startYear - 3,
          acquisitionMonth: acquisitionMonth,
          unit: currentUnit,
        ),
      );
    }

    for (int year = 1; year <= years; year++) {
      final currentYear = startYear + (year - 1);
      final matureBuffaloes = herd.where((b) => b.age >= 3).toList();
      for (final parent in List<Buffalo>.from(matureBuffaloes)) {
        // Realistic Herd Growth Logic:
        // Assume 50% Probability of Female Calf (Retained) vs Male Calf (Sold).
        // Deterministic check using (Parent ID + Current Year) to alternate births.
        // Even sum = Female (Keep); Odd sum = Male (Sold/Ignored).
        // This prevents unrealistic exponential 100% female growth.
        final bool isFemale = (parent.id + currentYear) % 2 == 0;

        if (isFemale) {
          herd.add(
            Buffalo(
              id: nextId++,
              age: 0,
              mature: false,
              parentId: parent.id,
              generation: parent.generation + 1,
              birthYear: currentYear,
              acquisitionMonth: parent.acquisitionMonth,
              unit: parent.unit,
            ),
          );
        }
      }

      herd.forEach((b) {
        b.age++;
        if (b.age >= 3) b.mature = true;
      });
    }

    // Build revenue/yearly data summary
    final yearlyData = <YearlyData>[];
    double totalRevenue = 0;
    int totalMatureBuffaloYears = 0;

    for (int yearOffset = 0; yearOffset < years; yearOffset++) {
      final currentYear = startYear + yearOffset;
      final mature = herd.where((b) => b.birthYear <= currentYear - 3).toList();
      final totalBuffaloes = herd
          .where((b) => b.birthYear <= currentYear)
          .length;
      final annualRevenue = _calculateAnnualRevenueForHerd(
        herd,
        startYear,
        startMonth,
        currentYear,
      );
      totalRevenue += annualRevenue;
      totalMatureBuffaloYears += mature.length;

      yearlyData.add(
        YearlyData(
          year: currentYear,
          totalBuffaloes: totalBuffaloes,
          producingBuffaloes: mature.length,
          revenue: annualRevenue,
        ),
      );
    }

    return {
      'treeData': {
        'units': units,
        'years': years,
        'startYear': startYear,
        'startMonth': startMonth,
        'totalBuffaloes': herd.length,
        'buffaloes': herd,
      },
      'revenueData': {
        'yearlyData': yearlyData,
        'totalRevenue': totalRevenue,
        'totalUnits': totalMatureBuffaloYears / years,
        'averageAnnualRevenue': years > 0 ? totalRevenue / years : 0,
      },
    };
  }

  static double _calculateAnnualRevenueForHerd(
    List<Buffalo> herd,
    int startYear,
    int startMonth,
    int currentYear,
  ) {
    double annualRevenue = 0;
    const int landingPeriod = 2;
    const int highRevenueMonths = 5;
    const int highRevenueValue = 9000;
    const int mediumRevenueMonths = 3;
    const int mediumRevenueValue = 6000;
    const int restPeriodValue = 0;

    final matureBuffaloes = herd
        .where((b) => b.birthYear <= currentYear - 3)
        .toList();

    for (final b in matureBuffaloes) {
      final acquisitionMonth = b.acquisitionMonth;
      for (int month = 0; month < 12; month++) {
        final monthsSinceAcquisition =
            (currentYear - startYear) * 12 + (month - acquisitionMonth);
        if (monthsSinceAcquisition < 0) continue; // not acquired yet
        if (monthsSinceAcquisition < landingPeriod) continue;

        final productionMonths = monthsSinceAcquisition - landingPeriod;
        final cyclePosition = productionMonths % 12;
        if (cyclePosition < highRevenueMonths) {
          annualRevenue += highRevenueValue;
        } else if (cyclePosition < highRevenueMonths + mediumRevenueMonths) {
          annualRevenue += mediumRevenueValue;
        } else {
          annualRevenue += restPeriodValue;
        }
      }
    }

    return annualRevenue;
  }
}
