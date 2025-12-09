import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../widgets/reusable_pluto_grid.dart';
import '../../widgets/break_even_timeline.dart';
import '../../widgets/monthly_revenue_break.dart';
import '../../widgets/revenue_break_even.dart';
import '../../widgets/asset_market_value.dart';
import '../../widgets/herd_performance.dart';
import '../../widgets/annual_herd_revenue.dart';

class CostEstimationTable extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> revenueData;

  const CostEstimationTable({
    Key? key,
    required this.treeData,
    required this.revenueData,
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

  late TooltipBehavior _tooltipBehavior;

  Map<String, dynamic> _buffaloDetails = {};
  Map<String, Map<String, Map<String, dynamic>>> _monthlyRevenue = {};
  Map<String, Map<String, double>> _investorMonthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _initializeBuffaloDetails();
    _calculateDetailedMonthlyRevenue();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y',
    );
    _selectedYear = widget.treeData['startYear'] ?? DateTime.now().year;
  }

  // void _initializeBuffaloDetails() {
  //   // This is a simplified version - you'll need to adapt based on your actual data structure
  //   final treeData = widget.treeData;
  //   final units = treeData['units'] ?? 1;
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
        final id = 'B$counter';
        counter++;

        buffaloDetails[buffalo['id'].toString()] = {
          // 'id' is the display id (eg. B1) and should be preserved
          'id': id,
          'originalId': buffalo['id'],
          'generation': 0,
          'unit': buffalo['unit'] ?? 1,
          'acquisitionMonth': buffalo['acquisitionMonth'] ?? 0,
          // default birthYear to startYear - 5 when not provided (match React)
          'birthYear': buffalo['birthYear'] ?? ((widget.treeData['startYear'] ?? DateTime.now().year) - 5),
          'birthMonth': buffalo['birthMonth'] ?? 0,
          'children': <dynamic>[],
          'grandchildren': <dynamic>[],
        };
      }
    }

    // STEP 2: Children
    for (var buffalo in buffaloList) {
      if (buffalo['generation'] == 1) {
        final parent = buffaloDetails.values.firstWhere(
          (p) => p['originalId'] == buffalo['parentId'],
        );

        final childId = "${parent['id']}C${(parent['children'] as List).length + 1}";

        buffaloDetails[buffalo['id'].toString()] = {
          'id': childId,
          'originalId': buffalo['id'],
          'generation': 1,
          'unit': parent['unit'],
          'acquisitionMonth': parent['acquisitionMonth'] ?? 0,
          // default birthYear to startYear for initial calves, otherwise use provided birthYear
          'birthYear': buffalo['birthYear'] ?? (widget.treeData['startYear'] ?? DateTime.now().year),
          'birthMonth': buffalo['birthMonth'] ?? 0,
          'children': <dynamic>[],
          'grandchildren': <dynamic>[],
          'parentId': parent['originalId'],
        };

        parent['children'].add(buffalo['id']);
      }
    }

    // STEP 3: Grandchildren
    for (var buffalo in buffaloList) {
      if (buffalo['generation'] == 2) {
        final grandparent = buffaloDetails.values.firstWhere(
          (p) => (p['children'] as List).contains(buffalo['parentId']),
        );

        final gcId =
            "${grandparent['id']}GC${(grandparent['grandchildren'] as List).length + 1}";

        buffaloDetails[buffalo['id'].toString()] = {
          'id': gcId,
          'originalId': buffalo['id'],
          'generation': 2,
          'unit': grandparent['unit'],
          'acquisitionMonth': grandparent['acquisitionMonth'] ?? 0,
          'birthYear': buffalo['birthYear'] ?? (widget.treeData['startYear'] ?? DateTime.now().year),
          'birthMonth': buffalo['birthMonth'] ?? 0,
          'parentId': buffalo['parentId'],
        };

        grandparent['grandchildren'].add(buffalo['id']);
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
    for (int year = startYear; year <= startYear + years; year++) {
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

      for (int year = startYear; year <= startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Buffalo becomes productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
            );

            if (revenue > 0) {
              final yearStr = year.toString();
              final monthStr = month.toString();

              _monthlyRevenue[yearStr]![monthStr]!['total'] =
                  (_monthlyRevenue[yearStr]![monthStr]!['total'] as int) +
                  revenue;

              // Store revenue keyed by display id (e.g., B1, B1C1)
              (_monthlyRevenue[yearStr]![monthStr]!['buffaloes'] as Map)[displayId] =
                  revenue;

              _investorMonthlyRevenue[yearStr]![monthStr] =
                  (_investorMonthlyRevenue[yearStr]![monthStr] ?? 0) + revenue;
            }
          }
        }
      }
    });
  }

  // Calculate monthly revenue for a buffalo
  int _calculateMonthlyRevenueForBuffalo(
    int acquisitionMonth,
    int currentMonth,
    int currentYear,
    int startYear,
  ) {
    final monthsSinceAcquisition =
        (currentYear - startYear) * 12 + (currentMonth - acquisitionMonth);

    if (monthsSinceAcquisition < 2) {
      return 0; // Landing period
    }

    final productionMonth = monthsSinceAcquisition - 2;
    final cycleMonth = productionMonth % 12;

    if (cycleMonth < 5) {
      return 9000; // High revenue phase
    } else if (cycleMonth < 8) {
      return 6000; // Medium revenue phase
    } else {
      return 0; // Rest period
    }
  }

  // Calculate age in months for a buffalo at a target year/month
  int _calculateAgeInMonths(Map<String, dynamic> buffalo, int targetYear, [int targetMonth = 0]) {
    final birthYear = (buffalo['birthYear'] as int?) ?? (widget.treeData['startYear'] ?? DateTime.now().year);
    final birthMonth = (buffalo['birthMonth'] as int?) ?? 0;
    final totalMonthsNum = (targetYear - birthYear) * 12 + (targetMonth - birthMonth);
    final int totalMonths = totalMonthsNum.toInt();
    return totalMonths < 0 ? 0 : totalMonths;
  }

  // Get parent buffaloes (generation 0) for selected unit
  List<Map<String, dynamic>> _getParentBuffaloes(int unit) {
    final List<Map<String, dynamic>> parents = [];

    _buffaloDetails.forEach((buffaloId, buffalo) {
      if (buffalo['unit'] == unit && buffalo['generation'] == 0) {
        parents.add({
          ...buffalo,
          'mapKey': buffaloId,
        });
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
        offspring.add({
          ...buffalo,
          'mapKey': buffaloId,
        });
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
            final revenue = (_monthlyRevenue[year.toString()]?[month.toString()]?['buffaloes'] as Map?)?[displayId] ?? 0;
            if (revenue > 0) {
              hasRevenue = true;
              break;
            }
          }

          if (hasRevenue) {
            incomeProducing.add({
              ...buffalo,
              'mapKey': buffaloId,
            });
          }
        }
      }
    });

    return incomeProducing;
  }

  Future<void> _downloadExcel() async {
    final unitBuffaloes = _getIncomeProducingBuffaloes(
      _selectedUnit,
      _selectedYear,
    );
    final cpfCost = _calculateCPFCost(unitBuffaloes);

    // Create CSV content
    StringBuffer csvContent = StringBuffer();
    csvContent.writeln(
      'Monthly Revenue Breakdown - Unit $_selectedUnit - $_selectedYear\n',
    );

    // Headers
    csvContent.write('Month,');
    for (final buffalo in unitBuffaloes) {
      csvContent.write('${buffalo['id']},');
    }
    csvContent.writeln('Unit Total,CPF Cost,Net Revenue');

    // Monthly data
    for (int monthIndex = 0; monthIndex < _monthNames.length; monthIndex++) {
      double unitTotal = 0;
      csvContent.write('${_monthNames[monthIndex]},');

      for (final buffalo in unitBuffaloes) {
        final revenue =
            (_monthlyRevenue[_selectedYear.toString()]?[monthIndex
                    .toString()]?['buffaloes']
                as Map?)?[buffalo['id']] ??
            0;
        csvContent.write('$revenue,');
        unitTotal += revenue.toDouble();
      }

      final netRevenue = unitTotal - cpfCost['monthlyCPFCost'];
      csvContent.writeln('$unitTotal,${cpfCost['monthlyCPFCost']},$netRevenue');
    }

    // Yearly totals
    double yearlyUnitTotal = 0;
    csvContent.write('\nYearly Total,');

    for (final buffalo in unitBuffaloes) {
      double yearlyTotal = 0;
      for (int monthIndex = 0; monthIndex < _monthNames.length; monthIndex++) {
        final revenue =
            (_monthlyRevenue[_selectedYear.toString()]?[monthIndex
                    .toString()]?['buffaloes']
                as Map?)?[buffalo['id']] ??
            0;
        yearlyTotal += revenue.toDouble();
      }
      csvContent.write('$yearlyTotal,');
      yearlyUnitTotal += yearlyTotal;
    }

    final yearlyNetRevenue = yearlyUnitTotal - cpfCost['annualCPFCost'];
    csvContent.writeln(
      '$yearlyUnitTotal,${cpfCost['annualCPFCost']},$yearlyNetRevenue',
    );

    // Share the CSV content
    await Share.share(
      csvContent.toString(),
      subject: 'Unit-$_selectedUnit-Revenue-$_selectedYear.csv',
    );
  }

  Map<String, dynamic> _calculateCPFCost(
    List<Map<String, dynamic>> unitBuffaloes,
  ) {
    int milkProducingBuffaloesWithCPF = 0;
    final List<Map<String, dynamic>> buffaloCPFDetails = [];

    // Determine first parent in the provided list (if any) and treat it like React's M1
    final parents = unitBuffaloes.where((b) => (b['generation'] as int) == 0).toList();
    String? firstParentId;
    if (parents.isNotEmpty) {
      firstParentId = parents.first['id'] as String?;
    }

    for (final buffalo in unitBuffaloes) {
      final gen = buffalo['generation'] as int? ?? 0;
      bool hasCPF = false;

      if (gen == 0) {
        // First parent (per the parents list) is considered to have CPF (approx React behavior)
        if (firstParentId != null && buffalo['id'] == firstParentId) {
          hasCPF = true;
        }
      } else if (gen == 1 || gen == 2) {
        final ageInMonths = _calculateAgeInMonths(buffalo, _selectedYear, 11);
        hasCPF = ageInMonths >= 36;
      }

      if (hasCPF) milkProducingBuffaloesWithCPF++;

      buffaloCPFDetails.add({
        'id': buffalo['id'],
        'hasCPF': hasCPF,
      });
    }

    final annualCPFCost = milkProducingBuffaloesWithCPF * 13000;
    final monthlyCPFCost = (annualCPFCost / 12).round();

    return {
      'milkProducingBuffaloes': unitBuffaloes.length,
      'milkProducingBuffaloesWithCPF': milkProducingBuffaloesWithCPF,
      'buffaloCPFDetails': buffaloCPFDetails,
      'annualCPFCost': annualCPFCost,
      'monthlyCPFCost': monthlyCPFCost,
    };
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
  String numberToWords(int num) {
    if (num == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    final crore = (num / 10000000).floor();
    final lakh = ((num % 10000000) / 100000).floor();
    final thousand = ((num % 100000) / 1000).floor();
    final hundred = ((num % 1000) / 100).floor();
    final remainder = num % 100;

    String words = '';

    if (crore > 0) {
      words += '${numberToWords(crore)} Crore ';
    }

    if (lakh > 0) {
      words += '${numberToWords(lakh)} Lakh ';
    }

    if (thousand > 0) {
      words += '${numberToWords(thousand)} Thousand ';
    }

    if (hundred > 0) {
      words += '${ones[hundred]} Hundred ';
    }

    if (remainder > 0) {
      if (words.isNotEmpty) words += 'and ';

      if (remainder < 10) {
        words += ones[remainder];
      } else if (remainder < 20) {
        words += teens[remainder - 10];
      } else {
        words += tens[(remainder / 10).floor()];
        if (remainder % 10 > 0) {
          words += ' ${ones[remainder % 10]}';
        }
      }
    }

    return words.trim();
  }

  String formatPriceInWords(double amount) {
    final integerPart = amount.toInt();
    final words = numberToWords(integerPart);
    return '$words Rupees Only';
  }

  // Calculate initial investment
  Map<String, dynamic> calculateInitialInvestment() {
    final units = widget.treeData['units'] ?? 0;
    final buffaloPrice = 175000;
    final cpfPerUnit = 13000;

    final buffaloCost = units * 2 * buffaloPrice;
    final cpfCost = units * cpfPerUnit;
    final totalInvestment = buffaloCost + cpfCost;

    return {
      'buffaloCost': buffaloCost,
      'cpfCost': cpfCost,
      'totalInvestment': totalInvestment,
    };
  }

  // Get buffalo market value based on age in months (match React SharedCalculations)
  int getBuffaloValueByAge(int ageInMonths) {
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
  Map<int, int> calculateYearlyCPFCost() {
    final Map<int, int> cpfCostByYear = {};
    final int startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final int years = widget.treeData['years'] ?? 10;

    for (int year = startYear; year <= startYear + years; year++) {
      int totalCPFCost = 0;

      final units = widget.treeData['units'] ?? 1;
      for (int unit = 1; unit <= units; unit++) {
        int unitCPFCost = 0;

        // collect buffaloes in this unit
        final unitBuffaloes = _buffaloDetails.values.where((b) => (b['unit'] ?? 1) == unit).toList();

        // determine first parent id for this unit (approx React M1 behavior)
        String? firstParentId;
        final parents = unitBuffaloes.where((b) => (b['generation'] as int?) == 0).toList();
        if (parents.isNotEmpty) {
          firstParentId = parents.first['id'] as String?;
        }

        for (final buffalo in unitBuffaloes) {
          final id = buffalo['id'] as String?;
          final gen = buffalo['generation'] as int? ?? 0;

          if (id != null && id == firstParentId) {
            unitCPFCost += 13000;
          } else if (gen == 1 || gen == 2) {
            final ageInMonths = _calculateAgeInMonths(buffalo, year, 11);
            if (ageInMonths >= 36) unitCPFCost += 13000;
          }
        }

        totalCPFCost += unitCPFCost;
      }

      cpfCostByYear[year] = totalCPFCost;
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

    for (int year = startYear; year <= startYear + years; year++) {
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
    // Without CPF: accumulate revenue and check revenue + asset value
    bool foundWithout = false;
    for (int year = startYear; year <= startYear + years && !foundWithout; year++) {
      for (int month = 0; month < 12; month++) {
        final monthlyRev = investorMonthlyRevenue[year.toString()]?[month.toString()] ?? 0;
        cumulativeWithoutCPF += monthlyRev;

        // asset value at this month
        double currentAssetValue = 0;
        _buffaloDetails.forEach((k, buffalo) {
          final birthYear = (buffalo['birthYear'] as int?) ?? startYear;
          final birthMonth = (buffalo['birthMonth'] as int?) ?? 0;
          if (birthYear < year || (birthYear == year && birthMonth <= month)) {
            final age = _calculateAgeInMonths(buffalo, year, month);
            currentAssetValue += getBuffaloValueByAge(age);
          }
        });

        final totalValueWithoutCPF = cumulativeWithoutCPF + currentAssetValue;
        if (totalValueWithoutCPF >= initialInvestment['totalInvestment'] && !foundWithout) {
          breakEvenYearWithoutCPF = year;
          breakEvenMonthWithoutCPF = month;
          foundWithout = true;

          final startDate = DateTime(startYear, startMonth + 1, startDay);
          final monthsSinceStart = (year - startYear) * 12 + (month - startMonth);
          final computed = DateTime(startDate.year, (startDate.month + monthsSinceStart + 1).toInt(), 0);
          exactBreakEvenDateWithoutCPF = computed;
        }
      }
    }

    // With CPF: subtract monthly CPF (annual/12) while accumulating
    double tempCumulativeWithCPF = 0;
    bool foundWith = false;
    for (int year = startYear; year <= startYear + years && !foundWith; year++) {
      final annualCPFCost = yearlyCPFCost[year] ?? 0;
      final monthlyCPF = annualCPFCost / 12.0;

      for (int month = 0; month < 12; month++) {
        final monthlyRev = investorMonthlyRevenue[year.toString()]?[month.toString()] ?? 0;
        tempCumulativeWithCPF += monthlyRev;
        tempCumulativeWithCPF -= monthlyCPF;

        double currentAssetValue = 0;
        _buffaloDetails.forEach((k, buffalo) {
          final birthYear = (buffalo['birthYear'] as int?) ?? startYear;
          final birthMonth = (buffalo['birthMonth'] as int?) ?? 0;
          if (birthYear < year || (birthYear == year && birthMonth <= month)) {
            final age = _calculateAgeInMonths(buffalo, year, month);
            currentAssetValue += getBuffaloValueByAge(age);
          }
        });

        final totalValueWithCPF = tempCumulativeWithCPF + currentAssetValue;
        if (totalValueWithCPF >= initialInvestment['totalInvestment'] && !foundWith) {
          breakEvenYearWithCPF = year;
          breakEvenMonthWithCPF = month;
          foundWith = true;

          final startDate = DateTime(startYear, startMonth + 1, startDay);
          final monthsSinceStart = (year - startYear) * 12 + (month - startMonth);
          final computed = DateTime(startDate.year, (startDate.month + monthsSinceStart + 1).toInt(), 0);
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
      final revenueWithoutCPF = (yearData['revenue'] as num).toDouble();
      final revenueWithCPF = revenueWithoutCPF - cpfCost;

      // Also carry herd stats so AnnualHerdRevenueWidget can display
      // totalBuffaloes per year (and keep mature/producing if needed).
      final totalBuffaloes =
          (yearData['totalBuffaloes'] as int?) ?? 0;
      final producingBuffaloes =
          (yearData['producingBuffaloes'] as int?) ?? 0;

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
          final age = _calculateAgeInMonths(buffalo, year, 11);
          yearEndAssetValue += getBuffaloValueByAge(age);
        }
      });

      final totalValueWith = cumulativeWith + yearEndAssetValue;
      final recoveryPercentageWith = (totalValueWith / (initialInvestment['totalInvestment'] as num)) * 100;
      final revenueOnlyPercentageWith = (cumulativeWith / (initialInvestment['totalInvestment'] as num)) * 100;

      String statusWith = 'in Progress';
      String revenueOnlyStatusWith = 'in Progress';
      if (recoveryPercentageWith >= 100) statusWith = '✔ Break-Even';
      else if (recoveryPercentageWith >= 75) statusWith = '75% Recovered';
      else if (recoveryPercentageWith >= 50) statusWith = '50% Recovered';

      if (revenueOnlyPercentageWith >= 100) revenueOnlyStatusWith = '✔ Break-Even';
      else if (revenueOnlyPercentageWith >= 75) revenueOnlyStatusWith = '75% Recovered';
      else if (revenueOnlyPercentageWith >= 50) revenueOnlyStatusWith = '50% Recovered';

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
    for (int year = startYear; year <= startYear + years; year++) {
      investorMonthlyRevenue[year.toString()] = {};
      for (int month = 0; month < 12; month++) {
        investorMonthlyRevenue[year.toString()]![month.toString()] = 0.0;
      }
    }

    // Calculate revenue based on buffalo details
    _buffaloDetails.forEach((buffaloId, buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;

      for (int year = startYear; year <= startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
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
    final buffaloPrice = 175000;

    return yearlyData.map((yearData) {
      final totalBuffaloes = yearData['totalBuffaloes'] as int;
      return {
        'year': yearData['year'],
        'totalBuffaloes': totalBuffaloes,
        'assetValue': totalBuffaloes * buffaloPrice,
        'totalAssetValue': totalBuffaloes * buffaloPrice,
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
  Widget buildRevenueGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> chartData = yearlyData.map((data) {
      return ChartData(
        data['year'].toString(),
        (data['revenue'] as num).toDouble(),
      );
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        tooltipBehavior: _tooltipBehavior,
        title: ChartTitle(
          text: 'Revenue Trends',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
        ),
        series: <CartesianSeries<ChartData, String>>[
          ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Revenue',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  // Buffalo Growth Graph Widget
  Widget buildBuffaloGrowthGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> chartData = yearlyData.map((data) {
      return ChartData(
        data['year'].toString(),
        (data['totalBuffaloes'] as num).toDouble(),
      );
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        tooltipBehavior: _tooltipBehavior,
        title: ChartTitle(
          text: 'Herd Growth',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Buffaloes',
            color: const Color(0xFF8B5CF6),
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // Buffalo Population Growth Graph (Matching React component)
  Widget _buildBuffaloPopulationGrowthGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;

    if (yearlyData.isEmpty) return Container();

    // Find max buffaloes for percentage calculation
    final maxBuffaloes = yearlyData.fold<double>(
      0,
      (max, data) => math.max(max, (data['totalBuffaloes'] as num).toDouble()),
    );

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 32, color: Colors.purple),
              const SizedBox(width: 12),
              const Text(
                'Buffalo Population Growth',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data rows similar to React component
          Column(
            children: yearlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final total = (data['totalBuffaloes'] as num).toDouble();
              final producing = (data['producingBuffaloes'] as num).toDouble();
              final percentage = (total / maxBuffaloes) * 100;

              // Calculate growth percentage
              double growthPercentage = 0;
              if (index > 0) {
                final prevTotal =
                    (yearlyData[index - 1]['totalBuffaloes'] as num).toDouble();
                growthPercentage = ((total - prevTotal) / prevTotal) * 100;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Year and stats row
                    Row(
                      children: [
                        Container(
                          width: 100,
                          child: Text(
                            data['year'].toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${formatNumber(total.toInt())} Buffaloes',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '(${formatNumber(producing.toInt())} producing)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: growthPercentage > 0
                                      ? Colors.purple[100]
                                      : growthPercentage < 0
                                      ? Colors.red[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  index > 0
                                      ? '${growthPercentage > 0
                                            ? '↗ '
                                            : growthPercentage < 0
                                            ? '↘ '
                                            : ''}${growthPercentage.abs().toStringAsFixed(1)}%'
                                      : 'Start',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: growthPercentage > 0
                                        ? Colors.purple[700]
                                        : growthPercentage < 0
                                        ? Colors.red[700]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Progress bar
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          // Progress
                          AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOut,
                            width:
                                MediaQuery.of(context).size.width *
                                (percentage / 100) *
                                0.7,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.purple,
                                  Colors.indigo,
                                  Colors.purple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${percentage.toStringAsFixed(0)}% of peak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Production Analysis Graph Widget
  // Production Analysis Graph Widget - CORRECTED
  Widget buildProductionAnalysisGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> producingData = yearlyData.map((data) {
      return ChartData(
        data['year'].toString(),
        (data['producingBuffaloes'] as num).toDouble(),
      );
    }).toList();

    final List<ChartData> nonProducingData = yearlyData.map((data) {
      final total = data['totalBuffaloes'] as int;
      final producing = data['producingBuffaloes'] as int;
      return ChartData(data['year'].toString(), (total - producing).toDouble());
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        tooltipBehavior: _tooltipBehavior,
        title: ChartTitle(
          text: 'Production Analysis',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<ChartData, String>>[
          StackedColumnSeries<ChartData, String>(
            dataSource: producingData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Producing',
            color: const Color(0xFF10B981),
          ),
          StackedColumnSeries<ChartData, String>(
            dataSource: nonProducingData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Non-Producing',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

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

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final card = cards[index];

          return Container(
            width: 365, // card width for horizontal layout
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: card['gradient'] == true ? Colors.blue : Colors.white,
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
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card['value'].toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: card['gradient'] == true
                          ? Colors.white
                          : (card['color'] as Color),
                    ),
                  ),
                  // const SizedBox(height: 5),
                  Text(
                    card['label'].toString(),
                    style: TextStyle(
                      fontSize: 12,
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
                      fontSize: 10,
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
        },
      ),
    );
  }

  Widget _buildMonthlyRevenueBreakdown() {
    // Get parent buffaloes for the selected unit (generation 0)
    final parentBuffaloes = _getParentBuffaloes(_selectedUnit);
    
    // Get all offspring of parents (children and grandchildren)
    final allOffspringBuffaloes = <Map<String, dynamic>>[];
    for (final parent in parentBuffaloes) {
      allOffspringBuffaloes.addAll(_getOffspringBuffaloes(parent['originalId']));
    }
    
    // CRITICAL FIX: Filter by age and revenue like React does
    // Only show buffaloes that are:
    // 1. At least 3 years old in the selected year
    // 2. Have revenue in at least one month of the selected year
    final offspringBuffaloes = allOffspringBuffaloes.where((buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      
      // Check if buffalo is at least 3 years old in selected year
      if (_selectedYear < birthYear + 3) {
        return false;
      }
      
      // Check if buffalo has any revenue in the selected year
      bool hasRevenue = false;
      final displayId = buffalo['id'] as String;

      for (int month = 0; month < 12; month++) {
        final revenue = (_monthlyRevenue[_selectedYear.toString()]?[month.toString()]?['buffaloes'] as Map?)?[displayId] ?? 0;
        if (revenue > 0) {
          hasRevenue = true;
          break;
        }
      }

      return hasRevenue;
    }).toList();
    
    // Combine parents and filtered offspring for the table
    final allBuffaloesInUnit = [...parentBuffaloes, ...offspringBuffaloes];
    
    final cpfCost = _calculateCPFCost(allBuffaloesInUnit); // Use all income-producing buffaloes
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.cyan[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 40, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly Revenue - Income Producing Buffaloes Only',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Year and Unit Selection with Download Button
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 4,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                                                                                                                                                                                                                                                                                                                                     
                      Text(
                        'Select Year:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                        ),
                        items: List.generate(years + 1, (i) {
                          final year = startYear + i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                            _initializeBuffaloDetails();
                            _calculateDetailedMonthlyRevenue();
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else if (index == 1) {
                final units = widget.treeData['units'] ?? 1;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Unit:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                        ),
                        items: List.generate(units, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text('Unit ${i + 1}'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                            _initializeBuffaloDetails();
                            _calculateDetailedMonthlyRevenue();
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: ElevatedButton(
                    onPressed: _downloadExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Download Excel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Buffalo Family Tree
          // if (parentBuffaloes.isNotEmpty) ...[
          //   Container(
          //     padding: const EdgeInsets.all(20),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(20),
          //       border: Border.all(color: Colors.purple[200]!),
          //     ),
          //     child: Column(
          //       children: [
          //         Text(
          //           'Income Producing Buffaloes - Unit $_selectedUnit ($_selectedYear)',
          //           style: TextStyle(
          //             fontSize: 22,
          //             fontWeight: FontWeight.bold,
          //             color: Colors.purple[800],
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //         const SizedBox(height: 16),
          //         GridView.builder(
          //           shrinkWrap: true,
          //           physics: const NeverScrollableScrollPhysics(),
          //           gridDelegate:
          //               const SliverGridDelegateWithFixedCrossAxisCount(
          //                 crossAxisCount: 2,
          //                 crossAxisSpacing: 16,
          //                 mainAxisSpacing: 16,
          //                 childAspectRatio: 4,
          //               ),
          //           itemCount: parentBuffaloes.length,
          //           itemBuilder: (context, index) {
          //             if (index >= parentBuffaloes.length)
          //               return const SizedBox.shrink();

          //             final parent = parentBuffaloes[index];
          //             return Container(
          //               padding: const EdgeInsets.all(16),
          //               decoration: BoxDecoration(
          //                 color: Colors.purple[50],
          //                 borderRadius: BorderRadius.circular(16),
          //                 border: Border.all(color: Colors.purple[300]!),
          //               ),
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Row(
          //                     children: [
          //                       Text(
          //                         parent['id'] as String,
          //                         style: TextStyle(
          //                           fontSize: 18,
          //                           fontWeight: FontWeight.bold,
          //                           color: Colors.purple[700],
          //                         ),
          //                       ),
          //                       const SizedBox(width: 8),
          //                       Container(
          //                         padding: const EdgeInsets.symmetric(
          //                           horizontal: 8,
          //                           vertical: 2,
          //                         ),
          //                         decoration: BoxDecoration(
          //                           color: Colors.green[500],
          //                           borderRadius: BorderRadius.circular(12),
          //                         ),
          //                         child: const Text(
          //                           'Parent',
          //                           style: TextStyle(
          //                             fontSize: 12,
          //                             color: Colors.white,
          //                             fontWeight: FontWeight.bold,
          //                           ),
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                   const SizedBox(height: 8),
          //                   Text(
          //                     'Acquisition: ${_monthNames[parent['acquisitionMonth'] as int]}',
          //                     style: TextStyle(
          //                       fontSize: 14,
          //                       color: Colors.purple[600],
          //                     ),
          //                   ),
          //                   const SizedBox(height: 4),
          //                   Text(
          //                     'Active in $_selectedYear',
          //                     style: TextStyle(
          //                       fontSize: 14,
          //                       color: Colors.green[600],
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             );
          //           },
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 24),
          // ],

          // Monthly Revenue Table
          if (allBuffaloesInUnit.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Monthly Revenue Breakdown - $_selectedYear (Unit $_selectedUnit)',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ReusablePlutoGrid(
                    // include selected unit and year in the gridId so the PlutoGrid
                    // gets a new ValueKey when dropdowns change and rebuilds
                    gridId: 'monthly_revenue_breakdown_unit_${_selectedUnit}_year_${_selectedYear}',
                    height: 600,
                    rowHeight: 70,
                    columns: [
                      PlutoColumnBuilder.customColumn(
                        title: 'Month',
                        field: 'month',
                        width: 100,
                        renderer: (ctx) {
                          return Container(
                            decoration: BoxDecoration(color: Colors.grey[50]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ctx.cell.value.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ...allBuffaloesInUnit.asMap().entries.map((entry) {
                        final buffalo = entry.value;
                        final generationLabel = buffalo['generation'] == 0
                            ? ' (P)'
                            : buffalo['generation'] == 1
                                ? ' (C)'
                                : ' (GC)'; // Parent, Child, Grandchild
                        return PlutoColumnBuilder.customColumn(
                          title: '${buffalo['id']}$generationLabel',
                          field: 'buffalo_${buffalo['id']}',
                          width: 120,
                          renderer: (ctx) {
                            final monthIndex = ctx.rowIdx;
                            final revenue =
                                (_monthlyRevenue[_selectedYear
                                        .toString()]?[monthIndex
                                        .toString()]?['buffaloes']
                                    as Map?)?[buffalo['id']] ??
                                0;

                            Color textColor = Colors.grey;
                            String phase = 'Rest';
                            Color backgroundColor = Colors.grey[50]!;

                            if (revenue == 9000) {
                              textColor = Colors.green;
                              phase = 'High';
                              backgroundColor = Colors.green[50]!;
                            } else if (revenue == 6000) {
                              textColor = Colors.blue;
                              phase = 'Medium';
                              backgroundColor = Colors.blue[50]!;
                            }

                            return Container(
                              decoration: BoxDecoration(color: backgroundColor),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formatCurrency(revenue.toDouble()),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    phase,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                      PlutoColumnBuilder.customColumn(
                        title: 'Unit Total',
                        field: 'unit_total',
                        width: 120,
                        renderer: (ctx) {
                          final monthIndex = ctx.rowIdx;
                          double unitTotal = 0;

                          for (final buffalo in allBuffaloesInUnit) {
                            final revenue =
                                (_monthlyRevenue[_selectedYear
                                        .toString()]?[monthIndex
                                        .toString()]?['buffaloes']
                                    as Map?)?[buffalo['id']] ??
                                0;
                            unitTotal += revenue.toDouble();
                          }

                          return Container(
                            decoration: BoxDecoration(color: Colors.blue[50]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatCurrency(unitTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      PlutoColumnBuilder.customColumn(
                        title: 'CPF Cost',
                        field: 'cpf_cost',
                        width: 120,
                        renderer: (ctx) {
                          return Container(
                            decoration: BoxDecoration(color: Colors.orange[50]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatCurrency(
                                    cpfCost['monthlyCPFCost'].toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      PlutoColumnBuilder.customColumn(
                        title: 'Net Revenue',
                        field: 'net_revenue',
                        width: 120,
                        renderer: (ctx) {
                          final monthIndex = ctx.rowIdx;
                          double unitTotal = 0;

                          for (final buffalo in allBuffaloesInUnit) {
                            final revenue =
                                (_monthlyRevenue[_selectedYear
                                        .toString()]?[monthIndex
                                        .toString()]?['buffaloes']
                                    as Map?)?[buffalo['id']] ??
                                0;
                            unitTotal += revenue.toDouble();
                          }

                          final netRevenue =
                              unitTotal - cpfCost['monthlyCPFCost'];

                          return Container(
                            decoration: BoxDecoration(color: Colors.green[50]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatCurrency(netRevenue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: netRevenue >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    rows: _monthNames.asMap().entries.map((monthEntry) {
                      final monthIndex = monthEntry.key;
                      final monthName = monthEntry.value;

                      double unitTotal = 0;
                      final Map<String, dynamic> rowData = {'month': monthName};

                      // Calculate unit total for this month
                      for (final buffalo in allBuffaloesInUnit) {
                        final revenue =
                            (_monthlyRevenue[_selectedYear
                                    .toString()]?[monthIndex
                                    .toString()]?['buffaloes']
                                as Map?)?[buffalo['id']] ??
                            0;
                        rowData['buffalo_${buffalo['id']}'] = revenue;
                        unitTotal += revenue.toDouble();
                      }

                      rowData['unit_total'] = unitTotal;
                      rowData['cpf_cost'] = cpfCost['monthlyCPFCost'];
                      rowData['net_revenue'] =
                          unitTotal - cpfCost['monthlyCPFCost'];

                      return PlutoRow(
                        cells: rowData.map((key, value) {
                          return MapEntry(key, PlutoCell(value: value));
                        }),
                      );
                    }).toList(),
                  ),

                  // Yearly Total Row
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[900]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Yearly Total',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ...allBuffaloesInUnit.map((buffalo) {
                          double yearlyTotal = 0;
                          for (
                            int monthIndex = 0;
                            monthIndex < _monthNames.length;
                            monthIndex++
                          ) {
                            final revenue =
                                (_monthlyRevenue[_selectedYear
                                        .toString()]?[monthIndex
                                        .toString()]?['buffaloes']
                                    as Map?)?[buffalo['id']] ??
                                0;
                            yearlyTotal += revenue.toDouble();
                          }
                          return Expanded(
                            child: Text(
                              formatCurrency(yearlyTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                allBuffaloesInUnit.fold<double>(0, (sum, buffalo) {
                                  double yearlyTotal = 0;
                                  for (
                                    int monthIndex = 0;
                                    monthIndex < _monthNames.length;
                                    monthIndex++
                                  ) {
                                    final revenue =
                                        (_monthlyRevenue[_selectedYear
                                                .toString()]?[monthIndex
                                                .toString()]?['buffaloes']
                                            as Map?)?[buffalo['id']] ??
                                        0;
                                    yearlyTotal += revenue.toDouble();
                                  }
                                  return sum + yearlyTotal;
                                }),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                cpfCost['annualCPFCost'].toDouble(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                allBuffaloesInUnit.fold<double>(0, (sum, buffalo) {
                                      double yearlyTotal = 0;
                                      for (
                                        int monthIndex = 0;
                                        monthIndex < _monthNames.length;
                                        monthIndex++
                                      ) {
                                        final revenue =
                                            (_monthlyRevenue[_selectedYear
                                                    .toString()]?[monthIndex
                                                    .toString()]?['buffaloes']
                                                as Map?)?[buffalo['id']] ??
                                            0;
                                        yearlyTotal += revenue.toDouble();
                                      }
                                      return sum + yearlyTotal;
                                    }) -
                                    cpfCost['annualCPFCost'],
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '🐄 No Income Producing Buffaloes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'There are no income-producing buffaloes in Unit $_selectedUnit for the year $_selectedYear.',
                    style: TextStyle(fontSize: 16, color: Colors.yellow[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buffaloes start generating income at age 3 (born in ${_selectedYear - 3} or earlier).',
                    style: TextStyle(fontSize: 14, color: Colors.yellow[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Revenue Break-Even Analysis Widget
  Widget _buildRevenueBreakEvenAnalysis() {
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final initialInvestment = calculateInitialInvestment();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[50]!, Colors.indigo[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.purple[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 40, color: Colors.purple),
              const SizedBox(width: 12),
              Text(
                'Revenue Break-Even Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Initial Investment Breakdown
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.5,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> investments = [
                {
                  'value': formatCurrency(initialInvestment['buffaloCost']),
                  'label': 'Buffalo Cost',
                  'description':
                      '${widget.treeData['units']} units × 2 buffaloes × ₹1.75 Lakhs',
                  'color': Colors.blue,
                },
                {
                  'value': formatCurrency(initialInvestment['cpfCost']),
                  'label': 'CPF Cost',
                  'description': '${widget.treeData['units']} units × ₹13,000',
                  'color': Colors.green,
                },
                {
                  'value': formatCurrency(initialInvestment['totalInvestment']),
                  'label': 'Total Investment',
                  'description': 'Initial Capital Outlay',
                  'color': Colors.purple,
                  'gradient': true,
                },
              ];

              final investment = investments[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: investment['gradient'] == true
                      ? Colors.purple
                      : Colors.white,
                  border: Border.all(
                    color: investment['gradient'] == true
                        ? Colors.transparent
                        : (investment['color'] as Color).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        investment['value'].toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: investment['gradient'] == true
                              ? Colors.white
                              : (investment['color'] as Color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        investment['label'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: investment['gradient'] == true
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        investment['description'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: investment['gradient'] == true
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Break-Even Result
          // Break-Even Result - Enhanced
          if (breakEvenAnalysis['breakEvenYear'] != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[500]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 Break-Even Achieved!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    breakEvenAnalysis['breakEvenMonth'] != null
                        ? 'Year ${breakEvenAnalysis['breakEvenYear']} (Month ${breakEvenAnalysis['breakEvenMonth']! + 1})'
                        : 'Year ${breakEvenAnalysis['breakEvenYear']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Investment Recovery Time: ${(breakEvenAnalysis['breakEvenYear']! - (widget.treeData['startYear'] ?? DateTime.now().year))} Years ${breakEvenAnalysis['breakEvenMonth'] != null ? '${breakEvenAnalysis['breakEvenMonth']! + 1} Months' : ''}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cumulative Revenue: ${formatCurrency(breakEvenAnalysis['finalCumulativeRevenue'])}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            )
          else if (breakEvenAnalysis['finalCumulativeRevenue'] > 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[500]!, Colors.amber[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '📈 Break-Even Not Reached',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cumulative Revenue: ${formatCurrency(breakEvenAnalysis['finalCumulativeRevenue'])}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((breakEvenAnalysis['finalCumulativeRevenue'] / initialInvestment['totalInvestment']) * 100).toStringAsFixed(1)}% of Investment Recovered',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Break-Even Timeline Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Break-Even Timeline',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Break-Even Timeline Table - PlutoGrid
                ReusablePlutoGrid(
                  gridId: 'break_even_timeline',
                  height: 750,
                  rowHeight: 90,
                  columns: [
                    PlutoColumnBuilder.customColumn(
                      title: 'Year',
                      field: 'year',
                      width: 220,
                      renderer: (ctx) {
                        final idx = ctx.rowIdx + 1;
                        final year = ctx.cell.value?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[500]!,
                                      Colors.purple[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Center(
                                  child: Text(
                                    '$idx',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    year,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Year $idx',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Total Buffaloes',
                      field: 'totalBuffaloes',
                      width: 140,
                      renderer: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Mature Buffaloes',
                      field: 'matureBuffaloes',
                      width: 140,
                      renderer: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Annual Revenue',
                      field: 'annualRevenue',
                      width: 160,
                      renderer: (ctx) {
                        final val = ctx.cell.value is num
                            ? (ctx.cell.value as num).toDouble()
                            : double.tryParse(
                                    ctx.cell.value.toString().replaceAll(
                                      RegExp('[^0-9.-]'),
                                      '',
                                    ),
                                  ) ??
                                  0.0;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            formatCurrency(val),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Cumulative Revenue',
                      field: 'cumulativeRevenue',
                      width: 180,
                      renderer: (ctx) {
                        final val = ctx.cell.value is num
                            ? (ctx.cell.value as num).toDouble()
                            : double.tryParse(
                                    ctx.cell.value.toString().replaceAll(
                                      RegExp('[^0-9.-]'),
                                      '',
                                    ),
                                  ) ??
                                  0.0;
                        final progress =
                            (val /
                                (initialInvestment['totalInvestment'] == 0
                                    ? 1
                                    : initialInvestment['totalInvestment'])) *
                            100;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                formatCurrency(val),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${progress.toStringAsFixed(1)}% recovered',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Status',
                      field: 'status',
                      width: 160,
                      renderer: (ctx) {
                        final cum =
                            (ctx.row.cells['cumulativeRevenue']?.value is num)
                            ? (ctx.row.cells['cumulativeRevenue']!.value as num)
                                  .toDouble()
                            : double.tryParse(
                                    ctx.row.cells['cumulativeRevenue']?.value
                                            .toString()
                                            .replaceAll(
                                              RegExp('[^0-9.-]'),
                                              '',
                                            ) ??
                                        '0',
                                  ) ??
                                  0.0;
                        final isBreak =
                            (ctx.row.cells['isBreakEven']?.value == true);
                        final progress =
                            (cum /
                                (initialInvestment['totalInvestment'] == 0
                                    ? 1
                                    : initialInvestment['totalInvestment'])) *
                            100;

                        String statusText = 'In Progress';
                        Color bg = Colors.grey[100]!;
                        Color txt = Colors.grey[600]!;

                        if (isBreak) {
                          statusText = '✓ Break-Even';
                          bg = Colors.green[100]!;
                          txt = Colors.green[800]!;
                        } else if (progress >= 75) {
                          statusText = '75% Recovered';
                          bg = Colors.green[50]!;
                          txt = Colors.green[700]!;
                        } else if (progress >= 50) {
                          statusText = '50% Recovered';
                          bg = Colors.yellow[100]!;
                          txt = Colors.yellow[800]!;
                        } else if (progress >= 25) {
                          statusText = '25% Recovered';
                          bg = Colors.blue[50]!;
                          txt = Colors.blue[700]!;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: txt.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: txt,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  rows: (breakEvenAnalysis['breakEvenData'] as List<dynamic>)
                      .asMap()
                      .entries
                      .map((entry) {
                        final data = entry.value as Map<String, dynamic>;
                        final cum = (data['cumulativeRevenue'] as num)
                            .toDouble();
                        final ann = (data['annualRevenue'] as num).toDouble();
                        return PlutoRow(
                          cells: {
                            'year': PlutoCell(value: data['year'].toString()),
                            'totalBuffaloes': PlutoCell(
                              value: formatNumber(data['totalBuffaloes']),
                            ),
                            'matureBuffaloes': PlutoCell(
                              value: formatNumber(data['matureBuffaloes']),
                            ),
                            'annualRevenue': PlutoCell(value: ann),
                            'cumulativeRevenue': PlutoCell(value: cum),
                            'isBreakEven': PlutoCell(
                              value: data['isBreakEven'] == true,
                            ),
                            'status': PlutoCell(value: ''),
                          },
                        );
                      })
                      .toList(),
                ),
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: DataTable(
                //     columns: const [
                //       DataColumn(label: Text('Year')),
                //       DataColumn(label: Text('Annual Revenue')),
                //       DataColumn(label: Text('Cumulative Revenue')),
                //       DataColumn(label: Text('Status')),
                //     ],
                //     rows: (breakEvenAnalysis['breakEvenData'] as List<dynamic>).map((
                //       data,
                //     ) {
                //       // print(data);
                //       return DataRow(
                //         cells: [
                //           DataCell(
                //             Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   data['year'].toString(),
                //                   style: const TextStyle(
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //                 ),
                //                 Text(
                //                   'Year ${(breakEvenAnalysis['breakEvenData'] as List<dynamic>).indexOf(data) + 1}',
                //                   style: TextStyle(color: Colors.grey[600]),
                //                 ),
                //               ],
                //             ),
                //           ),
                //           DataCell(
                //             Text(
                //               formatCurrency(data['annualRevenue']),
                //               style: const TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.green,
                //               ),
                //             ),
                //           ),
                //           DataCell(
                //             Text(
                //               formatCurrency(data['cumulativeRevenue']),
                //               style: const TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.blue,
                //               ),
                //             ),
                //           ),
                //           DataCell(
                //             Container(
                //               padding: const EdgeInsets.symmetric(
                //                 horizontal: 12,
                //                 vertical: 6,
                //               ),
                //               decoration: BoxDecoration(
                //                 color: data['isBreakEven'] == true
                //                     ? Colors.green[100]
                //                     : data['cumulativeRevenue'] >=
                //                           initialInvestment['totalInvestment'] *
                //                               0.5
                //                     ? Colors.yellow[100]
                //                     : Colors.grey[100],
                //                 borderRadius: BorderRadius.circular(20),
                //               ),
                //               child: Text(
                //                 data['isBreakEven'] == true
                //                     ? '✓ Break-Even'
                //                     : data['cumulativeRevenue'] >=
                //                           initialInvestment['totalInvestment'] *
                //                               0.5
                //                     ? '50% Recovered'
                //                     : 'In Progress',
                //                 style: TextStyle(
                //                   color: data['isBreakEven'] == true
                //                       ? Colors.green[800]
                //                       : data['cumulativeRevenue'] >=
                //                             initialInvestment['totalInvestment'] *
                //                                 0.5
                //                       ? Colors.yellow[800]
                //                       : Colors.grey[600],
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 12,
                //                 ),
                //               ),
                //             ),
                //           ),
                //         ],
                //       );
                //     }).toList(),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Asset Market Value Widget
  Widget _buildAssetMarketValue() {
    final assetMarketValue = calculateAssetMarketValue();
    final currentValue = assetMarketValue.isNotEmpty
        ? assetMarketValue[0]
        : {'totalAssetValue': 0};
    final finalValue = assetMarketValue.isNotEmpty
        ? assetMarketValue.last
        : {'totalAssetValue': 0};
    final growthMultiple =
        finalValue['totalAssetValue'] /
        (currentValue['totalAssetValue'] == 0
            ? 1
            : currentValue['totalAssetValue']);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange[50]!, Colors.red[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, size: 40, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Asset Market Value Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Current vs Final Asset Value
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 6,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> assets = [
                {
                  'value': formatCurrency(
                    (currentValue['totalAssetValue'] ?? 0).toDouble(),
                  ),
                  'label': 'Initial Asset Value',
                  'description':
                      '${currentValue['totalBuffaloes'] ?? 0} buffaloes × ₹1.75 Lakhs',
                  'color': Colors.blue,
                },
                {
                  'value': formatCurrency(
                    (finalValue['totalAssetValue'] ?? 0).toDouble(),
                  ),
                  'label': 'Final Asset Value',
                  'description':
                      '${finalValue['totalBuffaloes'] ?? 0} buffaloes × ₹1.75 Lakhs + CPF',
                  'color': Colors.orange,
                  'gradient': true,
                },
              ];

              final asset = assets[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: asset['gradient'] == true
                      ? Colors.orange
                      : Colors.white,
                  border: Border.all(
                    color: asset['gradient'] == true
                        ? Colors.transparent
                        : (asset['color'] as Color).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        asset['value'].toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: asset['gradient'] == true
                              ? Colors.white
                              : (asset['color'] as Color),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        asset['label'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: asset['gradient'] == true
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset['description'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: asset['gradient'] == true
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Asset Growth Multiple
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Asset Growth: ${growthMultiple.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'From ${formatCurrency((currentValue['totalAssetValue'] ?? 0).toDouble())} to ${formatCurrency((finalValue['totalAssetValue'] ?? 0).toDouble())}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Yearly Asset Value Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yearly Asset Market Value',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ReusablePlutoGrid(
                  gridId: 'asset_market_value',
                  height: 750,
                  rowHeight: 70,
                  columns: [
                    PlutoColumnBuilder.customColumn(
                      title: 'Year',
                      field: 'year',
                      width: 120,
                      renderer: (ctx) {
                        final val = ctx.cell.value?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                val,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox.shrink(),
                            ],
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Total Buffaloes',
                      field: 'totalBuffaloes',
                      width: 140,
                      renderer: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Buffalo Value',
                      field: 'assetValue',
                      width: 140,
                      renderer: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    PlutoColumnBuilder.customColumn(
                      title: 'Total Asset Value',
                      field: 'totalAssetValue',
                      width: 160,
                      renderer: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  rows: assetMarketValue.map((data) {
                    return PlutoRow(
                      cells: {
                        'year': PlutoCell(value: data['year'].toString()),
                        'totalBuffaloes': PlutoCell(
                          value: formatNumber(data['totalBuffaloes']),
                        ),
                        'assetValue': PlutoCell(
                          value: formatCurrency(data['assetValue'].toDouble()),
                        ),
                        'totalAssetValue': PlutoCell(
                          value: formatCurrency(
                            data['totalAssetValue'].toDouble(),
                          ),
                        ),
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Stats Card Widget
  Widget _buildQuickStatsCard() {
    final initialInvestment = calculateInitialInvestment();
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final assetMarketValue = calculateAssetMarketValue();
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[500]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Investment Summary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatItem(
            'Total Investment:',
            formatCurrency(initialInvestment['totalInvestment']),
          ),
          _buildStatItem('Total Revenue:', formatCurrency(totalRevenue)),
          _buildStatItem(
            'Final Asset Value:',
            formatCurrency(
              assetMarketValue.isNotEmpty
                  ? assetMarketValue.last['totalAssetValue']
                  : 0,
            ),
          ),
          _buildStatItem(
            'Break-Even Year:',
            breakEvenAnalysis['breakEvenYear']?.toString() ?? 'Not Reached',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Production Schedule Widget
  Widget _buildProductionSchedule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 40, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'Staggered Revenue Distribution Schedule',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> phases = [
                {
                  'title': 'High Revenue Phase',
                  'value': '₹9,000',
                  'subtitle': 'per month',
                  'duration': '5 months duration',
                  'colors': [Colors.green[500]!, Colors.green[600]!],
                },
                {
                  'title': 'Medium Revenue Phase',
                  'value': '₹6,000',
                  'subtitle': 'per month',
                  'duration': '3 months duration',
                  'colors': [Colors.blue[500]!, Colors.blue[600]!],
                },
                {
                  'title': 'Rest Period',
                  'value': '₹0',
                  'subtitle': 'per month',
                  'duration': '4 months duration',
                  'colors': [Colors.grey[500]!, Colors.grey[600]!],
                },
              ];

              final phase = phases[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: phase['colors'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      phase['title'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      phase['value'].toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phase['subtitle'].toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      phase['duration'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.yellow[200]!),
            ),
            child: Column(
              children: [
                Text(
                  '🎯 Staggered 6-Month Cycles | 📈 Year 1 Revenue: ₹99,000 per Unit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Each buffalo follows independent 12-month cycle: 2m rest + 5m high + 3m medium + 2m rest',
                  style: TextStyle(fontSize: 18, color: Colors.yellow[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Revenue Table Widget
  Widget _buildRevenueTable() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final totalMatureBuffaloYears =
        widget.revenueData['totalMatureBuffaloYears'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[600]!,
                  Colors.purple[600]!,
                  Colors.indigo[600]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // const SizedBox(height: 40),
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Annual Herd Revenue Breakdown',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Detailed year-by-year financial analysis based on actual herd growth with staggered cycles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          Container(
            color: Colors.white,
            child: ReusablePlutoGrid(
              gridId: 'annual_herd_revenue',
              height: 950,
              rowHeight: 90,
              columns: [
                PlutoColumnBuilder.customColumn(
                  title: 'Year',
                  field: 'year',
                  width: 220,
                  renderer: (rendererContext) {
                    final idx = rendererContext.rowIdx + 1;
                    final year = rendererContext.cell.value.toString();
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[500]!,
                                  Colors.purple[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                year,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Year $idx',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                PlutoColumnBuilder.customColumn(
                  title: 'Total Buffaloes',
                  field: 'totalBuffaloes',
                  width: 140,
                  renderer: (ctx) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            'total buffaloes',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                PlutoColumnBuilder.customColumn(
                  title: 'Mature Buffaloes',
                  field: 'producingBuffaloes',
                  width: 140,
                  renderer: (ctx) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'mature buffaloes',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                PlutoColumnBuilder.customColumn(
                  title: 'Annual Revenue',
                  field: 'revenue',
                  width: 160,
                  renderer: (ctx) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          // optional growth text omitted here
                        ],
                      ),
                    );
                  },
                ),
                PlutoColumnBuilder.customColumn(
                  title: 'Cumulative Revenue',
                  field: 'cumulativeRevenue',
                  width: 180,
                  renderer: (ctx) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.cell.value.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            '${((double.tryParse(ctx.cell.value.toString().replaceAll(RegExp('[^0-9.]'), '')) ?? 0) / (totalRevenue == 0 ? 1 : totalRevenue) * 100).toStringAsFixed(1)}% of total',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              rows: yearlyData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final cumulativeRevenue = yearlyData
                    .sublist(0, index + 1)
                    .fold(
                      0.0,
                      (sum, item) => sum + (item['revenue'] as num).toDouble(),
                    );
                return PlutoRow(
                  cells: {
                    'year': PlutoCell(value: data['year'].toString()),
                    'totalBuffaloes': PlutoCell(
                      value: formatNumber(data['totalBuffaloes']),
                    ),
                    'producingBuffaloes': PlutoCell(
                      value: formatNumber(data['producingBuffaloes']),
                    ),
                    'revenue': PlutoCell(
                      value: formatCurrency(
                        (data['revenue'] as num).toDouble(),
                      ),
                    ),
                    'cumulativeRevenue': PlutoCell(
                      value: formatCurrency(cumulativeRevenue),
                    ),
                  },
                );
              }).toList(),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[900]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.treeData['years']} Years',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatNumber(
                        yearlyData.isNotEmpty
                            ? yearlyData.last['totalBuffaloes']
                            : 0,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'final herd size',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatNumber(totalMatureBuffaloYears),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'mature buffalo years',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatCurrency(totalRevenue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'total revenue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatCurrency(totalRevenue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'final cumulative',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Additional Information Widget
  Widget _buildAdditionalInformation() {
    final initialInvestment = calculateInitialInvestment();
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final assetMarketValue = calculateAssetMarketValue();
    final herdStats = calculateHerdStats();
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.yellow[50]!, Colors.orange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.yellow[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          size: 40,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Investment Highlights',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...[
                      {
                        'title': 'Initial Investment',
                        'description':
                            '${formatCurrency(initialInvestment['totalInvestment'])} (Buffaloes: ${formatCurrency(initialInvestment['buffaloCost'])} + CPF: ${formatCurrency(initialInvestment['cpfCost'])})',
                      },
                      {
                        'title': 'Break-Even Point',
                        'description':
                            breakEvenAnalysis['breakEvenYear'] != null
                            ? 'Year ${breakEvenAnalysis['breakEvenYear']}'
                            : 'Not reached within simulation period',
                      },
                      {
                        'title': 'Asset Growth',
                        'description':
                            '${((assetMarketValue.isNotEmpty ? assetMarketValue.last['totalAssetValue'] : 0) / (assetMarketValue.isNotEmpty ? assetMarketValue[0]['totalAssetValue'] : 1)).toStringAsFixed(1)}x growth in ${widget.treeData['years']} years',
                      },
                      {
                        'title': 'Total Returns',
                        'description':
                            'Revenue: ${formatCurrency(totalRevenue)} + Final Assets: ${formatCurrency(assetMarketValue.isNotEmpty ? assetMarketValue.last['totalAssetValue'] : 0)}',
                      },
                      {
                        'title': 'Herd Growth',
                        'description':
                            '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x herd growth (${herdStats['startingBuffaloes']} → ${widget.treeData['totalBuffaloes']} buffaloes)',
                      },
                    ].asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.yellow[100]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.yellow[500],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['title'].toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value['description'].toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[50]!, Colors.cyan[50]!],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.blue[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Financial Performance',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3.5,
                          ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> stats = [
                          {
                            'value': formatCurrency(
                              totalRevenue / (widget.treeData['years'] ?? 1),
                            ),
                            'label': 'Average Annual Revenue',
                            'color': Colors.blue,
                          },
                          {
                            'value': formatCurrency(
                              herdStats['revenuePerBuffalo'],
                            ),
                            'label': 'Revenue per Buffalo',
                            'color': Colors.green,
                          },
                          {
                            'value':
                                '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x',
                            'label': 'Herd Growth Multiple',
                            'color': Colors.purple,
                          },
                          {
                            'value': formatCurrency(
                              (totalRevenue +
                                      (assetMarketValue.isNotEmpty
                                          ? assetMarketValue
                                                .last['totalAssetValue']
                                          : 0)) /
                                  initialInvestment['totalInvestment'],
                            ),
                            'label': 'ROI Multiple',
                            'color': Colors.orange,
                          },
                        ];

                        final stat = stats[index];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (stat['color'] as Color).withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stat['value'].toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: stat['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stat['label'].toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: (stat['color'] as Color),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Graph Navigation Widget
  Widget _buildGraphNavigation() {
    final List<Map<String, dynamic>> buttons = [
      {'key': 'revenue', 'label': 'Revenue Trends', 'color': Colors.green},
      {'key': 'buffaloes', 'label': 'Herd Growth', 'color': Colors.purple},
      {
        'key': 'production',
        'label': 'Production Analysis',
        'color': Colors.orange,
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: buttons.map((button) {
        final isActive = activeGraph == button['key'];
        return ElevatedButton(
          onPressed: () {
            setState(() {
              activeGraph = button['key'];
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? button['color'] : Colors.grey[100],
            foregroundColor: isActive ? Colors.white : Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isActive
                    ? (button['color'] as Color).withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 4,
              ),
            ),
            elevation: isActive ? 8 : 4,
          ),
          child: Text(button['label']),
        );
      }).toList(),
    );
  }

  // Graphs Section Widget
  Widget _buildGraphsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(bottom: 32, top: 12, right: 32, left: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          // const SizedBox(height: 64),
          Text(
            'Herd Performance Analytics',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Graph Navigation
          _buildGraphNavigation(),
          const SizedBox(height: 20),

          // Graph Display
          if (activeGraph == 'revenue') buildRevenueGraph(),
          if (activeGraph == 'buffaloes') buildBuffaloGrowthGraph(),
          if (activeGraph == 'production') buildProductionAnalysisGraph(),
        ],
      ),
    );
  }

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: sections.map((s) {
          final isSelected = selectedSection == s['key'];
          return InkWell(
            onTap: () =>
                setState(() => selectedSection = isSelected ? 'all' : s['key']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (s['color'] as Color).withOpacity(0.85)
                    : Colors.white,
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : s['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Price in Words Widget
  Widget _buildPriceInWords() {
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final assetMarketValue = calculateAssetMarketValue();
    final finalAssetValue = assetMarketValue.isNotEmpty
        ? assetMarketValue.last['totalAssetValue']
        : 0;
    final totalReturns = totalRevenue + finalAssetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[500]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Investment Returns in Words',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              formatPriceInWords(totalReturns),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '(Revenue: ${formatCurrency(totalRevenue)} + Final Assets: ${formatCurrency(finalAssetValue)})',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCostEstimation) {
      Navigator.of(context).pop();
    }

    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final units = widget.treeData['units'] ?? 0;
    final years = widget.treeData['years'] ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // const SizedBox(height: 20),

                // Header
                Text(
                  'Buffalo Herd Investment Analysis',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Summary Cards
                _buildSummaryCards(),

                const SizedBox(height: 20),

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
                    endYear: ((widget.treeData['startYear'] ??
                            DateTime.now().year) +
                        (widget.treeData['years'] ?? 10)),
                    yearRange:
                        '${widget.treeData['startYear'] ?? DateTime.now().year}-${((widget.treeData['startYear'] ?? DateTime.now().year) + (widget.treeData['years'] ?? 10))}',
                  ),
                  const SizedBox(height: 40),
                ],

                // const SizedBox(height: 20),

                // Additional Information
                // _buildAdditionalInformation(),
                // const SizedBox(height: 40),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 12),
                          Text('Back to Family Tree'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final csvBuffer = StringBuffer();
                        csvBuffer.writeln(
                          'Year,TotalBuffaloes,ProducingBuffaloes,Revenue',
                        );
                        final yearlyData =
                            widget.revenueData['yearlyData'] as List<dynamic>;
                        for (final y in yearlyData) {
                          csvBuffer.writeln(
                            '${y['year']},${y['totalBuffaloes']},${y['matureBuffaloes']},${y['revenue']}',
                          );
                        }
                        final csvString = csvBuffer.toString();
                        await Share.share(csvString, subject: 'Revenue CSV');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 12),
                          Text('Share Revenue CSV'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class for chart data
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
