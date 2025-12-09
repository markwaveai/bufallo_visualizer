import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'reusable_pluto_grid.dart';

class AssetMarketValueWidget extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final List<Map<String, dynamic>> yearlyData;
  final String Function(double) formatCurrency;
  final String Function(num) formatNumber;
  final int Function(Map<String, dynamic>, int, [int]) calculateAgeInMonths;
  final Map<String, dynamic> buffaloDetails;

  const AssetMarketValueWidget({
    Key? key,
    required this.treeData,
    required this.yearlyData,
    required this.formatCurrency,
    required this.formatNumber,
    required this.calculateAgeInMonths,
    required this.buffaloDetails,
  }) : super(key: key);

  @override
  State<AssetMarketValueWidget> createState() => _AssetMarketValueWidgetState();
}

class _AssetMarketValueWidgetState extends State<AssetMarketValueWidget> {
  late int _selectedYear;
  late List<Map<String, dynamic>> _assetMarketValue;

  @override
  void initState() {
    super.initState();
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    _assetMarketValue = _calculateAssetMarketValueTimeline();
    // Match React AssetMarketValue: start from startYear by default
    _selectedYear = startYear;
  }

  // Get buffalo market value based on age in months
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

  // Get age category label (match React AssetMarketValue ageCategories keys)
  String getAgeCategory(int ageInMonths) {
    if (ageInMonths >= 60) return '60+ months (Mother Buffalo)';
    if (ageInMonths >= 48) return '48-60 months';
    if (ageInMonths >= 40) return '40-48 months';
    if (ageInMonths >= 36) return '36-40 months';
    if (ageInMonths >= 30) return '30-36 months';
    if (ageInMonths >= 24) return '24-30 months';
    if (ageInMonths >= 18) return '18-24 months';
    if (ageInMonths >= 12) return '12-18 months';
    if (ageInMonths >= 6) return '6-12 months';
    return '0-6 months (Calves)'; // Changed to match React
  }

  // Build per-year asset market value timeline
  List<Map<String, dynamic>> _calculateAssetMarketValueTimeline() {
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    final categories = <String, int>{
      '0-6 months (Calves)': 3000, // Changed to match React
      '6-12 months': 6000,
      '12-18 months': 12000,
      '18-24 months': 25000,
      '24-30 months': 35000,
      '30-36 months': 50000,
      '36-40 months': 50000,
      '40-48 months': 100000,
      '48-60 months': 150000,
      '60+ months (Mother Buffalo)': 175000,
    };

    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i <= years; i++) {
      final year = startYear + i;

      // init age categories
      final Map<String, Map<String, num>> ageCategories = {
        for (final entry in categories.entries)
          entry.key: {'count': 0, 'value': 0},
      };

      int totalBuffaloes = 0;
      int motherBuffaloes = 0;

      widget.buffaloDetails.forEach((_, buffalo) {
        final ageInMonths = widget.calculateAgeInMonths(
          buffalo,
          year,
          11,
        ); // December valuation
        final category = getAgeCategory(ageInMonths);

        final key = ageCategories.containsKey(category)
            ? category
            : (ageCategories.keys.firstWhere(
                (k) => k.startsWith(category),
                orElse: () => '0-6 months (Calves)',
              ));

        final unitValue = categories[key] ?? 3000;
        ageCategories[key]!['count'] =
            (ageCategories[key]!['count'] as num) + 1;
        ageCategories[key]!['value'] =
            (ageCategories[key]!['value'] as num) + unitValue;

        totalBuffaloes += 1;
        if (ageInMonths >= 60) {
          motherBuffaloes += 1;
        }
      });

      final totalAssetValue = ageCategories.values.fold<num>(
        0,
        (sum, v) => sum + (v['value'] as num),
      );

      result.add({
        'year': year,
        'totalBuffaloes': totalBuffaloes,
        'motherBuffaloes': motherBuffaloes,
        'totalAssetValue': totalAssetValue,
        'ageCategories': ageCategories,
      });
    }

    return result;
  }

  // Calculate detailed asset value for selected year (like React's calculateDetailedAssetValueForYear)
  Map<String, dynamic> _calculateDetailedAssetValueForYear(int year) {
    final ageGroups = {
      '0-6 months (Calves)': {'count': 0, 'value': 0, 'unitValue': 3000},
      '6-12 months': {'count': 0, 'value': 0, 'unitValue': 6000},
      '12-18 months': {'count': 0, 'value': 0, 'unitValue': 12000},
      '18-24 months': {'count': 0, 'value': 0, 'unitValue': 25000},
      '24-30 months': {'count': 0, 'value': 0, 'unitValue': 35000},
      '30-36 months': {'count': 0, 'value': 0, 'unitValue': 50000},
      '36-40 months': {'count': 0, 'value': 0, 'unitValue': 50000},
      '40-48 months': {'count': 0, 'value': 0, 'unitValue': 100000},
      '48-60 months': {'count': 0, 'value': 0, 'unitValue': 150000},
      '60+ months (Mother Buffalo)': {
        'count': 0,
        'value': 0,
        'unitValue': 175000
      },
    };

    double totalValue = 0;
    int totalCount = 0;

    widget.buffaloDetails.forEach((_, buffalo) {
      if (year >= (buffalo['birthYear'] as int)) {
        final ageInMonths = widget.calculateAgeInMonths(buffalo, year, 11);
        final value = getBuffaloValueByAge(ageInMonths);

        if (ageInMonths >= 60) {
          ageGroups['60+ months (Mother Buffalo)']!['count'] =
              (ageGroups['60+ months (Mother Buffalo)']!['count'] as int) + 1;
          ageGroups['60+ months (Mother Buffalo)']!['value'] =
              (ageGroups['60+ months (Mother Buffalo)']!['value'] as int) +
                  value;
        } else if (ageInMonths >= 48) {
          ageGroups['48-60 months']!['count'] =
              (ageGroups['48-60 months']!['count'] as int) + 1;
          ageGroups['48-60 months']!['value'] =
              (ageGroups['48-60 months']!['value'] as int) + value;
        } else if (ageInMonths >= 40) {
          ageGroups['40-48 months']!['count'] =
              (ageGroups['40-48 months']!['count'] as int) + 1;
          ageGroups['40-48 months']!['value'] =
              (ageGroups['40-48 months']!['value'] as int) + value;
        } else if (ageInMonths >= 36) {
          ageGroups['36-40 months']!['count'] =
              (ageGroups['36-40 months']!['count'] as int) + 1;
          ageGroups['36-40 months']!['value'] =
              (ageGroups['36-40 months']!['value'] as int) + value;
        } else if (ageInMonths >= 30) {
          ageGroups['30-36 months']!['count'] =
              (ageGroups['30-36 months']!['count'] as int) + 1;
          ageGroups['30-36 months']!['value'] =
              (ageGroups['30-36 months']!['value'] as int) + value;
        } else if (ageInMonths >= 24) {
          ageGroups['24-30 months']!['count'] =
              (ageGroups['24-30 months']!['count'] as int) + 1;
          ageGroups['24-30 months']!['value'] =
              (ageGroups['24-30 months']!['value'] as int) + value;
        } else if (ageInMonths >= 18) {
          ageGroups['18-24 months']!['count'] =
              (ageGroups['18-24 months']!['count'] as int) + 1;
          ageGroups['18-24 months']!['value'] =
              (ageGroups['18-24 months']!['value'] as int) + value;
        } else if (ageInMonths >= 12) {
          ageGroups['12-18 months']!['count'] =
              (ageGroups['12-18 months']!['count'] as int) + 1;
          ageGroups['12-18 months']!['value'] =
              (ageGroups['12-18 months']!['value'] as int) + value;
        } else if (ageInMonths >= 6) {
          ageGroups['6-12 months']!['count'] =
              (ageGroups['6-12 months']!['count'] as int) + 1;
          ageGroups['6-12 months']!['value'] =
              (ageGroups['6-12 months']!['value'] as int) + value;
        } else {
          ageGroups['0-6 months (Calves)']!['count'] =
              (ageGroups['0-6 months (Calves)']!['count'] as int) + 1;
          ageGroups['0-6 months (Calves)']!['value'] =
              (ageGroups['0-6 months (Calves)']!['value'] as int) + value;
        }

        totalValue += value;
        totalCount++;
      }
    });

    return {
      'ageGroups': ageGroups,
      'totalValue': totalValue,
      'totalCount': totalCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totalBuffaloes = widget.buffaloDetails.length;

    if (_assetMarketValue.isEmpty || totalBuffaloes == 0) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No buffalo data available for asset valuation.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final selectedAsset = _assetMarketValue.firstWhere(
      (a) => a['year'] == _selectedYear,
      orElse: () => _assetMarketValue.last,
    );

    final totalAssetValue =
        (selectedAsset['totalAssetValue'] as num?)?.toDouble() ?? 0.0;
    final selectedAgeCategories =
        (selectedAsset['ageCategories'] as Map<String, Map<String, num>>);
    final detailedValue = _calculateDetailedAssetValueForYear(_selectedYear);
    final detailedAgeGroups =
        detailedValue['ageGroups'] as Map<String, Map<String, dynamic>>;

    // Calculate total buffaloes for selected year
    int totalSelectedYearBuffaloes = 0;
    selectedAgeCategories.forEach((key, value) {
      totalSelectedYearBuffaloes += (value['count'] as num).toInt();
    });

    // Get count for a category from asset data (matching React's getCategoryCount)
    int getCategoryCount(String categoryKey) {
      // Try exact key first
      if (selectedAgeCategories.containsKey(categoryKey)) {
        return (selectedAgeCategories[categoryKey]!['count'] as num).toInt();
      }

      // Try without parentheses suffixes
      final keyWithoutParentheses = categoryKey
          .replaceAll(' (Calves)', '')
          .replaceAll(' (Mother Buffalo)', '');
      if (selectedAgeCategories.containsKey(keyWithoutParentheses)) {
        return (selectedAgeCategories[keyWithoutParentheses]!['count'] as num)
            .toInt();
      }

      // Fallbacks for plain forms like '0-6 months' or '60+ months'
      if (categoryKey.contains('0-6')) {
        const plainKey = '0-6 months';
        if (selectedAgeCategories.containsKey(plainKey)) {
          return (selectedAgeCategories[plainKey]!['count'] as num).toInt();
        }
      }
      if (categoryKey.contains('60+')) {
        const plainKey = '60+ months';
        if (selectedAgeCategories.containsKey(plainKey)) {
          return (selectedAgeCategories[plainKey]!['count'] as num).toInt();
        }
      }

      return 0;
    }

    // Get value for a category from asset data (matching React's getCategoryValue)
    double getCategoryValue(String categoryKey) {
      // Try exact key first
      if (selectedAgeCategories.containsKey(categoryKey)) {
        return (selectedAgeCategories[categoryKey]!['value'] as num).toDouble();
      }

      // Try without parentheses suffixes
      final keyWithoutParentheses = categoryKey
          .replaceAll(' (Calves)', '')
          .replaceAll(' (Mother Buffalo)', '');
      if (selectedAgeCategories.containsKey(keyWithoutParentheses)) {
        return (selectedAgeCategories[keyWithoutParentheses]!['value'] as num)
            .toDouble();
      }

      // Fallbacks for plain forms like '0-6 months' or '60+ months'
      if (categoryKey.contains('0-6')) {
        const plainKey = '0-6 months';
        if (selectedAgeCategories.containsKey(plainKey)) {
          return (selectedAgeCategories[plainKey]!['value'] as num).toDouble();
        }
      }
      if (categoryKey.contains('60+')) {
        const plainKey = '60+ months';
        if (selectedAgeCategories.containsKey(plainKey)) {
          return (selectedAgeCategories[plainKey]!['value'] as num).toDouble();
        }
      }

      return 0;
    }

    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final endYear = startYear + (widget.treeData['years'] ?? 10) - 1;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined Year Selection and Summary (matching React)
            Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Year Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'Select Year for Valuation:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: _selectedYear,
                              items: _assetMarketValue
                                  .map(
                                    (asset) => DropdownMenuItem<int>(
                                      value: asset['year'] as int,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          '${asset['year']} (Year ${(asset['year'] as int) - (widget.treeData['startYear'] ?? 0) + 1})',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedYear = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Total Value Display (matching React gradient)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.indigo[700]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue[800]!.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Total Asset Value',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[100],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.formatCurrency(totalAssetValue),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalSelectedYearBuffaloes buffaloes'
                              '${getCategoryCount('60+ months (Mother Buffalo)') > 0 ? ' · ${getCategoryCount('60+ months (Mother Buffalo)')} mothers' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[200],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Age-Based Valuation Breakdown Table (matching React)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                         Text(
                          'Age-Based Valuation Breakdown',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Year $_selectedYear',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ReusablePlutoGrid(
                    gridId: 'asset_detailed_breakdown',
                    height: 400,
                    rowHeight: 52,
                    columns: [
                      PlutoColumnBuilder.textColumn(
                        title: 'Age Group',
                        field: 'ageGroup',
                        width: 200,
                        titleTextAlign: PlutoColumnTextAlign.left,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Unit Value',
                        field: 'unitValue',
                        width: 120,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Count',
                        field: 'count',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Total Value',
                        field: 'totalValue',
                        width: 140,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '% of Total',
                        field: 'percentage',
                        width: 120,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                    ],
                    rows: [
                      ...detailedAgeGroups.entries
                          .where((entry) => (entry.value['count'] as int) > 0)
                          .map((entry) {
                        final ageGroup = entry.key;
                        final data = entry.value;
                        final count = data['count'] as int;
                        final value = data['value'] as int;
                        final totalValue = detailedValue['totalValue'] as double;
                        final percentage = totalValue > 0
                            ? (value / totalValue) * 100
                            : 0.0;

                        return PlutoRow(
                          cells: {
                            'ageGroup': PlutoCell(value: ageGroup),
                            'unitValue': PlutoCell(
                              value: widget.formatCurrency(
                                (data['unitValue'] as int).toDouble(),
                              ),
                            ),
                            'count': PlutoCell(value: count.toString()),
                            'totalValue': PlutoCell(
                              value: widget.formatCurrency(value.toDouble()),
                            ),
                            'percentage': PlutoCell(
                              value: '${percentage.toStringAsFixed(1)}%',
                            ),
                          },
                        );
                      }),
                      // Footer row
                      PlutoRow(
                        cells: {
                          'ageGroup': PlutoCell(value: 'Total'),
                          'unitValue': PlutoCell(value: '-'),
                          'count': PlutoCell(
                            value: totalSelectedYearBuffaloes.toString(),
                          ),
                          'totalValue': PlutoCell(
                            value: widget.formatCurrency(totalAssetValue),
                          ),
                          'percentage': PlutoCell(value: '100%'),
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Compact Age-Based Asset Breakdown (Second Table)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Age-Based Asset Breakdown - $_selectedYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            // color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.indigo[700]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            widget.formatCurrency(totalAssetValue),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ReusablePlutoGrid(
                    gridId: 'asset_compact_breakdown',
                    height: 420,
                    rowHeight: 52,
                    columns: [
                      PlutoColumnBuilder.textColumn(
                        title: 'Age Category',
                        field: 'ageCategory',
                        width: 180,
                        titleTextAlign: PlutoColumnTextAlign.left,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Unit Value',
                        field: 'unitValue',
                        width: 120,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Count',
                        field: 'count',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Total Value',
                        field: 'totalValue',
                        width: 140,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '% of Total',
                        field: 'percentage',
                        width: 120,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                    ],
                    rows: [
                      ...[
                        {'category': '0-6 months (Calves)', 'unitValue': 3000},
                        {'category': '6-12 months', 'unitValue': 6000},
                        {'category': '12-18 months', 'unitValue': 12000},
                        {'category': '18-24 months', 'unitValue': 25000},
                        {'category': '24-30 months', 'unitValue': 35000},
                        {'category': '30-36 months', 'unitValue': 50000},
                        {'category': '36-40 months', 'unitValue': 50000},
                        {'category': '40-48 months', 'unitValue': 100000},
                        {'category': '48-60 months', 'unitValue': 150000},
                        {
                          'category': '60+ months (Mother Buffalo)',
                          'unitValue': 175000,
                        },
                      ].map((item) {
                        final catKey = item['category'] as String;
                        final count = getCategoryCount(catKey);
                        final value = getCategoryValue(catKey);
                        final percentage = totalAssetValue > 0
                            ? (value / totalAssetValue) * 100
                            : 0.0;

                        return PlutoRow(
                          cells: {
                            'ageCategory': PlutoCell(value: catKey),
                            'unitValue': PlutoCell(
                              value: widget.formatCurrency(
                                (item['unitValue'] as num).toDouble(),
                              ),
                            ),
                            'count': PlutoCell(value: count.toString()),
                            'totalValue': PlutoCell(
                              value: widget.formatCurrency(value),
                            ),
                            'percentage': PlutoCell(
                              value: '${percentage.toStringAsFixed(1)}%',
                            ),
                          },
                        );
                      }),
                      // Footer row
                      PlutoRow(
                        cells: {
                          'ageCategory': PlutoCell(value: 'Total'),
                          'unitValue': PlutoCell(value: '-'),
                          'count': PlutoCell(
                            value: totalSelectedYearBuffaloes.toString(),
                          ),
                          'totalValue': PlutoCell(
                            value: widget.formatCurrency(totalAssetValue),
                          ),
                          'percentage': PlutoCell(value: '100%'),
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Year-wise Age Category Distribution (Years 1-10)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Year-wise Age Category Distribution (Years 1-10)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            // color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  ReusablePlutoGrid(
                    gridId: 'asset_year_wise_distribution',
                    height: 400,
                    rowHeight: 48,
                    columns: [
                      PlutoColumnBuilder.textColumn(
                        title: 'Year',
                        field: 'year',
                        width: 140,
                        titleTextAlign: PlutoColumnTextAlign.left,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Total Buffaloes',
                        field: 'totalBuffaloes',
                        width: 120,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '0-6 months',
                        field: 'm0_6',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '6-12 months',
                        field: 'm6_12',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '12-18 months',
                        field: 'm12_18',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '18-24 months',
                        field: 'm18_24',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '24-30 months',
                        field: 'm24_30',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '30-36 months',
                        field: 'm30_36',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '36-40 months',
                        field: 'm36_40',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '40-48 months',
                        field: 'm40_48',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '48-60 months',
                        field: 'm48_60',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: '60+ months',
                        field: 'm60plus',
                        width: 90,
                        titleTextAlign: PlutoColumnTextAlign.center,
                      ),
                      PlutoColumnBuilder.textColumn(
                        title: 'Total Value',
                        field: 'totalValue',
                        width: 140,
                        titleTextAlign: PlutoColumnTextAlign.right,
                      ),
                    ],
                    rows: _assetMarketValue
                        .take(10)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final asset = entry.value;
                      final ageCats = asset['ageCategories']
                          as Map<String, Map<String, num>>;

                      int getCount(String key) {
                        if (ageCats.containsKey(key)) {
                          return (ageCats[key]!['count'] as num).toInt();
                        }
                        // Try without parentheses
                        final keyWithoutParentheses = key
                            .replaceAll(' (Calves)', '')
                            .replaceAll(' (Mother Buffalo)', '');
                        if (ageCats.containsKey(keyWithoutParentheses)) {
                          return (ageCats[keyWithoutParentheses]!['count']
                                  as num)
                              .toInt();
                        }
                        return 0;
                      }

                      return PlutoRow(
                        cells: {
                          'year': PlutoCell(
                            value: 'Year ${index + 1} (${asset['year']})',
                          ),
                          'totalBuffaloes': PlutoCell(
                            value: (asset['totalBuffaloes'] as num)
                                .toInt()
                                .toString(),
                          ),
                          'm0_6': PlutoCell(
                            value: getCount('0-6 months (Calves)').toString(),
                          ),
                          'm6_12': PlutoCell(
                            value: getCount('6-12 months').toString(),
                          ),
                          'm12_18': PlutoCell(
                            value: getCount('12-18 months').toString(),
                          ),
                          'm18_24': PlutoCell(
                            value: getCount('18-24 months').toString(),
                          ),
                          'm24_30': PlutoCell(
                            value: getCount('24-30 months').toString(),
                          ),
                          'm30_36': PlutoCell(
                            value: getCount('30-36 months').toString(),
                          ),
                          'm36_40': PlutoCell(
                            value: getCount('36-40 months').toString(),
                          ),
                          'm40_48': PlutoCell(
                            value: getCount('40-48 months').toString(),
                          ),
                          'm48_60': PlutoCell(
                            value: getCount('48-60 months').toString(),
                          ),
                          'm60plus': PlutoCell(
                            value: getCount('60+ months (Mother Buffalo)')
                                .toString(),
                          ),
                          'totalValue': PlutoCell(
                            value: widget.formatCurrency(
                              (asset['totalAssetValue'] as num).toDouble(),
                            ),
                          ),
                        },
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Shows the distribution of buffaloes across different age categories for each year (1-10)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Initial vs Final Asset Value Cards (matching React layout)
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.indigo[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[100]!.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          widget.formatCurrency(
                            (_assetMarketValue.first['totalAssetValue'] as num)
                                .toDouble(),
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Initial Asset Value ($startYear)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_assetMarketValue.first['totalBuffaloes']} buffaloes\n'
                          '${((_assetMarketValue.first['ageCategories'] as Map<String, Map<String, num>>)['60+ months (Mother Buffalo)']?['count'] ?? 0).toInt()} mother buffaloes (60+ months)\n'
                          '${((_assetMarketValue.first['ageCategories'] as Map<String, Map<String, num>>)['0-6 months (Calves)']?['count'] ?? 0).toInt()} newborn calves',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo[600]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo[800]!.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          widget.formatCurrency(
                            (_assetMarketValue.last['totalAssetValue'] as num)
                                .toDouble(),
                          ),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Final Asset Value ($endYear)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_assetMarketValue.last['totalBuffaloes']} buffaloes\n'
                          '${((_assetMarketValue.last['ageCategories'] as Map<String, Map<String, num>>)['60+ months (Mother Buffalo)']?['count'] ?? 0).toInt()} mother buffaloes (60+ months)\n'
                          'Multiple generations with age-based valuation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Price Schedule Grid
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Age-Based Price Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    children: [
                      {
                        'age': '0-6 months',
                        'price': '₹3,000',
                        'gradient': 'from-blue-50 to-blue-100',
                        'desc': 'New born',
                      },
                      {
                        'age': '6-12 months',
                        'price': '₹6,000',
                        'gradient': 'from-blue-100 to-blue-200',
                        'desc': 'Growing',
                      },
                      {
                        'age': '12-18 months',
                        'price': '₹12,000',
                        'gradient': 'from-teal-50 to-teal-100',
                        'desc': 'Growing',
                      },
                      {
                        'age': '18-24 months',
                        'price': '₹25,000',
                        'gradient': 'from-teal-100 to-teal-200',
                        'desc': 'Growing',
                      },
                      {
                        'age': '24-30 months',
                        'price': '₹35,000',
                        'gradient': 'from-emerald-50 to-emerald-100',
                        'desc': 'Growing',
                      },
                      {
                        'age': '30-36 months',
                        'price': '₹50,000',
                        'gradient': 'from-emerald-100 to-emerald-200',
                        'desc': 'Growing',
                      },
                      {
                        'age': '36-40 months',
                        'price': '₹50,000',
                        'gradient': 'from-amber-50 to-amber-100',
                        'desc': 'Transition',
                      },
                      {
                        'age': '40-48 months',
                        'price': '₹1,00,000',
                        'gradient': 'from-amber-100 to-amber-200',
                        'desc': '4+ years',
                      },
                      {
                        'age': '48-60 months',
                        'price': '₹1,50,000',
                        'gradient': 'from-orange-50 to-orange-100',
                        'desc': '5th year',
                      },
                      {
                        'age': '60+ months',
                        'price': '₹1,75,000',
                        'gradient': 'from-red-50 to-red-100',
                        'desc': 'Mother buffalo',
                      },
                    ].map((item) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getColorFromString(
                                  item['gradient'] as String, true),
                              _getColorFromString(
                                  item['gradient'] as String, false),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['age'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                // color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['price'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                // color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get color from gradient string
  Color _getColorFromString(String gradient, bool isFrom) {
    final parts = gradient.replaceAll('from-', '').replaceAll('to-', '').split(' ');
    final colorName = isFrom ? parts[0] : parts[1];
    
    switch (colorName) {
      case 'blue-50':
        return Colors.blue[50]!;
      case 'blue-100':
        return Colors.blue[100]!;
      case 'blue-200':
        return Colors.blue[200]!;
      case 'teal-50':
        return Colors.teal[50]!;
      case 'teal-100':
        return Colors.teal[100]!;
      case 'teal-200':
        return Colors.teal[200]!;
      case 'emerald-50':
        return Colors.green[50]!;
      case 'emerald-100':
        return Colors.green[100]!;
      case 'emerald-200':
        return Colors.green[200]!;
      case 'amber-50':
        return Colors.amber[50]!;
      case 'amber-100':
        return Colors.amber[100]!;
      case 'amber-200':
        return Colors.amber[200]!;
      case 'orange-50':
        return Colors.orange[50]!;
      case 'orange-100':
        return Colors.orange[100]!;
      case 'red-50':
        return Colors.red[50]!;
      case 'red-100':
        return Colors.red[100]!;
      default:
        return Colors.grey[50]!;
    }
  }
}