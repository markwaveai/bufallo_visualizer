import 'package:buffalo_visualizer/buffalo_tree/models/buffalo_node.dart';
import 'package:buffalo_visualizer/buffalo_tree/models/node_shape.dart';
import 'package:buffalo_visualizer/buffalo_tree/models/tree_theme.dart';
import 'package:buffalo_visualizer/buffalo_tree/utils/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;

class OrganizationTreeWidget extends StatefulWidget {
  final BuffaloNode rootNode;
  final Function(String nodeId)? onNodeTap;
  final TreeTheme theme;
  final NodeShape nodeShape;
  final Function(TransformationController)? onControllerReady;

  const OrganizationTreeWidget({
    super.key,
    required this.rootNode,
    this.onNodeTap,
    this.theme = TreeTheme.vibrantGradients,
    this.nodeShape = NodeShape.roundedRectangle,
    this.onControllerReady,
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

  @override
  void initState() {
    super.initState();
    _calculateLayout();
    // Expose the transformation controller to parent
    widget.onControllerReady?.call(_transformationController);
  }

  @override
  void didUpdateWidget(OrganizationTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode) {
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
          width: Dimensions.nodeWidth,
          height: Dimensions.nodeHeight,
        );
      } else {
        double totalWidth = 0;
        double maxHeight = Dimensions.nodeHeight;

        for (var child in currentNode.children) {
          final childDim = cache[child.id]!;
          totalWidth += childDim.width + Dimensions.siblingSpacing;

          double childTreeHeight =
              Dimensions.nodeHeight + Dimensions.levelSpacing + childDim.height;
          if (childTreeHeight > maxHeight) {
            maxHeight = childTreeHeight;
          }
        }

        totalWidth -= Dimensions.siblingSpacing;

        cache[currentNode.id] = TreeDimensions(
          width: totalWidth > Dimensions.nodeWidth
              ? totalWidth
              : Dimensions.nodeWidth,
          height: maxHeight,
        );
      }
    }
  }

  void _positionNodes(BuffaloNode node, double x, double y, int level) {
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
          size: const Size(Dimensions.nodeWidth, Dimensions.nodeHeight),
        ),
      );

      if (currentNode.children.isNotEmpty) {
        final childY =
            currentY + Dimensions.nodeHeight + Dimensions.levelSpacing;

        double totalChildrenWidth = 0;
        for (var child in currentNode.children) {
          final childDim = _calculateTreeDimensions(child);
          totalChildrenWidth += childDim.width + Dimensions.siblingSpacing;
        }
        totalChildrenWidth -= Dimensions.siblingSpacing;

        double childStartX =
            currentX + (Dimensions.nodeWidth / 2) - (totalChildrenWidth / 2);

        for (var child in currentNode.children) {
          final childDim = _calculateTreeDimensions(child);

          final childNodeX =
              childStartX + (childDim.width / 2) - (Dimensions.nodeWidth / 2);

          final childConnectionX = childNodeX + (Dimensions.nodeWidth / 2);

          connections.add(
            ConnectionLine(
              start: Offset(
                currentX + Dimensions.nodeWidth / 2,
                currentY + Dimensions.nodeHeight,
              ),
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

        final rootX = (effectiveWidth / 2) - (Dimensions.nodeWidth / 2);
        const rootY = Dimensions.screenPadding;

        if (_lastRootX != rootX || _lastRootY != rootY) {
          _positionNodesWithStart(rootX, rootY);
          _lastRootX = rootX;
          _lastRootY = rootY;
        }

        return GestureDetector(
          onTapUp: (details) {
            _handleTapWithTransform(details.localPosition);
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
                      ),
                      foregroundPainter: _NodeTextPainter(
                        positionedNodes: positionedNodes,
                        themeData: TreeThemeData.getTheme(widget.theme),
                        nodeShape: widget.nodeShape,
                      ),
                    ),
                  ),
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
    for (var posNode in positionedNodes) {
      if (posNode.rect.contains(position)) {
        newHoveredId = posNode.node.id;
        break;
      }
    }
    if (newHoveredId != hoveredNodeId) {
      setState(() {
        hoveredNodeId = newHoveredId;
      });
    }
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

    // Determine text color based on theme - always use high contrast colors
    final textColor = _isLightTheme() ? Colors.black87 : Colors.white;
    final shadowColor = _isLightTheme() ? Colors.white70 : Colors.black87;

    // Adjust font sizes based on shape - increased for better visibility
    final nameFontSize = nodeShape == NodeShape.circle ? 16.0 : 18.0;
    final yearFontSize = nodeShape == NodeShape.circle ? 12.0 : 14.0;
    final genFontSize = nodeShape == NodeShape.circle ? 11.0 : 12.0;

    // Draw year and generation only - show simulation year for founders
    final displayYear = node.generation == 0
        ? node.birthYear + 3
        : node.birthYear;
    final yearText = nodeShape == NodeShape.circle
        ? '$displayYear'
        : 'Year $displayYear';
    final nameSpan = TextSpan(
      text: yearText,
      style: TextStyle(
        color: textColor,
        fontSize: nameFontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 4, color: shadowColor),
          Shadow(offset: Offset(-1, -1), blurRadius: 4, color: shadowColor),
          Shadow(offset: Offset(1, -1), blurRadius: 4, color: shadowColor),
          Shadow(offset: Offset(-1, 1), blurRadius: 4, color: shadowColor),
        ],
      ),
    );
    final namePainter = TextPainter(
      text: nameSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
    );
    namePainter.layout(maxWidth: textArea.width);

    // Center the year text
    final nameX = textArea.left + (textArea.width - namePainter.width) / 2;
    final nameY = textArea.top + 12;
    namePainter.paint(canvas, Offset(nameX, nameY));

    // Draw generation badge (only for rectangle and pill)
    if (nodeShape != NodeShape.circle) {
      final genText = 'Gen ${node.generation}';
      final genSpan = TextSpan(
        text: genText,
        style: TextStyle(
          color: textColor,
          fontSize: genFontSize,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(offset: Offset(0.5, 0.5), blurRadius: 2, color: shadowColor),
          ],
        ),
      );
      final genPainter = TextPainter(
        text: genSpan,
        textDirection: TextDirection.ltr,
      );
      genPainter.layout();

      // Draw badge background
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.right - genPainter.width - 16,
          rect.top + 8,
          genPainter.width + 10,
          18,
        ),
        const Radius.circular(9),
      );
      final badgePaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(badgeRect, badgePaint);

      genPainter.paint(
        canvas,
        Offset(rect.right - genPainter.width - 10, rect.top + 10),
      );
    }

    // Draw children count with icon (simplified for circle)
    if (node.children.isNotEmpty) {
      final countText = nodeShape == NodeShape.circle
          ? '${node.children.length}'
          : '🐃 ${node.children.length} ${node.children.length == 1 ? 'child' : 'children'}';
      final countSpan = TextSpan(
        text: countText,
        style: TextStyle(
          color: textColor,
          fontSize: yearFontSize,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(offset: Offset(0.5, 0.5), blurRadius: 2, color: shadowColor),
          ],
        ),
      );
      final countPainter = TextPainter(
        text: countSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      countPainter.layout();

      final countX = textArea.left + (textArea.width - countPainter.width) / 2;
      final countY = textArea.bottom - countPainter.height - 4;
      countPainter.paint(canvas, Offset(countX, countY));
    }
  }

  bool _isLightTheme() {
    // Check if background is light (for pastel and earthy themes)
    final bgLuminance = themeData.backgroundColor.computeLuminance();
    return bgLuminance > 0.5;
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

  BuffaloTreeCanvasPainter({
    required this.positionedNodes,
    required this.connections,
    this.hoveredNodeId,
    required this.themeData,
    required this.nodeShape,
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
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 8
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

    const double arrowLength = 16;
    const double arrowWidth = 18;

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

    // Create gradient background based on generation
    final gradientColors = _getGradientColors(node.generation);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: isHovered
            ? [
                gradientColors[0].withOpacity(0.9),
                gradientColors[1].withOpacity(0.9),
              ]
            : [
                gradientColors[0].withOpacity(0.7),
                gradientColors[1].withOpacity(0.7),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
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

    // Draw border
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: isHovered
            ? [gradientColors[0], gradientColors[1]]
            : [
                gradientColors[0].withOpacity(0.8),
                gradientColors[1].withOpacity(0.8),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
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
    _drawNodeText(canvas, posNode);
  }

  void _drawNodeText(Canvas canvas, PositionedNode posNode) {
    final node = posNode.node;
    final rect = posNode.rect;
    final isCircle = nodeShape == NodeShape.circle;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Configure text style based on node shape
    final textStyle = TextStyle(
      color: _isLightTheme() ? Colors.black87 : Colors.white,
      fontSize: isCircle ? 12.0 : 14.0,
      fontWeight: FontWeight.w500,
    );

    // Create text span with the node's identification
    final textSpan = TextSpan(text: node.id, style: textStyle);

    // Layout the text
    textPainter.text = textSpan;
    textPainter.layout(minWidth: 0, maxWidth: rect.width * 0.9);

    // Calculate text position
    double dx, dy;
    if (isCircle) {
      // Center text in circle
      dx = rect.left + (rect.width - textPainter.width) / 2;
      dy = rect.top + (rect.height - textPainter.height) / 2;
    } else {
      // Position text in rectangle
      dx = rect.left + (rect.width - textPainter.width) / 2;
      dy = rect.top + 12; // Add some padding from top
    }

    // Draw the text
    // textPainter.paint(canvas, Offset(dx, dy));

    // Draw generation text if not a circle
    // if (!isCircle) {
    //   final genText = 'G${node.generation}';
    //   final genStyle = TextStyle(color: Colors.black54, fontSize: 11.0);
    //   final genPainter = TextPainter(
    //     text: TextSpan(text: genText, style: genStyle),
    //     textDirection: TextDirection.ltr,
    //     textAlign: TextAlign.center,
    //   );
    //   genPainter.layout();

    //   final genDx = rect.left + (rect.width - genPainter.width) / 2;
    //   final genDy = dy + textPainter.height + 2; // Small gap between texts
    //   genPainter.paint(canvas, Offset(genDx, genDy));
    // }
  }

  bool _isLightTheme() {
    // Check if the current theme is light
    final brightness =
        themeData.backgroundColor == Colors.black ?? Brightness.light;
    return brightness == Brightness.light;
  }

  List<Color> _getGradientColors(int generation) {
    return themeData.generationPalettes[generation %
        themeData.generationPalettes.length];
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
