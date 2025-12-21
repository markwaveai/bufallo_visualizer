import 'package:buffalo_visualizer/buffalo_tree/models/buffalo_node.dart';
import 'package:buffalo_visualizer/buffalo_tree/models/node_shape.dart';
import 'package:buffalo_visualizer/buffalo_tree/models/tree_theme.dart';
import 'package:buffalo_visualizer/buffalo_tree/utils/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;

enum TreeOrientation { vertical, horizontal }

class OrganizationTreeWidget extends StatefulWidget {
  final BuffaloNode rootNode;
  final Function(String nodeId)? onNodeTap;
  final TreeTheme theme;
  final NodeShape nodeShape;
  final Function(TransformationController)? onControllerReady;
  final TreeOrientation orientation;

  const OrganizationTreeWidget({
    super.key,
    required this.rootNode,
    this.onNodeTap,
    this.theme = TreeTheme.vibrantGradients,
    this.nodeShape = NodeShape.roundedRectangle,
    this.onControllerReady,
    this.orientation = TreeOrientation.vertical,
  });

  @override
  State<OrganizationTreeWidget> createState() => _OrganizationTreeWidgetState();
}

class _OrganizationTreeWidgetState extends State<OrganizationTreeWidget> {
  String? hoveredNodeId;
  String? selectedNodeId;
  List<PositionedNode> positionedNodes = [];
  List<ConnectionLine> connections = [];
  Size canvasSize = Size.zero;
  final TransformationController _transformationController =
      TransformationController();
  double? _lastRootX;
  double? _lastRootY;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _calculateLayout();

    // Initial zoom out (0.6x)
    _transformationController.value = Matrix4.identity()..scale(0.6);

    // Expose the transformation controller to parent
    widget.onControllerReady?.call(_transformationController);
  }

  @override
  void didUpdateWidget(OrganizationTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode ||
        oldWidget.orientation != widget.orientation) {
      _calculateLayout();
    }
  }

  void _calculateLayout() {
    final treeInfo = _calculateTreeDimensions(widget.rootNode);
    canvasSize = Size(
      treeInfo.width + Dimensions.screenPadding * 2,
      treeInfo.height + Dimensions.screenPadding * 2,
    );
    _lastRootX = null;
    _lastRootY = null;
  }

  void _positionNodesWithStart(double startX, double startY) {
    positionedNodes = [];
    connections = [];
    _positionNodes(widget.rootNode, startX, startY, 0);
  }

  TreeDimensions _calculateTreeDimensions(BuffaloNode node) {
    if (node.children.isEmpty) {
      return TreeDimensions(
        width: Dimensions.nodeWidth,
        height: Dimensions.nodeHeight,
      );
    }

    Map<String, TreeDimensions> dimensionsCache = {};
    _calculateDimensionsBottomUp(node, dimensionsCache);

    return dimensionsCache[node.id]!;
  }

  void _calculateDimensionsBottomUp(
    BuffaloNode node,
    Map<String, TreeDimensions> cache,
  ) {
    final nodeWidth = widget.orientation == TreeOrientation.horizontal
        ? 110.0
        : Dimensions.nodeWidth;
    final nodeHeight = widget.orientation == TreeOrientation.horizontal
        ? 50.0
        : Dimensions.nodeHeight;

    List<BuffaloNode> stack = [node];
    List<BuffaloNode> processed = [];

    while (stack.isNotEmpty) {
      BuffaloNode current = stack.last;

      bool allChildrenProcessed = true;
      if (current.children.isNotEmpty) {
        for (var child in current.children) {
          if (!processed.contains(child)) {
            allChildrenProcessed = false;
            stack.add(child);
          }
        }
      }

      if (allChildrenProcessed) {
        processed.add(current);
        stack.removeLast();
      }
    }

    for (var currentNode in processed) {
      if (currentNode.children.isEmpty) {
        cache[currentNode.id] = TreeDimensions(
          width: nodeWidth,
          height: nodeHeight,
        );
      } else {
        if (widget.orientation == TreeOrientation.vertical) {
          // Vertical (Top-Down) Logic
          double totalWidth = 0;
          double maxHeight = nodeHeight;

          for (var child in currentNode.children) {
            final childDim = cache[child.id]!;
            totalWidth += childDim.width + Dimensions.siblingSpacing;

            double childTreeHeight =
                nodeHeight + Dimensions.levelSpacing + childDim.height;
            if (childTreeHeight > maxHeight) {
              maxHeight = childTreeHeight;
            }
          }

          totalWidth -= Dimensions.siblingSpacing;

          cache[currentNode.id] = TreeDimensions(
            width: totalWidth > nodeWidth ? totalWidth : nodeWidth,
            height: maxHeight,
          );
        } else {
          // Horizontal (Left-Right) Logic
          double totalHeight = 0;
          double maxWidth = nodeWidth;

          for (var child in currentNode.children) {
            final childDim = cache[child.id]!;
            totalHeight += childDim.height + Dimensions.siblingSpacing;

            double childTreeWidth =
                nodeWidth + Dimensions.levelSpacing + childDim.width;
            if (childTreeWidth > maxWidth) {
              maxWidth = childTreeWidth;
            }
          }

          totalHeight -= Dimensions.siblingSpacing;

          cache[currentNode.id] = TreeDimensions(
            width: maxWidth,
            height: totalHeight > nodeHeight ? totalHeight : nodeHeight,
          );
        }
      }
    }
  }

  void _positionNodes(BuffaloNode node, double x, double y, int level) {
    final nodeWidth = widget.orientation == TreeOrientation.horizontal
        ? 110.0
        : Dimensions.nodeWidth;
    final nodeHeight = widget.orientation == TreeOrientation.horizontal
        ? 50.0
        : Dimensions.nodeHeight;

    List<_NodePositionInfo> queue = [
      _NodePositionInfo(node: node, x: x, y: y, level: level),
    ];

    while (queue.isNotEmpty) {
      _NodePositionInfo info = queue.removeAt(0);
      BuffaloNode currentNode = info.node;
      double currentX = info.x;
      double currentY = info.y;
      int currentLevel = info.level;

      final position = Offset(currentX, currentY);
      positionedNodes.add(
        PositionedNode(
          node: currentNode,
          position: position,
          size: Size(nodeWidth, nodeHeight),
        ),
      );

      if (currentNode.children.isNotEmpty) {
        if (widget.orientation == TreeOrientation.vertical) {
          // Vertical Layout
          final childY = currentY + nodeHeight + Dimensions.levelSpacing;

          double totalChildrenWidth = 0;
          for (var child in currentNode.children) {
            final childDim = _calculateTreeDimensions(child);
            totalChildrenWidth += childDim.width + Dimensions.siblingSpacing;
          }
          totalChildrenWidth -= Dimensions.siblingSpacing;

          double childStartX =
              currentX + (nodeWidth / 2) - (totalChildrenWidth / 2);

          for (var child in currentNode.children) {
            final childDim = _calculateTreeDimensions(child);

            final childNodeX =
                childStartX + (childDim.width / 2) - (nodeWidth / 2);

            final childConnectionX = childNodeX + (nodeWidth / 2);

            connections.add(
              ConnectionLine(
                start: Offset(currentX + nodeWidth / 2, currentY + nodeHeight),
                end: Offset(childConnectionX, childY),
              ),
            );

            queue.add(
              _NodePositionInfo(
                node: child,
                x: childNodeX,
                y: childY,
                level: currentLevel + 1,
              ),
            );

            childStartX += childDim.width + Dimensions.siblingSpacing;
          }
        } else {
          // Horizontal Layout
          final childX = currentX + nodeWidth + Dimensions.levelSpacing;

          double totalChildrenHeight = 0;
          for (var child in currentNode.children) {
            final childDim = _calculateTreeDimensions(child);
            totalChildrenHeight += childDim.height + Dimensions.siblingSpacing;
          }
          totalChildrenHeight -= Dimensions.siblingSpacing;

          // Center children vertically relative to parent
          double childStartY =
              currentY + (nodeHeight / 2) - (totalChildrenHeight / 2);

          for (var child in currentNode.children) {
            final childDim = _calculateTreeDimensions(child);

            // The child's "height" is the height of its entire subtree.
            // We place the child node centered within that subtree height.
            // But wait, our drawing logic assumes (x,y) is top-left of node.
            // If we just stack them, it's easier.

            // Let's optimize visual alignment:
            // The slot for this child tree starts at childStartY.
            // It has height childDim.height.
            // We want to place the child node such that it is vertically centered in this slot.
            // childNodeY = childStartY + (childDim.height / 2) - (nodeHeight / 2)

            final childNodeY =
                childStartY + (childDim.height / 2) - (nodeHeight / 2);

            final childConnectionY = childNodeY + (nodeHeight / 2);

            connections.add(
              ConnectionLine(
                start: Offset(currentX + nodeWidth, currentY + nodeHeight / 2),
                end: Offset(childX, childConnectionY),
              ),
            );

            queue.add(
              _NodePositionInfo(
                node: child,
                x: childX,
                y: childNodeY,
                level: currentLevel + 1,
              ),
            );

            childStartY += childDim.height + Dimensions.siblingSpacing;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = canvasSize.width > constraints.maxWidth
            ? canvasSize.width
            : constraints.maxWidth;
        final effectiveHeight = canvasSize.height > constraints.maxHeight
            ? canvasSize.height
            : constraints.maxHeight;

        final nodeWidth = widget.orientation == TreeOrientation.horizontal
            ? 110.0
            : Dimensions.nodeWidth;
        final nodeHeight = widget.orientation == TreeOrientation.horizontal
            ? 50.0
            : Dimensions.nodeHeight;

        double rootX;
        double rootY;

        if (widget.orientation == TreeOrientation.vertical) {
          rootX = (effectiveWidth / 2) - (nodeWidth / 2);
          rootY = Dimensions.screenPadding;
        } else {
          // Horizontal: Start from left, vertically centered
          rootX = Dimensions.screenPadding;
          rootY = (effectiveHeight / 2) - (nodeHeight / 2);
        }

        if (_lastRootX != rootX || _lastRootY != rootY) {
          _positionNodesWithStart(rootX, rootY);
          _lastRootX = rootX;
          _lastRootY = rootY;
        }

        return GestureDetector(
          onTapUp: (details) {
            _handleTapWithTransform(details.localPosition);
          },
          onLongPressStart: (details) {
            _handleLongPress(details.localPosition);
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.001,
            maxScale: 4.0,
            constrained: false,
            child: SizedBox(
              width: effectiveWidth,
              height: effectiveHeight,
              child: Stack(
                children: [
                  MouseRegion(
                    onHover: (event) {
                      _handleHover(event.localPosition);
                    },
                    onExit: (_) {
                      setState(() {
                        hoveredNodeId = null;
                      });
                    },
                    child: CustomPaint(
                      size: Size(effectiveWidth, effectiveHeight),
                      painter: BuffaloTreeCanvasPainter(
                        positionedNodes: positionedNodes,
                        connections: connections,
                        hoveredNodeId: hoveredNodeId,
                        themeData: TreeThemeData.getTheme(widget.theme),
                        nodeShape: widget.nodeShape,
                        orientation: widget.orientation,
                      ),
                      foregroundPainter: _NodeTextPainter(
                        positionedNodes: positionedNodes,
                        themeData: TreeThemeData.getTheme(widget.theme),
                        nodeShape: widget.nodeShape,
                      ),
                    ),
                  ),
                  if (hoveredNodeId != null && _hoverPosition != null)
                    _buildTooltip(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapWithTransform(Offset position) {
    final Matrix4 transform = _transformationController.value;
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final Vector3 canvasPoint = inverseTransform.transform3(
      Vector3(position.dx, position.dy, 0),
    );
    final Offset canvasPosition = Offset(canvasPoint.x, canvasPoint.y);

    _handleTap(canvasPosition);
  }

  void _handleTap(Offset position) {
    for (var posNode in positionedNodes) {
      if (posNode.rect.contains(position)) {
        widget.onNodeTap?.call(posNode.node.id);
        return;
      }
    }
  }

  void _handleHover(Offset position) {
    String? newHoveredId;
    Offset? newHoverPosition;

    for (var posNode in positionedNodes) {
      if (posNode.rect.contains(position)) {
        newHoveredId = posNode.node.id;
        // Position tooltip at top-right of node
        newHoverPosition = posNode.rect.topRight;
        break;
      }
    }

    if (newHoveredId != hoveredNodeId) {
      setState(() {
        hoveredNodeId = newHoveredId;
        _hoverPosition = newHoverPosition;
      });
    }
  }

  void _handleLongPress(Offset localPosition) {
    final Matrix4 transform = _transformationController.value;
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final Vector3 canvasPoint = inverseTransform.transform3(
      Vector3(localPosition.dx, localPosition.dy, 0),
    );
    final Offset canvasPosition = Offset(canvasPoint.x, canvasPoint.y);

    for (var posNode in positionedNodes) {
      if (posNode.rect.contains(canvasPosition)) {
        _showNodeDetailsDialog(posNode.node);
        return;
      }
    }
  }

  void _showNodeDetailsDialog(BuffaloNode node) {
    // Calculate simple stats derived from the node itself
    final childrenCount = node.children.length;
    // Estimate logical revenue/value based on age/status for display purposes
    // Since we don't have the full financial model here, we infer
    final isMature = node.data['status'] == 'Mature';
    final estValue = isMature
        ? '₹1,50,000'
        : '₹60,000'; // Placeholder logic based on status
    final currentRevenue = isMature ? '₹12,000/yr' : '₹0/yr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${node.name.split('\n').first} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Generation', '${node.generation}'),
            _buildDialogRow('Unit', '${node.unit}'),
            const Divider(),
            if (node.data.isNotEmpty) ...[
              _buildDialogRow('Type', node.data['type']),
              _buildDialogRow('Age', node.data['age']),
              _buildDialogRow('Status', node.data['status']),
              _buildDialogRow(
                'Production',
                // If status is Mature, it's Producing, otherwise Non-Producing
                node.data['status'] == 'Mature' ? 'Producing' : 'Non-Producing',
              ),
              _buildDialogRow('Description', node.data['desc']),
            ],
            const Divider(),
            _buildDialogRow('Children Count', '$childrenCount'),
            _buildDialogRow('Est. Market Value', estValue),
            _buildDialogRow('Current Revenue', currentRevenue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    final node = positionedNodes
        .firstWhere((p) => p.node.id == hoveredNodeId)
        .node;
    if (node.data.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: _hoverPosition!.dx + 10,
      top: _hoverPosition!.dy - 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.data['type'] ?? 'Buffalo',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Age: ${node.data['age']}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${node.data['status']}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeTextPainter extends CustomPainter {
  final List<PositionedNode> positionedNodes;
  final TreeThemeData themeData;
  final NodeShape nodeShape;

  _NodeTextPainter({
    required this.positionedNodes,
    required this.themeData,
    required this.nodeShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var posNode in positionedNodes) {
      _drawNodeText(canvas, posNode);
    }
  }

  void _drawNodeText(Canvas canvas, PositionedNode posNode) {
    final rect = posNode.rect;
    final node = posNode.node;

    // Get the proper text area for the shape
    final textArea = NodeShapeData.getTextArea(nodeShape, rect);

    // Determine text color based on node color luminance
    final nodeColor = _getNodeColor(node.generation);
    // Use a higher threshold for better readability on mid-tones
    final isDarkBackground = nodeColor.computeLuminance() < 0.6;

    final textColor = isDarkBackground
        ? Colors.white
        : Colors.black.withOpacity(0.9);
    final shadowColor = isDarkBackground
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.6);

    // 1. Draw Name (Center)
    final nameTitleFontSize = 14.0;
    final unitFontSize = 9.0;

    // Split "A1\nUnit 1"
    final nameParts = node.name.split('\n');
    final mainName = nameParts.isNotEmpty ? nameParts[0] : node.name;
    final subName = nameParts.length > 1 ? nameParts[1] : '';

    final nameSpan = TextSpan(
      children: [
        TextSpan(
          text: mainName,
          style: TextStyle(
            color: textColor,
            fontSize: nameTitleFontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1,
                color: shadowColor,
              ),
            ],
          ),
        ),
        if (subName.isNotEmpty) ...[
          const TextSpan(text: '\n'),
          TextSpan(
            text: subName,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: unitFontSize,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ],
    );

    final namePainter = TextPainter(
      text: nameSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );
    namePainter.layout(maxWidth: textArea.width);

    // Center vertically
    final nameX = textArea.left + (textArea.width - namePainter.width) / 2;
    final nameY = textArea.top + (textArea.height - namePainter.height) / 2 - 4;
    namePainter.paint(canvas, Offset(nameX, nameY));

    // 2. Draw Year (Bottom Left)
    final infoFontSize = 9.0;
    final displayYear = node.generation == 0
        ? node.birthYear + 3
        : node.birthYear;

    final yearSpan = TextSpan(
      text: '$displayYear',
      style: TextStyle(
        color: textColor.withOpacity(0.9),
        fontSize: infoFontSize,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(0.5, 0.5), blurRadius: 1, color: shadowColor),
        ],
      ),
    );
    final yearPainter = TextPainter(
      text: yearSpan,
      textDirection: TextDirection.ltr,
    );
    yearPainter.layout();

    final yearX = textArea.left + 4;
    final yearY = textArea.bottom - yearPainter.height - 2;
    yearPainter.paint(canvas, Offset(yearX, yearY));

    // 4. Draw Generation (Top Right)
    final genFontSize = 7.0;
    final genText = 'Gen ${node.generation}';
    final genSpan = TextSpan(
      text: genText,
      style: TextStyle(
        color: textColor.withOpacity(0.8),
        fontSize: genFontSize,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(0.5, 0.5), blurRadius: 1, color: shadowColor),
        ],
      ),
    );
    final genPainter = TextPainter(
      text: genSpan,
      textDirection: TextDirection.ltr,
    );
    genPainter.layout();

    final genX = textArea.right - genPainter.width - 4;
    final genY = textArea.top + 4;
    genPainter.paint(canvas, Offset(genX, genY));
  }

  Color _getNodeColor(int generation) {
    final palette = themeData
        .generationPalettes[generation % themeData.generationPalettes.length];
    return palette[0];
  }

  @override
  bool shouldRepaint(_NodeTextPainter oldDelegate) {
    return oldDelegate.positionedNodes != positionedNodes;
  }
}

class BuffaloTreeCanvasPainter extends CustomPainter {
  final List<PositionedNode> positionedNodes;
  final List<ConnectionLine> connections;
  final String? hoveredNodeId;
  final TreeThemeData themeData;
  final NodeShape nodeShape;
  final TreeOrientation orientation;

  BuffaloTreeCanvasPainter({
    required this.positionedNodes,
    required this.connections,
    this.hoveredNodeId,
    required this.themeData,
    required this.nodeShape,
    required this.orientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first (behind nodes)
    _drawConnections(canvas);

    _drawNodes(canvas);
  }

  void _drawConnections(Canvas canvas) {
    final paint = Paint()
      ..shader =
          LinearGradient(
            colors: themeData.connectionGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTRB(0, 0, 800, 600),
          ) // Approximate canvas bounds
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final connection in connections) {
      final path = _smoothCurve(connection.start, connection.end);

      // Draw gradient shadow for depth
      canvas.drawPath(path, shadowPaint);

      // Draw main connection line
      canvas.drawPath(path, paint);

      // Draw arrow with proper curve direction
      _drawArrow(canvas, path, connection.end, paint);
    }
  }

  Path _smoothCurve(Offset start, Offset end) {
    if (orientation == TreeOrientation.vertical) {
      // Vertical (Curved Top-Down)
      final midY = (start.dy + end.dy) / 2;
      return Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx,
          midY, // control 1
          end.dx,
          midY, // control 2
          end.dx,
          end.dy, // end
        );
    } else {
      // Horizontal (Curved Left-Right)
      final midX = (start.dx + end.dx) / 2;
      return Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          midX,
          start.dy, // control 1
          midX,
          end.dy, // control 2
          end.dx,
          end.dy, // end
        );
    }
  }

  // Offset _curveDirection(Path path) {
  //   // Extract the curve direction at the end point
  //   // For our cubic curve, the direction at the end is from control point 2 to end point
  //   // We'll approximate this by using a small step back from the end
  //   final pathMetrics = path.computeMetrics().first;
  //   final length = pathMetrics.length;

  //   if (length < 2) return const Offset(0, 1); // Default downward direction

  //   final endTangent = pathMetrics.getTangentForOffset(length);
  //   final startTangent = pathMetrics.getTangentForOffset(length - 2);

  //   if (endTangent != null && startTangent != null) {
  //     return endTangent.position - startTangent.position;
  //   }

  //   // Fallback: approximate direction
  //   return const Offset(0, 1);
  // }
  Offset _curveDirection(Path path, {double sample = 2}) {
    final metrics = path.computeMetrics();
    final m = metrics.first;

    final t = m.length - sample; // sample some pixels before the end
    final tangent = m.getTangentForOffset(t < 0 ? 0 : t);

    return tangent?.vector ?? Offset.zero;
  }

  void _drawArrow(Canvas canvas, Path path, Offset endPoint, Paint linePaint) {
    final dir = _curveDirection(path, sample: 5);
    final length = dir.distance;
    if (length == 0) return;

    final normalizedDir = dir / length;

    const double arrowLength = 8;
    const double arrowWidth = 10;

    final base = endPoint - normalizedDir * arrowLength;
    final perp = Offset(-normalizedDir.dy, normalizedDir.dx);

    final left = base + perp * (arrowWidth / 2);
    final right = base - perp * (arrowWidth / 2);

    final arrowPath = Path()
      ..moveTo(endPoint.dx, endPoint.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    // Create arrow head paint with same gradient as line
    final arrowPaint = Paint()
      ..shader = linePaint.shader
      ..style = PaintingStyle.fill;

    // Draw filled arrow head
    canvas.drawPath(arrowPath, arrowPaint);

    // Draw arrow head outline for better definition
    final outlinePaint = Paint()
      ..color = themeData.connectionGradient.first.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(arrowPath, outlinePaint);
  }

  void _drawNodes(Canvas canvas) {
    for (var posNode in positionedNodes) {
      final isHovered = posNode.node.id == hoveredNodeId;
      _drawNode(canvas, posNode, isHovered);
    }
  }

  // void _drawNode(Canvas canvas, PositionedNode posNode, bool isHovered) {
  //   final rect = posNode.rect;
  //   final node = posNode.node;

  //   // Enhanced shadow with multiple layers for depth
  //   final shadowPaint1 = Paint()
  //     ..color = Colors.black.withOpacity(0.08)
  //     ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  //   canvas.drawRRect(
  //     RRect.fromRectAndRadius(
  //       rect.shift(const Offset(0, 4)),
  //       const Radius.circular(12),
  //     ),
  //     shadowPaint1,
  //   );

  //   final shadowPaint2 = Paint()
  //     ..color = Colors.black.withOpacity(0.05)
  //     ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  //   canvas.drawRRect(
  //     RRect.fromRectAndRadius(
  //       rect.shift(const Offset(0, 8)),
  //       const Radius.circular(12),
  //     ),
  //     shadowPaint2,
  //   );

  //   // Create gradient background based on generation
  //   final gradientColors = _getGradientColors(node.generation);
  //   final bgPaint = Paint()
  //     ..shader = LinearGradient(
  //       colors: isHovered
  //           ? [
  //               gradientColors[0].withOpacity(0.9),
  //               gradientColors[1].withOpacity(0.9),
  //             ]
  //           : [
  //               gradientColors[0].withOpacity(0.7),
  //               gradientColors[1].withOpacity(0.7),
  //             ],
  //       begin: Alignment.topLeft,
  //       end: Alignment.bottomRight,
  //     ).createShader(rect)
  //     ..style = PaintingStyle.fill;

  //   NodeShapeData.drawShape(
  //     canvas: canvas,
  //     shape: nodeShape,
  //     rect: rect,
  //     paint: bgPaint,
  //   );

  //   // Add subtle inner glow
  //   final innerGlowPaint = Paint()
  //     ..shader = RadialGradient(
  //       colors: [Colors.white.withOpacity(0.3), Colors.transparent],
  //       center: Alignment.topLeft,
  //       radius: 1.5,
  //     ).createShader(rect)
  //     ..style = PaintingStyle.fill;
  //   NodeShapeData.drawShape(
  //     canvas: canvas,
  //     shape: nodeShape,
  //     rect: rect,
  //     paint: innerGlowPaint,
  //   );

  //   // Enhanced border with gradient
  //   final borderPaint = Paint()
  //     ..shader = LinearGradient(
  //       colors: isHovered
  //           ? [gradientColors[0], gradientColors[1]]
  //           : [
  //               gradientColors[0].withOpacity(0.8),
  //               gradientColors[1].withOpacity(0.8),
  //             ],
  //       begin: Alignment.topLeft,
  //       end: Alignment.bottomRight,
  //     ).createShader(rect)
  //     ..strokeWidth = isHovered ? 3.0 : 2.5
  //     ..style = PaintingStyle.stroke;
  //   NodeShapeData.drawShape(
  //     canvas: canvas,
  //     shape: nodeShape,
  //     rect: rect,
  //     paint: borderPaint,
  //   );

  //   // Add highlight on hover
  //   if (isHovered) {
  //     final highlightPaint = Paint()
  //       ..color = Colors.white.withOpacity(0.2)
  //       ..style = PaintingStyle.fill;
  //     NodeShapeData.drawShape(
  //       canvas: canvas,
  //       shape: nodeShape,
  //       rect: rect,
  //       paint: highlightPaint,
  //     );
  //   }
  // }
  void _drawNode(Canvas canvas, PositionedNode posNode, bool isHovered) {
    final rect = posNode.rect;
    final node = posNode.node;
    final isCircle = nodeShape == NodeShape.circle;
    final center = rect.center;
    final radius = isCircle
        ? (rect.width < rect.height ? rect.width : rect.height) / 2
        : 0.0;

    // Only draw shadow for non-circle shapes
    if (!isCircle) {
      final shadowPaint1 = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 4)),
          const Radius.circular(12),
        ),
        shadowPaint1,
      );

      final shadowPaint2 = Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 8)),
          const Radius.circular(12),
        ),
        shadowPaint2,
      );
    }

    // Use solid color based on generation
    final nodeColor = _getNodeColor(node.generation);
    final bgPaint = Paint()
      ..color = isHovered ? nodeColor : nodeColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Draw the main shape
    NodeShapeData.drawShape(
      canvas: canvas,
      shape: nodeShape,
      rect: rect,
      paint: bgPaint,
    );

    // Add subtle inner glow - different for circle vs other shapes
    if (isCircle) {
      final innerGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.transparent],
          center: Alignment.topLeft,
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, innerGlowPaint);
    } else {
      final innerGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.transparent],
          center: Alignment.topLeft,
          radius: 1.5,
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      NodeShapeData.drawShape(
        canvas: canvas,
        shape: nodeShape,
        rect: rect,
        paint: innerGlowPaint,
      );
    }

    // Draw border with solid color
    final borderPaint = Paint()
      ..color = isHovered
          ? nodeColor.withOpacity(1.0)
          : nodeColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.0 : 1.5;

    if (isCircle) {
      canvas.drawCircle(center, radius - 1, borderPaint);
    } else {
      NodeShapeData.drawShape(
        canvas: canvas,
        shape: nodeShape,
        rect: rect.deflate(0.5),
        paint: borderPaint,
      );
    }

    // Draw node text
    // Draw node text
    // _drawNodeText(canvas, posNode); // Removed as redundant
  }

  Color _getNodeColor(int generation) {
    // Use the first color of the palette for a solid look, but ensure it's vibrant
    final palette = themeData
        .generationPalettes[generation % themeData.generationPalettes.length];
    return palette[0];
  }

  @override
  bool shouldRepaint(BuffaloTreeCanvasPainter oldDelegate) {
    return oldDelegate.positionedNodes != positionedNodes ||
        oldDelegate.connections != connections ||
        oldDelegate.hoveredNodeId != hoveredNodeId;
  }
}

class TreeDimensions {
  final double width;
  final double height;

  TreeDimensions({required this.width, required this.height});
}

class _NodePositionInfo {
  final BuffaloNode node;
  final double x;
  final double y;
  final int level;

  _NodePositionInfo({
    required this.node,
    required this.x,
    required this.y,
    required this.level,
  });
}

class PositionedNode {
  final BuffaloNode node;
  final Offset position;
  final Size size;

  PositionedNode({
    required this.node,
    required this.position,
    required this.size,
  });

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

class ConnectionLine {
  final Offset start;
  final Offset end;

  ConnectionLine({required this.start, required this.end});
}
