import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSize.s48,
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
          SizedBox(
              width: AppSize.s24,
              height: AppSize.s24,
              child: SvgPicture.asset(AssetsManager.searchIcon)),
          AppGap.w12,
          Expanded(
            child: SizedBox(
              height: AppSize.s24,
              child: TextField(
                maxLines: 1,
                minLines: 1,
                style: TextStyles.getRegularStyle(fontSize: FontSize.s18),
                decoration: InputDecoration(
                  hintText: 'Search for songs',
                  hintStyle: TextStyles.getRegularStyle(
                    color: ColorManager.lightGrey,
                    fontSize: FontSize.s18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border:
                      const UnderlineInputBorder(borderSide: BorderSide.none),
                ),
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
