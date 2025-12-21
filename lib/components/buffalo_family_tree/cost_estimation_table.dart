import 'package:buffalo_visualizer/models/simulation_config.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../widgets/break_even_timeline.dart';
import '../../widgets/monthly_revenue_break.dart';
import '../../widgets/revenue_break_even.dart';
import '../../widgets/asset_market_value.dart';
import '../../widgets/herd_performance.dart';
import '../../widgets/annual_herd_revenue.dart';
import '../../widgets/cpf_footer.dart';

class CostEstimationTable extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> revenueData;

  final bool isEmbedded;
  final SimulationConfig? config;

  const CostEstimationTable({
    Key? key,
    required this.treeData,
    required this.revenueData,
    this.isEmbedded = false,
    this.config,
  }) : super(key: key);

  @override
  State<CostEstimationTable> createState() => _CostEstimationTableState();
}

class _CostEstimationTableState extends State<CostEstimationTable> {
  String activeGraph = "revenue";
  bool _showCostEstimation = true;
  int _selectedYear = 0;
  int _selectedUnit = 1;
  String selectedSection = 'monthly';

  final List<String> _monthNames = [
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  // TooltipBehavior? _tooltipBehavior; // Removed

  Map<String, dynamic> _buffaloDetails = {};
  Map<String, Map<String, Map<String, dynamic>>> _monthlyRevenue = {};
  Map<String, Map<String, double>> _investorMonthlyRevenue = {};
  bool _includeCPF = true; // Default to TRUE (Included)

  @override
  void initState() {
    super.initState();
    _initializeBuffaloDetails();
    _calculateDetailedMonthlyRevenue();
    // _tooltipBehavior = TooltipBehavior(enable: true, format: 'point.x : point.y');
    _selectedYear = widget.treeData['startYear'] ?? DateTime.now().year;
  }

  // void _initializeBuffaloDetails() {
  //   // This is a simplified version - you'll need to adapt based on your actual data structure
  //   final treeData = widget.treeData;
  //
  //   _buffaloDetails = {};

  //   // Generate buffalo details for each unit
  //   for (int unit = 1; unit <= units; unit++) {
  //     // Parent buffaloes (2 per unit)
  //     for (int i = 1; i <= 2; i++) {
  //       final buffaloId = 'B${(unit - 1) * 2 + i}';
  //       _buffaloDetails[buffaloId] = {
  //         'id': buffaloId,
  //         'unit': unit,
  //         'generation': 0,
  //         'acquisitionMonth': 0, // January
  //         'birthYear': _selectedYear - 3, // Assume 3 years old
  //         'children': [],
  //         'grandchildren': [],
  //         'isActive': true,
  //       };
  //     }
  //   }
  // }

  void _initializeBuffaloDetails() {
    final buffaloList = widget.treeData['buffaloes'] ?? [];
    Map<String, dynamic> buffaloDetails = {};
    int counter = 1;

    // STEP 1: Parents
    for (var buffalo in buffaloList) {
      if (buffalo['generation'] == 0) {
        // Generate alphabetic ID (A1, B1, C1...) to match Type A/B logic
        // Counter 1 -> A, 2 -> B, 3 -> C, etc.
        final prefix = String.fromCharCode(65 + (counter - 1) % 26);
        // Note: This logic handles up to Z (26 buffaloes).
        // If more, we might need AA, but for this visualizer usage it's okay.
        // We append the unit number or global counter to be unique if needed?
        // The React logic expects A, B, C... so distinct letters.
        // Actually, if we have UNITS, maybe A1 for Unit 1 Type A, B1 for Unit 1 Type B?
        // But the React logic `(charCode - 65) % 2 == 0` relies on the LETTER.
        // So Unit 1: A, B. Unit 2: C, D.
        // Let's stick to strict letters for the first char.

        final id = '$prefix${(counter - 1) ~/ 26 + 1}'; // A1, B1 ...
        counter++;

        buffaloDetails[buffalo['id'].toString()] = {
          // 'id' is the display id (eg. A1, B1)
          'id': id,
          'originalId': buffalo['id'],
          'generation': 0,
          'unit': buffalo['unit'] ?? 1,
          'acquisitionMonth': buffalo['acquisitionMonth'] ?? 0,
          // default birthYear to startYear - 5 when not provided (match React)
          'birthYear':
              buffalo['birthYear'] ??
              ((widget.treeData['startYear'] ?? DateTime.now().year) - 5),
          'birthMonth': buffalo['birthMonth'] ?? 0,
          'children': <dynamic>[],
          'grandchildren': <dynamic>[],
        };
      }
    }

    // STEP 2: Children & Descendants (Recursive or Iterative)
    // The previous logic only handled Gen 1. We need to handle ALL subsequent generations.
    // Since 'buffaloList' is likely sorted by generation or we can iterate multiple times,
    // or simply process generation by generation.
    // Generally, simulation produces generation-ordered list or birth-order.

    // Sort buffaloes by generation to ensure parents exist before children
    final sortedBuffaloes = [...buffaloList];
    sortedBuffaloes.sort(
      (a, b) => (a['generation'] as int).compareTo(b['generation'] as int),
    );

    for (var buffalo in sortedBuffaloes) {
      if (buffalo['generation'] > 0) {
        // Find parent in already processed details
        final parentEntry = buffaloDetails.entries.firstWhere(
          (entry) => entry.value['originalId'] == buffalo['parentId'],
          orElse: () => const MapEntry('null', {}),
        );

        if (parentEntry.key != 'null') {
          final parent = parentEntry.value;
          final int childIndex = (parent['children'] as List).length + 1;
          final childId = "${parent['id']}-${childIndex}"; // e.g. A1-1

          final newBuffalo = {
            'id': childId,
            'originalId': buffalo['id'],
            'generation': buffalo['generation'],
            'unit': parent['unit'],
            'acquisitionMonth': parent['acquisitionMonth'], // Inherit cycle
            'birthYear': buffalo['birthYear'],
            'birthMonth':
                buffalo['birthMonth'] ??
                buffalo['acquisitionMonth'] ??
                0, // Approx
            'children': <dynamic>[],
            'grandchildren': <dynamic>[], // if needed
            'parentId': parent['originalId'], // Keep reference
          };

          buffaloDetails[buffalo['id'].toString()] = newBuffalo;
          (parent['children'] as List).add(newBuffalo);
        }
      }
    }

    _buffaloDetails = buffaloDetails;
  }

  void _calculateDetailedMonthlyRevenue() {
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    _monthlyRevenue = {};
    _investorMonthlyRevenue = {};

    // Initialize monthly revenue structure
    for (int year = startYear; year < startYear + years; year++) {
      _monthlyRevenue[year.toString()] = {};
      _investorMonthlyRevenue[year.toString()] = {};

      for (int month = 0; month < 12; month++) {
        _monthlyRevenue[year.toString()]![month.toString()] = {
          'total': 0,
          'buffaloes': {},
        };
        _investorMonthlyRevenue[year.toString()]![month.toString()] = 0.0;
      }
    }

    // Calculate revenue for each buffalo
    _buffaloDetails.forEach((buffaloMapKey, buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;

      // Use the display id (buffalo['id']) as the revenue key so it matches React
      final displayId = buffalo['id'] as String;

      for (int year = startYear; year < startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Buffalo becomes productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
              buffalo, // Pass buffalo map
            );

            if (revenue > 0) {
              final yearStr = year.toString();
              final monthStr = month.toString();

              _monthlyRevenue[yearStr]![monthStr]!['total'] =
                  (_monthlyRevenue[yearStr]![monthStr]!['total'] as int) +
                  revenue;

              // Store revenue keyed by display id (e.g., B1, B1C1)
              (_monthlyRevenue[yearStr]![monthStr]!['buffaloes']
                      as Map)[displayId] =
                  revenue;

              _investorMonthlyRevenue[yearStr]![monthStr] =
                  (_investorMonthlyRevenue[yearStr]![monthStr] ?? 0) + revenue;
            }
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(CostEstimationTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.treeData != oldWidget.treeData) {
      setState(() {
        // _dropdownUnits = ((widget.treeData['units'] ?? 1) as num).toInt(); // This might reset user selection if not careful, but needed if external update
        _initializeBuffaloDetails();
        _calculateDetailedMonthlyRevenue();
        // If the start year changes, update selected year
        if (widget.treeData['startYear'] != oldWidget.treeData['startYear']) {
          _selectedYear = widget.treeData['startYear'] ?? DateTime.now().year;
        }
      });
    }
  }

  // Calculate monthly revenue for a buffalo
  int _calculateMonthlyRevenueForBuffalo(
    int acquisitionMonth,
    int currentMonth,
    int currentYear,
    int startYear,
    Map<String, dynamic> buffalo,
  ) {
    final generation = buffalo['generation'] as int? ?? 0;

    // Generation 0: Purchased Mothers
    // Revenue based on Time Since Acquisition (Project Start)
    if (generation == 0) {
      final monthsSinceAcquisition =
          (currentYear - startYear) * 12 + (currentMonth - acquisitionMonth);

      // Purchase Month (0) + Landing Month (1) + ... = Delay
      final delay =
          widget.config?.initialBuffaloesPerUnit.revenueStartDelayMonths ?? 2;
      if (monthsSinceAcquisition < delay) {
        return 0;
      }

      final productionMonth = monthsSinceAcquisition - delay;
      final cycleMonth = productionMonth % 12;

      if (cycleMonth < 5) return 9000;
      if (cycleMonth < 8) return 6000;
      return 0;
    }
    // Generation 1+: Calves (Born or Acquired as Calves)
    // Revenue based on Age (Maturity at 36 months + 2 months delay)
    else {
      final ageInMonths = _calculateAgeInMonths(
        buffalo,
        currentYear,
        currentMonth,
      );

      // Start Milking at Age 38 (36 months growth + 2 months prep/delay)
      if (ageInMonths < 38) {
        return 0;
      }

      final productionMonth = ageInMonths - 38;
      final cycleMonth = productionMonth % 12;

      if (cycleMonth < 5) return 9000;
      if (cycleMonth < 8) return 6000;
      return 0;
    }
  }

  // Calculate age in months for a buffalo at a target year/month
  int _calculateAgeInMonths(
    Map<String, dynamic> buffalo,
    int targetYear, [
    int targetMonth = 0,
  ]) {
    final birthYear =
        (buffalo['birthYear'] as int?) ??
        (widget.treeData['startYear'] ?? DateTime.now().year);
    final birthMonth = (buffalo['birthMonth'] as int?) ?? 0;
    final totalMonthsNum =
        (targetYear - birthYear) * 12 + (targetMonth - birthMonth);
    final int totalMonths = totalMonthsNum.toInt();
    return totalMonths < 0 ? 0 : totalMonths;
  }

  // Get parent buffaloes (generation 0) for selected unit
  List<Map<String, dynamic>> _getParentBuffaloes(int unit) {
    final List<Map<String, dynamic>> parents = [];

    _buffaloDetails.forEach((buffaloId, buffalo) {
      if (buffalo['unit'] == unit && buffalo['generation'] == 0) {
        parents.add({...buffalo, 'mapKey': buffaloId});
      }
    });

    return parents;
  }

  // Get all offspring buffaloes (generation 1 & 2) for parent buffalo
  List<Map<String, dynamic>> _getOffspringBuffaloes(dynamic parentOriginalId) {
    final List<Map<String, dynamic>> offspring = [];

    _buffaloDetails.forEach((buffaloId, buffalo) {
      // Check if this buffalo's parent is the requested parent (by originalId)
      if (buffalo['parentId'] == parentOriginalId) {
        offspring.add({...buffalo, 'mapKey': buffaloId});
      }
    });

    return offspring;
  }

  // Get all income producing buffaloes for selected unit and year (deprecated - keep for reference)
  List<Map<String, dynamic>> _getIncomeProducingBuffaloes(int unit, int year) {
    final List<Map<String, dynamic>> incomeProducing = [];

    _buffaloDetails.forEach((buffaloId, buffalo) {
      if (buffalo['unit'] == unit) {
        final birthYear = buffalo['birthYear'] as int;

        // Check if buffalo is at least 3 years old
        if (year >= birthYear + 3) {
          // Check if buffalo has any revenue in the selected year
          bool hasRevenue = false;
          for (int month = 0; month < 12; month++) {
            final displayId = buffalo['id'] as String;
            final revenue =
                (_monthlyRevenue[year.toString()]?[month
                        .toString()]?['buffaloes']
                    as Map?)?[displayId] ??
                0;
            if (revenue > 0) {
              hasRevenue = true;
              break;
            }
          }

          if (hasRevenue) {
            incomeProducing.add({...buffalo, 'mapKey': buffaloId});
          }
        }
      }
    });

    return incomeProducing;
  }

  // Format currency
  String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  // Format number
  String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  // Format number (accepts num for widget compatibility)
  String formatNumberNum(num number) {
    return _numberFormat.format(number);
  }

  // Number to words conversion

  // Calculate initial investment
  Map<String, dynamic> calculateInitialInvestment() {
    final num units = widget.treeData['units'] ?? 0;
    // Use config if available, else fallback
    final int buffaloPrice =
        widget.config?.initialBuffaloesPerUnit.buffaloPrice.toInt() ?? 175000;
    final int cpfPerUnitInitial =
        widget.config?.initialBuffaloesPerUnit.cpfPerUnitInitial.toInt() ??
        13000;

    // Consider Total Buffaloes (Mothers)
    final int totalBuffaloes = (units * 2).round();

    final buffaloCost = totalBuffaloes * buffaloPrice;
    final cpfCost = (units * cpfPerUnitInitial).round();
    final totalInvestment = buffaloCost + cpfCost;

    return {
      'buffaloCost': buffaloCost,
      'cpfCost': cpfCost,
      'totalInvestment': totalInvestment,
    };
  }

  // Get buffalo market value based on age in months (match Real Config)
  int getBuffaloValueByAge(int ageInMonths) {
    if (widget.config?.assetValues != null) {
      // Iterate through sorted keys (descending) to find match
      final sortedKeys = widget.config!.assetValues.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final threshold in sortedKeys) {
        if (ageInMonths >= threshold) {
          return widget.config!.assetValues[threshold]!.toInt();
        }
      }
    }
    // Fallback
    if (ageInMonths >= 60) return 175000;
    if (ageInMonths >= 48) return 150000;
    if (ageInMonths >= 40) return 100000;
    if (ageInMonths >= 36) return 50000;
    if (ageInMonths >= 30) return 50000;
    if (ageInMonths >= 24) return 35000;
    if (ageInMonths >= 18) return 25000;
    if (ageInMonths >= 12) return 12000;
    if (ageInMonths >= 6) return 6000;
    return 3000;
  }

  // Calculate yearly CPF cost for entire tree (match React calculateYearlyCPFCost)
  // UPDATED: Monthly precision with Type A/B logic and Type B free period
  Map<int, int> calculateYearlyCPFCost() {
    final Map<int, int> cpfCostByYear = {};
    final int startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final int years = widget.treeData['years'] ?? 10;
    final double cpfPerMonth = 13000 / 12; // ₹1,083.33 per month

    for (int year = startYear; year < startYear + years; year++) {
      double totalCPFCost = 0;

      final num units = widget.treeData['units'] ?? 1;
      for (int unit = 1; unit <= units.ceil(); unit++) {
        double unitCPFCost = 0;

        // Collect buffaloes in this unit
        final unitBuffaloes = _buffaloDetails.values
            .where((b) => (b['unit'] ?? 1) == unit)
            .toList();

        for (final buffalo in unitBuffaloes) {
          final id = buffalo['id'] as String?;
          final gen = buffalo['generation'] as int? ?? 0;
          int monthsWithCPF = 0;

          for (int month = 0; month < 12; month++) {
            bool isCpfApplicable = false;

            if (gen == 0) {
              // Generation 0: Identify Type A (First in unit) vs Type B (Second in unit)
              // Type A: charCode even (A=65, C=67, E=69...) - (65-65)%2=0, (67-65)%2=0
              // Type B: charCode odd (B=66, D=68, F=70...) - (66-65)%2=1, (68-65)%2=1
              if (id != null && id.isNotEmpty) {
                final charCode = id.codeUnitAt(0);
                final isFirstInUnit = (charCode - 65) % 2 == 0;

                if (isFirstInUnit) {
                  // Type A: Always pays CPF from start
                  isCpfApplicable = true;
                } else {
                  // Type B: Free Period Check
                  final acquisitionMonth =
                      buffalo['acquisitionMonth'] as int? ?? 0;
                  final isPresentInSimulation =
                      year > startYear ||
                      (year == startYear && month >= acquisitionMonth);

                  if (isPresentInSimulation) {
                    // Free Period: July of Start Year (month 6) to June of Start Year + 1 (month 5)
                    final isFreePeriod =
                        (year == startYear && month >= 6) ||
                        (year == startYear + 1 && month <= 5);

                    if (!isFreePeriod) {
                      isCpfApplicable = true;
                    }
                  }
                }
              }
            } else if (gen >= 1) {
              // Child CPF: Age >= 36 months (per month check for accuracy)
              final ageInMonths = _calculateAgeInMonths(buffalo, year, month);
              if (ageInMonths >= 36) {
                isCpfApplicable = true;
              }
            }

            if (isCpfApplicable) {
              monthsWithCPF++;
            }
          }

          unitCPFCost += monthsWithCPF * cpfPerMonth;
        }

        totalCPFCost += unitCPFCost;
      }

      cpfCostByYear[year] = totalCPFCost.round();
    }

    return cpfCostByYear;
  }

  // Calculate break-even analysis
  // Calculate break-even analysis with monthly precision
  Map<String, dynamic> calculateBreakEvenAnalysis() {
    final initialInvestment = calculateInitialInvestment();
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final startMonth = widget.treeData['startMonth'] ?? 0;
    final startDay = widget.treeData['startDay'] ?? 1;
    final years = widget.treeData['years'] ?? 10;

    // Prepare detailed structures
    final investorMonthlyRevenue = _calculateInvestorMonthlyRevenue();
    final buffaloValuesByYear = <int, Map<String, Map<String, dynamic>>>{};

    for (int year = startYear; year < startYear + years; year++) {
      buffaloValuesByYear[year] = {};
      _buffaloDetails.forEach((key, buffalo) {
        final ageInMonths = _calculateAgeInMonths(buffalo, year, 11);
        buffaloValuesByYear[year]![buffalo['id'] as String] = {
          'ageInMonths': ageInMonths,
          'value': getBuffaloValueByAge(ageInMonths),
        };
      });
    }

    // Yearly CPF costs
    final yearlyCPFCost = calculateYearlyCPFCost();

    // Break-even timeline (with and without CPF) using month-by-month accumulation
    int? breakEvenYearWithoutCPF;
    int? breakEvenMonthWithoutCPF;
    DateTime? exactBreakEvenDateWithoutCPF;

    int? breakEvenYearWithCPF;
    int? breakEvenMonthWithCPF;
    DateTime? exactBreakEvenDateWithCPF;

    double cumulativeWithoutCPF = 0;
    // Without CPF: accumulate revenue only (Cash Flow Break Even)
    bool foundWithout = false;
    for (
      int year = startYear;
      year < startYear + years && !foundWithout;
      year++
    ) {
      for (int month = 0; month < 12; month++) {
        final monthlyRev =
            investorMonthlyRevenue[year.toString()]?[month.toString()] ?? 0;
        cumulativeWithoutCPF += monthlyRev;

        // Check for Cash-on-Cash Break-Even (Revenue Only)
        // User requested break-even to be based on revenue recovery (approx 36 months),
        if (cumulativeWithoutCPF >= initialInvestment['totalInvestment'] &&
            !foundWithout) {
          breakEvenYearWithoutCPF = year;
          breakEvenMonthWithoutCPF = month;
          foundWithout = true;

          final startDate = DateTime(startYear, startMonth + 1, startDay);
          final monthsSinceStart =
              (year - startYear) * 12 + (month - startMonth);
          final computed = DateTime(
            startDate.year,
            (startDate.month + monthsSinceStart + 1).toInt(),
            0,
          );
          exactBreakEvenDateWithoutCPF = computed;
        }
      }
    }

    // With CPF: subtract monthly CPF (annual/12) while accumulating
    double tempCumulativeWithCPF = 0;
    bool foundWith = false;
    for (int year = startYear; year < startYear + years && !foundWith; year++) {
      final annualCPFCost = yearlyCPFCost[year] ?? 0;
      final monthlyCPF = annualCPFCost / 12.0;

      for (int month = 0; month < 12; month++) {
        final monthlyRev =
            investorMonthlyRevenue[year.toString()]?[month.toString()] ?? 0;

        // Net Cash Flow for this month (Revenue - CPF)
        final netMonthly = monthlyRev - monthlyCPF;
        tempCumulativeWithCPF += netMonthly;

        if (tempCumulativeWithCPF >= initialInvestment['totalInvestment'] &&
            !foundWith) {
          breakEvenYearWithCPF = year;
          breakEvenMonthWithCPF = month;
          foundWith = true;

          final startDate = DateTime(startYear, startMonth + 1, startDay);
          final monthsSinceStart =
              (year - startYear) * 12 + (month - startMonth);
          final computed = DateTime(
            startDate.year,
            (startDate.month + monthsSinceStart + 1).toInt(),
            0,
          );
          exactBreakEvenDateWithCPF = computed;
        }
      }
    }

    // Revenue-only break-even (cumulative revenue reaching investment) is also useful but
    // React calculates both. We'll compute yearly aggregates for the table.
    final List<Map<String, dynamic>> breakEvenData = [];
    final cumulativeYearlyData = <Map<String, dynamic>>[];

    // compute yearly CPF and revenue-with-cpf
    for (int i = 0; i < yearlyData.length; i++) {
      final yearData = yearlyData[i];
      final year = yearData['year'] as int;
      final cpfCost = yearlyCPFCost[year] ?? 0;

      // FIX: Calculate annual revenue by summing the detailed monthly revenue
      // instead of using the SimulationService's annual approximation.
      // This ensures consistency with the "Monthly Revenue Breakdown".
      double revenueWithoutCPF = 0;
      final yearStr = year.toString();
      if (investorMonthlyRevenue.containsKey(yearStr)) {
        for (int month = 0; month < 12; month++) {
          revenueWithoutCPF +=
              investorMonthlyRevenue[yearStr]?[month.toString()] ?? 0;
        }
      }

      final revenueWithCPF = revenueWithoutCPF - cpfCost;

      // Also carry herd stats so AnnualHerdRevenueWidget can display
      // totalBuffaloes per year (and keep mature/producing if needed).
      final totalBuffaloes = (yearData['totalBuffaloes'] as int?) ?? 0;
      final producingBuffaloes = (yearData['producingBuffaloes'] as int?) ?? 0;

      cumulativeYearlyData.add({
        'year': year,
        'cpfCost': cpfCost,
        'revenueWithoutCPF': revenueWithoutCPF,
        'revenueWithCPF': revenueWithCPF,
        'totalBuffaloes': totalBuffaloes,
        'matureBuffaloes': producingBuffaloes,
      });
    }

    // build cumulative and per-year table rows
    double cumulativeWithout = 0;
    double cumulativeWith = 0;
    for (int i = 0; i < cumulativeYearlyData.length; i++) {
      final yd = cumulativeYearlyData[i];
      final year = yd['year'] as int;
      final yearData = yearlyData[i];
      cumulativeWithout += yd['revenueWithoutCPF'] as double;
      cumulativeWith += yd['revenueWithCPF'] as double;

      // year-end asset value (December)
      double yearEndAssetValue = 0;
      _buffaloDetails.forEach((k, buffalo) {
        if ((buffalo['birthYear'] as int?) == null) return;
        if (year >= (buffalo['birthYear'] as int)) {
          final age = _calculateAgeInMonths(buffalo, year, 11); // Dec 31
          yearEndAssetValue += getBuffaloValueByAge(age);
        }
      });

      final totalValueWith = cumulativeWith + yearEndAssetValue;
      final recoveryPercentageWith =
          (totalValueWith / (initialInvestment['totalInvestment'] as num)) *
          100;
      final revenueOnlyPercentageWith =
          (cumulativeWith / (initialInvestment['totalInvestment'] as num)) *
          100;

      String statusWith = 'in Progress';
      String revenueOnlyStatusWith = 'in Progress';
      if (recoveryPercentageWith >= 100)
        statusWith = '✔ Break-Even';
      else if (recoveryPercentageWith >= 75)
        statusWith = '75% Recovered';
      else if (recoveryPercentageWith >= 50)
        statusWith = '50% Recovered';

      if (revenueOnlyPercentageWith >= 100)
        revenueOnlyStatusWith = '✔ Break-Even';
      else if (revenueOnlyPercentageWith >= 75)
        revenueOnlyStatusWith = '75% Recovered';
      else if (revenueOnlyPercentageWith >= 50)
        revenueOnlyStatusWith = '50% Recovered';

      breakEvenData.add({
        'year': year,
        'annualRevenueWithCPF': yd['revenueWithCPF'],
        'annualRevenueWithoutCPF': yd['revenueWithoutCPF'],
        // Backwards-compatible keys used by the existing UI (annual & cumulative without CPF)
        'annualRevenue': yd['revenueWithoutCPF'],
        'cumulativeRevenue': cumulativeWithout,
        'isBreakEven': breakEvenYearWithoutCPF == year,
        'cpfCost': yd['cpfCost'],
        'cumulativeRevenueWithCPF': cumulativeWith,
        'cumulativeRevenueWithoutCPF': cumulativeWithout,
        'assetValue': yearEndAssetValue,
        'totalValueWithCPF': totalValueWith,
        'recoveryPercentageWithCPF': recoveryPercentageWith,
        'revenueOnlyPercentageWithCPF': revenueOnlyPercentageWith,
        'statusWithCPF': statusWith,
        'revenueOnlyStatusWithCPF': revenueOnlyStatusWith,
        'isBreakEvenWithCPF': breakEvenYearWithCPF == year,
        'isBreakEvenWithoutCPF': breakEvenYearWithoutCPF == year,
        'totalBuffaloes': yearData['totalBuffaloes'],
        'matureBuffaloes': yearData['producingBuffaloes'],
      });
    }

    final finalCumulativeWith = cumulativeWith;
    final finalCumulativeWithout = cumulativeWithout;

    return {
      'breakEvenData': breakEvenData,
      'cumulativeYearlyData': cumulativeYearlyData,
      'breakEvenYearWithCPF': breakEvenYearWithCPF,
      'breakEvenMonthWithCPF': breakEvenMonthWithCPF,
      'exactBreakEvenDateWithCPF': exactBreakEvenDateWithCPF,
      'breakEvenYearWithoutCPF': breakEvenYearWithoutCPF,
      'breakEvenMonthWithoutCPF': breakEvenMonthWithoutCPF,
      'exactBreakEvenDateWithoutCPF': exactBreakEvenDateWithoutCPF,
      // Backwards compatible keys (default to "without CPF" values)
      'breakEvenYear': breakEvenYearWithoutCPF,
      'breakEvenMonth': breakEvenMonthWithoutCPF,
      'exactBreakEvenDate': exactBreakEvenDateWithoutCPF,
      'initialInvestment': initialInvestment['totalInvestment'],
      'finalCumulativeRevenueWithCPF': finalCumulativeWith,
      'finalCumulativeRevenueWithoutCPF': finalCumulativeWithout,
      'finalCumulativeRevenue': finalCumulativeWithout,
    };
  }

  // Calculate investor monthly revenue (shared between buffaloes)
  Map<String, Map<String, double>> _calculateInvestorMonthlyRevenue() {
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;
    final units = widget.treeData['units'] ?? 1;

    Map<String, Map<String, double>> investorMonthlyRevenue = {};

    // Initialize structure
    for (int year = startYear; year < startYear + years; year++) {
      investorMonthlyRevenue[year.toString()] = {};
      for (int month = 0; month < 12; month++) {
        investorMonthlyRevenue[year.toString()]![month.toString()] = 0.0;
      }
    }

    // Calculate revenue based on buffalo details
    _buffaloDetails.forEach((buffaloId, buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;

      for (int year = startYear; year < startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
              buffalo, // Pass buffalo map
            );

            // Investor gets revenue if buffalo is generating income
            if (revenue > 0) {
              investorMonthlyRevenue[year.toString()]![month.toString()] =
                  (investorMonthlyRevenue[year.toString()]![month.toString()] ??
                      0) +
                  revenue;
            }
          }
        }
      }
    });

    return investorMonthlyRevenue;
  }

  // Calculate asset market value
  List<Map<String, dynamic>> calculateAssetMarketValue() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;

    return yearlyData.map((yearData) {
      final year = yearData['year'] as int;
      final totalBuffaloes = yearData['totalBuffaloes'] as int;

      double yearEndAssetValue = 0;
      _buffaloDetails.forEach((k, buffalo) {
        if ((buffalo['birthYear'] as int?) == null) return;
        if (year >= (buffalo['birthYear'] as int)) {
          final age = _calculateAgeInMonths(buffalo, year, 11); // Dec 31
          yearEndAssetValue += getBuffaloValueByAge(age);
        }
      });

      return {
        'year': year,
        'totalBuffaloes': totalBuffaloes,
        'assetValue': yearEndAssetValue,
        'totalAssetValue': yearEndAssetValue,
      };
    }).toList();
  }

  // Calculate herd statistics
  Map<String, dynamic> calculateHerdStats() {
    final units = widget.treeData['units'] ?? 0;
    final totalBuffaloes = widget.treeData['totalBuffaloes'] ?? 0;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final years = widget.treeData['years'] ?? 0;
    final totalMatureBuffaloYears =
        widget.revenueData['totalMatureBuffaloYears'] ?? 0;

    final startingBuffaloes = units * 2;
    final growthMultiple = totalBuffaloes / startingBuffaloes;
    final averageMatureBuffaloes = totalMatureBuffaloYears / years;
    final revenuePerBuffalo = totalRevenue / totalBuffaloes;

    return {
      'startingBuffaloes': startingBuffaloes,
      'finalBuffaloes': totalBuffaloes,
      'growthMultiple': growthMultiple,
      'averageMatureBuffaloes': averageMatureBuffaloes,
      'revenuePerBuffalo': revenuePerBuffalo,
    };
  }

  // Revenue Graph Widget

  // Buffalo Growth Graph Widget

  // Buffalo Population Growth Graph (Matching React component)

  // Production Analysis Graph Widget
  // Production Analysis Graph Widget - CORRECTED

  // Summary Cards Widget
  Widget _buildSummaryCards() {
    final herdStats = calculateHerdStats();
    final units = widget.treeData['units'] ?? 0;
    final years = widget.treeData['years'] ?? 0;
    final totalBuffaloes = widget.treeData['totalBuffaloes'] ?? 0;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    final cards = [
      {
        'value': units.toString(),
        'label': 'Starting Units',
        'description': '${herdStats['startingBuffaloes']} initial buffaloes',
        'color': Colors.blue,
      },
      {
        'value': years.toString(),
        'label': 'Simulation Years',
        'description': 'Revenue generation period',
        'color': Colors.green,
      },
      {
        'value': totalBuffaloes.toString(),
        'label': 'Final Herd Size',
        'description':
            '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x growth',
        'color': Colors.purple,
      },
      {
        'value': formatCurrency(totalRevenue),
        'label': 'Total Revenue',
        'description': 'From entire herd growth',
        'color': Colors.blue,
        // 'gradient': true,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Common card builder
        Widget buildCard(Map<String, dynamic> card, {double? width}) {
          return Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: card['gradient'] == true
                  ? (isDark ? Colors.blue[900] : Colors.blue)
                  : (isDark ? Colors.grey[850] : Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card['value'].toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: card['gradient'] == true
                          ? Colors.white
                          : (card['color'] as Color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['label'].toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: card['gradient'] == true
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['description'].toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 10,
                      color: card['gradient'] == true
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (isMobile) {
          // Mobile: Vertical stack or 2-column grid
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((card) {
              // Calculate width for 2 items per row with spacing
              // (screenWidth - (padding * 2) - spacing) / 2
              // Assuming 16px horizontal padding for parent container
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return buildCard(card, width: itemWidth);
            }).toList(),
          );
        } else if (isTablet) {
          // Tablet: 2x2 Grid (Wrapped)
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards.map((card) {
              final itemWidth = (constraints.maxWidth - 16) / 2;
              return buildCard(card, width: itemWidth);
            }).toList(),
          );
        } else {
          // Desktop: Horizontal row (Expanded)
          return Row(
            children: cards.map((card) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: buildCard(card),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  // Revenue Break-Even Analysis Widget

  // Asset Market Value Widget

  // Quick Stats Card Widget

  // Production Schedule Widget

  // Revenue Table Widget

  // Additional Information Widget

  // Graph Navigation Widget

  // Graphs Section Widget

  // Section Tabs after Summary Cards
  Widget _buildSectionTabs() {
    final List<Map<String, dynamic>> sections = [
      {
        'key': 'monthly',
        'label': 'Monthly Revenue Breakdown',
        'color': Colors.blue,
      },
      {
        'key': 'revenue_breakdown',
        'label': 'Revenue Break-Even',
        'color': Colors.purple,
      },
      {
        'key': 'asset_market',
        'label': 'Asset Market Value',
        'color': Colors.orange,
      },
      {
        'key': 'herd_performance',
        'label': 'Herd Performance',
        'color': Colors.green,
      },
      {
        'key': 'annual_revenue',
        'label': 'Annual herd revenue',
        'color': Colors.indigo,
      },
      {
        'key': 'staggered_schedule',
        'label': 'Break Even Timeline',
        'color': Colors.yellow[700],
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            alignment: WrapAlignment.center,
            children: sections.map((s) {
              final isSelected = selectedSection == s['key'];
              return InkWell(
                onTap: () => setState(
                  () => selectedSection = isSelected ? 'all' : s['key'],
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: isMobile ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (s['color'] as Color).withOpacity(0.85)
                        : (isDark ? Colors.grey[800] : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (s['color'] as Color).withOpacity(0.9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isMobile ? 8 : 10,
                        height: isMobile ? 8 : 10,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : s['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s['label'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[200] : Colors.black87),
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // CPF Toggle and Stats Row
        if (selectedSection == 'all' ||
            selectedSection == 'staggered_schedule' ||
            selectedSection == 'revenue_breakdown')
          Builder(
            builder: (context) {
              // Calculate Stats
              final totalRevenue =
                  (widget.revenueData['totalRevenue'] as num?)?.toDouble() ??
                  0.0;

              final cpfByYear = calculateYearlyCPFCost();
              final totalCPF = cpfByYear.values.fold(
                0,
                (sum, val) => sum + val,
              );

              final netRevenue = _includeCPF
                  ? (totalRevenue - totalCPF)
                  : totalRevenue;

              final assetMarketValues = calculateAssetMarketValue();
              final totalAssetValue = assetMarketValues.isNotEmpty
                  ? (assetMarketValues.last['totalAssetValue'] as num?)
                            ?.toDouble() ??
                        0.0
                  : 0.0;

              final roi = netRevenue + totalAssetValue;

              return Container(
                margin: const EdgeInsets.only(bottom: 24, top: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: isMobile
                    ? Column(
                        children: [
                          // Toggle Mobile
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CGF INCLUDED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _includeCPF,
                                  onChanged: (val) =>
                                      setState(() => _includeCPF = val),
                                  activeColor: Colors.tealAccent,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildDashboardStat(
                                'CUMULATIVE NET (WITH CGF)',
                                formatCurrency(netRevenue),
                                const Color(0xFF00BFA5),
                                isMobile,
                                isDark,
                              ),
                              _buildDashboardStat(
                                'TOTAL ASSET VALUE',
                                formatCurrency(totalAssetValue),
                                const Color(0xFF2979FF),
                                isMobile,
                                isDark,
                              ),
                              _buildDashboardStat(
                                'ROI (NET + ASSETS)',
                                formatCurrency(roi),
                                const Color(0xFF6200EA),
                                isMobile,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CGF INCLUDED',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _includeCPF ? 'ON' : 'OFF',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: _includeCPF,
                                          onChanged: (val) =>
                                              setState(() => _includeCPF = val),
                                          activeColor: Colors.tealAccent,
                                          activeTrackColor: Colors.teal
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          _buildDashboardStat(
                            'CUMULATIVE NET (WITH CGF)',
                            formatCurrency(netRevenue),
                            const Color(0xFF00BFA5),
                            isMobile,
                            isDark,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          _buildDashboardStat(
                            'TOTAL ASSET VALUE',
                            formatCurrency(totalAssetValue),
                            const Color(0xFF2979FF),
                            isMobile,
                            isDark,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          _buildDashboardStat(
                            'ROI (NET + ASSETS)',
                            formatCurrency(roi),
                            const Color(0xFF6200EA),
                            isMobile,
                            isDark,
                          ),
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }

  // Price in Words Widget

  @override
  Widget build(BuildContext context) {
    if (!_showCostEstimation && !widget.isEmbedded) {
      Navigator.of(context).pop();
    }

    // final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    // final units = widget.treeData['units'] ?? 0;
    // final years = widget.treeData['years'] ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.black]
                  : [Colors.blue[50]!, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              children: [
                // const SizedBox(height: 20),

                // // Header
                // Text(
                //   'Buffalo Herd Investment Analysis',
                //   style: TextStyle(
                //     fontSize: isMobile ? 20 : 25,
                //     fontWeight: FontWeight.bold,
                //     color: isDark ? Colors.white : Colors.black,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 20),

                // Summary Cards
                // _buildSummaryCards(),

                // const SizedBox(height: 20),

                // Section Cards
                _buildSectionTabs(),

                const SizedBox(height: 12),

                if (selectedSection == 'all' ||
                    selectedSection == 'monthly') ...[
                  MonthlyRevenueBreakWidget(
                    treeData: widget.treeData,
                    buffaloDetails: _buffaloDetails,
                    monthlyRevenue: _monthlyRevenue,
                    calculateAgeInMonths: _calculateAgeInMonths,
                    monthNames: _monthNames,
                    formatCurrency: formatCurrency,
                  ),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'revenue_breakdown') ...[
                  RevenueBreakEvenWidget(
                    treeData: widget.treeData,
                    breakEvenAnalysis: calculateBreakEvenAnalysis(),
                    monthNames: _monthNames,
                    formatCurrency: formatCurrency,
                  ),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'asset_market') ...[
                  AssetMarketValueWidget(
                    treeData: widget.treeData,
                    yearlyData: widget.revenueData['yearlyData'] ?? [],
                    formatCurrency: formatCurrency,
                    formatNumber: formatNumberNum,
                    calculateAgeInMonths: _calculateAgeInMonths,
                    buffaloDetails: _buffaloDetails,
                  ),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'herd_performance') ...[
                  HerdPerformanceWidget(
                    yearlyData: widget.revenueData['yearlyData'] ?? [],
                    formatNumber: formatNumberNum,
                  ),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'staggered_schedule') ...[
                  BreakEvenTimelineWidget(
                    treeData: widget.treeData,
                    breakEvenAnalysis: calculateBreakEvenAnalysis(),
                    monthNames: _monthNames,
                    formatCurrency: formatCurrency,
                    formatNumber: formatNumber,
                    includeCPF: _includeCPF, // Pass toggle
                  ),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'annual_revenue') ...[
                  AnnualHerdRevenueWidget(
                    // Use the same cumulativeYearlyData used for break-even,
                    // which already contains revenueWithCPF and cpfCost.
                    cumulativeYearlyData:
                        (calculateBreakEvenAnalysis()['cumulativeYearlyData']
                            as List<dynamic>?) ??
                        [],
                    formatCurrency: formatCurrency,
                    formatNumber: formatNumberNum,
                    treeData: widget.treeData,
                    startYear:
                        widget.treeData['startYear'] ?? DateTime.now().year,
                    endYear:
                        ((widget.treeData['startYear'] ?? DateTime.now().year) +
                        (widget.treeData['years'] ?? 10)),
                    yearRange:
                        '${widget.treeData['startYear'] ?? DateTime.now().year}-${((widget.treeData['startYear'] ?? DateTime.now().year) + (widget.treeData['years'] ?? 10))}',
                  ),
                  const SizedBox(height: 40),
                ],

                // CPF Footer
                const CpfFooterWidget(),
                const SizedBox(height: 40),

                // Additional Information
                // _buildAdditionalInformation(),
                // const SizedBox(height: 40),

                // Action Buttons
                if (!widget.isEmbedded)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      if (!widget.isEmbedded)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[500],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 48,
                              vertical: isMobile ? 12 : 20,
                            ),
                            textStyle: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: isMobile ? 20 : 24),
                              const SizedBox(width: 12),
                              const Text('Back to Family Tree'),
                            ],
                          ),
                        ),
                      // const SizedBox(width: 16),
                      // ElevatedButton(
                      //   onPressed: () async {
                      //     final csvBuffer = StringBuffer();
                      //     csvBuffer.writeln(
                      //       'Year,TotalBuffaloes,ProducingBuffaloes,Revenue',
                      //     );
                      //     final yearlyData =
                      //         widget.revenueData['yearlyData'] as List<dynamic>;
                      //     for (final y in yearlyData) {
                      //       csvBuffer.writeln(
                      //         '${y['year']},${y['totalBuffaloes']},${y['matureBuffaloes']},${y['revenue']}',
                      //       );
                      //     }
                      //     final csvString = csvBuffer.toString();
                      //     await Share.share(csvString, subject: 'Revenue CSV');
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue[500],
                      //     foregroundColor: Colors.white,
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: isMobile ? 24 : 48,
                      //       vertical: isMobile ? 12 : 20,
                      //     ),
                      //     textStyle: TextStyle(
                      //       fontSize: isMobile ? 16 : 20,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(20),
                      //     ),
                      //     elevation: 8,
                      //   ),
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       Icon(Icons.share, size: isMobile ? 20 : 24),
                      //       const SizedBox(width: 12),
                      //       const Text('Share Revenue CSV'),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),

                // const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardStat(
    String label,
    String value,
    Color color,
    bool isMobile,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ), // Uppercase Label
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Helper class for chart data
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
