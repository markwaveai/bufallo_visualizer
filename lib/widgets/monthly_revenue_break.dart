import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyRevenueBreakWidget extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> buffaloDetails;
  final Map<String, Map<String, Map<String, dynamic>>> monthlyRevenue;
  final int Function(Map<String, dynamic>, int, [int]) calculateAgeInMonths;
  final List<String> monthNames;
  final String Function(double) formatCurrency;

  const MonthlyRevenueBreakWidget({
    Key? key,
    required this.treeData,
    required this.buffaloDetails,
    required this.monthlyRevenue,
    required this.calculateAgeInMonths,
    required this.monthNames,
    required this.formatCurrency,
  }) : super(key: key);

  @override
  State<MonthlyRevenueBreakWidget> createState() =>
      _MonthlyRevenueBreakWidgetState();
}

class _MonthlyRevenueBreakWidgetState extends State<MonthlyRevenueBreakWidget> {
  late int _selectedYear;
  late int _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.treeData['startYear'] ?? DateTime.now().year;
    _selectedUnit = 0; // Default to All Units
  }

  // Filter buffaloes: unit + age >= 3 + has revenue
  List<Map<String, dynamic>> _getIncomeProducingBuffaloes() {
    final incomeProducing = <Map<String, dynamic>>[];

    widget.buffaloDetails.forEach((mapKey, buffalo) {
      if (_selectedUnit == 0 || (buffalo['unit'] ?? 1) == _selectedUnit) {
        final birthYear = (buffalo['birthYear'] as int?) ?? _selectedYear;

        // Check if buffalo is at least 3 years old
        if (_selectedYear >= birthYear + 3) {
          // Check if buffalo has any revenue in the selected year
          bool hasRevenue = false;
          for (int month = 0; month < 12; month++) {
            final displayId = buffalo['id'].toString();
            final revenue =
                (widget.monthlyRevenue[_selectedYear.toString()]?[month
                        .toString()]?['buffaloes']
                    as Map?)?[displayId] ??
                0;
            if (revenue > 0) {
              hasRevenue = true;
              break;
            }
          }

          if (hasRevenue) {
            incomeProducing.add({...buffalo, 'mapKey': mapKey});
          }
        }
      }
    });

    return incomeProducing;
  }

  // Helper to check precise CPF applicability per month (matching React)
  bool _isCpfApplicableForMonth(
    Map<String, dynamic> buffalo,
    int year,
    int month,
  ) {
    final id = buffalo['id']?.toString();
    final gen = buffalo['generation'] as int? ?? 0;
    final startYear = widget.treeData['startYear'] as int;

    if (id == null || id.isEmpty) return false;

    if (gen == 0) {
      // Generation 0: Identify Type A vs Type B
      final charCode = id.codeUnitAt(0);
      final isFirstInUnit = (charCode - 65) % 2 == 0; // Type A

      if (isFirstInUnit) {
        // Type A: Always pays CPF from start
        return true;
      } else {
        // Type B: Free Period Check
        final acquisitionMonth = buffalo['acquisitionMonth'] as int? ?? 0;
        final isPresentInSimulation =
            year > startYear ||
            (year == startYear && month >= acquisitionMonth);

        if (isPresentInSimulation) {
          // Free Period: July of Start Year to June of Start Year + 1
          final isFreePeriod =
              (year == startYear && month >= 6) ||
              (year == startYear + 1 && month <= 5);

          if (!isFreePeriod) {
            return true;
          }
        }
      }
    } else if (gen >= 1) {
      // Child CPF: Age >= 36 months
      final ageInMonths = widget.calculateAgeInMonths(buffalo, year, month);
      if (ageInMonths >= 36) {
        return true;
      }
    }

    return false;
  }

  // Calculate CPF cost for milk-producing buffaloes (matching React with monthly precision)
  Map<String, dynamic> _calculateCPFCost() {
    final cpfPerMonth = 13000 / 12; // ₹1,083.33 per month
    final List<double> monthlyCosts = List.filled(12, 0.0);
    final List<Map<String, dynamic>> buffaloCPFDetails = [];
    int milkProducingBuffaloesWithCPF = 0;

    // Get ALL buffaloes in this unit (not just income-producing)
    final allUnitBuffaloes = <Map<String, dynamic>>[];
    widget.buffaloDetails.forEach((mapKey, buffalo) {
      if (_selectedUnit == 0 || (buffalo['unit'] ?? 1) == _selectedUnit) {
        allUnitBuffaloes.add({...buffalo, 'mapKey': mapKey});
      }
    });

    for (final buffalo in allUnitBuffaloes) {
      int monthsWithCPF = 0;

      for (int month = 0; month < 12; month++) {
        if (_isCpfApplicableForMonth(buffalo, _selectedYear, month)) {
          monthlyCosts[month] += cpfPerMonth;
          monthsWithCPF++;
        }
      }

      if (monthsWithCPF > 0) milkProducingBuffaloesWithCPF++;

      // Determine reason
      String reason = "No CPF";
      if (monthsWithCPF == 12) {
        reason = "Full Year";
      } else if (monthsWithCPF > 0) {
        reason = "Partial ($monthsWithCPF months)";
      } else {
        final id = buffalo['id']?.toString();
        final gen = buffalo['generation'] as int? ?? 0;
        final startYear = widget.treeData['startYear'] as int;

        if (id != null && id.isNotEmpty && gen == 0) {
          final charCode = id.codeUnitAt(0);
          final isFirstInUnit = (charCode - 65) % 2 == 0;

          if (!isFirstInUnit && _selectedYear <= startYear + 1) {
            reason = "Free Period";
          }
        } else if (gen > 0) {
          reason = "Age < 3 years";
        }
      }

      buffaloCPFDetails.add({
        'id': buffalo['id'],
        'hasCPF': monthsWithCPF > 0,
        'reason': reason,
        'monthsWithCPF': monthsWithCPF,
      });
    }

    final annualCPFCost = monthlyCosts.fold<double>(0, (a, b) => a + b);

    return {
      'monthlyCosts': monthlyCosts,
      'annualCPFCost': annualCPFCost.round(),
      'buffaloCPFDetails': buffaloCPFDetails,
      'milkProducingBuffaloesWithCPF': milkProducingBuffaloesWithCPF,
    };
  }

  // Calculate cumulative revenue until selected year
  Map<String, double> _calculateCumulativeRevenueUntilYear() {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cumulativeRevenue = <String, double>{};

    for (final buffalo in unitBuffaloes) {
      double total = 0;
      final displayId = buffalo['id'].toString();

      for (
        int year = widget.treeData['startYear'] as int;
        year <= _selectedYear;
        year++
      ) {
        for (int month = 0; month < 12; month++) {
          final revenue =
              (widget.monthlyRevenue[year.toString()]?[month
                      .toString()]?['buffaloes']
                  as Map?)?[displayId] ??
              0;
          total += (revenue as num?)?.toDouble() ?? 0.0;
        }
      }
      cumulativeRevenue[displayId] = total;
    }

    return cumulativeRevenue;
  }

  double _getTotalCumulativeRevenueUntilYear() {
    final cumulativeRevenue = _calculateCumulativeRevenueUntilYear();
    return cumulativeRevenue.values.fold<double>(
      0.0,
      (sum, revenue) => sum + revenue,
    );
  }

  // Calculate total CPF cost from start year to selected year
  int _getTotalCPFCostUntilYear() {
    int totalCPFCost = 0;

    // This logic is tricky with "All Units" because there are multiple "First Parents".
    // We should rely on _isCpfApplicableForMonth or similar per-buffalo logic instead of finding "The First Parent".
    // However, for total CPF cost until year, we can iterate over years and buffaloes.

    final startYear = widget.treeData['startYear'] as int;

    for (int year = startYear; year <= _selectedYear; year++) {
      // Recalculate CPF for each year for the filtered buffaloes
      // This is expensive but accurate.
      // For optimization, we can duplicate the iteration logic.

      final allUnitBuffaloes = <Map<String, dynamic>>[];
      widget.buffaloDetails.forEach((mapKey, buffalo) {
        if (_selectedUnit == 0 || (buffalo['unit'] ?? 1) == _selectedUnit) {
          allUnitBuffaloes.add(buffalo);
        }
      });

      for (final buffalo in allUnitBuffaloes) {
        // We need to check monthly applicability for "year"
        // But _isCpfApplicableForMonth takes (buffalo, year, month).
        for (int m = 0; m < 12; m++) {
          if (_isCpfApplicableForMonth(buffalo, year, m)) {
            totalCPFCost += (13000 ~/ 12);
          }
        }
      }
    }
    return totalCPFCost;
  }

  // Download CSV (Excel Compatible)
  Future<void> _downloadCSV() async {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cpfCost = _calculateCPFCost();
    final monthlyCosts = cpfCost['monthlyCosts'] as List<double>;

    String fileName = _selectedUnit == 0
        ? "All-Units-Revenue-$_selectedYear"
        : "Unit-$_selectedUnit-Revenue-$_selectedYear";

    String csvContent =
        "Monthly Revenue Breakdown - ${_selectedUnit == 0 ? 'All Units' : 'Unit $_selectedUnit'} - $_selectedYear\n\n";

    csvContent += "Month,";
    for (final buffalo in unitBuffaloes) {
      csvContent += '${buffalo['id']},';
    }
    csvContent += "Total,CPF Cost,Net Revenue\n";

    // Monthly Rows
    double yearlyUnitTotal = 0;

    // Calculate yearly totals
    Map<String, double> buffaloYearlyTotals = {};
    for (final buffalo in unitBuffaloes) {
      buffaloYearlyTotals[buffalo['id']] = 0;
    }

    for (int month = 0; month < 12; month++) {
      final monthName = widget.monthNames[month];
      csvContent += "$monthName,";

      double unitTotal = 0;
      for (final buffalo in unitBuffaloes) {
        final displayId = buffalo['id'].toString();
        final revenue =
            (widget.monthlyRevenue[_selectedYear.toString()]?[month
                    .toString()]?['buffaloes']
                as Map?)?[displayId] ??
            0;
        final revenueDouble = (revenue as num?)?.toDouble() ?? 0.0;

        csvContent += "$revenueDouble,";

        unitTotal += revenueDouble;
        buffaloYearlyTotals[displayId] =
            (buffaloYearlyTotals[displayId] ?? 0) + revenueDouble;
      }

      final monthlyCpf = monthlyCosts[month];
      final netRevenue = unitTotal - monthlyCpf;

      csvContent += "$unitTotal,$monthlyCpf,$netRevenue\n";
      yearlyUnitTotal += unitTotal;
    }

    // Yearly Total Row
    csvContent += "\nYearly Total,";

    for (final buffalo in unitBuffaloes) {
      csvContent += "${buffaloYearlyTotals[buffalo['id']] ?? 0.0},";
    }

    final annualCPFCost = (cpfCost['annualCPFCost'] as num).toDouble();
    final yearlyNetRevenue = yearlyUnitTotal - annualCPFCost;

    csvContent += "$yearlyUnitTotal,$annualCPFCost,$yearlyNetRevenue\n";

    // Save Logic
    final List<int> bytes = utf8.encode(csvContent);

    await FileSaver.instance.saveFile(
      name: '$fileName.csv',
      bytes: Uint8List.fromList(bytes),
      mimeType: MimeType.csv,
    );
  }

  // Download PDF
  Future<void> _downloadPDF() async {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cpfCost = _calculateCPFCost();
    final monthlyCosts = cpfCost['monthlyCosts'] as List<double>;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Monthly Revenue Breakdown - ${_selectedUnit == 0 ? 'All Units' : 'Unit $_selectedUnit'} - $_selectedYear',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Month',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    ...unitBuffaloes.map(
                      (b) => pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          b['id'].toString(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'CPF Cost',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Net Revenue',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Monthly Rows
                ...List.generate(12, (monthIndex) {
                  final monthName = widget.monthNames[monthIndex];
                  double unitTotal = 0;
                  final List<pw.Widget> rowCells = [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(monthName),
                    ),
                  ];

                  for (final buffalo in unitBuffaloes) {
                    final displayId = buffalo['id'].toString();
                    final revenue =
                        (widget.monthlyRevenue[_selectedYear
                                .toString()]?[monthIndex
                                .toString()]?['buffaloes']
                            as Map?)?[displayId] ??
                        0;
                    final revenueDouble = (revenue as num?)?.toDouble() ?? 0.0;
                    unitTotal += revenueDouble;

                    rowCells.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(widget.formatCurrency(revenueDouble)),
                      ),
                    );
                  }

                  final monthlyCpf = monthlyCosts[monthIndex];
                  final netRevenue = unitTotal - monthlyCpf;

                  rowCells.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(widget.formatCurrency(unitTotal)),
                    ),
                  );
                  rowCells.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(widget.formatCurrency(monthlyCpf)),
                    ),
                  );
                  rowCells.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(widget.formatCurrency(netRevenue)),
                    ),
                  );

                  return pw.TableRow(children: rowCells);
                }),
                // Yearly Total Row (Optional, adding for completeness)
              ],
            ),
          ];
        },
      ),
    );

    String fileName = _selectedUnit == 0
        ? "All-Units-Revenue-$_selectedYear.pdf"
        : "Unit-$_selectedUnit-Revenue-$_selectedYear.pdf";

    await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
  }

  @override
  Widget build(BuildContext context) {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cpfCost = _calculateCPFCost();
    final cumulativeRevenue = _calculateCumulativeRevenueUntilYear();
    final totalCumulativeUntilYear = _getTotalCumulativeRevenueUntilYear();
    final yearlyUnitTotal = unitBuffaloes.fold<double>(0.0, (sum, buffalo) {
      double total = 0;
      final displayId = buffalo['id'].toString();
      for (int month = 0; month < 12; month++) {
        final revenue =
            (widget.monthlyRevenue[_selectedYear.toString()]?[month
                    .toString()]?['buffaloes']
                as Map?)?[displayId] ??
            0;
        total += (revenue as num?)?.toDouble() ?? 0.0;
      }
      return sum + total;
    });
    final yearlyNetRevenue = yearlyUnitTotal - cpfCost['annualCPFCost'];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 40,
          vertical: isMobile ? 0 : 20,
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Redesigned Header Layout
            Container(
              width: double.infinity,
              padding: isMobile ? EdgeInsets.all(10) : EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Unit Dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedUnit,
                            isDense: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: isMobile ? 16 : 20,
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 11 : 14,
                            ),
                            items: [
                              DropdownMenuItem<int>(
                                value: 0,
                                child: Text(
                                  'All Units',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 14,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                (widget.treeData['units'] as num? ?? 1).ceil(),
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('Unit ${i + 1}'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedUnit = value);
                              }
                            },
                          ),
                        ),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            // Center: Title + Year Dropdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Monthly Revenue Breakdown - ',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    dropdownColor: isDark
                                        ? Colors.grey[850]
                                        : null,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: isMobile ? 17 : 24,
                                    ),
                                    items: List.generate(
                                      (widget.treeData['years'] as num? ?? 10)
                                          .toInt(),
                                      (i) {
                                        final year =
                                            ((widget.treeData['startYear']
                                                        as num? ??
                                                    2026)
                                                .toInt()) +
                                            i;
                                        return DropdownMenuItem<int>(
                                          value: year,
                                          child: Text(year.toString()),
                                        );
                                      },
                                    ).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedYear = value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Center: Subtitle
                            Text(
                              'Unit $_selectedUnit • ${unitBuffaloes.length} Buffalo${unitBuffaloes.length != 1 ? 'es' : ''}',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Center: B CPF Status (Conditionally shown for Year 1/2)
                            if (_selectedYear == widget.treeData['startYear'] ||
                                _selectedYear ==
                                    (widget.treeData['startYear'] as int) + 1)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 6,
                                ),
                                child: Text(
                                  'B CPF: Free (July-Dec ${widget.treeData['startYear']})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Right: Stats Box + Button
                      isMobile
                          ? SizedBox.shrink()
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.blue[900]!.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.blue[800]!
                                          : Colors.blue[100]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total Revenue (1st Jan - 31st Dec $_selectedYear)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.formatCurrency(yearlyUnitTotal),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        'Net: ${widget.formatCurrency(yearlyNetRevenue)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                  isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blue[900]!.withValues(alpha: 0.3)
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.blue[800]!
                                        : Colors.blue[100]!,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Revenue (1st Jan - 31st Dec $_selectedYear)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.formatCurrency(yearlyUnitTotal),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    Text(
                                      'Net: ${widget.formatCurrency(yearlyNetRevenue)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),

            // Table (Attached to Header)
            if (unitBuffaloes.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.blue[200],
                            ),
                            columnSpacing: 16,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 48,
                            border: TableBorder(
                              verticalInside: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              horizontalInside: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            columns: [
                              // Month
                              const DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Month',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // Dynamic Buffalo Columns
                              ...unitBuffaloes.map((buffalo) {
                                final gen =
                                    (buffalo['generation'] as int?) ?? 0;
                                final genLabel = gen == 0
                                    ? 'Mother'
                                    : gen == 1
                                    ? 'Child'
                                    : 'Grandchild';
                                return DataColumn(
                                  label: Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          buffalo['id'].toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          genLabel,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              // Unit Total
                              const DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Total',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // CPF Cost
                              const DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'CPF Cost',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Net Revenue
                              const DataColumn(
                                label: Expanded(
                                  child: Text(
                                    'Net Revenue',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            rows: [
                              // Monthly rows
                              ...List.generate(12, (monthIndex) {
                                final monthName = widget.monthNames[monthIndex];
                                double unitTotal = 0;

                                for (final buffalo in unitBuffaloes) {
                                  final displayId = buffalo['id'].toString();
                                  final revenue =
                                      (widget.monthlyRevenue[_selectedYear
                                              .toString()]?[monthIndex
                                              .toString()]?['buffaloes']
                                          as Map?)?[displayId] ??
                                      0;
                                  unitTotal +=
                                      (revenue as num?)?.toDouble() ?? 0.0;
                                }

                                // Use monthly CPF from monthlyCosts array
                                final monthlyCpf =
                                    (cpfCost['monthlyCosts']
                                        as List<double>)[monthIndex];
                                final netRevenue = unitTotal - monthlyCpf;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Center(
                                        child: Text(
                                          monthName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...unitBuffaloes.map((buffalo) {
                                      final displayId = buffalo['id']
                                          .toString();
                                      final revenue =
                                          (widget.monthlyRevenue[_selectedYear
                                                  .toString()]?[monthIndex
                                                  .toString()]?['buffaloes']
                                              as Map?)?[displayId] ??
                                          0;
                                      final revenueType = revenue == 9000
                                          ? 'high'
                                          : revenue == 6000
                                          ? 'medium'
                                          : 'low';

                                      // Fix for potential type error with MaterialColor vs Color
                                      final Map<String, Color> bgColors = {
                                        'high': isDark
                                            ? Colors.green[900]!.withValues(
                                                alpha: 0.5,
                                              )
                                            : Colors.green[50]!,
                                        'medium': isDark
                                            ? Colors.blue[900]!.withValues(
                                                alpha: 0.5,
                                              )
                                            : Colors.blue[50]!,
                                        'low': isDark
                                            ? Colors.grey[800]!.withValues(
                                                alpha: 0.5,
                                              )
                                            : Colors.grey[50]!,
                                      };

                                      final textColors = {
                                        'high': isDark
                                            ? Colors.green[100]
                                            : Colors.green[900],
                                        'medium': isDark
                                            ? Colors.blue[100]
                                            : Colors.blue[900],
                                        'low': isDark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      };

                                      return DataCell(
                                        Center(
                                          child: Container(
                                            color: bgColors[revenueType],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Text(
                                              widget.formatCurrency(
                                                (revenue as num).toDouble(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: textColors[revenueType],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: Colors.grey[200],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            widget.formatCurrency(
                                              unitTotal.toDouble(),
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.black87
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: Colors.amber[100],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            widget.formatCurrency(monthlyCpf),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.amber[900]
                                                  : Colors.amber[900],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: netRevenue >= 0
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            widget.formatCurrency(
                                              netRevenue.toDouble(),
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: netRevenue >= 0
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),

                              // Yearly Total Row
                              DataRow(
                                cells: [
                                  const DataCell(
                                    Center(
                                      child: Text(
                                        'Yearly Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...unitBuffaloes.map((buffalo) {
                                    final displayId = buffalo['id'].toString();
                                    int yearlyTotal = 0;
                                    for (int month = 0; month < 12; month++) {
                                      final revenue =
                                          (widget.monthlyRevenue[_selectedYear
                                                  .toString()]?[month
                                                  .toString()]?['buffaloes']
                                              as Map?)?[displayId] ??
                                          0;
                                      yearlyTotal += (revenue as int? ?? 0);
                                    }
                                    return DataCell(
                                      Center(
                                        child: Text(
                                          widget.formatCurrency(
                                            yearlyTotal.toDouble(),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          yearlyUnitTotal.toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          cpfCost['annualCPFCost']
                                              .toString()
                                              .parseDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          yearlyNetRevenue.toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                color: WidgetStatePropertyAll(Colors.grey[700]),
                              ),

                              // Cumulative Row
                              DataRow(
                                cells: [
                                  DataCell(
                                    Center(
                                      child: Text(
                                        'Cumulative Until $_selectedYear',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...unitBuffaloes.map((buffalo) {
                                    final displayId = buffalo['id'] as String;
                                    final cumRev =
                                        cumulativeRevenue[displayId] ?? 0;
                                    return DataCell(
                                      Center(
                                        child: Text(
                                          widget.formatCurrency(
                                            cumRev.toDouble(),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          totalCumulativeUntilYear.toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          // ((cpfCost['annualCPFCost'] as int) * 10)
                                          //     .toDouble()
                                          _getTotalCPFCostUntilYear()
                                              .toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        widget.formatCurrency(
                                          // (totalCumulativeUntilYear -
                                          //         ((cpfCost['annualCPFCost'] as int) *
                                          //             10))
                                          //     .toDouble()
                                          totalCumulativeUntilYear -
                                              _getTotalCPFCostUntilYear()
                                                  .toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                color: WidgetStatePropertyAll(Colors.blue[900]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[50]!, Colors.amber[100]!],
                  ),
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 8 : 16),
                    Text(
                      'No Income Producing Buffaloes',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      'There are no income-producing buffaloes in Unit $_selectedUnit for $_selectedYear.',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 16,
                        color: Colors.amber[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      'Buffaloes start generating income at age 3 (born in ${_selectedYear - 3} or earlier).',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.amber[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobileLayout = constraints.maxWidth < 800;
                final cards = [
                  _summaryCard(
                    "Yearly Net Revenue",
                    widget.formatCurrency(yearlyNetRevenue),
                    Colors.indigo,
                    "After CPF Deduction",
                    isCompact: isMobileLayout,
                  ),
                  _summaryCard(
                    "Cumulative Net",
                    widget.formatCurrency(
                      totalCumulativeUntilYear - _getTotalCPFCostUntilYear(),
                    ),
                    Colors.teal,
                    "Since Start",
                    isCompact: isMobileLayout,
                  ),
                  _summaryCard(
                    "Annual CPF Cost",
                    widget.formatCurrency(
                      (cpfCost['annualCPFCost'] as num).toDouble(),
                    ),
                    Colors.orange,
                    "${cpfCost['milkProducingBuffaloesWithCPF']} Buffaloes",
                    isCompact: isMobileLayout,
                  ),
                  _summaryCard(
                    "Monthly Avg Revenue",
                    widget.formatCurrency(yearlyNetRevenue / 12),
                    Colors.green,
                    "Net Income / Month",
                    isCompact: isMobileLayout,
                  ),
                ];

                if (isMobileLayout) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: cards,
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 20),
                      Expanded(child: cards[1]),
                      const SizedBox(width: 20),
                      Expanded(child: cards[2]),
                      const SizedBox(width: 20),
                      Expanded(child: cards[3]),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    MaterialColor color,
    String subtitle, {
    bool isCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  color[900]!.withValues(alpha: 0.5),
                  color[800]!.withValues(alpha: 0.5),
                ]
              : [color[50]!, color[100]!],
        ),
        border: Border.all(color: isDark ? color[700]! : color[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: isDark ? color[100] : color[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: isDark ? color[200] : color[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              color: isDark ? color[300] : color[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

extension on String {
  double parseDouble() {
    try {
      return double.parse(this);
    } catch (e) {
      return 0.0;
    }
  }
}
