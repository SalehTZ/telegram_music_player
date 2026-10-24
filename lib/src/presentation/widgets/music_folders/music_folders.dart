import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../utils/song_text.dart';

/// Asks for a folder and adds it to the ones Stash looks in.
Future<void> addMusicFolder(BuildContext context) async {
  final cubit = context.read<LibraryCubit>();
  final path = await getDirectoryPath(confirmButtonText: 'Add');
  if (path != null) await cubit.addFolder(path);
}

/// The folders Stash looks in, on a computer, and the way to change them.
class MusicFolders extends StatelessWidget {
  const MusicFolders({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    final folders = cubit.pickedFolders?.folders ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stash looks in',
          style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
        ),
        AppGap.h4,
        Text(
          'and everything inside. You can also drop songs or folders on '
          'this window.',
          style: TextStyles.getRegularStyle(
            fontSize: FontSize.s14,
            color: ColorManager.secondaryText,
          ),
        ),
        AppGap.h12,
        for (final folder in folders)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.p2),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: ColorManager.secondaryText,
                ),
                AppGap.w12,
                Expanded(
                  child: Text(
                    displayPath(folder),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.getMediumStyle(fontSize: FontSize.s16),
                  ),
                ),
                IconButton(
                  tooltip: 'Stop looking here',
                  onPressed: () => cubit.removeFolder(folder),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ColorManager.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        AppGap.h12,
        OutlinedButton(
          onPressed: () => addMusicFolder(context),
          child: const Text('Add a folder'),
        ),
      ],
    );
  }
}

/// Takes songs and folders dropped on [child]: songs are copied into the
/// library, folders are added to the ones Stash looks in.
class DropToAdd extends StatefulWidget {
  final Widget child;
  const DropToAdd({super.key, required this.child});

  @override
  State<DropToAdd> createState() => _DropToAddState();
}

class _DropToAddState extends State<DropToAdd> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    if (cubit.pickedFolders == null) return widget.child;
    return DropTarget(
      onDragEntered: (_) => setState(() => _over = true),
      onDragExited: (_) => setState(() => _over = false),
      onDragDone: (details) {
        setState(() => _over = false);
        cubit.importPaths([for (final file in details.files) file.path]);
      },
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (_over)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(AppPadding.p12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ColorManager.playButtonOverlay,
                    borderRadius: const BorderRadius.all(AppRadius.rad16),
                    border: Border.all(
                      color: ColorManager.primaryPressedColor,
                      width: AppSize.s2,
                    ),
                  ),
                  child: Text(
                    'Drop songs to copy them into Stash,\n'
                    'or folders to look in them too',
                    textAlign: TextAlign.center,
                    style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
