import 'package:flutter/material.dart';

import '../../../../constants/colors_manager.dart';
import '../../../../constants/fonts_manager.dart';
import '../../../../constants/styles_manager.dart';
import '../../../../constants/values_manager.dart';

/// The name of a page and one line about what is on it.
class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PageTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.getBoldStyle(fontSize: FontSize.s30),
        ),
        if (subtitle != null) ...[
          AppGap.h4,
          Text(
            subtitle!,
            style: TextStyles.getRegularStyle(
              fontSize: FontSize.s14,
              color: ColorManager.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}
