import 'package:buffalo_visualizer/buffalo_tree/models/tree_theme.dart';
import 'package:buffalo_visualizer/buffalo_tree/view/buffalo_tree_widget.dart';
import 'package:buffalo_visualizer/components/buffalo_family_tree/cost_estimation_table.dart';
import 'package:buffalo_visualizer/providers/simulation_provider.dart';
import 'package:buffalo_visualizer/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Buffalo Visualizer',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(body: SafeArea(child: ControllerPage())),
    );
  }
}

enum ViewMode { tree, estimation }

class ControllerPage extends ConsumerStatefulWidget {
  const ControllerPage({super.key});

  @override
  ConsumerState<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends ConsumerState<ControllerPage> {
  ViewMode _currentView = ViewMode.tree;
  bool _isTreeFullscreen = false;

  // Temporary controllers for text fields to decouple from provider updates while typing
  late TextEditingController _unitsController;
  late TextEditingController _yearsController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(simulationProvider);
    _unitsController = TextEditingController(text: state.units.toString());
    _yearsController = TextEditingController(text: state.years.toString());
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to simulation state
    final simState = ref.watch(simulationProvider);
    final simNotifier = ref.read(simulationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (Hidden in tree fullscreen mode)
        if (!_isTreeFullscreen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.grey[900] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Empty container for spacing balance
                    const SizedBox(width: 48),
                    Text(
                      'Buffalo Herd Investments',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    // Theme Toggle
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: isDark ? Colors.yellow : Colors.grey[700],
                      ),
                      onPressed: () {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      tooltip: 'Toggle Theme',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // View Mode Toggle (Top Row)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewToggle(
                              icon: Icons.account_tree,
                              label: 'Tree View',
                              mode: ViewMode.tree,
                              isDark: isDark,
                            ),
                            Container(
                              width: 1,
                              height: 16,
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                            _buildViewToggle(
                              icon: Icons.table_chart,
                              label: 'Revenue Estimation',
                              mode: ViewMode.estimation,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Inputs and Buttons (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;

                          if (isMobile) {
                            // Mobile: Stack vertically
                            return Column(
                              children: [
                                // First Row: Inputs only
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Units
                                      _buildFieldRow(
                                        label: 'Units',
                                        child: SizedBox(
                                          width: 50,
                                          child: TextField(
                                            controller: _unitsController,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            onSubmitted: (v) {
                                              simNotifier.updateSettings(
                                                units: double.tryParse(v),
                                              );
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Years
                                      _buildFieldRow(
                                        label: 'Years',
                                        child: SizedBox(
                                          width: 50,
                                          child: TextField(
                                            controller: _yearsController,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            keyboardType: TextInputType.number,
                                            onSubmitted: (v) {
                                              simNotifier.updateSettings(
                                                years: int.tryParse(v),
                                              );
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Start Date
                                      _buildFieldRow(
                                        label: 'Start Date',
                                        child: InkWell(
                                          onTap: () async {
                                            final DateTime? picked =
                                                await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      simState.startDate,
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                );
                                            if (picked != null) {
                                              simNotifier.updateSettings(
                                                startDate: picked,
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${simState.startDate.day}/${simState.startDate.month}/${simState.startDate.year}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Second Row: Buttons + Stats
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Run Button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final unitsText = _unitsController
                                              .text
                                              .trim();
                                          final double? unitsVal =
                                              double.tryParse(unitsText);

                                          if (unitsVal == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter a valid number for units',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          bool isValid = false;
                                          if (unitsVal == 0.5) {
                                            isValid = true;
                                          } else if (unitsVal >= 1 &&
                                              (unitsVal % 1 == 0)) {
                                            isValid = true;
                                          }

                                          if (!isValid) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invalid Units: Please enter 0.5 or a whole number (1, 2, etc.)',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          simNotifier.updateSettings(
                                            units: unitsVal,
                                            years: int.tryParse(
                                              _yearsController.text,
                                            ),
                                          );
                                          simNotifier.runSimulation();
                                        },
                                        icon: const Icon(
                                          Icons.play_arrow,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Run',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Reset Button
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          simNotifier.reset();
                                          _unitsController.text = '1';
                                          _yearsController.text = '10';
                                        },
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Reset',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Stats
                                      _buildOverallStats(simState),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Desktop: Horizontal layout
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Units
                                  _buildFieldRow(
                                    label: 'Units',
                                    child: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        controller: _unitsController,
                                        style: const TextStyle(fontSize: 13),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onSubmitted: (v) {
                                          simNotifier.updateSettings(
                                            units: double.tryParse(v),
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Years
                                  _buildFieldRow(
                                    label: 'Years',
                                    child: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        controller: _yearsController,
                                        style: const TextStyle(fontSize: 13),
                                        keyboardType: TextInputType.number,
                                        onSubmitted: (v) {
                                          simNotifier.updateSettings(
                                            years: int.tryParse(v),
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Start Date
                                  _buildFieldRow(
                                    label: 'Start Date',
                                    child: InkWell(
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: simState.startDate,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                        if (picked != null) {
                                          simNotifier.updateSettings(
                                            startDate: picked,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${simState.startDate.day}/${simState.startDate.month}/${simState.startDate.year}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Run Button
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Validate Units Input
                                      final unitsText = _unitsController.text
                                          .trim();
                                      final double? unitsVal = double.tryParse(
                                        unitsText,
                                      );

                                      if (unitsVal == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a valid number for units',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return; // Stop execution
                                      }

                                      // Check Specific Constraints: 0.5 OR integer >= 1
                                      bool isValid = false;
                                      if (unitsVal == 0.5) {
                                        isValid = true;
                                      } else if (unitsVal >= 1 &&
                                          (unitsVal % 1 == 0)) {
                                        isValid = true;
                                      }

                                      if (!isValid) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Invalid Units: Please enter 0.5 or a whole number (1, 2, etc.)',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return; // Stop execution
                                      }

                                      // Ensure settings are updated from text fields before running
                                      simNotifier.updateSettings(
                                        units: unitsVal,
                                        years: int.tryParse(
                                          _yearsController.text,
                                        ),
                                      );
                                      simNotifier.runSimulation();
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Run',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Reset Button
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      FocusScope.of(
                                        context,
                                      ).unfocus(); // Close keyboard
                                      simNotifier.reset();
                                      _unitsController.text = '1';
                                      _yearsController.text = '10';
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  _buildOverallStats(simState),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Status indicator
        if (simState.isLoading)
          LinearProgressIndicator(color: Colors.blue[300])
        else if (simState.treeData == null && simState.revenueData == null)
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark
                ? Colors.blue[900]!.withOpacity(0.3)
                : Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info,
                  color: isDark ? Colors.blue[200] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Click "Run" to simulate and generate data for price estimation',
                    style: TextStyle(
                      color: isDark ? Colors.blue[200] : Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark
                ? Colors.green[900]!.withOpacity(0.3)
                : Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: isDark ? Colors.green[300] : Colors.green[700],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Simulation data ready! ${simState.treeData!['totalBuffaloes']} buffaloes simulated over ${simState.years} years',
                    style: TextStyle(
                      color: isDark ? Colors.green[300] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Main Content Area
        if (_currentView == ViewMode.tree)
          Expanded(
            child: Container(
              color: isDark ? Colors.black : Colors.grey[50],
              child: simState.treeData != null
                  ? BuffaloTreeWidget(
                      treeData: simState.treeData!,
                      revenueData: simState.revenueData,
                      theme: TreeTheme.vibrantGradients,
                      onAnalyticsPressed: () {
                        setState(() {
                          _currentView = ViewMode.estimation;
                        });
                      },
                      onFullscreenChanged: (isFullscreen) {
                        setState(() {
                          _isTreeFullscreen = isFullscreen;
                        });
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_tree,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No genealogy tree yet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Run" to generate the buffalo family tree',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
            ),
          )
        else // ViewMode.estimation
          Expanded(
            child: (simState.treeData != null && simState.revenueData != null)
                ? CostEstimationTable(
                    treeData: simState.treeData!,
                    revenueData: simState.revenueData!,
                    isEmbedded: true,
                  )
                : Container(
                    color: isDark ? Colors.black : Colors.grey[50],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No estimation data yet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Run" to generate data for price estimation',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  // Full currency format
  String _formatCurrency(double value) {
    String result = value.toInt().toString();
    return '₹${result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _buildOverallStats(SimulationState simState) {
    if (simState.treeData == null || simState.revenueData == null) {
      return const SizedBox.shrink();
    }

    final buffaloes = simState.treeData!['buffaloes'] as List<dynamic>;
    // final totalRevenue = simState.revenueData!['totalRevenue'] as double;
    final years = simState.years;
    final startYear = simState.startDate.year;
    // final startMonth = simState.startDate.month - 1; // 0-based

    // 1. Final Herd Size
    final totalBuffaloes = buffaloes.length;

    // 2. Net Revenue (From Simulation State - Single Source of Truth)
    // Matches CostEstimationTable logic (Type A/B, Free Period, Age > 36mo)
    final netRevenue =
        (simState.revenueData!['totalNetRevenue'] as num?)?.toDouble() ?? 0.0;

    // 3. Asset Value (Matching CostEstimationTable logic exactly)
    double totalAssetValue = 0;
    // Target: Last year of simulation (e.g., Year 10 = 2035 if start is 2026)
    // Asset value calculated at Dec 31 of final year
    final List<dynamic> yearlyData =
        simState.revenueData!['yearlyData'] as List<dynamic>;
    final lastYear = yearlyData.isNotEmpty
        ? yearlyData.last['year'] as int
        : startYear + years - 1;
    final targetMonth = 11; // December (0-based)

    for (final b in buffaloes) {
      final birthYear = b['birthYear'] as int?;
      if (birthYear == null || lastYear < birthYear) continue;

      final birthMonth =
          (b['birthMonth'] as int?) ?? (b['acquisitionMonth'] as int?) ?? 0;
      final ageInMonths =
          ((lastYear - birthYear) * 12) + (targetMonth - birthMonth);

      if (ageInMonths < 0) continue;

      int value = 3000;
      if (ageInMonths >= 60)
        value = 175000;
      else if (ageInMonths >= 48)
        value = 150000;
      else if (ageInMonths >= 40)
        value = 100000;
      else if (ageInMonths >= 36)
        value = 50000;
      else if (ageInMonths >= 30)
        value = 50000;
      else if (ageInMonths >= 24)
        value = 35000;
      else if (ageInMonths >= 18)
        value = 25000;
      else if (ageInMonths >= 12)
        value = 12000;
      else if (ageInMonths >= 6)
        value = 6000;

      totalAssetValue += value;
    }

    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverallStatItem('FINAL HERD', '$totalBuffaloes'),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          const SizedBox(width: 16),
          _buildOverallStatItem(
            'NET REVENUE',
            _formatCurrency(netRevenue),
            color: Colors.green[700],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          const SizedBox(width: 16),
          _buildOverallStatItem(
            'ASSET VALUE',
            _formatCurrency(totalAssetValue),
            color: Colors.blue[700],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required String label,
    required ViewMode mode,
    required bool isDark,
  }) {
    final isSelected = _currentView == mode;
    return InkWell(
      onTap: () => setState(() => _currentView = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue[900]!.withOpacity(0.5) : Colors.blue[100])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? Colors.blue[200] : Colors.blue[700])
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? Colors.blue[200] : Colors.blue[700])
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}
