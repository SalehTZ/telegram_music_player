import 'package:flutter/material.dart';

class ColorManager {
  //! New Color Scheme
  static const Color error = Colors.red; // TODO change error color later
  static const Color scaffoldBgColor = Color(0xFFF5F5F5);
  static const Color likeButtonColor = Color(0xFFFE3B7C);
  static const Color white = Colors.white;

  //* Primary Colors
  static Color primaryMaterial = HexColor.toMaterialColor(0xFF5947B2);
  static const Color primaryEnabledColor = Color(0xFF5947B2);
  static const Color primaryPressedColor = Color(0xFF7A6CC1);
  static const Color primaryDisabledColor = Color(0xFFACA3D8);

  // * Shadow Colors
  static const Color hardDropShadowColor = Color(0x26000000);
  static const Color softDropShadowColor = Color(0x0A000000);
}

// * An extension to convert Hex to Color class
extension HexColor on Color {
  /// Convert any Hex color to Material Color.
  /// Input: color without alpha example #FF94C7
  static MaterialColor toMaterialColor(int hexColorString) {
    final color = Color(hexColorString);
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }
}
