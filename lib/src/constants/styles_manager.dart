import 'package:flutter/material.dart';

import 'colors_manager.dart';
import 'fonts_manager.dart';

class TextStyles {
  static TextStyle _getTextStyle(
    double fontSize,
    String fontFamily,
    FontWeight fontWeight,
    Color color,
    double height,
    double letterSpacingFactor,
    List<Shadow> shadows,
  ) =>
      TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        color: color,
        height: height,
        // * Matches how Figma places text inside its line height
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: fontSize * letterSpacingFactor,
        shadows: shadows,
      );

  // * light style
  static TextStyle getLightStyle({
    double fontSize = FontSize.s12,
    Color color = ColorManager.white,
    double height = FontHeight.h1_3,
    double letterSpacing = FontLetterSpacing.tight,
    List<Shadow>? shadows,
  }) =>
      _getTextStyle(
        fontSize,
        FontConstants.fontFamily,
        FontWeightManager.light,
        color,
        height,
        letterSpacing,
        shadows ?? [],
      );

  // * regular style
  static TextStyle getRegularStyle({
    double fontSize = FontSize.s12,
    Color color = ColorManager.white,
    double height = FontHeight.h1_3,
    double letterSpacing = FontLetterSpacing.tight,
    List<Shadow>? shadows,
  }) =>
      _getTextStyle(
        fontSize,
        FontConstants.fontFamily,
        FontWeightManager.regular,
        color,
        height,
        letterSpacing,
        shadows ?? [],
      );

  // * medium style
  static TextStyle getMediumStyle({
    double fontSize = FontSize.s12,
    Color color = ColorManager.white,
    double height = FontHeight.h1_3,
    double letterSpacing = FontLetterSpacing.tight,
    List<Shadow>? shadows,
  }) =>
      _getTextStyle(
        fontSize,
        FontConstants.fontFamily,
        FontWeightManager.medium,
        color,
        height,
        letterSpacing,
        shadows ?? [],
      );

  // * Semi bold text style
  static TextStyle getSemiBoldStyle({
    double fontSize = FontSize.s12,
    Color color = ColorManager.white,
    double height = FontHeight.h1_3,
    double letterSpacing = FontLetterSpacing.tight,
    List<Shadow>? shadows,
  }) =>
      _getTextStyle(
        fontSize,
        FontConstants.fontFamily,
        FontWeightManager.semiBold,
        color,
        height,
        letterSpacing,
        shadows ?? [],
      );

  // * bold text style
  static TextStyle getBoldStyle({
    double fontSize = FontSize.s16,
    Color color = ColorManager.white,
    double height = FontHeight.h1_3,
    double letterSpacing = FontLetterSpacing.tight,
    List<Shadow>? shadows,
  }) =>
      _getTextStyle(
        fontSize,
        FontConstants.fontFamily,
        FontWeightManager.bold,
        color,
        height,
        letterSpacing,
        shadows ?? [],
      );
}
