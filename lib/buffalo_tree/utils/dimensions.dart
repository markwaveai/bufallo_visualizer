import 'package:flutter/material.dart';

class Dimensions {
  // Tree dimensions
  static const double nodeWidth = 200.0;
  static const double nodeHeight = 80.0;
  static const double siblingSpacing = 20.0;
  static const double levelSpacing = 60.0;
  
  // Padding and margins
  static const double screenPadding = 16.0;
  static const double nodePadding = 8.0;
  
  // Text styles
  static const TextStyle nodeTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  // Colors
  static const Color nodeBackground = Colors.white;
  static const Color nodeBorder = Color(0xFFE0E0E0);
  static const Color selectedNodeBorder = Colors.blue;
  
  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 200);
}
