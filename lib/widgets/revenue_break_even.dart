import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueBreakEvenWidget extends StatelessWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> breakEvenAnalysis;
  final List<String> monthNames;
  final String Function(double) formatCurrency;

  const RevenueBreakEvenWidget({
    Key? key,
    required this.treeData,
    required this.breakEvenAnalysis,
    required this.monthNames,
    required this.formatCurrency,
  }) : super(key: key);

  // Calculate months difference between start date and break-even date
  int? _calculateMonthsToBreakEven(DateTime? breakEvenDate) {
    if (breakEvenDate == null) return null;

    final startYear = treeData['startYear'] as int?;
    final startMonth = treeData['startMonth'] as int?;
    final startDay = (treeData['startDay'] as int?) ?? 1;

    if (startYear == null || startMonth == null) return null;

    final startDate = DateTime(startYear, startMonth, startDay);
    final yearsDiff = breakEvenDate.year - startDate.year;
    final monthsDiff = breakEvenDate.month - startDate.month;

    return yearsDiff * 12 + monthsDiff;
  }

  // Calculate investment recovery status
  Map<String, dynamic> _calculateInvestmentRecoveryStatus(
    int cumulativeRevenue,
    int totalInvestment,
    bool isRevenueBreakEven,
  ) {
    // Protect against division by zero if initialInvestment is 0 or missing
    if (totalInvestment <= 0) {
      return {
        'recoveryPercentage': 0.0,
        'status': 'In Progress',
      };
    }

    final recoveryPercentage =
        (cumulativeRevenue / totalInvestment) * 100;

    String status = "";
    if (isRevenueBreakEven || recoveryPercentage >= 100) {
      status = "Break-Even Achieved ✓";
    } else if (recoveryPercentage >= 75) {
      status = "75% Investment Recovered";
    } else if (recoveryPercentage >= 50) {
      status = "50% Investment Recovered";
    } else if (recoveryPercentage >= 25) {
      status = "25% Investment Recovered";
    } else {
      status = "In Progress";
    }

    return {
      'recoveryPercentage': recoveryPercentage,
      'status': status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final breakEvenData =
        (breakEvenAnalysis['breakEvenData'] as List<dynamic>?) ?? [];
    final initialInvestment =
        (breakEvenAnalysis['initialInvestment'] as int?) ?? 0;

    final exactBreakEvenDateWithCPF =
        breakEvenAnalysis['exactBreakEvenDateWithCPF'] as DateTime?;
    final finalCumulativeRevenueWithCPF =
        (breakEvenAnalysis['finalCumulativeRevenueWithCPF'] as num?)
                ?.toDouble() ??
            0.0;

    // Months to break-even (with CPF), matching React helper
    final monthsToBreakEvenWithCPF =
        _calculateMonthsToBreakEven(exactBreakEvenDateWithCPF);

    // Derived year range similar to React yearRange prop
    final startYear = (treeData['startYear'] as int?) ??
        (breakEvenData.isNotEmpty
            ? (breakEvenData.first as Map<String, dynamic>)['year'] as int
            : DateTime.now().year);
    final yearsSpan = (breakEvenAnalysis['years'] as int?) ??
        (breakEvenData.isNotEmpty
            ? ((breakEvenData.last as Map<String, dynamic>)['year'] as int) -
                startYear +
                1
            : 0);
    final endYear = yearsSpan > 0 ? startYear + yearsSpan - 1 : startYear;
    final yearRange = '$startYear - $endYear';

    final breakEvenDateText = exactBreakEvenDateWithCPF != null
        ? DateFormat('MMM dd, yyyy').format(exactBreakEvenDateWithCPF)
        : 'Not yet achieved';

    // Final asset value and combined value (Rev + Asset) for footer / cards
    double finalAssetValue = 0;
    if (breakEvenData.isNotEmpty) {
      final last = breakEvenData.last as Map<String, dynamic>;
      finalAssetValue = (last['assetValue'] as num?)?.toDouble() ?? 0.0;
    }
    final finalCombinedValue = finalCumulativeRevenueWithCPF + finalAssetValue;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text(
                    'Revenue Break-Even Analysis',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'With CPF',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4 Info Cards
            Row(
              children: [
                // Mother Buffaloes Cost
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.white],
                      ),
                      border: Border.all(color: Colors.blue[100]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(
                              ((treeData['units'] ?? 1) * 2 * 175000).toDouble()),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mother Buffaloes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${treeData['units'] ?? 1} units × 2 mothers × ₹1.75L\n${((treeData['units'] ?? 1) * 2)} mother buffaloes @ ₹1.75L each',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // CPF Cost
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.white],
                      ),
                      border: Border.all(color: Colors.green[100]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(
                              (((treeData['units'] ?? 1) * 13000).toDouble())),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'CPF Coverage',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${treeData['units'] ?? 1} units × ₹13,000\nOne CPF covers both M1 and M2 per unit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Total Investment
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade600, Colors.purple.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(initialInvestment.toDouble()),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Total Initial Investment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((treeData['units'] ?? 1) * 4)} buffaloes total\n(2 mothers + 2 calves per unit)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Break-Even With CPF
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[50]!, Colors.white],
                      ),
                      border: Border.all(color: Colors.orange[100]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          breakEvenDateText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Break-Even with CPF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Net cumulative revenue with CPF:\n${formatCurrency(finalCumulativeRevenueWithCPF)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (monthsToBreakEvenWithCPF != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Achieved in $monthsToBreakEvenWithCPF months',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange[700],
                            ),
                          ),
                          Text(
                            '(${(monthsToBreakEvenWithCPF ~/ 12)} years and ${monthsToBreakEvenWithCPF % 12} months)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Break-Even Details (Timeline + Investment Recovery Progress)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Break-Even Timeline Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Break-Even Timeline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Start Date:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${monthNames[treeData['startMonth'] ?? 0]} ${treeData['startDay'] ?? 1}, ${treeData['startYear'] ?? startYear}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (exactBreakEvenDateWithCPF != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Break-Even Date:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                breakEvenDateText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (monthsToBreakEvenWithCPF != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Time to Break-Even:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$monthsToBreakEvenWithCPF months',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Net Cumulative Revenue:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formatCurrency(
                                    finalCumulativeRevenueWithCPF),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Investment Recovery Progress Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Investment Recovery Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Initial Investment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              formatCurrency(initialInvestment.toDouble()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[400]!,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (exactBreakEvenDateWithCPF != null) ...[
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recovered at Break-Even',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formatCurrency(
                                    initialInvestment.toDouble()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Final Cumulative Revenue',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              formatCurrency(
                                  finalCumulativeRevenueWithCPF),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: initialInvestment > 0
                              ? (finalCumulativeRevenueWithCPF /
                                      initialInvestment)
                                  .clamp(0.0, 2.0)
                              : 0.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            initialInvestment > 0
                                ? '${((finalCumulativeRevenueWithCPF / initialInvestment) * 100).toStringAsFixed(1)}% of initial'
                                : '0.0% of initial',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Break-Even Timeline Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Break-Even Timeline ($yearRange) - With CPF',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Builder(
                      builder: (_) {
                        // Precompute totals for footer row
                        double totalAnnualRevenueWithCPF = 0;
                        double totalCpfCost = 0;

                        for (final d in breakEvenData) {
                          final m = d as Map<String, dynamic>;
                          totalAnnualRevenueWithCPF +=
                              (m['annualRevenueWithCPF'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                          totalCpfCost +=
                              (m['cpfCost'] as num?)?.toDouble() ?? 0.0;
                        }

                        final combinedRoiPercent = initialInvestment > 0
                            ? (finalCombinedValue / initialInvestment) * 100
                            : 0.0;

                        final rows = <DataRow>[];

                        for (var i = 0; i < breakEvenData.length; i++) {
                          final yearData =
                              breakEvenData[i] as Map<String, dynamic>;
                          final year = yearData['year'] as int;
                          // In CostEstimationTable.calculateBreakEvenAnalysis,
                          // annualRevenueWithCPF and cumulativeRevenueWithCPF
                          // are stored as num (double). Read them as num and
                          // convert to int to avoid them becoming 0.
                          final annualRevenue =
                              (yearData['annualRevenueWithCPF'] as num?)
                                      ?.toInt() ??
                                  0;
                          final cumulativeRevenue =
                              (yearData['cumulativeRevenueWithCPF'] as num?)
                                      ?.toInt() ??
                                  0;
                          final assetValue =
                              yearData['assetValue'] as int? ?? 0;
                          final totalValueWithCPF =
                              yearData['totalValueWithCPF'] as int? ?? 0;
                          final isRevenueBreakEven =
                              yearData['isRevenueBreakEvenWithCPF'] as bool? ??
                                  false;

                          final recovery = _calculateInvestmentRecoveryStatus(
                            cumulativeRevenue,
                            initialInvestment,
                            isRevenueBreakEven,
                          );

                          final recoveryPercentage =
                              (recovery['recoveryPercentage'] as double);
                          final status = (recovery['status'] as String);

                          rows.add(
                            DataRow(
                              color: WidgetStatePropertyAll(
                                isRevenueBreakEven
                                    ? Colors.green[50]
                                    : null,
                              ),
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        year.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isRevenueBreakEven)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '⭐ Break-Even',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCurrency(
                                            annualRevenue.toDouble()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'CPF: -${formatCurrency((yearData['cpfCost'] as int? ?? 0).toDouble())}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCurrency(
                                        cumulativeRevenue.toDouble()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCurrency(assetValue.toDouble()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCurrency(
                                        totalValueWithCPF.toDouble()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            height: 6,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              child: LinearProgressIndicator(
                                                value: (recoveryPercentage / 100)
                                                    .clamp(0.0, 1.0),
                                                backgroundColor:
                                                    Colors.grey[200],
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  recoveryPercentage >= 100
                                                      ? Colors.green[500]!
                                                      : Colors.blue[500]!,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${recoveryPercentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status
                                                  .contains('Break-Even')
                                              ? Colors.green[100]
                                              : status.contains('75%')
                                                  ? Colors.yellow[100]
                                                  : status.contains('50%')
                                                      ? Colors.blue[100]
                                                      : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: status
                                                    .contains('Break-Even')
                                                ? Colors.green[800]
                                                : status.contains('75%')
                                                    ? Colors.yellow[800]
                                                    : status.contains('50%')
                                                        ? Colors.blue[800]
                                                        : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Append FINAL TOTALS row similar to React footer
                        rows.add(
                          DataRow(
                            color: WidgetStatePropertyAll(
                              Colors.grey[900],
                            ),
                            cells: [
                              const DataCell(
                                Text(
                                  'FINAL TOTALS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatCurrency(
                                          totalAnnualRevenueWithCPF),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    Text(
                                      'Total CPF: ${formatCurrency(totalCpfCost)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  formatCurrency(
                                      finalCumulativeRevenueWithCPF),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigoAccent,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  formatCurrency(finalAssetValue),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatCurrency(finalCombinedValue),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    Text(
                                      'Revenue + Assets',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ROI',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '${combinedRoiPercent.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    Text(
                                      '${formatCurrency(initialInvestment.toDouble())} initial',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        return DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Year',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Annual Revenue (Net)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cumulative (Net)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Asset Market Value',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Value (Rev + Asset)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Investment Recovery',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          rows: rows,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
