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
  bool _showControlsDrawer = false; // For mobile drawer
  String _selectedBuffaloType =
      'A'; // 'A' or 'B' or 'ALL' (mobile drawer + tree)

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

    // Sync controllers when simulation finishes loading (initial load or reset)
    ref.listen(simulationProvider, (previous, next) {
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.config != null) {
        _unitsController.text = next.units.toString();
        _yearsController.text = next.years.toString();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Mobile layout with drawer
    if (isMobile) {
      return _buildMobileLayout(context, simState, simNotifier, isDark);
    }

    // Desktop layout (original)
    return _buildDesktopLayout(context, simState, simNotifier, isDark);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SimulationState simState,
    SimulationNotifier simNotifier,
    bool isDark,
  ) {
    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with menu button
            if (!_isTreeFullscreen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Row(
                  children: [
                    // Menu button
                    IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _showControlsDrawer = true;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    // View Mode Toggle (Moved here)
                    Expanded(child: _buildMobileViewModePillToggle(isDark)),
                    const SizedBox(width: 4),
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
              ),

            // Status indicator
            // _buildStatusIndicator(simState, isDark),

            // Main Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1300),
                reverseDuration: const Duration(milliseconds: 1300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  final slide = Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<ViewMode>(_currentView),
                  child: _buildMainContent(simState, isDark),
                ),
              ),
            ),
          ],
        ),

        // Controls Drawer
        if (_showControlsDrawer)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
                color: isDark ? Colors.black : Colors.white,
              ),
              child: Column(
                children: [
                  // Drawer header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Simulation Controls',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _showControlsDrawer = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Controls content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDrawerInputCard(
                                  isDark: isDark,
                                  label: 'Units',
                                  child: TextField(
                                    controller: _unitsController,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
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
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDrawerInputCard(
                                  isDark: isDark,
                                  label: 'Years',
                                  child: TextField(
                                    controller: _yearsController,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (v) {
                                      simNotifier.updateSettings(
                                        years: int.tryParse(v),
                                      );
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.center,
                            child: _buildDrawerDateCard(
                              label: 'Date',
                              value:
                                  '${simState.startDate.day}/${simState.startDate.month}/${simState.startDate.year}',
                              isDark: isDark,
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: simState.startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  simNotifier.updateSettings(startDate: picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildDrawerRunResetRow(
                            isDark: isDark,
                            onRun: () {
                              _validateAndRunSimulation(simNotifier, context);
                            },
                            onReset: () {
                              FocusScope.of(context).unfocus();
                              simNotifier.reset();
                              // Update controllers with defaults from config
                              if (simState.config != null) {
                                _unitsController.text = simState
                                    .config!
                                    .defaultUnits
                                    .toString();
                                _yearsController.text = simState
                                    .config!
                                    .defaultYears
                                    .toString();
                              } else {
                                // Fallback
                                _unitsController.text = '1';
                                _yearsController.text = '10';
                              }
                            },
                          ),

                          const SizedBox(height: 22),
                          if (simState.treeData != null &&
                              simState.revenueData != null)
                            _buildDrawerStatsRow(simState, isDark)
                          else
                            const SizedBox.shrink(),

                          if (simState.treeData != null)
                            const SizedBox(height: 22),
                          if (simState.treeData != null)
                            _buildDrawerBuffaloTypeSection(simState, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    SimulationState simState,
    SimulationNotifier simNotifier,
    bool isDark,
  ) {
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
                    const SizedBox(width: 48),
                    Text(
                      'Buffalo Herd Investments',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewToggle(
                              icon: Icons.account_tree,
                              label: 'Tree View',
                              mode: ViewMode.tree,
                              isDark: isDark,
                              isMobile: false,
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
                              isMobile: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Inputs and Buttons (Horizontal layout for desktop)
                      SingleChildScrollView(
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
                                  final DateTime? picked = await showDatePicker(
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
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
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
                                        style: const TextStyle(fontSize: 13),
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
                                _validateAndRunSimulation(simNotifier, context);
                              },
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Run'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            if (simState.treeData != null &&
                                simState.revenueData != null)
                              _buildOverallStats(simState),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Status indicator
        // _buildStatusIndicator(simState, isDark),

        // Main Content Area
        Expanded(child: _buildMainContent(simState, isDark)),
      ],
    );
  }

  // Widget _buildStatusIndicator(SimulationState simState, bool isDark) {
  //   if (simState.isLoading) {
  //     return LinearProgressIndicator(color: Colors.blue[300]);
  //   } else if (simState.treeData == null && simState.revenueData == null) {
  //     return Container(
  //       padding: const EdgeInsets.all(16),
  //       color: isDark
  //           ? Colors.blue[900]!.withOpacity(0.3)
  //           : Colors.blue[50],
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             Icons.info,
  //             color: isDark ? Colors.blue[200] : Colors.blue[700],
  //           ),
  //           const SizedBox(width: 8),
  //           Flexible(
  //             child: Text(
  //               'Click "Run" to simulate and generate data for price estimation',
  //               style: TextStyle(
  //                 color: isDark ? Colors.blue[200] : Colors.blue[700],
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //   else {
  //     return Container(
  //       padding: const EdgeInsets.all(12),
  //       color: isDark
  //           ? Colors.green[900]!.withOpacity(0.3)
  //           : Colors.green[50],
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             Icons.check_circle,
  //             color: isDark ? Colors.green[300] : Colors.green[700],
  //           ),
  //           // const SizedBox(width: 8),
  //           // Flexible(
  //           //   child: Text(
  //           //     'Simulation data ready! ${simState.treeData!['totalBuffaloes']} buffaloes simulated over ${simState.years} years',
  //           //     style: TextStyle(
  //           //       color: isDark ? Colors.green[300] : Colors.green[700],
  //           //       fontWeight: FontWeight.bold,
  //           //     ),
  //           //     textAlign: TextAlign.center,
  //           //   ),
  //           // ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  Widget _buildMainContent(SimulationState simState, bool isDark) {
    if (_currentView == ViewMode.tree) {
      return Container(
        color: isDark ? Colors.black : Colors.grey[50],
        child: simState.treeData != null
            ? BuffaloTreeWidget(
                treeData: simState.treeData!,
                revenueData: simState.revenueData,
                theme: TreeTheme.vibrantGradients,
                selectedBuffaloType: _selectedBuffaloType,
                onSelectedBuffaloTypeChanged: (t) {
                  setState(() {
                    _selectedBuffaloType = t;
                  });
                },
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
                    Icon(Icons.account_tree, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No genealogy tree yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Run" to generate the buffalo family tree',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
      );
    } else {
      // ViewMode.estimation
      return (simState.treeData != null && simState.revenueData != null)
          ? CostEstimationTable(
              treeData: simState.treeData!,
              revenueData: simState.revenueData!,
              isEmbedded: true,
              config: simState.config,
            )
          : Container(
              color: isDark ? Colors.black : Colors.grey[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_chart, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No estimation data yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Run" to generate data for price estimation',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
    }
  }

  void _validateAndRunSimulation(
    SimulationNotifier simNotifier,
    BuildContext context,
  ) {
    final unitsText = _unitsController.text.trim();
    final double? unitsVal = double.tryParse(unitsText);

    if (unitsVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isValid = false;
    if (unitsVal == 0.5) {
      isValid = true;
    } else if (unitsVal >= 1 && (unitsVal % 1 == 0)) {
      isValid = true;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      years: int.tryParse(_yearsController.text),
    );
    simNotifier.runSimulation();
  }

  // Full currency format
  String _formatCurrency(double value) {
    String result = value.toInt().toString();
    return '₹${result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  double _calculateAssetValue(SimulationState simState) {
    final buffaloes = simState.treeData!['buffaloes'] as List<dynamic>;
    final years = simState.years;
    final startYear = simState.startDate.year;
    final List<dynamic> yearlyData =
        simState.revenueData!['yearlyData'] as List<dynamic>;
    final lastYear = yearlyData.isNotEmpty
        ? yearlyData.last['year'] as int
        : startYear + years - 1;
    final targetMonth = 11;

    double totalAssetValue = 0;
    for (final b in buffaloes) {
      final birthYear = b['birthYear'] as int?;
      if (birthYear == null || lastYear < birthYear) continue;

      final birthMonth =
          (b['birthMonth'] as int?) ?? (b['acquisitionMonth'] as int?) ?? 0;
      final ageInMonths =
          ((lastYear - birthYear) * 12) + (targetMonth - birthMonth);
      if (ageInMonths < 0) continue;

      int value = 10000;
      if (simState.config?.assetValues != null) {
        final sortedKeys = simState.config!.assetValues.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        for (final threshold in sortedKeys) {
          if (ageInMonths >= threshold) {
            value = simState.config!.assetValues[threshold]!.toInt();
            break;
          }
        }
      } else {
        // Fallback (Updated to match new schedule)
        if (ageInMonths >= 49) {
          value = 200000;
        } else if (ageInMonths >= 41) {
          value = 175000;
        } else if (ageInMonths >= 35) {
          value = 150000;
        } else if (ageInMonths >= 25) {
          value = 100000;
        } else if (ageInMonths >= 19) {
          value = 40000;
        } else if (ageInMonths >= 13) {
          value = 25000;
        } else {
          value = 10000;
        }
      }

      totalAssetValue += value;
    }

    return totalAssetValue;
  }

  Widget _buildDrawerInputCard({
    required String label,
    required Widget child,
    required bool isDark,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }

  Widget _buildDrawerDateCard({
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 44,
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark ? Colors.black : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerRunResetRow({
    required bool isDark,
    required VoidCallback onRun,
    required VoidCallback onReset,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRun,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), // Green shade
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'RUN',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'RESET',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileViewModePillToggle(bool isDark) {
    const outerColor = Color(0xFF0B7A2A);
    const innerColor = Colors.white;

    void setMode(ViewMode mode) {
      if (_currentView == mode) return;
      setState(() {
        _currentView = mode;
      });
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outerColor, width: 1.4),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: innerColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 4.0;
            final segmentWidth = (constraints.maxWidth - gap) / 2;
            final isTree = _currentView == ViewMode.tree;

            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  left: isTree ? 0 : segmentWidth + gap,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: outerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setMode(ViewMode.tree),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Center(
                              child: Text(
                                'Tree',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setMode(ViewMode.estimation),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Center(
                              child: Text(
                                'Estimation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Tree',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isTree ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Estimation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isTree ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerStatsRow(SimulationState simState, bool isDark) {
    final buffaloes = simState.treeData!['buffaloes'] as List<dynamic>;
    final totalBuffaloes = buffaloes.length;
    final netRevenue =
        (simState.revenueData!['totalNetRevenue'] as num?)?.toDouble() ?? 0.0;
    final assetValue = _calculateAssetValue(simState);

    return Row(
      children: [
        Expanded(
          child: _buildDrawerStatCard(
            isDark: isDark,
            title: 'Final Herd',
            value: '$totalBuffaloes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDrawerStatCard(
            isDark: isDark,
            title: 'Net Revenue',
            value: _formatCurrency(netRevenue),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDrawerStatCard(
            isDark: isDark,
            title: 'Asset Value',
            value: _formatCurrency(assetValue),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerStatCard({
    required String title,
    required bool isDark,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isTypeAFromData(
    Map<String, dynamic> buffalo,
    Map<String, dynamic> treeData,
  ) {
    final startMonth = treeData['startMonth'] as int? ?? 0;
    final acqMonth = buffalo['acquisitionMonth'] as int? ?? startMonth;
    return acqMonth == startMonth;
  }

  int _getBuffaloCountFromState(SimulationState simState, String type) {
    final buffaloes = (simState.treeData?['buffaloes'] as List<dynamic>?) ?? [];
    if (type == 'ALL') return buffaloes.length;
    if (type == 'A') {
      return buffaloes
          .where(
            (b) =>
                _isTypeAFromData(b as Map<String, dynamic>, simState.treeData!),
          )
          .length;
    }
    return buffaloes
        .where(
          (b) =>
              !_isTypeAFromData(b as Map<String, dynamic>, simState.treeData!),
        )
        .length;
  }

  Widget _buildDrawerBuffaloTypeSection(SimulationState simState, isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDrawerTypeButton(
                    'A',
                    'Batch A',
                    'Start',
                    _getBuffaloCountFromState(simState, 'A'),
                  ),
                  if (_getBuffaloCountFromState(simState, 'B') > 0) ...[
                    const SizedBox(width: 6),
                    Container(width: 1, height: 20, color: Colors.grey[300]),
                    const SizedBox(width: 6),
                    _buildDrawerTypeButton(
                      'B',
                      'Batch B',
                      '+6mo',
                      _getBuffaloCountFromState(simState, 'B'),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(width: 1, height: 20, color: Colors.grey[300]),
                  const SizedBox(width: 6),
                  _buildDrawerTypeButton(
                    'ALL',
                    'All',
                    'Total',
                    _getBuffaloCountFromState(simState, 'ALL'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildDrawerFilteredStatsWidget(simState, isDark),
      ],
    );
  }

  Widget _buildDrawerTypeButton(
    String type,
    String label,
    String subLabel,
    int count,
  ) {
    final isSelected = _selectedBuffaloType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBuffaloType = type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (type == 'A'
                      ? Colors.blue.withOpacity(0.1)
                      : type == 'B'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (type == 'A'
                        ? Colors.blue
                        : type == 'B'
                        ? Colors.green
                        : Colors.purple)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (type == 'A'
                            ? Colors.blue.shade800
                            : type == 'B'
                            ? Colors.green.shade800
                            : Colors.purple.shade800)
                      : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$subLabel • $count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (type == 'A'
                            ? Colors.blue.shade600
                            : type == 'B'
                            ? Colors.green.shade600
                            : Colors.purple.shade600)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrencyShort(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  Widget _buildDrawerFilteredStatsWidget(SimulationState simState, isDark) {
    final treeData = simState.treeData as Map<String, dynamic>?;
    if (treeData == null) return const SizedBox.shrink();

    final buffaloes = (treeData['buffaloes'] as List<dynamic>?) ?? [];
    final filtered = _selectedBuffaloType == 'ALL'
        ? buffaloes
        : buffaloes.where((b) {
            final isA = _isTypeAFromData(b as Map<String, dynamic>, treeData);
            return _selectedBuffaloType == 'A' ? isA : !isA;
          }).toList();

    int producing = 0;
    int nonProducing = 0;
    double assetValue = 0;

    final startYear = treeData['startYear'] ?? DateTime.now().year;
    final years = treeData['years'] ?? 10;
    final targetYear = startYear + years - 1;
    final targetMonth = 11;

    for (final raw in filtered) {
      final b = raw as Map<String, dynamic>;
      final birthYear = b['birthYear'] as int? ?? startYear;
      final birthMonth =
          (b['birthMonth'] as int?) ?? (b['acquisitionMonth'] as int?) ?? 0;

      final ageInMonths =
          ((targetYear - birthYear) * 12) + (targetMonth - birthMonth);

      if (ageInMonths >= 38) {
        producing++;
      } else {
        nonProducing++;
      }

      if (ageInMonths >= 60)
        assetValue += 175000;
      else if (ageInMonths >= 48)
        assetValue += 150000;
      else if (ageInMonths >= 40)
        assetValue += 100000;
      else if (ageInMonths >= 36)
        assetValue += 50000;
      else if (ageInMonths >= 30)
        assetValue += 50000;
      else if (ageInMonths >= 24)
        assetValue += 35000;
      else if (ageInMonths >= 18)
        assetValue += 25000;
      else if (ageInMonths >= 12)
        assetValue += 12000;
      else if (ageInMonths >= 6)
        assetValue += 6000;
      else
        assetValue += 3000;
    }

    double estimatedNet = 0;
    if (simState.revenueData != null) {
      final totalNetRevenue =
          (simState.revenueData!['totalNetRevenue'] as num?)?.toDouble() ?? 0.0;
      final totalBuffaloes = treeData['totalBuffaloes'] as int? ?? 1;
      if (_selectedBuffaloType == 'ALL') {
        estimatedNet = totalNetRevenue;
      } else {
        final proportion = filtered.length / totalBuffaloes;
        estimatedNet = totalNetRevenue * proportion;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _buildDrawerBigStatCard(
          isDark: isDark,
          title: 'Buffaloes',
          value: '${filtered.length}',
        ),
        _buildDrawerBigStatCard(
          isDark: isDark,
          title: 'Cumulative Net',
          value: _formatCurrencyShort(estimatedNet),
        ),
        _buildDrawerBigStatCard(
          isDark: isDark,
          title: 'Asset Value',
          value: _formatCurrencyShort(assetValue),
        ),
        _buildDrawerBigStatCard(
          isDark: isDark,
          title: 'Producing',
          value: '$producing',
        ),
        _buildDrawerBigStatCard(
          isDark: isDark,
          title: 'Non-Producing',
          value: '$nonProducing',
        ),
      ],
    );
  }

  Widget _buildDrawerBigStatCard({
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF333333), const Color(0xFF1F1F1F)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF0F2F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(SimulationState simState) {
    if (simState.treeData == null || simState.revenueData == null) {
      return const SizedBox.shrink();
    }

    final buffaloes = simState.treeData!['buffaloes'] as List<dynamic>;
    final netRevenue =
        (simState.revenueData!['totalNetRevenue'] as num?)?.toDouble() ?? 0.0;
    final years = simState.years;
    final startYear = simState.startDate.year;
    final List<dynamic> yearlyData =
        simState.revenueData!['yearlyData'] as List<dynamic>;
    final lastYear = yearlyData.isNotEmpty
        ? yearlyData.last['year'] as int
        : startYear + years - 1;
    final targetMonth = 11;

    // 1. Final Herd Size
    final totalBuffaloes = buffaloes.length;

    // 3. Asset Value
    double totalAssetValue = 0;
    for (final b in buffaloes) {
      final birthYear = b['birthYear'] as int?;
      if (birthYear == null || lastYear < birthYear) continue;

      final birthMonth =
          (b['birthMonth'] as int?) ?? (b['acquisitionMonth'] as int?) ?? 0;
      final ageInMonths =
          ((lastYear - birthYear) * 12) + (targetMonth - birthMonth);

      if (ageInMonths < 0) continue;

      int value = 3000;
      if (simState.config?.assetValues != null) {
        final sortedKeys = simState.config!.assetValues.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        for (final threshold in sortedKeys) {
          if (ageInMonths >= threshold) {
            value = simState.config!.assetValues[threshold]!.toInt();
            break;
          }
        }
      } else {
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
      }

      totalAssetValue += value;
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Simulation Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                _buildMobileStatItem('FINAL HERD', '$totalBuffaloes'),
                const SizedBox(height: 12),
                _buildMobileStatItem(
                  'NET REVENUE',
                  _formatCurrency(netRevenue),
                  color: Colors.green[700],
                ),
                const SizedBox(height: 12),
                _buildMobileStatItem(
                  'ASSET VALUE',
                  _formatCurrency(totalAssetValue),
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
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

  Widget _buildMobileStatItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildMobileViewToggle(String label, ViewMode mode, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_currentView == mode) return;
          setState(() {
            _currentView = mode;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[200]
                          : Colors.grey[800]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required String label,
    required ViewMode mode,
    required bool isDark,
    bool isMobile = false,
  }) {
    final isSelected = _currentView == mode;
    if (isMobile) {
      return _buildMobileViewToggle(label, mode, isSelected);
    }
    return InkWell(
      onTap: () => setState(() => _currentView = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
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
              size: isMobile ? 16 : 20,
              color: isSelected
                  ? (isDark ? Colors.blue[200] : Colors.blue[700])
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 16,
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
