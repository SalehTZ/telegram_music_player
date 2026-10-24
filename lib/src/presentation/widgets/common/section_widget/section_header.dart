import 'package:flutter/material.dart';
import 'package:stash/src/constants/values_manager.dart';

class SectionHeader extends StatelessWidget {
  final Widget child;
  const SectionHeader({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.p12,
        horizontal: AppPadding.p20,
      ),
      child: SizedBox(
        width: double.infinity,
        child: child,
      ),
    );
  }
}
