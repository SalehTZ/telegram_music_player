import 'package:flutter/material.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../common/round_button/round_button_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool hasSecondAction;
  final bool isMainScreen;
  final VoidCallback? onSecondActionTap;
  const AppBarWidget({
    super.key,
    this.hasSecondAction = false,
    this.isMainScreen = true,
    this.onSecondActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.p20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            isMainScreen
                ? RoundButtonWidget(
                    svgIcon: AssetsManager.hamburgerMenuIcon,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  )
                : RoundButtonWidget(
                    svgIcon: AssetsManager.arrowBackIcon,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
            Text(
              "logo",
              style: TextStyles.getBoldStyle(fontSize: FontSize.s24),
            ),
            if (hasSecondAction)
              RoundButtonWidget(
                svgIcon: AssetsManager.dotsMenuIcon,
                onTap: onSecondActionTap,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size(double.maxFinite, AppSize.s50);
}
