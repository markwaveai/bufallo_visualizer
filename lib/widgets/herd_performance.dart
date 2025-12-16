import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class HerdPerformanceWidget extends StatefulWidget {
  final List<Map<String, dynamic>> yearlyData;
  final String Function(num) formatNumber;

  const HerdPerformanceWidget({
    Key? key,
    required this.yearlyData,
    required this.formatNumber,
  }) : super(key: key);

  @override
  State<HerdPerformanceWidget> createState() => _HerdPerformanceWidgetState();
}

class _HerdPerformanceWidgetState extends State<HerdPerformanceWidget> {
  late TooltipBehavior _tooltipBehavior;
  bool _showProducingBreakdown = false;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.yearlyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        padding: isMobile?EdgeInsets.all(0): EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Toggle
            Center(
              child: Column(
                children: [
                  Text(
                    'Herd Performance Analysis',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _showProducingBreakdown,
                          onChanged: (value) {
                            setState(() => _showProducingBreakdown = value);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Total Buffalo Growth Chart
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Total Buffalo Population Growth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 350,
                    child: SfCartesianChart(
                      tooltipBehavior: _tooltipBehavior,
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(
                        numberFormat: NumberFormat.decimalPattern('en_IN'),
                      ),
                      series: <CartesianSeries<ChartData, String>>[
                        LineSeries<ChartData, String>(
                          dataSource: widget.yearlyData.map((data) {
                            return ChartData(
                              data['year'].toString(),
                              (data['totalBuffaloes'] as num).toDouble(),
                            );
                          }).toList(),
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          name: 'Total Buffaloes',
                          color: Colors.deepPurple,
                          width: 3,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            width: 8,
                            height: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_showProducingBreakdown) ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Production Status Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 350,
                      child: SfCartesianChart(
                        tooltipBehavior: _tooltipBehavior,
                        primaryXAxis: CategoryAxis(),
                        primaryYAxis: NumericAxis(
                          numberFormat: NumberFormat.decimalPattern('en_IN'),
                        ),
                        series: <CartesianSeries<ChartData, String>>[
                          ColumnSeries<ChartData, String>(
                            dataSource: widget.yearlyData.map((data) {
                              return ChartData(
                                data['year'].toString(),
                                (data['producingBuffaloes'] as num? ?? 0)
                                    .toDouble(),
                              );
                            }).toList(),
                            xValueMapper: (ChartData data, _) => data.x,
                            yValueMapper: (ChartData data, _) => data.y,
                            name: 'Producing Buffaloes',
                            color: Colors.green,
                          ),
                          ColumnSeries<ChartData, String>(
                            dataSource: widget.yearlyData.map((data) {
                              final total = (data['totalBuffaloes'] as num)
                                  .toDouble();
                              final producing =
                                  (data['producingBuffaloes'] as num? ?? 0)
                                      .toDouble();
                              return ChartData(
                                data['year'].toString(),
                                total - producing,
                              );
                            }).toList(),
                            xValueMapper: (ChartData data, _) => data.x,
                            yValueMapper: (ChartData data, _) => data.y,
                            name: 'Non-Producing Buffaloes',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Performance Metrics Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Yearly Performance Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
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
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? Colors.grey[800] : Colors.blue[50],
                              ),
                              dataRowHeight: 70, // Increased cell height
                              columnSpacing: 16,
                              columns: [
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Text(
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
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Text(
                                    'Total Buffaloes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Text(
                                    'Producing',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Text(
                                    'Production %',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Center(
                                    child: Text(
                                      'YoY Growth',
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
                              rows: List.generate(widget.yearlyData.length, (
                                index,
                              ) {
                                final data = widget.yearlyData[index];
                                final year = data['year'];
                                final total = data['totalBuffaloes'] as int;
                                final producing =
                                    (data['producingBuffaloes'] as int? ?? 0);
                                final productionPct = total > 0
                                    ? ((producing / total) * 100)
                                          .toStringAsFixed(1)
                                    : '0.0';

                                final prevTotal = index > 0
                                    ? widget.yearlyData[index -
                                              1]['totalBuffaloes']
                                          as int
                                    : total;
                                final growth = index > 0
                                    ? (((total - prevTotal) / prevTotal) * 100)
                                          .toStringAsFixed(1)
                                    : '0.0';
                                final growthColor = double.parse(growth) >= 0
                                    ? Colors.green
                                    : Colors.red;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Center(
                                        child: Text(
                                          year.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: isDark
                                              ? Colors.blue[900]
                                              : Colors.blue[50],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            widget.formatNumber(total),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.blue[100]
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: isDark
                                              ? Colors.green[900]
                                              : Colors.green[50],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            widget.formatNumber(producing),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.green[100]
                                                  : Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: isDark
                                              ? Colors.purple[900]
                                              : Colors.purple[50],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '$productionPct%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.purple[100]
                                                  : Colors.purple[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Container(
                                          color: isDark
                                              ? growthColor.withValues(alpha: 0.1)
                                              : growthColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '$growth%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color:
                                                  isDark &&
                                                      growthColor == Colors.green
                                                  ? Colors.green[300]
                                                  : growthColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary Statistics
            isMobile
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1, // ✅ Mobile: single column
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 3.0, // adjust height of card
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final cards = [
                        _summaryCard(
                          'Starting Herd',
                          widget.yearlyData.isNotEmpty
                              ? widget.formatNumber(
                                  widget.yearlyData.first['totalBuffaloes'],
                                )
                              : '0',
                          Colors.blue,
                          'Year ${widget.yearlyData.isNotEmpty ? widget.yearlyData.first['year'] : '-'}',
                        ),
                        _summaryCard(
                          'Final Herd',
                          widget.yearlyData.isNotEmpty
                              ? widget.formatNumber(
                                  widget.yearlyData.last['totalBuffaloes'],
                                )
                              : '0',
                          Colors.green,
                          'Year ${widget.yearlyData.isNotEmpty ? widget.yearlyData.last['year'] : '-'}',
                        ),
                        _summaryCard(
                          'Total Growth',
                          widget.yearlyData.isNotEmpty
                              ? '${(((widget.yearlyData.last['totalBuffaloes'] as int) / (widget.yearlyData.first['totalBuffaloes'] as int)) * 100 - 100).toStringAsFixed(1)}%'
                              : '0%',
                          Colors.purple,
                          'Over ${widget.yearlyData.length} years',
                        ),
                        _summaryCard(
                          'Avg Production %',
                          widget.yearlyData.isNotEmpty
                              ? '${(widget.yearlyData.fold<num>(0, (sum, data) => sum + ((data['producingBuffaloes'] as num? ?? 0) / (data['totalBuffaloes'] as num) * 100)) / widget.yearlyData.length).toStringAsFixed(1)}%'
                              : '0%',
                          Colors.orange,
                          'Average across years',
                        ),
                      ];

                      return cards[index];
                    },
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Starting Herd',
                          widget.yearlyData.isNotEmpty
                              ? widget.formatNumber(
                                  widget.yearlyData.first['totalBuffaloes'],
                                )
                              : '0',
                          Colors.blue,
                          'Year ${widget.yearlyData.isNotEmpty ? widget.yearlyData.first['year'] : '-'}',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _summaryCard(
                          'Final Herd',
                          widget.yearlyData.isNotEmpty
                              ? widget.formatNumber(
                                  widget.yearlyData.last['totalBuffaloes'],
                                )
                              : '0',
                          Colors.green,
                          'Year ${widget.yearlyData.isNotEmpty ? widget.yearlyData.last['year'] : '-'}',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _summaryCard(
                          'Total Growth',
                          widget.yearlyData.isNotEmpty
                              ? '${(((widget.yearlyData.last['totalBuffaloes'] as int) / (widget.yearlyData.first['totalBuffaloes'] as int)) * 100 - 100).toStringAsFixed(1)}%'
                              : '0%',
                          Colors.purple,
                          'Over ${widget.yearlyData.length} years',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _summaryCard(
                          'Avg Production %',
                          widget.yearlyData.isNotEmpty
                              ? '${(widget.yearlyData.fold<num>(0, (sum, data) => sum + ((data['producingBuffaloes'] as num? ?? 0) / (data['totalBuffaloes'] as num) * 100)) / widget.yearlyData.length).toStringAsFixed(1)}%'
                              : '0%',
                          Colors.orange,
                          'Average across years',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  color[900] ?? Colors.grey[900]!,
                  color[800] ?? Colors.grey[800]!,
                ],
              )
            : LinearGradient(colors: [color[50]!, color[100]!]),
        border: Border.all(
          color: isDark
              ? (color[700] ?? Colors.grey[700]!)
              : (color[200] ?? Colors.grey[200]!),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? (color[100] ?? Colors.white)
                  : (color[700] ?? Colors.black),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? (color[50] ?? Colors.grey[200])
                  : (color[800] ?? Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? (color[200] ?? Colors.grey[400])
                  : (color[600] ?? Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
