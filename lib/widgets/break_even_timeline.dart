import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';
import 'reusable_pluto_grid.dart';

class BreakEvenTimelineWidget extends StatelessWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> breakEvenAnalysis;
  final List<String> monthNames;
  final String Function(double) formatCurrency;
  final String Function(int) formatNumber;
  final bool includeCPF;

  const BreakEvenTimelineWidget({
    Key? key,
    required this.treeData,
    required this.breakEvenAnalysis,
    required this.monthNames,
    required this.formatCurrency,
    required this.formatNumber,
    this.includeCPF = true,
  }) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Break-even analysis data
    // Select correct keys based on toggle
    final exactBreakEvenDate = includeCPF
        ? breakEvenAnalysis['exactBreakEvenDateWithCPF'] as DateTime?
        : breakEvenAnalysis['exactBreakEvenDateWithoutCPF']
              as DateTime?; // Note: WithoutCPF key needs to exist

    final breakEvenMonth = includeCPF
        ? breakEvenAnalysis['breakEvenMonthWithCPF'] as int? ?? 0
        : breakEvenAnalysis['breakEvenMonthWithoutCPF'] as int? ?? 0;

    final breakEvenYear = includeCPF
        ? breakEvenAnalysis['breakEvenYearWithCPF'] as int?
        : breakEvenAnalysis['breakEvenYearWithoutCPF'] as int?;

    final finalCumulativeRevenue = includeCPF
        ? breakEvenAnalysis['finalCumulativeRevenueWithCPF'] ?? 0.0
        : breakEvenAnalysis['finalCumulativeRevenueWithoutCPF'] ?? 0.0;

    // ALIASES for backward compatibility with existing UI code
    final exactBreakEvenDateWithCPF = exactBreakEvenDate;
    final breakEvenMonthWithCPF = breakEvenMonth;
    final breakEvenYearWithCPF = breakEvenYear;
    final finalCumulativeRevenueWithCPF = finalCumulativeRevenue;

    final initialInvestment = breakEvenAnalysis['initialInvestment'] ?? 0;
    final breakEvenData =
        breakEvenAnalysis['breakEvenData'] as List<dynamic>? ?? [];

    // Tree data for calculation
    final startYear = treeData['startYear'] ?? DateTime.now().year;
    final startMonth = treeData['startMonth'] ?? 0;

    // Calculate months to break-even (Total Duration)
    final monthsToBreakEven = (breakEvenYear != null)
        ? ((breakEvenYear - startYear) * 12) + (breakEvenMonth - startMonth) + 1
        : 0;

    final startDay = treeData['startDay'] ?? 1;
    final units = treeData['units'] ?? 1;
    final years = treeData['years'] ?? 10;

    final startDateFormatted =
        '${monthNames[startMonth]} $startDay, $startYear';
    final yearRange = '$startYear-${startYear + years - 1}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        final isMobile = constraints.maxWidth < 600;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? Colors.green[900]! : Colors.green[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main Heading with Badge
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Break-Even Timeline Analysis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green[900]!.withValues(alpha: 0.3)
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'With CPF',
                          style: TextStyle(
                            color: isDark
                                ? Colors.green[300]
                                : Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Investment Summary & Achievement Cards Grid
                if (isSmallScreen)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Investment Summary Card (Mobile)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[700]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'INVESTMENT SUMMARY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Projection Settings',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Use Wrap or Column for inner items on mobile
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width:
                                      (constraints.maxWidth -
                                          (isMobile ? 40 : 80) -
                                          40 -
                                          12) /
                                      2, // constrained width
                                  child: _buildInvestmentSummaryBox(
                                    context: context,
                                    title: 'Start Date',
                                    value: startDateFormatted,
                                    color: Colors.green,
                                    isMobile: isMobile,
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      (constraints.maxWidth -
                                          (isMobile ? 40 : 80) -
                                          40 -
                                          12) /
                                      2,
                                  child: _buildInvestmentSummaryBox(
                                    context: context,
                                    title: 'Initial Investment',
                                    value: formatCurrency(
                                      initialInvestment.toDouble(),
                                    ),
                                    color: Colors.green,
                                    isMobile: isMobile,
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      (constraints.maxWidth -
                                          (isMobile ? 40 : 80) -
                                          40 -
                                          12) /
                                      2,
                                  child: _buildInvestmentSummaryBox(
                                    context: context,
                                    title: 'Units',
                                    value: units.toString(),
                                    color: Colors.indigo,
                                    isMobile: isMobile,
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      (constraints.maxWidth -
                                          (isMobile ? 40 : 80) -
                                          40 -
                                          12) /
                                      2,
                                  child: _buildInvestmentSummaryBox(
                                    context: context,
                                    title: 'Projection Period',
                                    value: yearRange,
                                    color: Colors.purple,
                                    isMobile: isMobile,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Break-Even Achievement Card (Mobile)
                      if (exactBreakEvenDateWithCPF != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Your Investment is Now Risk-Free!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Break-Even WITH CPF Achieved on ${_formatDate(exactBreakEvenDateWithCPF)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            (isMobile ? 40 : 80) -
                                            40 -
                                            12) /
                                        2,
                                    child: _buildAchievementBox(
                                      title:
                                          'In Just $monthsToBreakEven Months\n(${(monthsToBreakEven ~/ 12)} years and ${monthsToBreakEven % 12} months)',
                                      label: '',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            (isMobile ? 40 : 80) -
                                            40 -
                                            12) /
                                        2,
                                    child: _buildAchievementBox(
                                      title:
                                          'Year ${exactBreakEvenDateWithCPF.year - startYear + 1}\nMonth ${breakEvenMonthWithCPF + 1}',
                                      label: 'Investment Cycle',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            (isMobile ? 40 : 80) -
                                            40 -
                                            12) /
                                        2,
                                    child: _buildAchievementBox(
                                      title: formatCurrency(
                                        finalCumulativeRevenueWithCPF,
                                      ),
                                      label: 'Net Cumulative Revenue',
                                      subtitle: 'Total net milk sales to date',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            (isMobile ? 40 : 80) -
                                            40 -
                                            12) /
                                        2,
                                    child: _buildAchievementBox(
                                      title: formatCurrency(
                                        initialInvestment.toDouble(),
                                      ),
                                      label: 'Initial Investment',
                                      subtitle: 'Fully recovered!',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 2.0,
                    ),
                    children: [
                      // Investment Summary Card (Desktop)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[700]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'INVESTMENT SUMMARY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Projection Settings',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GridView(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 3,
                                    ),
                                children: [
                                  _buildInvestmentSummaryBox(
                                    title: 'Start Date',
                                    value: startDateFormatted,
                                    color: Colors.green,
                                    isMobile: isMobile,
                                    context: context,
                                  ),
                                  _buildInvestmentSummaryBox(
                                    title: 'Initial Investment',
                                    value: formatCurrency(
                                      initialInvestment.toDouble(),
                                    ),
                                    color: Colors.green,
                                    isMobile: isMobile,
                                    context: context,
                                  ),
                                  _buildInvestmentSummaryBox(
                                    title: 'Units',
                                    value: units.toString(),
                                    color: Colors.indigo,
                                    isMobile: isMobile,
                                    context: context,
                                  ),
                                  _buildInvestmentSummaryBox(
                                    title: 'Projection Period',
                                    value: yearRange,
                                    color: Colors.purple,
                                    isMobile: isMobile,
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Break-Even Achievement Card (Desktop)
                      if (exactBreakEvenDateWithCPF != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[700]!),
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Your Investment is Now Risk-Free!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Break-Even WITH CPF Achieved on ${_formatDate(exactBreakEvenDateWithCPF)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: GridView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 3,
                                      ),
                                  children: [
                                    _buildAchievementBox(
                                      title:
                                          'In Just $monthsToBreakEven Months\n(${(monthsToBreakEven ~/ 12)} years and ${monthsToBreakEven % 12} months)',
                                      label: '',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                    _buildAchievementBox(
                                      title:
                                          'Year ${exactBreakEvenDateWithCPF.year - startYear + 1}\nMonth ${breakEvenMonthWithCPF + 1}',
                                      label: 'Investment Cycle',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                    _buildAchievementBox(
                                      title: formatCurrency(
                                        finalCumulativeRevenueWithCPF,
                                      ),
                                      label: 'Net Cumulative Revenue',
                                      subtitle: 'Total net milk sales to date',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                    _buildAchievementBox(
                                      title: formatCurrency(
                                        initialInvestment.toDouble(),
                                      ),
                                      label: 'Initial Investment',
                                      subtitle: 'Fully recovered!',
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Break-Even Details & Recovery Progress - Side by Side
                if (isSmallScreen)
                  Column(
                    children: [
                      // Break-Even Timeline Details
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break-Even Timeline',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              'Start Date:',
                              startDateFormatted,
                              isMobile: isMobile,
                              context: context,
                            ),
                            if (exactBreakEvenDateWithCPF != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Break-Even Date:',
                                _formatDate(exactBreakEvenDateWithCPF),
                                valueColor: Colors.green[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Time to Break-Even:',
                                '$monthsToBreakEven months',
                                valueColor: Colors.indigo[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Net Cumulative Revenue:',
                                formatCurrency(finalCumulativeRevenueWithCPF),
                                valueColor: Colors.green[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Investment Recovery Progress
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Investment Recovery Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildProgressBar(
                              label: 'Initial Investment',
                              amount: formatCurrency(
                                initialInvestment.toDouble(),
                              ),
                              percentage: 100.0,
                              color: Colors.grey[400]!,
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            if (exactBreakEvenDateWithCPF != null)
                              _buildProgressBar(
                                label: 'Recovered at Break-Even',
                                amount: formatCurrency(
                                  initialInvestment.toDouble(),
                                ),
                                percentage: 100.0,
                                color: Colors.green[500]!,
                                context: context,
                              ),
                            const SizedBox(height: 16),
                            _buildProgressBar(
                              label: 'Final Cumulative Revenue',
                              amount: formatCurrency(
                                finalCumulativeRevenueWithCPF,
                              ),
                              percentage:
                                  (finalCumulativeRevenueWithCPF /
                                      (initialInvestment == 0
                                          ? 1
                                          : initialInvestment)) *
                                  100,
                              color: Colors.purple[500]!,
                              showPercentage: true,
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 2.0,
                    ),
                    children: [
                      // Break-Even Timeline Details
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break-Even Timeline',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // const SizedBox(height: 20),
                            _buildDetailRow(
                              'Start Date:',
                              startDateFormatted,
                              isMobile: isMobile,
                              context: context,
                            ),
                            if (exactBreakEvenDateWithCPF != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Break-Even Date:',
                                _formatDate(exactBreakEvenDateWithCPF),
                                valueColor: Colors.green[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Time to Break-Even:',
                                '$monthsToBreakEven months',
                                valueColor: Colors.indigo[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Net Cumulative Revenue:',
                                formatCurrency(finalCumulativeRevenueWithCPF),
                                valueColor: Colors.green[700],
                                isMobile: isMobile,
                                context: context,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Investment Recovery Progress
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Investment Recovery Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            // const SizedBox(height: 10),
                            _buildProgressBar(
                              label: 'Initial Investment',
                              amount: formatCurrency(
                                initialInvestment.toDouble(),
                              ),
                              percentage: 100.0,
                              color: Colors.grey[400]!,
                              context: context,
                            ),
                            // const SizedBox(height: 10),
                            if (exactBreakEvenDateWithCPF != null)
                              _buildProgressBar(
                                label: 'Recovered at Break-Even',
                                amount: formatCurrency(
                                  initialInvestment.toDouble(),
                                ),
                                percentage: 100.0,
                                color: Colors.green[500]!,
                                context: context,
                              ),
                            // const SizedBox(height: 10),
                            _buildProgressBar(
                              label: 'Final Cumulative Revenue',
                              amount: formatCurrency(
                                finalCumulativeRevenueWithCPF,
                              ),
                              percentage:
                                  (finalCumulativeRevenueWithCPF /
                                      (initialInvestment == 0
                                          ? 1
                                          : initialInvestment)) *
                                  100,
                              color: Colors.purple[500]!,
                              showPercentage: true,
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Main Break-Even Table with Footer
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Break-Even Timeline ($yearRange) - With CPF',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _buildBreakEvenTable(
                        breakEvenData: breakEvenData,
                        initialInvestment: initialInvestment,
                        startYear: startYear,
                        exactBreakEvenDateWithCPF: exactBreakEvenDateWithCPF,
                        context: context,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvestmentSummaryBox({
    required String title,
    required String value,
    required MaterialColor color,
    bool isMobile = false,
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBox({
    required String title,
    required String label,
    String? subtitle,
    bool isMobile = false,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[800],
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 8 : 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          if (label.isNotEmpty) const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: isDark ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isMobile ? 7 : 8,
                color: isDark ? Colors.grey[400] : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMobile = false,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : Colors.grey[900]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required String amount,
    required double percentage,
    required Color color,
    bool showPercentage = false,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cap percentage at 100 for visual bar, but show actual for text if needed
    final visualPercentage = percentage > 100.0 ? 100.0 : percentage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (showPercentage)
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: visualPercentage / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakEvenTable({
    required List<dynamic> breakEvenData,
    required dynamic initialInvestment,
    required int startYear,
    required DateTime? exactBreakEvenDateWithCPF,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- Calculate Totals ---
    double totalRevenue = 0;
    double totalCPF = 0;
    for (var item in breakEvenData) {
      totalRevenue += (item['annualRevenueWithCPF'] as num? ?? 0).toDouble();
      totalCPF += (item['cpfCost'] as num? ?? 0).toDouble();
    }

    final lastItem = breakEvenData.isNotEmpty
        ? breakEvenData.last
        : <String, dynamic>{};
    final finalCumulative = (lastItem['cumulativeRevenueWithCPF'] as num? ?? 0)
        .toDouble();
    final finalAsset = (lastItem['assetValue'] as num? ?? 0).toDouble();
    final finalTotalValue = (lastItem['totalValueWithCPF'] as num? ?? 0)
        .toDouble();
    final double initialInvDouble = (initialInvestment is num)
        ? initialInvestment.toDouble()
        : 0.0;
    final roi = initialInvDouble > 0
        ? ((finalTotalValue - initialInvDouble) / initialInvDouble) * 100
        : 0.0;
    // ------------------------

    final columns = [
      PlutoColumnBuilder.customColumn(
        title: 'Year',
        field: 'year',
        width: 120,
        renderer: (ctx) {
          final val = ctx.cell.value.toString();
          final isTotal = val == 'TOTAL';
          return Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            color: isTotal
                ? (isDark ? Colors.grey[800] : Colors.grey[200])
                : null,
            child: Text(
              val,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          );
        },
      ),
      PlutoColumnBuilder.customColumn(
        title: 'Annual Revenue (Net)',
        field: 'annualRevenueWithCPF',
        width: 160,
        renderer: (ctx) {
          final val = ctx.cell.value;
          final cpfCost = ctx.row.cells['cpfCost']?.value ?? 0;
          final isBreakEvenRow =
              ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          final isTotal = ctx.row.cells['year']?.value == 'TOTAL';

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(
                    color: Colors.green[50],
                    border: Border(
                      left: BorderSide(color: Colors.green[500]!, width: 4),
                    ),
                  )
                : (isTotal
                      ? BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        )
                      : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatCurrency((val as num).toDouble()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTotal
                        ? (isDark ? Colors.greenAccent : Colors.green[800])
                        : Colors.green,
                    fontSize: isTotal ? 15 : 14,
                  ),
                ),
                Text(
                  'CPF: -${formatCurrency((cpfCost as num).toDouble())}',
                  style: TextStyle(fontSize: 11, color: Colors.amber[600]),
                ),
              ],
            ),
          );
        },
      ),
      PlutoColumnBuilder.customColumn(
        title: 'Cumulative (Net)',
        field: 'cumulativeRevenueWithCPF',
        width: 140,
        renderer: (ctx) {
          final val = ctx.cell.value;
          final isBreakEvenRow =
              ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          final isTotal = ctx.row.cells['year']?.value == 'TOTAL';

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(color: Colors.green[50])
                : (isTotal
                      ? BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        )
                      : null),
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          );
        },
      ),
      PlutoColumnBuilder.customColumn(
        title: 'Asset Market Value',
        field: 'assetValue',
        width: 150,
        renderer: (ctx) {
          final val = ctx.cell.value;
          final isBreakEvenRow =
              ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          final isTotal = ctx.row.cells['year']?.value == 'TOTAL';

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(color: Colors.green[50])
                : (isTotal
                      ? BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        )
                      : null),
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          );
        },
      ),
      PlutoColumnBuilder.customColumn(
        title: 'Total Value (Rev + Asset)',
        field: 'totalValueWithCPF',
        width: 170,
        renderer: (ctx) {
          final val = ctx.cell.value;
          final isBreakEvenRow =
              ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          final isTotal = ctx.row.cells['year']?.value == 'TOTAL';

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(color: Colors.green[50])
                : (isTotal
                      ? BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        )
                      : null),
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          );
        },
      ),
      PlutoColumnBuilder.customColumn(
        title: 'Investment Recovery',
        field: 'recoveryPercentageWithCPF',
        width: 180,
        renderer: (ctx) {
          final percentage = ctx.cell.value as num;
          final status =
              ctx.row.cells['statusWithCPF']?.value as String? ?? 'in Progress';
          final isBreakEvenRow =
              ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          final isTotal = ctx.row.cells['year']?.value == 'TOTAL';

          if (isTotal) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROI: ${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Initial: ${formatCurrency(initialInvDouble)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final color = status.contains('Break-Even')
              ? Colors.green[500]
              : status.contains('75%')
              ? Colors.blue[500]
              : status.contains('50%')
              ? Colors.indigo[400]
              : Colors.grey[400];

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(color: Colors.green[50])
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% recovered',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: math.min(percentage / 100.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color ?? Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isBreakEvenRow)
                  Container(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 10, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Break-Even Achieved',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];

    final rows = (breakEvenData).asMap().entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      final year = data['year'] as int;
      final isBreakEvenRow = data['isBreakEvenWithCPF'] == true;
      final yearDisplay = year == startYear
          ? '$year\nYear 1'
          : '$year\nYear ${entry.key + 1}';

      return PlutoRow(
        cells: {
          'year': PlutoCell(value: yearDisplay),
          'annualRevenueWithCPF': PlutoCell(
            value: data['annualRevenueWithCPF'] ?? 0,
          ),
          'cpfCost': PlutoCell(value: data['cpfCost'] ?? 0),
          'cumulativeRevenueWithCPF': PlutoCell(
            value: data['cumulativeRevenueWithCPF'] ?? 0,
          ),
          'assetValue': PlutoCell(value: data['assetValue'] ?? 0),
          'totalValueWithCPF': PlutoCell(value: data['totalValueWithCPF'] ?? 0),
          'recoveryPercentageWithCPF': PlutoCell(
            value: data['recoveryPercentageWithCPF'] ?? 0,
          ),
          'statusWithCPF': PlutoCell(
            value: data['statusWithCPF'] ?? 'in Progress',
          ),
          'isBreakEvenWithCPF': PlutoCell(value: isBreakEvenRow),
        },
      );
    }).toList();

    // Append Total Row
    rows.add(
      PlutoRow(
        cells: {
          'year': PlutoCell(value: 'TOTAL'),
          'annualRevenueWithCPF': PlutoCell(value: totalRevenue),
          'cpfCost': PlutoCell(value: totalCPF),
          'cumulativeRevenueWithCPF': PlutoCell(value: finalCumulative),
          'assetValue': PlutoCell(value: finalAsset),
          'totalValueWithCPF': PlutoCell(value: finalTotalValue),
          'recoveryPercentageWithCPF': PlutoCell(value: roi),
          'statusWithCPF': PlutoCell(value: 'ROI'),
          'isBreakEvenWithCPF': PlutoCell(value: false),
        },
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        if (isSmallScreen) {
          // Mobile: Use simpler DataTable
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? Colors.blue[900]!.withValues(alpha: 0.3)
                      : Colors.blue[50],
                ),
                headingRowHeight: 60,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                columnSpacing: 12, // reduce spacing slightly
                horizontalMargin: 8,
                columns: [
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Expanded(
                      child: Text(
                        'Year\nMonth',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text(
                      'Revenue (Net)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text(
                      'Cumulative',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text(
                      'Asset Value',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text(
                      'Total Value',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text(
                      'Recovery %',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                ],
                rows: [
                  ...breakEvenData.asMap().entries.map((entry) {
                    final data = entry.value as Map<String, dynamic>;
                    final year = data['year'] as int;
                    final isBreakEvenRow = data['isBreakEvenWithCPF'] == true;
                    final yearDisplay = year == startYear
                        ? 'Y1 ($year)'
                        : 'Y${entry.key + 1} ($year)';
                    final recoveryPct = data['recoveryPercentageWithCPF'] ?? 0;

                    return DataRow(
                      color: isBreakEvenRow
                          ? WidgetStateProperty.all(Colors.green[50])
                          : null,
                      cells: [
                        DataCell(
                          Align(
                            child: Text(
                              yearDisplay,
                              style: TextStyle(
                                fontWeight: isBreakEvenRow
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency(
                              (data['annualRevenueWithCPF'] as num? ?? 0)
                                  .toDouble(),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency(
                              (data['cumulativeRevenueWithCPF'] as num? ?? 0)
                                  .toDouble(),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency(
                              (data['assetValue'] as num? ?? 0).toDouble(),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency(
                              (data['totalValueWithCPF'] as num? ?? 0)
                                  .toDouble(),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(recoveryPct as num).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBreakEvenRow ? Colors.green[700] : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  DataRow(
                    color: WidgetStateProperty.all(
                      isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    cells: [
                      DataCell(
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatCurrency(totalRevenue),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatCurrency(finalCumulative),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatCurrency(finalAsset),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatCurrency(finalTotalValue),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          'ROI: ${roi.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Desktop: Use PlutoGrid with custom renderers
        return SizedBox(
          width: constraints.maxWidth,
          child: ReusablePlutoGrid(
            columns: columns,
            rows: rows,
            gridId: 'break_even_timeline_table',
            height: math.max(300, rows.length * 100.0 + 60),
            rowHeight: 100,
            onLoaded: null,
            mode: PlutoGridMode.normal,
          ),
        );
      },
    );
  }
}
