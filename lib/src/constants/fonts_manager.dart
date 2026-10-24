import 'package:flutter/material.dart';

class FontConstants {
  static const String fontFamily = "Poppins";
}

class FontWeightManager {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class FontSize {
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s16 = 16.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s30 = 30.0;
  static const double s34 = 34.0;
  static const double s36 = 36.0;
}

class FontHeight {
  static const double h1 = 1.0;
  static const double h1_2 = 1.2;
  static const double h1_3 = 1.3;
  static const double h1_4 = 1.4;
}

class FontLetterSpacing {
  // * The design uses -2% letter spacing, so this is multiplied by font size.
  static const double tight = -0.02;
  static const double none = 0.0;
}
