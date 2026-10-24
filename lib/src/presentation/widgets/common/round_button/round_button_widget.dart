import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants/colors_manager.dart';
import '../../../../constants/values_manager.dart';

class RoundButtonWidget extends StatelessWidget {
  final String svgIcon;
  final VoidCallback? onTap;
  const RoundButtonWidget({
    super.key,
    required this.svgIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var shapeDecoration = BoxDecoration(
      borderRadius: const BorderRadius.all(AppRadius.rad999),
      border: Border.all(
        width: AppSize.s0_5,
        color: ColorManager.iconButtonBorder,
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: const BorderRadius.all(AppRadius.rad999),
        onTap: onTap,
        child: Container(
          width: AppSize.s50,
          height: AppSize.s50,
          decoration: shapeDecoration,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            svgIcon,
            width: AppSize.s24,
            height: AppSize.s24,
          ),
        ),
      ),
    );
  }
}
