import 'package:flutter/widgets.dart';

import '../constants/colors_manager.dart';

/// Window widths where Stash stops looking like a phone app.
class Layout {
  /// The pages sit next to a side bar instead of behind a drawer.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  /// The playing song gets a panel of its own instead of the mini player.
  static bool hasPlayerPanel(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;

  /// How wide a page opened over the main screen grows, so its lines stay
  /// easy to read.
  static const double pageWidth = 720;
}

/// A page no wider than [Layout.pageWidth], in the middle of a wide window.
class ReadableWidth extends StatelessWidget {
  final Widget child;
  const ReadableWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorManager.backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.pageWidth),
          child: child,
        ),
      ),
    );
  }
}
