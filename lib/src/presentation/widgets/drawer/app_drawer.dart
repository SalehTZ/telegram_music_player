import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../common/logo/stash_mark.dart';

enum DrawerPage { home, folders, playlists, songs }

const _version = String.fromEnvironment('APP_VERSION');

class AppDrawer extends StatelessWidget {
  final ValueChanged<DrawerPage> onPageSelected;
  const AppDrawer({
    super.key,
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
          Container(
            width: AppSize.s304,
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
                        _DrawerItem(
                          icon: AssetsManager.homeIcon,
                          title: "Home",
                          onTap: () => _select(context, DrawerPage.home),
                        ),
                        AppGap.h36,
                        _DrawerItem(
                          icon: AssetsManager.libraryIcon,
                          title: "Folders",
                          onTap: () => _select(context, DrawerPage.folders),
                        ),
                        AppGap.h36,
                        _DrawerItem(
                          icon: AssetsManager.songIcon,
                          title: "Playlists",
                          onTap: () => _select(context, DrawerPage.playlists),
                        ),
                        AppGap.h36,
                        _DrawerItem(
                          icon: AssetsManager.albumIcon,
                          title: "Songs",
                          onTap: () => _select(context, DrawerPage.songs),
                        ),
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

  void _select(BuildContext context, DrawerPage page) {
    Navigator.of(context).pop();
    onPageSelected(page);
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: AppSize.s24, height: AppSize.s24),
          AppGap.w16,
          Text(
            title,
            style: TextStyles.getBoldStyle(fontSize: FontSize.s24),
          ),
        ],
      ),
    );
  }
}
