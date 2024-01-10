import 'package:flutter/material.dart';

import 'colors_manager.dart';

class ThemesManager {
  static final nightTheme = ThemeData(
    scaffoldBackgroundColor: ColorManager.scaffoldBgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorManager.scaffoldBgColor,
    ),
  );
}
