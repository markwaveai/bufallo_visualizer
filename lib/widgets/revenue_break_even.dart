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
      return {'recoveryPercentage': 0.0, 'status': 'In Progress'};
    }

    final recoveryPercentage = (cumulativeRevenue / totalInvestment) * 100;

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

    return {'recoveryPercentage': recoveryPercentage, 'status': status};
  }

  @override
  Widget build(BuildContext context) {
    final breakEvenData =
        (breakEvenAnalysis['breakEvenData'] as List<dynamic>?) ?? [];
    final initialInvestment =
        (breakEvenAnalysis['initialInvestment'] as num?)?.toInt() ?? 0;

    final exactBreakEvenDateWithCPF =
        breakEvenAnalysis['exactBreakEvenDateWithCPF'] as DateTime?;
    final finalCumulativeRevenueWithCPF =
        (breakEvenAnalysis['finalCumulativeRevenueWithCPF'] as num?)
            ?.toDouble() ??
        0.0;

    // Months to break-even (with CPF), matching React helper
    final monthsToBreakEvenWithCPF = _calculateMonthsToBreakEven(
      exactBreakEvenDateWithCPF,
    );

    // Derived year range similar to React yearRange prop
    final startYear =
        (treeData['startYear'] as int?) ??
        (breakEvenData.isNotEmpty
            ? (breakEvenData.first as Map<String, dynamic>)['year'] as int
            : DateTime.now().year);
    final yearsSpan =
        (breakEvenAnalysis['years'] as num?)?.toInt() ??
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
final isMobile=MediaQuery.of(context).size.width<600;
    return SingleChildScrollView(
      child: Container(
        padding: isMobile? EdgeInsets.symmetric(horizontal: 0, vertical: 0): EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'Revenue Break-Even Analysis',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green[900] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'With CPF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.green[100] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 900;
                final isMobile = constraints.maxWidth < 600;

                // Define responsive sizes
                final double cardPadding = isMobile
                    ? 8.0
                    : (isSmallScreen ? 12.0 : 20.0);
                final double valueFontSize = isMobile
                    ? 16.0
                    : (isSmallScreen ? 18.0 : 20.0);
                final double titleFontSize = isMobile
                    ? 11.0
                    : (isSmallScreen ? 12.0 : 14.0);
                final double descFontSize = isMobile
                    ? 10.0
                    : (isSmallScreen ? 11.0 : 12.0);

                final cards = [
                  // Mother Buffaloes Cost
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [Colors.blue[900]!, Colors.blue[800]!],
                            )
                          : LinearGradient(
                              colors: [Colors.blue[50]!, Colors.white],
                            ),
                      border: Border.all(
                        color: isDark ? Colors.blue[700]! : Colors.blue[100]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(
                            ((treeData['units'] ?? 1) * 2 * 175000).toDouble(),
                          ),
                          style: TextStyle(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blue[100] : Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mother Buffaloes',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${treeData['units'] ?? 1} units × 2 mothers × ₹1.75L\n${((treeData['units'] ?? 1) * 2)} mother buffaloes @ ₹1.75L each',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: isDark ? Colors.blue[200] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CPF Cost
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [Colors.green[900]!, Colors.green[800]!],
                            )
                          : LinearGradient(
                              colors: [Colors.green[50]!, Colors.white],
                            ),
                      border: Border.all(
                        color: isDark ? Colors.green[700]! : Colors.green[100]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(
                            (((treeData['units'] ?? 1) * 13000).toDouble()),
                          ),
                          style: TextStyle(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.green[100]
                                : Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CPF Coverage',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${treeData['units'] ?? 1} units × ₹13,000\nOne CPF covers both M1 and M2 per unit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: isDark
                                ? Colors.green[200]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total Investment
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade600,
                          Colors.purple.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      children: [
                        Text(
                          formatCurrency(initialInvestment.toDouble()),
                          style: TextStyle(
                            fontSize: isMobile
                                ? 20
                                : 22, // Slightly larger than others
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Initial Investment',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((treeData['units'] ?? 1) * 4)} buffaloes total\n(2 mothers + 2 calves per unit)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Break-Even With CPF
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                Colors.orange[900]!,
                                Colors.orange[800]!,
                              ],
                            )
                          : LinearGradient(
                              colors: [Colors.orange[50]!, Colors.white],
                            ),
                      border: Border.all(
                        color: isDark
                            ? Colors.orange[700]!
                            : Colors.orange[100]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      children: [
                        Text(
                          breakEvenDateText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.orange[100]
                                : Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Break-Even with CPF',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Net cumulative revenue with CPF:\n${formatCurrency(finalCumulativeRevenueWithCPF)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: isDark
                                ? Colors.orange[200]
                                : Colors.grey[600],
                          ),
                        ),
                        if (monthsToBreakEvenWithCPF != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Achieved in $monthsToBreakEvenWithCPF months',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: descFontSize,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.deepOrange[200]
                                  : Colors.deepOrange[700],
                            ),
                          ),
                          Text(
                            '(${(monthsToBreakEvenWithCPF ~/ 12)} years and ${monthsToBreakEvenWithCPF % 12} months)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: descFontSize - 1,
                              color: isDark
                                  ? Colors.orange[200]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ];

                if (isMobile) {
                  // Stack vertically
                  return Column(
                    children: cards
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(width: double.infinity, child: c),
                          ),
                        )
                        .toList(),
                  );
                } else if (isSmallScreen) {
                  // 2x2 Grid
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 20),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 20),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Original 4 in a row
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
            const SizedBox(height: 32),

            // Break-Even Details (Timeline + Investment Recovery Progress)
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 900;

                final timelineCard = Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Break-Even Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Start Date:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                          Text(
                            '${monthNames[treeData['startMonth'] ?? 0]} ${treeData['startDay'] ?? 1}, ${treeData['startYear'] ?? startYear}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (exactBreakEvenDateWithCPF != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Break-Even Date:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                            ),
                            Text(
                              breakEvenDateText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.green[300]
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (monthsToBreakEvenWithCPF != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Time to Break-Even:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                '$monthsToBreakEvenWithCPF months',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.indigo[300]
                                      : Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Cumulative Revenue:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                            ),
                            Text(
                              formatCurrency(finalCumulativeRevenueWithCPF),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.green[300]
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );

                final recoveryCard = Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Investment Recovery Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Initial Investment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(initialInvestment.toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value:
                            1.0, // Always full for initial investment reference
                        backgroundColor: isDark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.grey[500]! : Colors.grey[400]!,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (exactBreakEvenDateWithCPF != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Recovered at Break-Even',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatCurrency(initialInvestment.toDouble()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.green[300]
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: isDark
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.green[400]! : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Final Cumulative Revenue',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(finalCumulativeRevenueWithCPF),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.deepPurple[200]
                                  : Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: initialInvestment > 0
                            ? (finalCumulativeRevenueWithCPF /
                                      initialInvestment)
                                  .clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: isDark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.deepPurple[300]! : Colors.deepPurple,
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
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (isSmallScreen) {
                  return Column(
                    children: [
                      timelineCard,
                      const SizedBox(height: 16),
                      recoveryCard,
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: timelineCard),
                      const SizedBox(width: 16),
                      Expanded(child: recoveryCard),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Break-Even Timeline Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
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
                                    ? (finalCombinedValue / initialInvestment) *
                                          100
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
                                      (yearData['cumulativeRevenueWithCPF']
                                              as num?)
                                          ?.toInt() ??
                                      0;
                                  final assetValue =
                                      yearData['assetValue'] ?? 0.0;
                                  final totalValueWithCPF =
                                      yearData['totalValueWithCPF'] ?? 0.0;
                                  final isRevenueBreakEven =
                                      yearData['isRevenueBreakEvenWithCPF'] ??
                                      false;

                                  final recovery =
                                      _calculateInvestmentRecoveryStatus(
                                        cumulativeRevenue,
                                        initialInvestment,
                                        isRevenueBreakEven,
                                      );

                                  final recoveryPercentage =
                                      (recovery['recoveryPercentage']
                                          as double);
                                  final status = (recovery['status'] as String);

                                  rows.add(
                                    DataRow(
                                      color: WidgetStatePropertyAll(
                                        isRevenueBreakEven
                                            ? (isDark
                                                  ? Colors.green[900]
                                                  : Colors.green[50])
                                            : null,
                                      ),
                                      cells: [
                                        DataCell(
                                          Center(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  year.toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                                if (isRevenueBreakEven)
                                                  Center(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.green[800]
                                                            : Colors.green[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '⭐ Break-Even',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? Colors.green[100]
                                                              : Colors.green[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  formatCurrency(
                                                    annualRevenue.toDouble(),
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.green[300]
                                                        : Colors.green,
                                                  ),
                                                ),
                                                Text(
                                                  'CPF: -${formatCurrency((yearData['cpfCost'] as int? ?? 0).toDouble())}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              formatCurrency(
                                                cumulativeRevenue.toDouble(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.blue[300]
                                                    : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              formatCurrency(
                                                assetValue.toDouble(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.deepPurple[300]
                                                    : Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              formatCurrency(
                                                totalValueWithCPF.toDouble(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.indigo[300]
                                                    : Colors.indigo,
                                              ),
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
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                      child: LinearProgressIndicator(
                                                        value:
                                                            (recoveryPercentage /
                                                                    100)
                                                                .clamp(
                                                                  0.0,
                                                                  1.0,
                                                                ),
                                                        backgroundColor: isDark
                                                            ? Colors.grey[700]
                                                            : Colors.grey[200],
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          recoveryPercentage >=
                                                                  100
                                                              ? (isDark
                                                                    ? Colors
                                                                          .green[400]!
                                                                    : Colors
                                                                          .green[500]!)
                                                              : (isDark
                                                                    ? Colors
                                                                          .blue[400]!
                                                                    : Colors
                                                                          .blue[500]!),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${recoveryPercentage.toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      status.contains(
                                                        'Break-Even',
                                                      )
                                                      ? (isDark
                                                            ? Colors.green[900]
                                                            : Colors.green[100])
                                                      : status.contains('75%')
                                                      ? (isDark
                                                            ? Colors.yellow[900]
                                                            : Colors
                                                                  .yellow[100])
                                                      : status.contains('50%')
                                                      ? (isDark
                                                            ? Colors.blue[900]
                                                            : Colors.blue[100])
                                                      : (isDark
                                                            ? Colors.grey[800]
                                                            : Colors.grey[100]),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        status.contains(
                                                          'Break-Even',
                                                        )
                                                        ? (isDark
                                                              ? Colors
                                                                    .green[100]
                                                              : Colors
                                                                    .green[800])
                                                        : status.contains('75%')
                                                        ? (isDark
                                                              ? Colors
                                                                    .yellow[100]
                                                              : Colors
                                                                    .yellow[800])
                                                        : status.contains('50%')
                                                        ? (isDark
                                                              ? Colors.blue[100]
                                                              : Colors
                                                                    .blue[800])
                                                        : (isDark
                                                              ? Colors.grey[300]
                                                              : Colors
                                                                    .grey[600]),
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
                                        Center(
                                          child: Text(
                                            'FINAL TOTALS',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                formatCurrency(
                                                  totalAnnualRevenueWithCPF,
                                                ),
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
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            formatCurrency(
                                              finalCumulativeRevenueWithCPF,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.indigoAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            formatCurrency(finalAssetValue),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.deepPurpleAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                formatCurrency(
                                                  finalCombinedValue,
                                                ),
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
                                      ),
                                      DataCell(
                                        Center(
                                          child: Column(
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
                                      ),
                                    ],
                                  ),
                                );

                                return DataTable(
                                  dataRowMaxHeight: 55,
                                  dataRowMinHeight: 40,
                                  headingRowColor: 
                                  WidgetStateProperty.all(
                                    isDark ? Colors.grey[800] : Colors.blue[50],
                                  ),
                                  columnSpacing: 16,
                                  columns: [
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          
                                          'Year',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          'Annual Revenue (Net)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          'Cumulative (Net)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          'Asset Market Value',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          'Total Value (Rev + Asset)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      headingRowAlignment: MainAxisAlignment.center,
                                      label: Center(
                                        child: Text(
                                          'Investment Recovery',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: rows,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
