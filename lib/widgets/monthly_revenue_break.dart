import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
    _selectedUnit = 1;
  }

  // Filter buffaloes: unit + age >= 3 + has revenue
  List<Map<String, dynamic>> _getIncomeProducingBuffaloes() {
    final incomeProducing = <Map<String, dynamic>>[];

    widget.buffaloDetails.forEach((mapKey, buffalo) {
      if ((buffalo['unit'] ?? 1) == _selectedUnit) {
        final birthYear = (buffalo['birthYear'] as int?) ?? _selectedYear;

        // Check if buffalo is at least 3 years old
        if (_selectedYear >= birthYear + 3) {
          // Check if buffalo has any revenue in the selected year
          bool hasRevenue = false;
          for (int month = 0; month < 12; month++) {
            final displayId = buffalo['id'] as String;
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

  // Calculate CPF cost for milk-producing buffaloes
  Map<String, dynamic> _calculateCPFCost() {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    int milkProducingBuffaloesWithCPF = 0;

    // Identify first parent (M1 equivalent)
    final parents = unitBuffaloes
        .where((b) => (b['generation'] as int?) == 0)
        .toList();
    final firstParentId = parents.isNotEmpty
        ? (parents.first['id'] as String?)
        : null;

    for (final buffalo in unitBuffaloes) {
      final id = buffalo['id'] as String?;
      final gen = (buffalo['generation'] as int?) ?? 0;

      if (id != null && id == firstParentId) {
        milkProducingBuffaloesWithCPF++;
      } else if (gen == 1 || gen == 2) {
        final ageInMonths = widget.calculateAgeInMonths(
          buffalo,
          _selectedYear,
          11,
        );
        if (ageInMonths >= 36) {
          milkProducingBuffaloesWithCPF++;
        }
      }
    }

    final annualCPFCost = milkProducingBuffaloesWithCPF * 13000;
    final monthlyCPFCost = (annualCPFCost / 12).round();

    return {
      'milkProducingBuffaloes': unitBuffaloes.length,
      'milkProducingBuffaloesWithCPF': milkProducingBuffaloesWithCPF,
      'annualCPFCost': annualCPFCost,
      'monthlyCPFCost': monthlyCPFCost,
    };
  }

  // Calculate cumulative revenue until selected year
  Map<String, int> _calculateCumulativeRevenueUntilYear() {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cumulativeRevenue = <String, int>{};

    for (final buffalo in unitBuffaloes) {
      int total = 0;
      final displayId = buffalo['id'] as String;

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
          total += (revenue as int? ?? 0);
        }
      }
      cumulativeRevenue[displayId] = total;
    }

    return cumulativeRevenue;
  }

  int _getTotalCumulativeRevenueUntilYear() {
    final cumulativeRevenue = _calculateCumulativeRevenueUntilYear();
    return cumulativeRevenue.values.fold<int>(
      0,
      (sum, revenue) => sum + revenue,
    );
  }

  // Calculate total CPF cost from start year to selected year
  int _getTotalCPFCostUntilYear() {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    int totalCPFCost = 0;

    // Identify first parent (M1 equivalent)
    final parents = unitBuffaloes
        .where((b) => (b['generation'] as int?) == 0)
        .toList();
    final firstParentId = parents.isNotEmpty
        ? (parents.first['id'] as String?)
        : null;

    final startYear = widget.treeData['startYear'] as int;

    // For each year from start to selected year
    for (int year = startYear; year <= _selectedYear; year++) {
      int yearCPFCost = 0;

      for (final buffalo in unitBuffaloes) {
        final id = buffalo['id'] as String?;
        final gen = (buffalo['generation'] as int?) ?? 0;

        if (id != null && id == firstParentId) {
          yearCPFCost += 13000;
        } else if (gen == 1 || gen == 2) {
          final ageInMonths = widget.calculateAgeInMonths(buffalo, year, 11);
          if (ageInMonths >= 36) {
            yearCPFCost += 13000;
          }
        }
      }

      totalCPFCost += yearCPFCost;
    }

    return totalCPFCost;
  }

  // Download CSV
  void _downloadCSV() {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cpfCost = _calculateCPFCost();

    String csvContent =
        "Monthly Revenue Breakdown - Unit $_selectedUnit - $_selectedYear\n\n";

    csvContent += "Month,";
    for (final buffalo in unitBuffaloes) {
      csvContent += '${buffalo['id']},';
    }
    csvContent += "Unit Total,CPF Cost,Net Revenue\n";

    for (int month = 0; month < 12; month++) {
      final monthName = widget.monthNames[month];
      csvContent += "$monthName,";

      int unitTotal = 0;
      for (final buffalo in unitBuffaloes) {
        final displayId = buffalo['id'] as String;
        final revenue =
            (widget.monthlyRevenue[_selectedYear.toString()]?[month
                    .toString()]?['buffaloes']
                as Map?)?[displayId] ??
            0;
        csvContent += "$revenue,";
        unitTotal += (revenue as int? ?? 0);
      }

      final netRevenue = unitTotal - cpfCost['monthlyCPFCost'];
      csvContent += "$unitTotal,${cpfCost['monthlyCPFCost']},$netRevenue\n";
    }

    // Yearly total
    csvContent += "\nYearly Total,";
    int yearlyUnitTotal = 0;
    for (final buffalo in unitBuffaloes) {
      final displayId = buffalo['id'] as String;
      int yearlyTotal = 0;
      for (int month = 0; month < 12; month++) {
        final revenue =
            (widget.monthlyRevenue[_selectedYear.toString()]?[month
                    .toString()]?['buffaloes']
                as Map?)?[displayId] ??
            0;
        yearlyTotal += (revenue as int? ?? 0);
      }
      csvContent += "$yearlyTotal,";
      yearlyUnitTotal += yearlyTotal;
    }

    final yearlyNetRevenue = yearlyUnitTotal - cpfCost['annualCPFCost'];
    csvContent +=
        "$yearlyUnitTotal,${cpfCost['annualCPFCost']},$yearlyNetRevenue\n";

    Share.share(
      csvContent,
      subject: "Unit-$_selectedUnit-Revenue-$_selectedYear.csv",
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitBuffaloes = _getIncomeProducingBuffaloes();
    final cpfCost = _calculateCPFCost();
    final cumulativeRevenue = _calculateCumulativeRevenueUntilYear();
    final totalCumulativeUntilYear = _getTotalCumulativeRevenueUntilYear();
    final yearlyUnitTotal = unitBuffaloes.fold<int>(0, (sum, buffalo) {
      int total = 0;
      final displayId = buffalo['id'] as String;
      for (int month = 0; month < 12; month++) {
        final revenue =
            (widget.monthlyRevenue[_selectedYear.toString()]?[month
                    .toString()]?['buffaloes']
                as Map?)?[displayId] ??
            0;
        total += (revenue as int? ?? 0);
      }
      return sum + total;
    });
    final yearlyNetRevenue = yearlyUnitTotal - cpfCost['annualCPFCost'];

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation Controls
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Year Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Select Year',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: _selectedYear,
                              items: List.generate(
                                (widget.treeData['years'] ?? 10) as int,
                                (i) {
                                  final year =
                                      ((widget.treeData['startYear'] ?? 2026)
                                          as int) +
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Unit Selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Select Unit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: _selectedUnit,
                              items: List.generate(
                                (widget.treeData['units'] ?? 1) as int,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('Unit ${i + 1}'),
                                ),
                              ).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUnit = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Download Button
                      ElevatedButton.icon(
                        onPressed: _downloadCSV,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cumulative Revenue Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.indigo[50]!],
                      ),
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total revenue generated by Unit $_selectedUnit from ${widget.treeData['startYear']} to $_selectedYear: ${widget.formatCurrency(totalCumulativeUntilYear.toDouble())}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Main Table
            if (unitBuffaloes.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Monthly Revenue Breakdown',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unit $_selectedUnit • ${unitBuffaloes.length} Buffalo${unitBuffaloes.length != 1 ? 'es' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: [
                          const DataColumn(
                            label: Text(
                              'Month',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...unitBuffaloes.map((buffalo) {
                            final gen = (buffalo['generation'] as int?) ?? 0;
                            final genLabel = gen == 0
                                ? 'Mother'
                                : gen == 1
                                ? 'Child'
                                : 'Grandchild';
                            return DataColumn(
                              label: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    buffalo['id'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    genLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const DataColumn(
                            label: Text(
                              'Unit Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'CPF Cost',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Net Revenue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        rows: [
                          // Monthly rows
                          ...List.generate(12, (monthIndex) {
                            final monthName = widget.monthNames[monthIndex];
                            int unitTotal = 0;

                            for (final buffalo in unitBuffaloes) {
                              final displayId = buffalo['id'] as String;
                              final revenue =
                                  (widget.monthlyRevenue[_selectedYear
                                          .toString()]?[monthIndex
                                          .toString()]?['buffaloes']
                                      as Map?)?[displayId] ??
                                  0;
                              unitTotal += (revenue as int? ?? 0);
                            }

                            final netRevenue =
                                unitTotal - cpfCost['monthlyCPFCost'];

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    monthName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ...unitBuffaloes.map((buffalo) {
                                  final displayId = buffalo['id'] as String;
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
                                  final colors = {
                                    'high': Colors.green[50],
                                    'medium': Colors.blue[50],
                                    'low': Colors.grey[50],
                                  };

                                  return DataCell(
                                    Container(
                                      color: colors[revenueType],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        widget.formatCurrency(
                                          (revenue as int).toDouble(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                DataCell(
                                  Container(
                                    color: Colors.grey[200],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      widget.formatCurrency(
                                        unitTotal.toDouble(),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    color: Colors.amber[100],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      widget.formatCurrency(
                                        cpfCost['monthlyCPFCost']
                                            .toString()
                                            .parseDouble(),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
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
                              ],
                            );
                          }).toList(),

                          // Yearly Total Row
                          DataRow(
                            cells: [
                              const DataCell(
                                Text(
                                  'Yearly Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ...unitBuffaloes.map((buffalo) {
                                final displayId = buffalo['id'] as String;
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
                                  Text(
                                    widget.formatCurrency(
                                      yearlyTotal.toDouble(),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                              DataCell(
                                Text(
                                  widget.formatCurrency(
                                    yearlyUnitTotal.toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
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
                              DataCell(
                                Text(
                                  widget.formatCurrency(
                                    yearlyNetRevenue.toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                                Text(
                                  'Cumulative Until $_selectedYear',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ...unitBuffaloes.map((buffalo) {
                                final displayId = buffalo['id'] as String;
                                final cumRev =
                                    cumulativeRevenue[displayId] ?? 0;
                                return DataCell(
                                  Text(
                                    widget.formatCurrency(cumRev.toDouble()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                              DataCell(
                                Text(
                                  widget.formatCurrency(
                                    totalCumulativeUntilYear.toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  widget.formatCurrency(
                                    // ((cpfCost['annualCPFCost'] as int) * 10)
                                    //     .toDouble()
                                    _getTotalCPFCostUntilYear().toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  widget.formatCurrency(
                                    // (totalCumulativeUntilYear -
                                    //         ((cpfCost['annualCPFCost'] as int) *
                                    //             10))
                                    //     .toDouble()
                                    totalCumulativeUntilYear -
                                        _getTotalCPFCostUntilYear().toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            color: WidgetStatePropertyAll(Colors.blue[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[50]!, Colors.amber[100]!],
                  ),
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'No Income Producing Buffaloes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no income-producing buffaloes in Unit $_selectedUnit for $_selectedYear.',
                      style: TextStyle(fontSize: 16, color: Colors.amber[900]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buffaloes start generating income at age 3 (born in ${_selectedYear - 3} or earlier).',
                      style: TextStyle(fontSize: 14, color: Colors.amber[800]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Annual Revenue',
                    widget.formatCurrency(yearlyUnitTotal.toDouble()),
                    Colors.blue,
                    '$_selectedYear',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _summaryCard(
                    'Annual CPF Cost',
                    widget.formatCurrency(
                      cpfCost['annualCPFCost'].toString().parseDouble(),
                    ),
                    Colors.amber,
                    '${cpfCost['milkProducingBuffaloesWithCPF']} buffaloes × ₹13,000',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _summaryCard(
                    'Net Annual Revenue',
                    widget.formatCurrency(yearlyNetRevenue.toDouble()),
                    Colors.green,
                    '$_selectedYear',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _summaryCard(
                    'Cumulative Net',
                    widget.formatCurrency(
                      // (totalCumulativeUntilYear - ((cpfCost['annualCPFCost'] as int) * 10))
                      //     .toDouble(),
                      totalCumulativeUntilYear -
                          _getTotalCPFCostUntilYear().toDouble(),
                    ),
                    Colors.indigo,
                    'Until $_selectedYear',
                  ),
                ),
              ],
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
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color[50]!, color[100]!]),
        border: Border.all(color: color[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: color[600])),
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
