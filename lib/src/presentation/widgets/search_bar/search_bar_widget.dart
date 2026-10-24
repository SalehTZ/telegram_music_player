import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final String? initialText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  const SearchBarWidget({
    super.key,
    this.hintText = 'Search for songs',
    this.initialText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.p12,
        horizontal: AppPadding.p16,
      ),
      decoration: const BoxDecoration(
        color: ColorManager.searchBarBackground,
        borderRadius: BorderRadius.all(AppRadius.rad16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AssetsManager.searchIcon,
            width: AppSize.s24,
            height: AppSize.s24,
          ),
          AppGap.w12,
          Expanded(
            child: TextFormField(
              initialValue: initialText,
              maxLines: 1,
              minLines: 1,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              cursorColor: ColorManager.primaryEnabledColor,
              style: TextStyles.getLightStyle(fontSize: FontSize.s18),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hintText,
                hintStyle: TextStyles.getLightStyle(
                  color: ColorManager.lightGrey,
                  fontSize: FontSize.s18,
                ),
                // * Not the filled field of the app's theme
                filled: false,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        ],
      ),
    );
  }
}
