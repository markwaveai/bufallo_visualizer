import 'package:flutter/material.dart';

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
  Map<String, dynamic> _selectedAsset = {};
  List<Map<String, dynamic>> _assetMarketValue = [];

  @override
  void initState() {
    super.initState();
    _recalculateValues();
  }

  @override
  void didUpdateWidget(AssetMarketValueWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.treeData != oldWidget.treeData ||
        widget.buffaloDetails != oldWidget.buffaloDetails) {
      _recalculateValues(keepSelection: true);
    }
  }

  void _recalculateValues({bool keepSelection = false}) {
    _assetMarketValue = _calculateAssetMarketValueTimeline();

    if (keepSelection && _selectedAsset.isNotEmpty) {
      // Try to find the currently selected asset in the new data
      final found = _assetMarketValue.firstWhere(
        (a) =>
            a['year'] == _selectedAsset['year'] &&
            a['month'] == _selectedAsset['month'] &&
            a['isInitial'] == _selectedAsset['isInitial'],
        orElse: () => {},
      );

      if (found.isNotEmpty) {
        _selectedAsset = found;
        return;
      }
    }

    // Default to first item (Initial) or empty
    _selectedAsset = _assetMarketValue.isNotEmpty
        ? _assetMarketValue.first
        : {};
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
      '0-6 months (Calves)': 3000,
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

    // Helper to calculate for a specific point in time
    Map<String, dynamic> calculateForPoint(
      int year,
      int month, {
      bool onlyGen0 = false,
    }) {
      final Map<String, Map<String, num>> ageCategories = {
        for (final entry in categories.entries)
          entry.key: {'count': 0, 'value': 0},
      };

      int totalBuffaloes = 0;
      int motherBuffaloes = 0;

      widget.buffaloDetails.forEach((_, buffalo) {
        // Timeline filtering checks
        if (onlyGen0 && (buffalo['generation'] as int? ?? 0) > 0) return;
        if (year < (buffalo['birthYear'] as int)) return;
        // If same year and month is strictly before birthMonth (if we tracked strict dates)
        // But for Jan (month 0), if birthMonth is 0, age is 0.
        // The 'onlyGen0' flag handles the Initial State strictness.

        final ageInMonths = widget.calculateAgeInMonths(buffalo, year, month);
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

      return {
        'year': year,
        'month': month,
        'label': onlyGen0
            ? 'Initial (Jan 1, $year)'
            : '$year (Year ${year - startYear + 1})',
        'isInitial': onlyGen0,
        'totalBuffaloes': totalBuffaloes,
        'motherBuffaloes': motherBuffaloes,
        'totalAssetValue': totalAssetValue,
        'ageCategories': ageCategories,
      };
    }

    // 1. Add Initial State (Jan 1st of Start Year) - Only Parents (Gen 0)
    result.add(calculateForPoint(startYear, 0, onlyGen0: true));

    // 2. Add Yearly States (Dec 31st of each year)
    // Start from i=1 to avoid duplicate "2026" (Initial vs End of Year 1)
    // Use i < years to stay within the 10-year simulation bounds (e.g. up to 2035, not 2036)
    for (int i = 1; i < years; i++) {
      result.add(calculateForPoint(startYear + i, 11));
    }

    return result;
  }

  // Calculate detailed asset value for selected year (like React's calculateDetailedAssetValueForYear)
  Map<String, dynamic> _calculateDetailedAssetValueForYear(
    int year, {
    int month = 11,
    bool onlyGen0 = false,
  }) {
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
        'unitValue': 175000,
      },
    };

    double totalValue = 0;
    int totalCount = 0;

    widget.buffaloDetails.forEach((_, buffalo) {
      if (onlyGen0 && (buffalo['generation'] as int? ?? 0) > 0) return;
      if (year >= (buffalo['birthYear'] as int)) {
        final ageInMonths = widget.calculateAgeInMonths(buffalo, year, month);
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
    // Basic Data Checks
    final totalBuffaloes = widget.buffaloDetails.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    

    if (_assetMarketValue.isEmpty || totalBuffaloes == 0) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.query_stats, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No buffalo data available for asset valuation.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Determine Selected Data using State
    final selectedAsset = _selectedAsset.isNotEmpty
        ? _selectedAsset
        : (_assetMarketValue.firstOrNull ?? {});

    // Calculate Detail Data for Selected Year
    final selectedYear = selectedAsset['year'] as int? ?? 1;
    final detailedValue = _calculateDetailedAssetValueForYear(
      selectedYear,
      month: selectedAsset['month'] as int? ?? 11,
      onlyGen0: selectedAsset['isInitial'] as bool? ?? false,
    );
    final detailedAgeGroups =
        detailedValue['ageGroups'] as Map<String, Map<String, dynamic>>;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA), // Premium Background
      child: SingleChildScrollView(
        padding: isMobile?EdgeInsets.all(0): EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Year-wise Overview Table (The "All Detailed" Timeline)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Asset Projection Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildYearlyOverviewTable(isDark, constraints);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2. Detailed Breakdown for Selected Year
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding:  EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.purple[600],
                            ),
                             SizedBox(width: isMobile?8:12),
                            Text(
                              'Detailed Breakdown',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                          ],
                        ),
                        // Year Selector embedded in header
                        _buildCompactYearSelector(isDark, isMobile),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      // Filter & Sort Rows
                      final tableRows = detailedAgeGroups.entries
                          .where((entry) => (entry.value['count'] as int) > 0)
                          .toList();

                      if (isMobile) {
                        return _buildMobileAssetList(
                          tableRows,
                          detailedValue['totalValue'] as double,
                          isDark,
                        );
                      } else {
                        return _buildDesktopAssetTable(
                          tableRows,
                          detailedValue['totalValue'] as double,
                          isDark,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCompactYearSelector(bool isDark, bool isMobile) {
    return Container(
      height: 35,
      width: isMobile ? 140 : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          dropdownColor: isDark ? Colors.grey[850] : Colors.white,
          value: _selectedAsset.isNotEmpty
              ? _selectedAsset
              : (_assetMarketValue.firstOrNull),
          icon: Icon(
            Icons.arrow_drop_down,
            size: isMobile?18:16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          style: TextStyle(
            fontSize: isMobile ? 11 : 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
          items: _assetMarketValue
              .map(
                (asset) => DropdownMenuItem<Map<String, dynamic>>(
                  value: asset,
                  child: Text(asset['label'] as String),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedAsset = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildYearlyOverviewTable(bool isDark, BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? Colors.grey[850] : const Color(0xFFF9FAFB),
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columnSpacing: 172,
          columns: [
            DataColumn(
              headingRowAlignment: MainAxisAlignment.center,
              
              label: Text(
                'Year',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ),
            DataColumn(
             
              label: Text(
                'Total Herd',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              numeric: true,
            ),
            DataColumn(
           
              label: Text(
                'Calves (0-6m)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              numeric: true,
            ),
            DataColumn(
             
              label: Text(
                'Mothers (60+m)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              numeric: true,
            ),
            DataColumn(
            
              label: Text(
                'Total Asset Value',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              numeric: true,
            ),
          ],
          rows: _assetMarketValue.map((asset) {
            final ageCats =
                asset['ageCategories'] as Map<String, Map<String, num>>;

            int getCount(String key) {
              if (ageCats.containsKey(key)) {
                return (ageCats[key]!['count'] as num).toInt();
              }
              // Try fallback if formatting differs
              final cleanKey = key
                  .replaceAll(' (Calves)', '')
                  .replaceAll(' (Mother Buffalo)', '');
              if (ageCats.containsKey(cleanKey)) {
                return (ageCats[cleanKey]!['count'] as num).toInt();
              }
              return 0;
            }

            final calfCount = getCount('0-6 months (Calves)');
            final motherCount = getCount('60+ months (Mother Buffalo)');
            final totalVal =
                (asset['totalAssetValue'] as num?)?.toDouble() ?? 0.0;
            final yearLabel = asset['label'] as String; // e.g., "Year 1"

            return DataRow(
              cells: [
                DataCell(
                  Center(
                    child: Text(
                      yearLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withValues(alpha: 0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${asset['totalBuffaloes']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue[200] : Colors.blue[800],
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      '$calfCount',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      '$motherCount',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      widget.formatCurrency(totalVal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.green[300] : Colors.green[700],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDesktopAssetTable(
    List<MapEntry<String, Map<String, dynamic>>> rows,
    double totalValue,
    bool isDark,
  ) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? Colors.grey[850] : Colors.grey[50],
      ),
      columnSpacing: 24,
      horizontalMargin: 24,
      columns: [
        DataColumn(
          label: Text(
            'Age Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Unit Value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Total Value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            '% of Portfolio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          numeric: true,
        ),
      ],
      rows: rows.map((entry) {
        final data = entry.value;
        final val = data['value'] as int;
        final pct = totalValue > 0 ? (val / totalValue * 100) : 0.0;

        return DataRow(
          cells: [
            DataCell(
              Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
            DataCell(
              Text(
                widget.formatCurrency((data['unitValue'] as int).toDouble()),
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]!.withValues(alpha: 0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data['count']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue[200] : Colors.blue[800],
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                widget.formatCurrency(val.toDouble()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.green[300] : Colors.green[700],
                ),
              ),
            ),
            DataCell(
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileAssetList(
    List<MapEntry<String, Map<String, dynamic>>> rows,
    double totalValue,
    bool isDark,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = rows[index];
        final data = entry.value;
        final val = data['value'] as int;
        final pct = totalValue > 0 ? (val / totalValue * 100) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue[900]!.withValues(alpha: 0.5)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${data['count']} Units',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.blue[200] : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit Value',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.formatCurrency(
                          (data['unitValue'] as int).toDouble(),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.formatCurrency(val.toDouble()),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[400] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      },
    );
  }
}
