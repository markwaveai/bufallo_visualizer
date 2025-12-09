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

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Toggle
            Center(
              child: Column(
                children: [
                  const Text(
                    'Herd Performance Analysis',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Show Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _showProducingBreakdown,
                          onChanged: (value) {
                            setState(
                                () => _showProducingBreakdown = value);
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
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Total Buffalo Population Growth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 350,
                    child: SfCartesianChart(
                      tooltipBehavior: _tooltipBehavior,
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(
                        numberFormat:
                            NumberFormat.decimalPattern('en_IN'),
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

            // Production Breakdown (Conditional)
            if (_showProducingBreakdown) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Production Status Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 350,
                      child: SfCartesianChart(
                        tooltipBehavior: _tooltipBehavior,
                        primaryXAxis: CategoryAxis(),
                        primaryYAxis: NumericAxis(
                          numberFormat:
                              NumberFormat.decimalPattern('en_IN'),
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
                              final total =
                                  (data['totalBuffaloes'] as num).toDouble();
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
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: const Text(
                      'Yearly Performance Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
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
                            'Total Buffaloes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Producing',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Production %',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'YoY Growth',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(
                        widget.yearlyData.length,
                        (index) {
                          final data = widget.yearlyData[index];
                          final year = data['year'];
                          final total = data['totalBuffaloes'] as int;
                          final producing =
                              (data['producingBuffaloes'] as int? ?? 0);
                          final productionPct = total > 0
                              ? ((producing / total) * 100).toStringAsFixed(1)
                              : '0.0';

                          final prevTotal = index > 0
                              ? widget.yearlyData[index - 1]
                                  ['totalBuffaloes'] as int
                              : total;
                          final growth = index > 0
                              ? (((total - prevTotal) / prevTotal) * 100)
                                  .toStringAsFixed(1)
                              : '0.0';
                          final growthColor =
                              double.parse(growth) >= 0
                                  ? Colors.green
                                  : Colors.red;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  year.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  color: Colors.blue[50],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Text(
                                    widget.formatNumber(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  color: Colors.green[50],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Text(
                                    widget.formatNumber(producing),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  color: Colors.purple[50],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Text(
                                    '$productionPct%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  color: growthColor.withOpacity(0.2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Text(
                                    '$growth%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: growthColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary Statistics
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Starting Herd',
                    widget.yearlyData.isNotEmpty
                        ? widget.formatNumber(
                            widget.yearlyData.first['totalBuffaloes'])
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
                            widget.yearlyData.last['totalBuffaloes'])
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[50]!, color[100]!],
        ),
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
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
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
