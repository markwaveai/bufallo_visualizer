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

  const BreakEvenTimelineWidget({
    Key? key,
    required this.treeData,
    required this.breakEvenAnalysis,
    required this.monthNames,
    required this.formatCurrency,
    required this.formatNumber,
  }) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Break-even analysis data
    final exactBreakEvenDateWithCPF = breakEvenAnalysis['exactBreakEvenDateWithCPF'] as DateTime?;
    final breakEvenMonthWithCPF = breakEvenAnalysis['breakEvenMonthWithCPF'] as int? ?? 0;
    final finalCumulativeRevenueWithCPF = breakEvenAnalysis['finalCumulativeRevenueWithCPF'] ?? 0.0;
    final initialInvestment = breakEvenAnalysis['initialInvestment'] ?? 0;
    final breakEvenData = breakEvenAnalysis['breakEvenData'] as List<dynamic>? ?? [];

    // Calculate months to break-even (using month index difference)
    final monthsToBreakEven = breakEvenMonthWithCPF; // This is 0-based months passed

    // Calculate totals for footer
    final totalAnnualRevenue = breakEvenData.fold<double>(
        0.0,
        (sum, data) => sum + ((data as Map<String, dynamic>)['annualRevenueWithCPF'] as num).toDouble());

    final totalCPFCost = breakEvenData.fold<double>(
        0.0,
        (sum, data) => sum + ((data as Map<String, dynamic>)['cpfCost'] as num).toDouble());

    final finalAssetValue = breakEvenData.isNotEmpty
        ? (breakEvenData.last as Map<String, dynamic>)['assetValue'] as num
        : 0;

    final totalValue = finalCumulativeRevenueWithCPF + finalAssetValue.toDouble();
    final roiPercentage = initialInvestment > 0
        ? (totalValue / initialInvestment) * 100
        : 0;

    // Tree data
    final startYear = treeData['startYear'] ?? DateTime.now().year;
    final startMonth = treeData['startMonth'] ?? 0;
    final startDay = treeData['startDay'] ?? 1;
    final units = treeData['units'] ?? 1;
    final years = treeData['years'] ?? 10;

    final startDateFormatted = '${monthNames[startMonth]} $startDay, $startYear';
    final yearRange = '$startYear-${startYear + years - 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Heading with Badge
            Center(
              child: Column(
                children: [
                  const Text(
                    'Break-Even Timeline Analysis',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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

            // Investment Summary & Achievement Cards Grid
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.0,
              ),
              children: [
                // Investment Summary Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                            ),
                            _buildInvestmentSummaryBox(
                              title: 'Initial Investment',
                              value: formatCurrency(initialInvestment.toDouble()),
                              color: Colors.green,
                            ),
                            _buildInvestmentSummaryBox(
                              title: 'Units',
                              value: units.toString(),
                              color: Colors.indigo,
                            ),
                            _buildInvestmentSummaryBox(
                              title: 'Projection Period',
                              value: yearRange,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Break-Even Achievement Card
                if (exactBreakEvenDateWithCPF != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Break-Even WITH CPF Achieved on ${_formatDate(exactBreakEvenDateWithCPF)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3,
                            ),
                            children: [
                              _buildAchievementBox(
                                title:
                                    'In Just $monthsToBreakEven Months\n(${(monthsToBreakEven ~/ 12)} years and ${monthsToBreakEven % 12} months)',
                                label: '',
                              ),
                              _buildAchievementBox(
                                title:
                                    'Year ${exactBreakEvenDateWithCPF.year - startYear + 1}\nMonth ${breakEvenMonthWithCPF + 1}',
                                label: 'Investment Cycle',
                              ),
                              _buildAchievementBox(
                                title: formatCurrency(finalCumulativeRevenueWithCPF),
                                label: 'Net Cumulative Revenue',
                                subtitle: 'Total net milk sales to date',
                              ),
                              _buildAchievementBox(
                                title: formatCurrency(initialInvestment.toDouble()),
                                label: 'Initial Investment',
                                subtitle: 'Fully recovered!',
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
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 3,
              ),
              children: [
                // Break-Even Timeline Details
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        'Start Date:',
                        startDateFormatted,
                      ),
                      if (exactBreakEvenDateWithCPF != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Break-Even Date:',
                          _formatDate(exactBreakEvenDateWithCPF),
                          valueColor: Colors.green[700],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Time to Break-Even:',
                          '$monthsToBreakEven months',
                          valueColor: Colors.indigo[700],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Net Cumulative Revenue:',
                          formatCurrency(finalCumulativeRevenueWithCPF),
                          valueColor: Colors.green[700],
                        ),
                      ],
                    ],
                  ),
                ),

                // Investment Recovery Progress
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildProgressBar(
                        label: 'Initial Investment',
                        amount: formatCurrency(initialInvestment.toDouble()),
                        percentage: 100.0,
                        color: Colors.grey[400]!,
                      ),
                      const SizedBox(height: 16),
                      if (exactBreakEvenDateWithCPF != null)
                        _buildProgressBar(
                          label: 'Recovered at Break-Even',
                          amount: formatCurrency(initialInvestment.toDouble()),
                          percentage: 100.0,
                          color: Colors.green[500]!,
                        ),
                      const SizedBox(height: 16),
                      _buildProgressBar(
                        label: 'Final Cumulative Revenue',
                        amount: formatCurrency(finalCumulativeRevenueWithCPF),
                        percentage: (finalCumulativeRevenueWithCPF /
                                (initialInvestment == 0 ? 1 : initialInvestment)) *
                            100,
                        color: Colors.purple[500]!,
                        showPercentage: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Break-Even Table with Footer
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                  ),
                  // Table Footer
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTableFooter(
                        totalAnnualRevenue: totalAnnualRevenue,
                        totalCPFCost: totalCPFCost,
                        finalCumulativeRevenue: finalCumulativeRevenueWithCPF,
                        finalAssetValue: finalAssetValue.toDouble(),
                        totalValue: totalValue,
                        roiPercentage: roiPercentage,
                        initialInvestment: initialInvestment.toDouble(),
                      ),
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

  Widget _buildInvestmentSummaryBox({
    required String title,
    required String value,
    required MaterialColor color,
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
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color[300],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
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
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          if (label.isNotEmpty) const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[400],
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.grey[800],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: math.min(percentage / 100.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${percentage.toStringAsFixed(1)}% of initial',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableFooter({
    required double totalAnnualRevenue,
    required double totalCPFCost,
    required double finalCumulativeRevenue,
    required double finalAssetValue,
    required double totalValue,
    required double roiPercentage,
    required double initialInvestment,
  }) {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINAL TOTALS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(totalAnnualRevenue),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[300],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total CPF: ${formatCurrency(totalCPFCost)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                formatCurrency(finalCumulativeRevenue),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[300],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                formatCurrency(finalAssetValue),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[300],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(totalValue),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[300],
                    ),
                  ),
                  const SizedBox(height: 4),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROI',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${roiPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[300],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatCurrency(initialInvestment)} initial',
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
  }

  Widget _buildBreakEvenTable({
    required List<dynamic> breakEvenData,
    required dynamic initialInvestment,
    required int startYear,
    required DateTime? exactBreakEvenDateWithCPF,
  }) {
    final columns = [
      PlutoColumnBuilder.textColumn(title: 'Year', field: 'year', width: 120),
      PlutoColumnBuilder.customColumn(
        title: 'Annual Revenue (Net)',
        field: 'annualRevenueWithCPF',
        width: 160,
        renderer: (ctx) {
          final val = ctx.cell.value;
          final cpfCost = ctx.row.cells['cpfCost']?.value ?? 0;
          final isBreakEvenRow = ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(
                    color: Colors.green[50],
                    border: Border(
                      left: BorderSide(color: Colors.green[500]!, width: 4),
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatCurrency((val as num).toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'CPF: -${formatCurrency((cpfCost as num).toDouble())}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber[600],
                  ),
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
          final isBreakEvenRow = ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(
                    color: Colors.green[50],
                  )
                : null,
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
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
          final isBreakEvenRow = ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(
                    color: Colors.green[50],
                  )
                : null,
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
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
          final isBreakEvenRow = ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: isBreakEvenRow
                ? BoxDecoration(
                    color: Colors.green[50],
                  )
                : null,
            child: Text(
              formatCurrency((val as num).toDouble()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
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
          final status = ctx.row.cells['statusWithCPF']?.value as String? ??
              'in Progress';
          final isBreakEvenRow = ctx.row.cells['isBreakEvenWithCPF']?.value == true;
          
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
                ? BoxDecoration(
                    color: Colors.green[50],
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% recovered',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
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
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.green[700]),
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
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color?.withOpacity(0.1),
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
          'totalValueWithCPF': PlutoCell(
            value: data['totalValueWithCPF'] ?? 0,
          ),
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

    return ReusablePlutoGrid(
      columns: columns,
      rows: rows,
      gridId: 'break_even_timeline_table',
      height: 800,
      rowHeight: 100,
      onLoaded: null,
      mode: PlutoGridMode.normal,
    );
  }
}