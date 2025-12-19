import 'package:flutter/material.dart';

class AnnualHerdRevenueWidget extends StatelessWidget {
  final List<dynamic> cumulativeYearlyData;
  final String Function(double) formatCurrency;
  final String Function(int) formatNumber;
  final Map<String, dynamic> treeData;
  final int startYear;
  final int endYear;
  final String yearRange;

  const AnnualHerdRevenueWidget({
    Key? key,
    required this.cumulativeYearlyData,
    required this.formatCurrency,
    required this.formatNumber,
    required this.treeData,
    required this.startYear,
    required this.endYear,
    required this.yearRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        final isMobile = constraints.maxWidth < 600;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 0: (isSmallScreen ? 24 : 40),
              vertical: isMobile ? 12 : 20,
            ),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Annual Herd Revenue Analysis',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : (isSmallScreen ? 20 : 24),
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green[900]!.withValues(alpha: 0.3)
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'with CPF',
                          style: TextStyle(
                            color: isDark
                                ? Colors.green[300]
                                : Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 32),

                // Table
                Container(
                  width: double.infinity, // Full width
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.blue[900]!.withValues(alpha: 0.3)
                              : Colors.indigo[100],
                        ),
                        dataRowHeight: 70, // Increased cell height
                        columnSpacing: isMobile ? 8 : 20,
                        columns: [
                          DataColumn(
                            headingRowAlignment: MainAxisAlignment.center,
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Year',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Timeline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            headingRowAlignment: MainAxisAlignment.center,
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Buffaloes',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            headingRowAlignment: MainAxisAlignment.center,
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Annual Revenue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'With CPF Deduction',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        rows: List.generate(cumulativeYearlyData.length, (
                          index,
                        ) {
                          final data =
                              cumulativeYearlyData[index]
                                  as Map<String, dynamic>;
                          final year = data['year'] as int;
                          final totalBuffaloes =
                              data['totalBuffaloes'] as int? ?? 0;

                          // Support both structures:
                          // - cumulativeYearlyData from break-even analysis
                          //   with 'revenueWithCPF' as num
                          // - breakEvenData rows with 'annualRevenueWithCPF' as num
                          final annualRevenueNum =
                              (data['revenueWithCPF'] ??
                                      data['annualRevenueWithCPF'] ??
                                      0)
                                  as num;
                          final annualRevenue = annualRevenueNum.toDouble();

                          final prevAnnualRevenueNum = index > 0
                              ? (((cumulativeYearlyData[index - 1]
                                            as Map<
                                              String,
                                              dynamic
                                            >)['revenueWithCPF'] ??
                                        (cumulativeYearlyData[index - 1]
                                            as Map<
                                              String,
                                              dynamic
                                            >)['annualRevenueWithCPF'] ??
                                        0)
                                    as num)
                              : 0;

                          final growthRate =
                              index > 0 && prevAnnualRevenueNum != 0
                              ? ((annualRevenue - prevAnnualRevenueNum) /
                                    prevAnnualRevenueNum *
                                    100)
                              : 0.0;

                          final isPositiveGrowth = growthRate >= 0;
                          final growthColor = isPositiveGrowth
                              ? Colors.green
                              : Colors.red;

                          return DataRow(
                            cells: [
                              DataCell(
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.indigo[500]!,
                                              Colors.indigo[600]!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            year.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Year ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Column(
                                    
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatNumber(totalBuffaloes),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.indigo[200]
                                              : Colors.indigo,
                                        ),
                                      ),
                                      Text(
                                        'total buffaloes',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Column(
                                   
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCurrency(annualRevenue),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.green[300]
                                              : Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'CPF: -${formatCurrency(((data['cpfCost'] as num?) ?? 0).toDouble())}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (growthRate != 0)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isPositiveGrowth ? '↑' : '↓',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: growthColor,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${growthRate.abs().toStringAsFixed(1)}% growth',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: growthColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        // Footer
                        // Manually add footer after table
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer Row
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildFooterCell(
                          'Grand Total',
                          '${treeData['years'] ?? 10} Years ($yearRange)',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _buildFooterCell(
                          formatNumber(
                            (cumulativeYearlyData.isNotEmpty
                                    ? (cumulativeYearlyData.last
                                              as Map<
                                                String,
                                                dynamic
                                              >)['totalBuffaloes']
                                          as int?
                                    : 0) ??
                                0,
                          ),
                          'final herd size',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _buildFooterCell(
                          formatCurrency(
                            cumulativeYearlyData.fold<double>(0, (sum, data) {
                              final yearData = data as Map<String, dynamic>;
                              final revenueNum =
                                  (yearData['revenueWithCPF'] ??
                                          yearData['annualRevenueWithCPF'] ??
                                          0)
                                      as num;
                              return sum + revenueNum.toDouble();
                            }),
                          ),
                          'total net revenue',
                        ),
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

  Widget _buildFooterCell(String title, String subtitle) {
    return Center(
      child: Column(
       
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
