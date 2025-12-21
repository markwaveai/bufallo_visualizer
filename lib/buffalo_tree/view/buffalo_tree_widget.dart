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
  final String? selectedBuffaloType;
  final ValueChanged<String>? onSelectedBuffaloTypeChanged;

  const BuffaloTreeWidget({
    super.key,
    required this.treeData,
    this.revenueData,
    this.theme = TreeTheme.vibrantGradients,
    this.nodeShape = NodeShape.roundedRectangle,
    this.onAnalyticsPressed,
    this.onFullscreenChanged,
    this.selectedBuffaloType,
    this.onSelectedBuffaloTypeChanged,
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
    _selectedBuffaloType = widget.selectedBuffaloType ?? 'A';
    _parseTreeData();
  }

  @override
  void didUpdateWidget(BuffaloTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeData != widget.treeData) {
      _parseTreeData();
    }

    if (widget.selectedBuffaloType != null &&
        oldWidget.selectedBuffaloType != widget.selectedBuffaloType &&
        widget.selectedBuffaloType != _selectedBuffaloType) {
      setState(() {
        _selectedBuffaloType = widget.selectedBuffaloType!;
        _parseTreeData();
      });
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Stack(
          children: [
            // Tree visualization
            OrganizationTreeWidget(
              rootNode: _rootNode!,
              theme: widget.theme,
              nodeShape: widget.nodeShape,
              orientation: isMobile
                  ? TreeOrientation.horizontal
                  : TreeOrientation.vertical,
              onControllerReady: (controller) {
                _transformationController = controller;
              },
            ),

            // Buffalo Type Toggle + Filtered Stats (Top-Left)
            // Type Toggle and Stats (Hidden in fullscreen)

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
                    icon: _isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    onPressed: () {
                      setState(() {
                        _isFullscreen = !_isFullscreen;
                      });
                      // Notify parent about fullscreen state change
                      widget.onFullscreenChanged?.call(_isFullscreen);
                    },
                    tooltip: _isFullscreen
                        ? 'Exit Fullscreen'
                        : 'Fullscreen View',
                    backgroundColor: _isFullscreen ? Colors.orange : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
