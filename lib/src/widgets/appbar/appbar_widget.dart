import 'package:flutter/material.dart';

import '../../constants/assets_manager.dart';
import '../../constants/styles_manager.dart';
import '../../constants/values_manager.dart';
import '../common/round_button/round_button_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool hasSecondAction;
  final bool isMainScreen;
  const AppBarWidget({
    super.key,
    this.hasSecondAction = false,
    this.isMainScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppPadding.p20,
        right: AppPadding.p20,
        top: AppPadding.p4,
      ),
      child: Row(
        children: [
          isMainScreen
              ? RoundButtonWidget(
                  svgIcon: AssetsManager.hamburgerMenuIcon,
                  onTap: () {},
                )
              : RoundButtonWidget(
                  svgIcon: AssetsManager.arrowBackIcon,
                  onTap: () {},
                ),
          const Spacer(),
          Text(
            "Logo",
            style: TextStyles.getBoldStyle(),
          ),
          if (hasSecondAction) ...[
            const Spacer(),
            const RoundButtonWidget(svgIcon: AssetsManager.dotsMenuIcon),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size(double.maxFinite, 54);
}
