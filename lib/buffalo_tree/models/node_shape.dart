import 'package:flutter/material.dart';

enum NodeShape {
  roundedRectangle,
  circle,
  pill,
}

class NodeShapeData {
  final String name;
  final IconData icon;

  const NodeShapeData({
    required this.name,
    required this.icon,
  });

  static NodeShapeData getShapeData(NodeShape shape) {
    switch (shape) {
      case NodeShape.roundedRectangle:
        return const NodeShapeData(
          name: 'Rectangle',
          icon: Icons.rectangle_outlined,
        );
      case NodeShape.circle:
        return const NodeShapeData(
          name: 'Circle',
          icon: Icons.circle_outlined,
        );
      case NodeShape.pill:
        return const NodeShapeData(
          name: 'Pill',
          icon: Icons.medication_outlined,
        );
    }
  }

  static List<NodeShape> getAllShapes() {
    return NodeShape.values;
  }

  /// Draw the shape on canvas
  static void drawShape({
    required Canvas canvas,
    required NodeShape shape,
    required Rect rect,
    required Paint paint,
    double cornerRadius = 12.0,
  }) {
    switch (shape) {
      case NodeShape.roundedRectangle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
          paint,
        );
        break;

      case NodeShape.circle:
        final center = rect.center;
        final radius = (rect.width < rect.height ? rect.width : rect.height) / 2;
        canvas.drawCircle(center, radius, paint);
        break;

      case NodeShape.pill:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
          paint,
        );
        break;
    }
  }

  /// Get text area for content based on shape
  static Rect getTextArea(NodeShape shape, Rect nodeRect) {
    switch (shape) {
      case NodeShape.roundedRectangle:
        return Rect.fromLTRB(
          nodeRect.left + 10,
          nodeRect.top + 10,
          nodeRect.right - 10,
          nodeRect.bottom - 10,
        );

      case NodeShape.circle:
        // For circle, use inscribed rectangle (about 70% of diameter)
        final center = nodeRect.center;
        final radius = (nodeRect.width < nodeRect.height ? nodeRect.width : nodeRect.height) / 2;
        final textRadius = radius * 0.7;
        return Rect.fromCenter(
          center: center,
          width: textRadius * 2,
          height: textRadius * 2,
        );

      case NodeShape.pill:
        // For pill, avoid the rounded ends
        final padding = nodeRect.height * 0.3;
        return Rect.fromLTRB(
          nodeRect.left + padding,
          nodeRect.top + 8,
          nodeRect.right - padding,
          nodeRect.bottom - 8,
        );
    }
  }
}
