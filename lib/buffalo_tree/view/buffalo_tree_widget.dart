import 'package:flutter/material.dart';
import '../models/buffalo_node.dart';
import '../models/node_shape.dart';
import '../models/tree_theme.dart';
import '../widgets/organization_tree_widget.dart';

/// Standalone Buffalo Tree Widget that can be embedded in any Flutter app
/// Receives treeData and displays the genealogy tree visualization
class BuffaloTreeWidget extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic>? revenueData;
  final TreeTheme theme;
  final NodeShape nodeShape;
  final VoidCallback? onAnalyticsPressed;
  final ValueChanged<bool>? onFullscreenChanged;

  const BuffaloTreeWidget({
    super.key,
    required this.treeData,
    this.revenueData,
    this.theme = TreeTheme.vibrantGradients,
    this.nodeShape = NodeShape.roundedRectangle,
    this.onAnalyticsPressed,
    this.onFullscreenChanged,
  });

  @override
  State<BuffaloTreeWidget> createState() => _BuffaloTreeWidgetState();
}

class _BuffaloTreeWidgetState extends State<BuffaloTreeWidget> {
  late BuffaloNode? _rootNode;
  TransformationController? _transformationController;
  String _selectedBuffaloType = 'A'; // 'A' or 'B' or 'ALL'
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _parseTreeData();
  }

  @override
  void didUpdateWidget(BuffaloTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeData != widget.treeData) {
      _parseTreeData();
    }
  }

  // Check if buffalo belongs to Type A (Batch A - Jan/Start Month)
  bool _isTypeA(Map<String, dynamic> buffalo) {
    final startMonth = widget.treeData['startMonth'] as int? ?? 0;
    // Default to startMonth if missing to treat as Type A
    final acqMonth = buffalo['acquisitionMonth'] as int? ?? startMonth;
    return acqMonth == startMonth;
  }

  bool _isTypeB(Map<String, dynamic> buffalo) {
    return !_isTypeA(buffalo);
  }

  void _parseTreeData() {
    // Convert the tree data to BuffaloNode structure
    try {
      final buffaloes = widget.treeData['buffaloes'] as List<dynamic>? ?? [];

      if (buffaloes.isEmpty) {
        setState(() => _rootNode = null);
        return;
      }

      // Pre-check: If Type B is selected but no Type B buffaloes exist, switch to A
      if (_selectedBuffaloType == 'B' && _getBuffaloCount('B') == 0) {
        _selectedBuffaloType = 'A';
      }

      // Filter buffaloes based on selected type
      List<dynamic> filteredBuffaloes;
      if (_selectedBuffaloType == 'ALL') {
        filteredBuffaloes = buffaloes;
      } else {
        filteredBuffaloes = buffaloes.where((buffalo) {
          if (_selectedBuffaloType == 'A') {
            return _isTypeA(buffalo as Map<String, dynamic>);
          } else {
            return _isTypeB(buffalo as Map<String, dynamic>);
          }
        }).toList();
      }

      // Build tree from filtered buffaloes list
      final Map<dynamic, BuffaloNode> nodeMap = {};

      // First pass: create all nodes
      final currentYear =
          (widget.treeData['startYear'] as int? ?? DateTime.now().year) +
          (widget.treeData['years'] as int? ?? 10);

      for (final buffalo in filteredBuffaloes) {
        final id = buffalo['id'].toString();
        final birthYear = buffalo['birthYear'] as int;
        final age = currentYear - birthYear;
        // Check lineage based on acquisition month property
        final isTypeA = _isTypeA(buffalo as Map<String, dynamic>);

        final node = BuffaloNode(
          id: id,
          name: '${isTypeA ? "A" : "B"}$id\nUnit ${buffalo['unit']}',
          birthYear: birthYear,
          generation: buffalo['generation'] as int,
          parentId: buffalo['parentId']?.toString(),
          unit: buffalo['unit'] as int,
          data: {
            'type': isTypeA ? 'Type A' : 'Type B',
            'age': '$age years',
            'status': age >= 3 ? 'Mature' : 'Calf',
            'desc': isTypeA ? 'Pays CPF' : 'Free Period',
            'birthYear': birthYear,
            'birthMonth': buffalo['birthMonth'],
            'acquisitionMonth': buffalo['acquisitionMonth'],
          },
        );
        nodeMap[id] = node;
      }

      // Second pass: build parent-child relationships
      for (final buffalo in filteredBuffaloes) {
        final id = buffalo['id'].toString();
        final parentId = buffalo['parentId']?.toString();

        if (parentId != null && nodeMap.containsKey(parentId)) {
          nodeMap[parentId]?.children.add(nodeMap[id]!);
        }
      }

      // Find root nodes for the filtered tree
      // When filtering by type, the Gen 0 buffalo (A or B) is the root
      final roots = nodeMap.values
          .where(
            (node) =>
                node.generation == 0 || // Gen 0 is always root
                node.parentId == null || // No parent means root
                !nodeMap.containsKey(
                  node.parentId,
                ), // Parent not in filtered list
          )
          .toList();

      setState(() {
        if (roots.isEmpty) {
          _rootNode = null;
        } else if (roots.length == 1) {
          // Single root - use it directly
          _rootNode = roots.first;
        } else {
          // Multiple roots (e.g., "All" showing both A and B)
          // Create a virtual root that contains all roots as children
          final virtualRoot = BuffaloNode(
            id: 'all_root',
            name: 'All',
            birthYear: widget.treeData['startYear'] ?? DateTime.now().year,
            generation: -1, // Virtual root is before Gen 0
            parentId: null,
            unit: 0,
          );

          // Add all roots as children of the virtual root
          for (final root in roots) {
            virtualRoot.children.add(root);
          }

          _rootNode = virtualRoot;
        }
      });
    } catch (e) {
      print('Error parsing tree data: $e');
      setState(() => _rootNode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rootNode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_tree, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tree data available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Run simulation to generate buffalo genealogy',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Tree visualization
        OrganizationTreeWidget(
          rootNode: _rootNode!,
          theme: widget.theme,
          nodeShape: widget.nodeShape,
          onControllerReady: (controller) {
            _transformationController = controller;
          },
        ),

        // Buffalo Type Toggle + Filtered Stats (Top-Left)
        // Type Toggle and Stats (Hidden in fullscreen)
        if (!_isFullscreen)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  // Mobile: Vertical stack with scrollable stats
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type Toggle - Scrollable on very small screens
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
                                _buildTypeButton(
                                  'A',
                                  'Batch A',
                                  'Start',
                                  _getBuffaloCount('A'),
                                  compact: true,
                                ),
                                if (_getBuffaloCount('B') > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildTypeButton(
                                    'B',
                                    'Batch B',
                                    '+6mo',
                                    _getBuffaloCount('B'),
                                    compact: true,
                                  ),
                                ],
                                const SizedBox(width: 6),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(width: 6),
                                _buildTypeButton(
                                  'ALL',
                                  'All',
                                  'Total',
                                  _getBuffaloCount('ALL'),
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Filtered Stats - Scrollable
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildFilteredStatsWidget(),
                      ),
                    ],
                  );
                } else {
                  // Desktop: Horizontal layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTypeButton(
                                'A',
                                'Batch A (Jan)',
                                'Start Month',
                                _getBuffaloCount('A'),
                              ),
                              if (_getBuffaloCount('B') > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(width: 8),
                                _buildTypeButton(
                                  'B',
                                  'Batch B (July)',
                                  '+6 Months',
                                  _getBuffaloCount('B'),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(width: 8),
                              _buildTypeButton(
                                'ALL',
                                'View All',
                                'Combined',
                                _getBuffaloCount('ALL'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Filtered Stats
                      _buildFilteredStatsWidget(),
                    ],
                  );
                }
              },
            ),
          ),

        // Zoom controls (Moved to Bottom Right)
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              _buildZoomButton(
                icon: Icons.zoom_in,
                onPressed: () {
                  if (_transformationController != null) {
                    final currentScale = _transformationController!.value
                        .getMaxScaleOnAxis();
                    final newScale = (currentScale * 1.2).clamp(0.1, 4.0);
                    _transformationController!.value = Matrix4.identity()
                      ..scale(newScale);
                  }
                },
                tooltip: 'Zoom In',
              ),
              const SizedBox(height: 8),
              _buildZoomButton(
                icon: Icons.zoom_out,
                onPressed: () {
                  if (_transformationController != null) {
                    final currentScale = _transformationController!.value
                        .getMaxScaleOnAxis();
                    final newScale = (currentScale / 1.2).clamp(0.1, 4.0);
                    _transformationController!.value = Matrix4.identity()
                      ..scale(newScale);
                  }
                },
                tooltip: 'Zoom Out',
              ),
              const SizedBox(height: 8),
              _buildZoomButton(
                icon: Icons.center_focus_strong,
                onPressed: () {
                  if (_transformationController != null) {
                    _transformationController!.value = Matrix4.identity();
                  }
                },
                tooltip: 'Reset Zoom',
              ),
              if (widget.onAnalyticsPressed != null) ...[
                const SizedBox(height: 8),
                _buildZoomButton(
                  icon: Icons.analytics,
                  onPressed: widget.onAnalyticsPressed!,
                  tooltip: 'View Analytics',
                ),
              ],
              const SizedBox(height: 8),
              _buildZoomButton(
                icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: () {
                  setState(() {
                    _isFullscreen = !_isFullscreen;
                  });
                  // Notify parent about fullscreen state change
                  widget.onFullscreenChanged?.call(_isFullscreen);
                },
                tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen View',
                backgroundColor: _isFullscreen ? Colors.orange : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Get buffalo count for each filter type
  int _getBuffaloCount(String type) {
    final buffaloes = widget.treeData['buffaloes'] as List<dynamic>? ?? [];

    if (type == 'ALL') {
      return buffaloes.length;
    }

    // Count buffaloes of selected type
    return buffaloes.where((buffalo) {
      if (type == 'A') {
        return _isTypeA(buffalo as Map<String, dynamic>);
      } else {
        return _isTypeB(buffalo as Map<String, dynamic>);
      }
    }).length;
  }

  // Calculate stats for a given list of buffaloes
  Map<String, dynamic> _calculateStats(List<dynamic> buffaloList) {
    int producing = 0;
    int nonProducing = 0;
    double assetValue = 0;
    double estimatedNet = 0;

    final currentYear =
        (widget.treeData['startYear'] as int? ?? DateTime.now().year) +
        (widget.treeData['years'] as int? ?? 10);

    for (final buffalo in buffaloList) {
      final birthYear = buffalo['birthYear'] as int;
      final age = currentYear - birthYear;
      final isMature = age >= 3;

      if (isMature) {
        producing++;
        assetValue += 150000; // ₹1.5L
        // Crude estimate: Revenue (12k/yr) for (Age-3) years - some costs
        // Using a heuristic multiplier for "Cumulative Net" based on user image ratio (~0.8 of Asset)
        estimatedNet += 150000 * 0.8;
      } else {
        nonProducing++;
        assetValue += 60000; // ₹60k
        estimatedNet +=
            0; // Calves have cost, but let's assume net ~ 0 or handled in producing
      }
    }

    return {
      'count': buffaloList.length,
      'producing': producing,
      'nonProducing': nonProducing,
      'assetValue': assetValue,
      'net': estimatedNet,
    };
  }

  // Format currency with L/Cr
  String _formatCurrencyShort(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  Widget _buildFilteredStatsWidget() {
    if (_rootNode == null) return const SizedBox.shrink();

    List<BuffaloNode> nodes = [];
    void traverse(BuffaloNode n) {
      if (n.id != 'all_root') nodes.add(n);
      for (var c in n.children) traverse(c);
    }

    traverse(_rootNode!);

    int producing = 0;
    int nonProducing = 0;
    double assetValue = 0;
    double estimatedNet = 0;

    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;
    // Target: Last year of simulation (matching CostEstimationTable)
    final targetYear = startYear + years - 1;
    final targetMonth = 11; // Dec

    for (var n in nodes) {
      final birthYear = n.data['birthYear'] as int? ?? startYear;
      final birthMonth =
          (n.data['birthMonth'] as int?) ??
          (n.data['acquisitionMonth'] as int?) ??
          0;

      final ageInMonths =
          ((targetYear - birthYear) * 12) + (targetMonth - birthMonth);

      // Strict Producing Check: Age >= 38 Months matches CostEstimationTable
      if (ageInMonths >= 38) {
        producing++;
      } else {
        nonProducing++;
      }

      // Asset Value Approximation (Exact Month Table)
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

      // Cumulative Net: Use exact value from simulation when available
      // For filtered views, calculate proportionally
      // (This will be replaced with exact calculation below)
    }

    // Calculate Cumulative Net using exact simulation data
    if (widget.revenueData != null) {
      final totalNetRevenue =
          (widget.revenueData!['totalNetRevenue'] as num?)?.toDouble() ?? 0.0;
      final totalBuffaloes = widget.treeData['totalBuffaloes'] as int? ?? 1;

      // If showing all buffaloes, use exact total
      // If filtered, proportion based on visible count
      if (_selectedBuffaloType == 'ALL') {
        estimatedNet = totalNetRevenue;
      } else {
        // Proportion based on buffalo count
        final proportion = nodes.length / totalBuffaloes;
        estimatedNet = totalNetRevenue * proportion;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatCard('BUFFALOES', '${nodes.length}'),
        const SizedBox(width: 8),
        _buildStatCard(
          'CUMULATIVE NET',
          _formatCurrencyShort(estimatedNet),
          valueColor: Colors.green[700],
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'ASSET VALUE',
          _formatCurrencyShort(assetValue),
          valueColor: Colors.blue[700],
        ),
        const SizedBox(width: 8),
        _buildStatCard('PRODUCING', '$producing', valueColor: Colors.teal[700]),
        const SizedBox(width: 8),
        _buildStatCard(
          'NON-PRODUCING',
          '$nonProducing',
          valueColor: Colors.orange[800],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String label,
    String subLabel,
    int count, {
    bool compact = false,
  }) {
    final isSelected = _selectedBuffaloType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBuffaloType = type;
            _parseTreeData(); // Rebuild tree with new filter
          });
        },
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (type == 'A'
                      ? Colors.blue.withOpacity(0.1)
                      : type == 'B'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: isSelected
                  ? (type == 'A'
                        ? Colors.blue
                        : type == 'B'
                        ? Colors.green
                        : Colors.purple)
                  : Colors.transparent,
              width: compact ? 1.2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 14,
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
              SizedBox(height: compact ? 1 : 2),
              Text(
                '$subLabel • $count 🐃',
                style: TextStyle(
                  fontSize: compact ? 9 : 11,
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

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: backgroundColor != null ? Colors.white : Colors.blue.shade600,
          iconSize: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
