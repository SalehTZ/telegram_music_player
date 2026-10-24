import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  const SearchBarWidget({
    super.key,
    this.hintText = 'Search for songs',
    this.onChanged,
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
            child: TextField(
              maxLines: 1,
              minLines: 1,
              onChanged: onChanged,
              cursorColor: ColorManager.primaryEnabledColor,
              style: TextStyles.getLightStyle(fontSize: FontSize.s18),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hintText,
                hintStyle: TextStyles.getLightStyle(
                  color: ColorManager.lightGrey,
                  fontSize: FontSize.s18,
                ),
                border: InputBorder.none,
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
