import 'package:flutter/material.dart';

import 'colors_manager.dart';
import 'fonts_manager.dart';
import 'styles_manager.dart';
import 'values_manager.dart';

class ThemesManager {
  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSize.s12),
  );
  static final _buttonText =
      TextStyles.getSemiBoldStyle(fontSize: FontSize.s16);
  static const _buttonSize = Size(AppSize.s48, AppSize.s48);
  static const _buttonPadding =
      EdgeInsets.symmetric(horizontal: AppPadding.p20);

  static final nightTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: FontConstants.fontFamily,
    scaffoldBackgroundColor: ColorManager.scaffoldBgColor,
    colorScheme: const ColorScheme.dark(
      primary: ColorManager.primaryEnabledColor,
      onPrimary: ColorManager.white,
      secondary: ColorManager.primaryEnabledColor,
      surface: ColorManager.sheetBackground,
      error: ColorManager.likeButtonColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorManager.scaffoldBgColor,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: ColorManager.primaryEnabledColor,
      selectionHandleColor: ColorManager.primaryEnabledColor,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColorManager.primaryEnabledColor,
        foregroundColor: ColorManager.white,
        disabledBackgroundColor: ColorManager.hairline,
        disabledForegroundColor: ColorManager.secondaryText,
        minimumSize: _buttonSize,
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorManager.white,
        side:
            const BorderSide(color: ColorManager.iconButtonBorder, width: 0.5),
        minimumSize: _buttonSize,
        padding: _buttonPadding,
        shape: _buttonShape,
        textStyle: _buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorManager.white,
        textStyle: TextStyles.getSemiBoldStyle(fontSize: FontSize.s14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorManager.searchBarBackground,
      labelStyle: TextStyles.getRegularStyle(
        fontSize: FontSize.s14,
        color: ColorManager.secondaryText,
      ),
      floatingLabelStyle: TextStyles.getRegularStyle(
        fontSize: FontSize.s14,
        color: ColorManager.secondaryText,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppPadding.p16,
        vertical: AppPadding.p14,
      ),
      // * Underline borders keep the floating label inside the filled box
      border: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(AppRadius.rad12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(AppRadius.rad12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(AppRadius.rad12),
        borderSide: BorderSide(
          color: ColorManager.primaryEnabledColor,
          width: AppSize.s2,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ColorManager.sheetBackground,
      surfaceTintColor: ColorManager.transparent,
      showDragHandle: true,
      dragHandleColor: ColorManager.faintText,
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: ColorManager.sheetBackground,
      surfaceTintColor: ColorManager.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A2A2A),
      contentTextStyle: TextStyles.getRegularStyle(fontSize: FontSize.s14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColorManager.primaryEnabledColor,
      linearTrackColor: ColorManager.hairline,
    ),
    dividerTheme: const DividerThemeData(
      color: ColorManager.hairline,
      thickness: AppSize.s0_5,
      space: AppSize.s0_5,
    ),
  );
}
