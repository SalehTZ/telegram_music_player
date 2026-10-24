import 'package:flutter/material.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../navigation.dart';

/// How many songs are saved more than once, and the way to clear them out.
class DuplicatesCard extends StatelessWidget {
  final LibraryState state;
  const DuplicatesCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final count = state.duplicates.length;
    final copies = state.duplicates.fold(0, (n, g) => n + g.length - 1);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppPadding.p20),
      padding: const EdgeInsets.all(AppPadding.p20),
      decoration: const BoxDecoration(
        color: ColorManager.searchBarBackground,
        borderRadius: BorderRadius.all(AppRadius.rad16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count == 1
                ? '1 song is saved more than once'
                : '$count songs are saved more than once',
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
          ),
          AppGap.h4,
          Text(
            copies == 1
                ? 'Delete the extra copy and keep the best one.'
                : 'Delete $copies extra copies and keep the best of each.',
            style: TextStyles.getRegularStyle(
              fontSize: FontSize.s14,
              color: ColorManager.secondaryText,
            ),
          ),
          AppGap.h20,
          OutlinedButton(
            onPressed: () => openDuplicates(context),
            child: const Text('See duplicates'),
          ),
        ],
      ),
    );
  }
}
