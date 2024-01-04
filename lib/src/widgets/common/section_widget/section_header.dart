import 'package:flutter/material.dart';
import 'package:telegram_music_player/src/constants/values_manager.dart';

class SectionHeader extends StatelessWidget {
  final Widget child;
  const SectionHeader({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p12),
      child: SizedBox(
        width: AppSize.s390,
        child: child,
      ),
    );
  }
}
