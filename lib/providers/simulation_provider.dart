import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class to hold all simulation data
class SimulationState {
  final double units;
  final int years;
  final DateTime startDate;
  final Map<String, dynamic>? treeData;
  final Map<String, dynamic>? revenueData;
  final bool isLoading;

  SimulationState({
    required this.units,
    required this.years,
    required this.startDate,
    this.treeData,
    this.revenueData,
    this.isLoading = false,
  });

  SimulationState copyWith({
    double? units,
    int? years,
    DateTime? startDate,
    Map<String, dynamic>? treeData,
    Map<String, dynamic>? revenueData,
    bool? isLoading,
  }) {
    return SimulationState(
      units: units ?? this.units,
      years: years ?? this.years,
      startDate: startDate ?? this.startDate,
      treeData: treeData ?? this.treeData,
      revenueData: revenueData ?? this.revenueData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final simulationProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(
      SimulationNotifier.new,
    );

// Notifier class
class SimulationNotifier extends Notifier<SimulationState> {
  @override
  SimulationState build() {
    final initialState = SimulationState(
      units: 1.0,
      years: 10,
      startDate: DateTime(2026, 1, 1),
      isLoading: false,
    );

    // Auto-run simulation on startup
    Future.microtask(() => runSimulation());

    return initialState;
  }

  void updateSettings({double? units, int? years, DateTime? startDate}) {
    state = state.copyWith(
      units: units ?? state.units,
      years: years ?? state.years,
      startDate: startDate ?? state.startDate,
    );
  }

  Future<void> reset() async {
    state = SimulationState(
      units: 1.0,
      years: 10,
      startDate: DateTime(2026, 1, 1),
      treeData: null,
      revenueData: null,
    );
    await runSimulation();
  }

  // Revenue configuration
  final Map<String, dynamic> revenueConfig = {
    'landingPeriod': 2,
    'highRevenuePhase': {'months': 5, 'revenue': 9000},
    'mediumRevenuePhase': {'months': 3, 'revenue': 6000},
    'restPeriod': {'months': 4, 'revenue': 0},
  };

  // Calculate monthly revenue for EACH buffalo based on its individual cycle (Match CostEstimationTable logic)
  int _calculateMonthlyRevenueForBuffalo(
    int birthYear,
    int birthMonth,
    int currentYear,
    int currentMonth,
  ) {
    // Calculate age in months
    final ageInMonths =
        ((currentYear - birthYear) * 12) + (currentMonth - birthMonth);

    // Start Milking at Age 38
    if (ageInMonths < 38) {
      return 0;
    }

    final productionMonth = ageInMonths - 38;
    final cycleMonth = productionMonth % 12;

    if (cycleMonth < 5) return 9000;
    if (cycleMonth < 8) return 6000;
    return 0;
  }

  // Calculate annual revenue for ALL mature buffaloes with individual cycles
  Map<String, dynamic> _calculateAnnualRevenueForHerd(
    List<dynamic> herd,
    int startYearVal,
    int startMonthVal,
    int currentYear,
  ) {
    double annualRevenue = 0;
    int producingCount = 0;

    // Only consider buffaloes born by this year
    final activeBuffaloes = herd
        .where((b) => (b['birthYear'] as int) <= currentYear)
        .toList();

    for (final buffalo in activeBuffaloes) {
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;
      final birthYear = buffalo['birthYear'] as int;

      double buffaloAnnualRev = 0;
      for (int month = 0; month < 12; month++) {
        buffaloAnnualRev += _calculateMonthlyRevenueForBuffalo(
          birthYear,
          acquisitionMonth,
          currentYear,
          month,
        );
      }

      annualRevenue += buffaloAnnualRev;
      if (buffaloAnnualRev > 0) {
        producingCount++;
      }
    }

    return {
      'annualRevenue': annualRevenue,
      'matureBuffaloes': producingCount,
      'totalBuffaloes': activeBuffaloes.length,
    };
  }

  // Calculate total revenue data based on ACTUAL herd growth with staggered cycles
  Map<String, dynamic> _calculateRevenueData(
    List<dynamic> herd,
    int startYearVal,
    int startMonthVal,
    int totalYears,
  ) {
    final List<Map<String, dynamic>> yearlyData = [];
    double totalRevenue = 0;
    double totalMatureBuffaloYears = 0;

    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    for (int yearOffset = 0; yearOffset < totalYears; yearOffset++) {
      final currentYear = startYearVal + yearOffset;

      final annualResult = _calculateAnnualRevenueForHerd(
        herd,
        startYearVal,
        startMonthVal,
        currentYear,
      );

      final annualRevenue = annualResult['annualRevenue'];
      final matureBuffaloes = annualResult['matureBuffaloes'];
      final totalBuffaloes = annualResult['totalBuffaloes'];

      totalRevenue += annualRevenue;
      totalMatureBuffaloYears += matureBuffaloes;

      final monthlyRevenuePerBuffalo = matureBuffaloes > 0
          ? annualRevenue / (matureBuffaloes * 12)
          : 0;

      yearlyData.add({
        'year': currentYear,
        'activeUnits': (totalBuffaloes / 2).ceil(),
        'monthlyRevenue': monthlyRevenuePerBuffalo,
        'revenue': annualRevenue,
        'totalBuffaloes': totalBuffaloes,
        'producingBuffaloes': matureBuffaloes,
        'nonProducingBuffaloes': totalBuffaloes - matureBuffaloes,
        'startMonth': monthNames[startMonthVal],
        'startYear': startYearVal,
        'matureBuffaloes': matureBuffaloes,
      });
    }

    return {
      'yearlyData': yearlyData,
      'totalRevenue': totalRevenue,
      'totalUnits': totalMatureBuffaloYears / totalYears,
      'averageAnnualRevenue': totalRevenue / totalYears,
      'revenueConfig': revenueConfig,
      'totalMatureBuffaloYears': totalMatureBuffaloYears,
      'totalNetRevenue':
          totalRevenue -
          _calculateTotalCPF(herd, startYearVal, startMonthVal, totalYears),
    };
  }

  // Calculate Precise Total CPF Cost (Type A/B & Age Logic)
  double _calculateTotalCPF(
    List<dynamic> herd,
    int startYear,
    int startMonth,
    int totalYears,
  ) {
    double totalCPF = 0;
    const double cpfPerMonth = 13000 / 12;

    for (int year = startYear; year < startYear + totalYears; year++) {
      for (int month = 0; month < 12; month++) {
        for (final b in herd) {
          final gen = b['generation'] as int? ?? 0;
          final acquisitionMonth = b['acquisitionMonth'] as int? ?? 0;
          final birthYear = b['birthYear'] as int? ?? startYear;
          final birthMonth = (b['birthMonth'] as int?) ?? acquisitionMonth;

          if (year < birthYear) continue;
          if (year == birthYear && month < birthMonth) continue;

          bool isCpfApplicable = false;

          if (gen == 0) {
            // Type A: Acquired at startMonth
            if (acquisitionMonth == startMonth) {
              isCpfApplicable = true;
            } else {
              // Type B: Free Period (First 12 months from acquisition)
              final isFreePeriod =
                  ((year == startYear && month >= 6) ||
                  (year == startYear + 1 && month <= 5));

              if (!isFreePeriod) {
                isCpfApplicable = true;
              }
            }
          } else {
            // Child: Age >= 36 months
            final ageInMonths =
                ((year - birthYear) * 12) + (month - birthMonth);
            if (ageInMonths >= 36) {
              isCpfApplicable = true;
            }
          }

          if (isCpfApplicable) {
            totalCPF += cpfPerMonth;
          }
        }
      }
    }
    return totalCPF;
  }

  Future<void> runSimulation() async {
    // Note: state = ... triggers a rebuild.
    state = state.copyWith(isLoading: true, treeData: null, revenueData: null);

    // Simulate loading/computation delay
    await Future.delayed(const Duration(milliseconds: 300));

    final totalYears = state.years;
    final List<Map<String, dynamic>> herd = [];
    int nextId = 1;

    // Create initial buffaloes (2 Mothers + 2 Calves per unit)
    for (int u = 0; u < state.units; u++) {
      // --- Batch A (January / Start Month) ---
      final batchAMonth = state.startDate.month - 1; // 0-based
      final motherAId = nextId++;

      // Mother A
      herd.add({
        'id': motherAId,
        'age': 5,
        'mature': true,
        'parentId': null,
        'generation': 0,
        'birthYear': state.startDate.year - 5,
        'birthMonth': batchAMonth,
        'acquisitionMonth': batchAMonth,
        'unit': u + 1,
      });

      // Child A (Placed with Mother)
      herd.add({
        'id': nextId++,
        'age': 0,
        'mature': false,
        'parentId': motherAId,
        'generation': 1,
        'birthYear': state.startDate.year,
        'birthMonth': batchAMonth,
        'acquisitionMonth': batchAMonth,
        'unit': u + 1,
      });

      // --- Batch B (July / 6 Months later) ---
      // Only create if units is whole number or handling partial
      if (state.units >= 1) {
        final batchBMonth = (batchAMonth + 6) % 12; // 6 month gap
        final motherBId = nextId++;

        // Mother B
        herd.add({
          'id': motherBId,
          'age': 5,
          'mature': true,
          'parentId': null,
          'generation': 0,
          'birthYear': state.startDate.year - 5,
          'birthMonth': batchBMonth,
          'acquisitionMonth': batchBMonth,
          'unit': u + 1,
        });

        // Child B (Placed with Mother)
        herd.add({
          'id': nextId++,
          'age': 0,
          'mature': false,
          'parentId': motherBId,
          'generation': 1,
          'birthYear': state.startDate.year,
          'birthMonth': batchBMonth,
          'acquisitionMonth': batchBMonth,
          'unit': u + 1,
        });
      }
    }

    // Simulate years
    for (int year = 1; year <= totalYears; year++) {
      final currentYear = state.startDate.year + (year - 1);

      // Breeding:
      // Skip breeding in Year 1 because we manually placed the "Year 1 Offspring" (Child A/B)
      // along with the mothers at the start.
      if (year > 1) {
        final matureBuffaloes = herd.where((b) => b['age'] >= 3).toList();

        // All offspring are female (AI Injections) and retained
        for (final parent in matureBuffaloes) {
          herd.add({
            'id': nextId++,
            'age': 0,
            'mature': false,
            'parentId': parent['id'],
            'birthYear': currentYear,
            'birthMonth': parent['acquisitionMonth'],
            'acquisitionMonth': parent['acquisitionMonth'],
            'generation': (parent['generation'] as int) + 1,
            'unit': parent['unit'],
          });
        }
      }

      // Age all buffaloes
      for (final b in herd) {
        b['age']++;
        if (b['age'] >= 3) b['mature'] = true;
      }
    }

    // Calculate revenue data based on ACTUAL herd growth with staggered cycles
    final calculatedRevenueData = _calculateRevenueData(
      herd,
      state.startDate.year,
      state.startDate.month - 1, // Convert to 0-based
      totalYears,
    );

    final newTreeData = {
      'units': state.units,
      'years': state.years,
      'startYear': state.startDate.year,
      'startMonth': state.startDate.month - 1, // Convert to 0-based
      'startDay': state.startDate.day,
      'totalBuffaloes': herd.length,
      'buffaloes': herd,
      'revenueData': calculatedRevenueData,
    };

    state = state.copyWith(
      isLoading: false,
      treeData: newTreeData,
      revenueData: calculatedRevenueData,
    );
  }
}
