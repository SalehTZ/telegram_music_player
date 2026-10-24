import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../motion.dart';
import '../common/logo/stash_mark.dart';

enum DrawerPage { home, folders, playlists, songs }

const _version = String.fromEnvironment('APP_VERSION');

class AppDrawer extends StatelessWidget {
  final DrawerPage page;
  final ValueChanged<DrawerPage> onPageSelected;
  const AppDrawer({
    super.key,
    required this.page,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    // * The drawer covers the whole screen: the panel on the left and a
    // * blurred, tappable area over the rest of the page.
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: double.infinity,
      child: Row(
        children: [
          NavPanel(
            width: AppSize.s304,
            page: page,
            onPageSelected: (page) {
              Navigator.of(context).pop();
              onPageSelected(page);
            },
          ),

          // * Blurred page behind the drawer, tap to close
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppBlur.sigma2,
                    sigmaY: AppBlur.sigma2,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo and the pages of the main screen: inside the drawer on a phone,
/// and always beside the page in a wide window.
class NavPanel extends StatelessWidget {
  final double width;
  final DrawerPage page;
  final ValueChanged<DrawerPage> onPageSelected;
  const NavPanel({
    super.key,
    required this.width,
    required this.page,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    _DrawerItem item(DrawerPage page, String icon, String title) => _DrawerItem(
          icon: icon,
          title: title,
          selected: page == this.page,
          onTap: () => onPageSelected(page),
        );

    return Container(
      width: width,
      color: ColorManager.drawerBgColor,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            AppGap.h48,
            // * Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StashMark(size: AppSize.s40),
                AppGap.w12,
                Text(
                  "Stash",
                  style: TextStyles.getBoldStyle(fontSize: FontSize.s36),
                ),
              ],
            ),

            AppGap.h114,
            // * Navigation items
            Container(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.only(left: AppPadding.p40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  item(DrawerPage.home, AssetsManager.homeIcon, "Home"),
                  AppGap.h36,
                  item(
                      DrawerPage.folders, AssetsManager.libraryIcon, "Folders"),
                  AppGap.h36,
                  item(DrawerPage.playlists, AssetsManager.songIcon,
                      "Playlists"),
                  AppGap.h36,
                  item(DrawerPage.songs, AssetsManager.albumIcon, "Songs"),
                ],
              ),
            ),

            const Spacer(),
            // * App version, set by the release build
            if (_version.isNotEmpty)
              Text(
                "version $_version",
                style: TextStyles.getRegularStyle(),
              ),
            AppGap.h8,
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // * The other pages are dimmed, so the open one stands out
    // * and the picked one brightens while the old one fades back
    final color = selected ? ColorManager.white : ColorManager.secondaryText;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: Motion.ui,
            curve: Motion.easeOut,
            builder: (context, color, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  icon,
                  width: AppSize.s24,
                  height: AppSize.s24,
                  colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
                ),
                AppGap.w16,
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.getBoldStyle(fontSize: FontSize.s24)
                        .copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
