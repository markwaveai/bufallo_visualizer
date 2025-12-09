import 'package:flutter/material.dart';
import '../models/buffalo_node.dart';
import '../models/node_shape.dart';
import '../models/tree_theme.dart';
import '../widgets/organization_tree_widget.dart';

/// Standalone Buffalo Tree Widget that can be embedded in any Flutter app
/// Receives treeData and displays the genealogy tree visualization
class BuffaloTreeWidget extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final TreeTheme theme;
  final NodeShape nodeShape;
  final VoidCallback? onAnalyticsPressed;

  const BuffaloTreeWidget({
    super.key,
    required this.treeData,
    this.theme = TreeTheme.vibrantGradients,
    this.nodeShape = NodeShape.roundedRectangle,
    this.onAnalyticsPressed,
  });

  @override
  State<BuffaloTreeWidget> createState() => _BuffaloTreeWidgetState();
}

class _BuffaloTreeWidgetState extends State<BuffaloTreeWidget> {
  late BuffaloNode? _rootNode;
  TransformationController? _transformationController;

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

  void _parseTreeData() {
    // Convert the tree data to BuffaloNode structure
    try {
      final buffaloes = widget.treeData['buffaloes'] as List<dynamic>? ?? [];
      
      if (buffaloes.isEmpty) {
        setState(() => _rootNode = null);
        return;
      }

      // Build tree from buffaloes list
      final Map<dynamic, BuffaloNode> nodeMap = {};
      
      // First pass: create all nodes
      for (final buffalo in buffaloes) {
        final id = buffalo['id'].toString();
        final node = BuffaloNode(
          id: id,
          name: 'Unit ${buffalo['unit']} - Gen ${buffalo['generation']}',
          birthYear: buffalo['birthYear'] as int,
          generation: buffalo['generation'] as int,
          parentId: buffalo['parentId']?.toString(),
          unit: buffalo['unit'] as int,
        );
        nodeMap[id] = node;
      }

      // Second pass: build parent-child relationships
      for (final buffalo in buffaloes) {
        final id = buffalo['id'].toString();
        final parentId = buffalo['parentId']?.toString();
        
        if (parentId != null && nodeMap.containsKey(parentId)) {
          nodeMap[parentId]?.children.add(nodeMap[id]!);
        }
      }

      // Find root nodes (those with no parent)
      final roots = nodeMap.values.where((node) => node.parentId == null).toList();
      
      setState(() {
        _rootNode = roots.isNotEmpty ? roots.first : null;
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Run simulation to generate buffalo genealogy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
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
        
        // Zoom controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildZoomButton(
                icon: Icons.zoom_in,
                onPressed: () {
                  if (_transformationController != null) {
                    final currentScale = _transformationController!.value.getMaxScaleOnAxis();
                    final newScale = (currentScale * 1.2).clamp(0.1, 4.0);
                    _transformationController!.value = Matrix4.identity()..scale(newScale);
                  }
                },
                tooltip: 'Zoom In',
              ),
              const SizedBox(height: 8),
              _buildZoomButton(
                icon: Icons.zoom_out,
                onPressed: () {
                  if (_transformationController != null) {
                    final currentScale = _transformationController!.value.getMaxScaleOnAxis();
                    final newScale = (currentScale / 1.2).clamp(0.1, 4.0);
                    _transformationController!.value = Matrix4.identity()..scale(newScale);
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
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
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: Colors.blue.shade600,
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
