import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/models/song_model.dart';
import '../../../utils/song_text.dart';
import '../../navigation.dart';
import '../../widgets/common/artwork/artwork_image.dart';

/// The folders that hold songs, the ones Telegram saves to first.
class FoldersScreen extends StatelessWidget {
  final double bottomPadding;
  const FoldersScreen({super.key, this.bottomPadding = AppPadding.p20});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final folders = state.folders;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
              AppPadding.p20, AppPadding.p20, AppPadding.p20, bottomPadding),
          itemCount: folders.length + 1,
          separatorBuilder: (_, __) => AppGap.h8,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppPadding.p12),
                child: Text(
                  folders.length == 1
                      ? '1 folder'
                      : '${folders.length} folders',
                  style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
                ),
              );
            }
            final folder = folders[index - 1];
            final name = Song.folderName(folder.name);
            return CollectionRow(
              cover: folder.songs.first,
              title: name,
              detail: displayPath(folder.name),
              count: folder.songs.length,
              // * Only when the name doesn't already say so
              tag: folder.songs.first.fromTelegram &&
                      !name.toLowerCase().contains('telegram')
                  ? 'Telegram'
                  : null,
              onTap: () => openSongList(
                context,
                title: name,
                select: (s) => [
                  for (final f in s.folders)
                    if (f.name == folder.name) ...f.songs,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// One folder or playlist: a cover, its name and how many songs it has.
class CollectionRow extends StatelessWidget {
  final Song? cover;
  final String title;
  final String? detail;
  final int count;
  final String? tag;
  final VoidCallback onTap;
  const CollectionRow({
    super.key,
    required this.cover,
    required this.title,
    required this.count,
    required this.onTap,
    this.detail,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final grey = TextStyles.getRegularStyle(
      fontSize: FontSize.s14,
      color: ColorManager.secondaryText,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(AppRadius.rad12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.p6),
        child: Row(
          children: [
            ArtworkImage(song: cover, size: AppSize.s64),
            AppGap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.getSemiBoldStyle(
                              fontSize: FontSize.s16),
                        ),
                      ),
                      if (tag != null) ...[
                        AppGap.w8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.p6,
                            vertical: AppPadding.p1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(AppRadius.rad999),
                            border: Border.all(
                              color: ColorManager.primaryPressedColor,
                            ),
                          ),
                          child: Text(
                            tag!,
                            style: TextStyles.getMediumStyle(
                              fontSize: FontSize.s10,
                              color: ColorManager.primaryPressedColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (detail != null) ...[
                    AppGap.h4,
                    Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: grey,
                    ),
                  ],
                ],
              ),
            ),
            AppGap.w12,
            Text('$count', style: grey),
          ],
        ),
      ),
    );
  }
}
