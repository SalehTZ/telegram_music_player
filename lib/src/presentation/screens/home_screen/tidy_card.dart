import 'package:flutter/material.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../navigation.dart';

/// The channels and websites that stamped their names into the library's tags,
/// and the way to take them out.
class TidyCard extends StatelessWidget {
  final LibraryState state;
  const TidyCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final count = state.fixes.length;
    final channels = state.channels;
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
            count == 1 ? '1 song needs tidying' : '$count songs need tidying',
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
          ),
          AppGap.h4,
          Text(
            channels.isEmpty
                ? 'Their text is garbled, or the title holds the artist too.'
                : 'Channels and websites left their names in the tags.',
            style: TextStyles.getRegularStyle(
              fontSize: FontSize.s14,
              color: ColorManager.secondaryText,
            ),
          ),
          if (channels.isNotEmpty) ...[
            AppGap.h16,
            Wrap(
              spacing: AppSize.s8,
              runSpacing: AppSize.s8,
              children: [
                for (final channel in channels.take(4))
                  ChannelChip(name: channel.name, songs: channel.songs),
                if (channels.length > 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppPadding.p6,
                    ),
                    child: Text(
                      '${channels.length - 4} more',
                      style: TextStyles.getRegularStyle(
                        fontSize: FontSize.s14,
                        color: ColorManager.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          AppGap.h20,
          FilledButton(
            onPressed: () => openTidy(context),
            child: const Text('Tidy up'),
          ),
        ],
      ),
    );
  }
}

/// A channel's name and how many songs carry it.
class ChannelChip extends StatelessWidget {
  final String name;
  final int songs;
  const ChannelChip({super.key, required this.name, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(AppRadius.rad999),
        border: Border.all(color: ColorManager.hairline),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: name),
            TextSpan(
              text: '  $songs',
              style: TextStyles.getSemiBoldStyle(
                fontSize: FontSize.s14,
                color: ColorManager.primaryPressedColor,
              ),
            ),
          ],
        ),
        style: TextStyles.getMediumStyle(fontSize: FontSize.s14),
      ),
    );
  }
}
