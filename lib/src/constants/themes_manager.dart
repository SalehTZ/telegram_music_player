import 'package:flutter/material.dart';

import 'colors_manager.dart';
import 'fonts_manager.dart';

class ThemesManager {
  static final nightTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: FontConstants.fontFamily,
    scaffoldBackgroundColor: ColorManager.scaffoldBgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorManager.scaffoldBgColor,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ColorManager.primaryEnabledColor,
      selectionHandleColor: ColorManager.primaryEnabledColor,
    ),
  );
}
