import 'package:flutter/material.dart';

enum TreeTheme {
  vibrantGradients,
  solidColors,

  pastelDreams,
  oceanBreeze,
  sunsetGlow,
  forestNature,
  royalPurple,
  candyPop,
  monochrome,
  neonNights,
  earthyTones,
}

class TreeThemeData {
  final String name;
  final List<List<Color>> generationPalettes;
  final List<Color> connectionGradient;
  final Color backgroundColor;

  const TreeThemeData({
    required this.name,
    required this.generationPalettes,
    required this.connectionGradient,
    required this.backgroundColor,
  });

  static TreeThemeData getTheme(TreeTheme theme) {
    switch (theme) {
      case TreeTheme.vibrantGradients:
        return TreeThemeData(
          name: 'Vibrant Gradients',
          backgroundColor: Color(0xFFF5F7FA),
          connectionGradient: [Color(0xFF667eea), Color(0xFF764ba2)],
          generationPalettes: [
            [Color(0xFF667eea), Color(0xFF764ba2)], // Purple-Blue
            [Color(0xFFf093fb), Color(0xFFF5576c)], // Pink-Red
            [Color(0xFF4facfe), Color(0xFF00f2fe)], // Blue-Cyan
            [Color(0xFF43e97b), Color(0xFF38f9d7)], // Green-Cyan
            [Color(0xFFfa709a), Color(0xFFfee140)], // Pink-Yellow
            [Color(0xFF30cfd0), Color(0xFF330867)], // Cyan-Purple
            [Color(0xFFa8edea), Color(0xFFfed6e3)], // Light Cyan-Pink
            [Color(0xFFff9a9e), Color(0xFFfecfef)], // Coral-Pink
            [Color(0xFFffecd2), Color(0xFFfcb69f)], // Peach
            [Color(0xFFff6e7f), Color(0xFFbfe9ff)], // Red-Blue
          ],
        );

      case TreeTheme.pastelDreams:
        return TreeThemeData(
          name: 'Pastel Dreams',
          backgroundColor: Color(0xFFFFF8F0),
          connectionGradient: [Color(0xFFFFB6C1), Color(0xFFDDA0DD)],
          generationPalettes: [
            [Color(0xFFFFB6C1), Color(0xFFDDA0DD)], // Light Pink-Plum
            [Color(0xFFB0E0E6), Color(0xFF98D8C8)], // Powder Blue-Mint
            [Color(0xFFFFDAB9), Color(0xFFFFE4B5)], // Peach Puff-Moccasin
            [Color(0xFFE6E6FA), Color(0xFFD8BFD8)], // Lavender-Thistle
            [Color(0xFFFFF0F5), Color(0xFFFFE4E1)], // Lavender Blush-Misty Rose
            [Color(0xFFF0E68C), Color(0xFFEEE8AA)], // Khaki-Pale Goldenrod
            [
              Color(0xFFAFEEEE),
              Color(0xFFB0C4DE),
            ], // Pale Turquoise-Light Steel Blue
            [Color(0xFFFFE4C4), Color(0xFFFAEBD7)], // Bisque-Antique White
            [Color(0xFFE0BBE4), Color(0xFFD291BC)], // Mauve-Pastel Violet
            [
              Color(0xFFFDFD96),
              Color(0xFFFFFFBA),
            ], // Pastel Yellow-Light Yellow
          ],
        );

      case TreeTheme.oceanBreeze:
        return TreeThemeData(
          name: 'Ocean Breeze',
          backgroundColor: Color(0xFFE8F4F8),
          connectionGradient: [Color(0xFF1e3c72), Color(0xFF2a5298)],
          generationPalettes: [
            [Color(0xFF1e3c72), Color(0xFF2a5298)], // Deep Blue
            [Color(0xFF00d2ff), Color(0xFF3a7bd5)], // Sky Blue
            [Color(0xFF0083B0), Color(0xFF00B4DB)], // Ocean Blue
            [Color(0xFF4CA1AF), Color(0xFF2C3E50)], // Teal-Dark
            [Color(0xFF56CCF2), Color(0xFF2F80ED)], // Light Blue
            [Color(0xFF00B4DB), Color(0xFF0083B0)], // Cyan Blue
            [Color(0xFF3a6186), Color(0xFF89253e)], // Navy-Wine
            [Color(0xFF2E3192), Color(0xFF1BFFFF)], // Deep Blue-Cyan
            [Color(0xFF134E5E), Color(0xFF71B280)], // Dark Teal-Green
            [Color(0xFF5f2c82), Color(0xFF49a09d)], // Purple-Teal
          ],
        );

      case TreeTheme.sunsetGlow:
        return TreeThemeData(
          name: 'Sunset Glow',
          backgroundColor: Color(0xFFFFF5E6),
          connectionGradient: [Color(0xFFFF512F), Color(0xFFDD2476)],
          generationPalettes: [
            [Color(0xFFFF512F), Color(0xFFDD2476)], // Red-Pink
            [Color(0xFFFF6B6B), Color(0xFFFFE66D)], // Coral-Yellow
            [Color(0xFFFF9966), Color(0xFFFF5E62)], // Orange-Red
            [Color(0xFFFFAA85), Color(0xFFB3315F)], // Peach-Magenta
            [Color(0xFFFFD89B), Color(0xFF19547B)], // Gold-Blue
            [Color(0xFFFFA07A), Color(0xFFFF6347)], // Light Salmon-Tomato
            [Color(0xFFFF7E5F), Color(0xFFFEB47B)], // Coral-Peach
            [Color(0xFFED4264), Color(0xFFFFEDBC)], // Red-Cream
            [Color(0xFFFC6076), Color(0xFFFF9A44)], // Pink-Orange
            [Color(0xFFFF8008), Color(0xFFFFC837)], // Orange-Gold
          ],
        );

      case TreeTheme.forestNature:
        return TreeThemeData(
          name: 'Forest Nature',
          backgroundColor: Color(0xFFF0F8F0),
          connectionGradient: [Color(0xFF134E5E), Color(0xFF71B280)],
          generationPalettes: [
            [Color(0xFF134E5E), Color(0xFF71B280)], // Dark Green-Light Green
            [Color(0xFF56ab2f), Color(0xFFa8e063)], // Green Gradient
            [Color(0xFF2F7336), Color(0xFFAA3A38)], // Forest Green-Red
            [Color(0xFF11998e), Color(0xFF38ef7d)], // Teal-Mint
            [Color(0xFF0F2027), Color(0xFF2C5364)], // Dark-Teal
            [Color(0xFF5A3F37), Color(0xFF2C7744)], // Brown-Green
            [Color(0xFF7F7FD5), Color(0xFF86A8E7)], // Purple-Blue
            [Color(0xFF00b09b), Color(0xFF96c93d)], // Teal-Lime
            [Color(0xFF3C8CE7), Color(0xFF00EAFF)], // Blue-Cyan
            [Color(0xFF659999), Color(0xFFf4791f)], // Sage-Orange
          ],
        );

      case TreeTheme.royalPurple:
        return TreeThemeData(
          name: 'Royal Purple',
          backgroundColor: Color(0xFFF8F0FF),
          connectionGradient: [Color(0xFF5f2c82), Color(0xFF49a09d)],
          generationPalettes: [
            [Color(0xFF5f2c82), Color(0xFF49a09d)], // Purple-Teal
            [Color(0xFF834d9b), Color(0xFFd04ed6)], // Purple-Magenta
            [Color(0xFF4A00E0), Color(0xFF8E2DE2)], // Deep Purple
            [Color(0xFF7F00FF), Color(0xFFE100FF)], // Violet-Magenta
            [Color(0xFF6A3093), Color(0xFFa044ff)], // Purple Gradient
            [Color(0xFF9D50BB), Color(0xFF6E48AA)], // Orchid-Purple
            [Color(0xFFDA22FF), Color(0xFF9733EE)], // Bright Purple
            [Color(0xFF8E54E9), Color(0xFF4776E6)], // Purple-Blue
            [Color(0xFFB06AB3), Color(0xFF4568DC)], // Mauve-Blue
            [Color(0xFFDD5E89), Color(0xFFF7BB97)], // Pink-Peach
          ],
        );

      case TreeTheme.candyPop:
        return TreeThemeData(
          name: 'Candy Pop',
          backgroundColor: Color(0xFFFFF0F5),
          connectionGradient: [Color(0xFFFF6FD8), Color(0xFF3813C2)],
          generationPalettes: [
            [Color(0xFFFF6FD8), Color(0xFF3813C2)], // Pink-Purple
            [Color(0xFFFFAFBD), Color(0xFFffc3a0)], // Pink-Peach
            [Color(0xFFFF0099), Color(0xFF493240)], // Hot Pink-Dark
            [Color(0xFFFF00FF), Color(0xFF00FFFF)], // Magenta-Cyan
            [Color(0xFFFF1493), Color(0xFFFF69B4)], // Deep Pink-Hot Pink
            [Color(0xFFFF6EC7), Color(0xFFFF1493)], // Pink Gradient
            [Color(0xFFFF85A1), Color(0xFFFFC3A0)], // Salmon-Peach
            [Color(0xFFFF9A8B), Color(0xFFFF6A88)], // Coral-Pink
            [Color(0xFFFFB199), Color(0xFFFF0844)], // Peach-Red
            [Color(0xFFFF96F9), Color(0xFFC32BAC)], // Light Pink-Magenta
          ],
        );

      case TreeTheme.monochrome:
        return TreeThemeData(
          name: 'Monochrome',
          backgroundColor: Color(0xFFF5F5F5),
          connectionGradient: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          generationPalettes: [
            [Color(0xFF000000), Color(0xFF434343)], // Black-Dark Gray
            [Color(0xFF4B4B4B), Color(0xFF6B6B6B)], // Dark Gray
            [Color(0xFF757575), Color(0xFF9E9E9E)], // Gray
            [Color(0xFFBDBDBD), Color(0xFFE0E0E0)], // Light Gray
            [Color(0xFF2C3E50), Color(0xFF3498DB)], // Dark-Blue
            [Color(0xFF34495E), Color(0xFF95A5A6)], // Slate-Gray
            [Color(0xFF1E272E), Color(0xFF485460)], // Dark Slate
            [Color(0xFF636E72), Color(0xFFB2BEC3)], // Gray-Light
            [Color(0xFF2D3436), Color(0xFF636E72)], // Charcoal
            [Color(0xFF57606F), Color(0xFF2F3542)], // Blue Gray
          ],
        );

      case TreeTheme.neonNights:
        return TreeThemeData(
          name: 'Neon Nights',
          backgroundColor: Color(0xFF1A1A2E),
          connectionGradient: [Color(0xFFFF00FF), Color(0xFF00FFFF)],
          generationPalettes: [
            [Color(0xFFFF00FF), Color(0xFF00FFFF)], // Magenta-Cyan
            [Color(0xFF00FF00), Color(0xFFFFFF00)], // Green-Yellow
            [Color(0xFFFF0080), Color(0xFF7928CA)], // Pink-Purple
            [Color(0xFF00F5FF), Color(0xFF0080FF)], // Cyan-Blue
            [Color(0xFFFF1744), Color(0xFFFF9100)], // Red-Orange
            [Color(0xFF76FF03), Color(0xFF00E676)], // Lime-Green
            [Color(0xFFE040FB), Color(0xFF7C4DFF)], // Purple-Violet
            [Color(0xFF00E5FF), Color(0xFF00B0FF)], // Cyan-Light Blue
            [Color(0xFFFFEA00), Color(0xFFFF6D00)], // Yellow-Orange
            [Color(0xFFFF4081), Color(0xFFFF80AB)], // Pink Accent
          ],
        );

      case TreeTheme.earthyTones:
        return TreeThemeData(
          name: 'Earthy Tones',
          backgroundColor: Color(0xFFFAF8F3),
          connectionGradient: [Color(0xFF8B4513), Color(0xFFD2691E)],
          generationPalettes: [
            [Color(0xFF8B4513), Color(0xFFD2691E)], // Saddle Brown-Chocolate
            [Color(0xFFCD853F), Color(0xFFDEB887)], // Peru-Burlywood
            [Color(0xFFD2B48C), Color(0xFFF5DEB3)], // Tan-Wheat
            [Color(0xFFBC8F8F), Color(0xFFCD5C5C)], // Rosy Brown-Indian Red
            [Color(0xFF8B7355), Color(0xFFA0826D)], // Burlywood-Tan
            [Color(0xFF6B4423), Color(0xFF8B4513)], // Dark Brown
            [Color(0xFFA0522D), Color(0xFFCD853F)], // Sienna-Peru
            [Color(0xFF8B7D6B), Color(0xFFBDB76B)], // Gray Brown-Dark Khaki
            [Color(0xFF704214), Color(0xFF966F33)], // Brown-Wood
            [Color(0xFF9C661F), Color(0xFFB8860B)], // Dark Goldenrod
          ],
        );

      case TreeTheme.solidColors:
        return TreeThemeData(
          name: 'Solid Colors',
          backgroundColor: Color(0xFFF5F7FA),
          connectionGradient: [
            Color(0xFF607D8B),
            Color(0xFF607D8B),
          ], // Same color for solid
          generationPalettes: [
            [Color(0xFF2196F3), Color(0xFF2196F3)], // Blue
            [Color(0xFFE91E63), Color(0xFFE91E63)], // Pink
            [Color(0xFF4CAF50), Color(0xFF4CAF50)], // Green
            [Color(0xFFFF9800), Color(0xFFFF9800)], // Orange
            [Color(0xFF9C27B0), Color(0xFF9C27B0)], // Purple
            [Color(0xFF00BCD4), Color(0xFF00BCD4)], // Cyan
            [Color(0xFFFF5722), Color(0xFFFF5722)], // Deep Orange
            [Color(0xFF3F51B5), Color(0xFF3F51B5)], // Indigo
            [Color(0xFFCDDC39), Color(0xFFCDDC39)], // Lime
            [Color(0xFFF44336), Color(0xFFF44336)], // Red
          ],
        );
    }
  }

  static List<TreeTheme> getAllThemes() {
    return TreeTheme.values;
  }
}
