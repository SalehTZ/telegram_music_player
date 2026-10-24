import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/library/library_cubit.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../widgets/music_folders/music_folders.dart';

/// What the app shows until it can list the songs: the permission it needs,
/// or why the library couldn't be read.
class LibraryGate extends StatelessWidget {
  final LibraryStatus status;
  const LibraryGate({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryCubit>();
    return switch (status) {
      LibraryStatus.needsPermission => _Message(
          title: 'Let Stash find your music',
          body: 'Stash plays and tidies the songs saved on this phone, '
              'like the ones in Music/Telegram and Download/Telegram. '
              'Your songs stay on your phone.',
          action: FilledButton(
            onPressed: library.allow,
            child: const Text('Allow access to music'),
          ),
          showTelegramTip: true,
        ),
      LibraryStatus.blocked => _Message(
          title: "Stash can't see your music",
          body: "Android won't ask again. In Settings, open Permissions, "
              'then Music and audio, and choose Allow.',
          action: FilledButton(
            onPressed: library.openSettings,
            child: const Text('Open settings'),
          ),
        ),
      LibraryStatus.failed => _Message(
          title: "Couldn't read your music",
          body: "Android's media library didn't answer. "
              'This usually passes after a moment.',
          action: OutlinedButton(
            onPressed: library.refresh,
            child: const Text('Try again'),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// The library is readable but has no songs.
class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.read<LibraryCubit>().pickedFolders != null) {
      return _Message(
        title: 'No songs yet',
        body: 'Songs in your Music folder and in Telegram Desktop\'s '
            'downloads show up here. Add the folder your music is in, or '
            'drop songs on this window.',
        action: FilledButton(
          onPressed: () => addMusicFolder(context),
          child: const Text('Add a folder'),
        ),
      );
    }
    return _Message(
      title: 'No songs yet',
      body: 'Songs you save to Music or Download show up here.',
      action: OutlinedButton(
        onPressed: context.read<LibraryCubit>().refresh,
        child: const Text('Look again'),
      ),
      showTelegramTip: true,
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final Widget action;
  final bool showTelegramTip;
  const _Message({
    required this.title,
    required this.body,
    required this.action,
    this.showTelegramTip = false,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyles.getRegularStyle(
      fontSize: FontSize.s16,
      color: ColorManager.secondaryText,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppPadding.p28, AppPadding.p40, AppPadding.p28, AppPadding.p28),
      children: [
        Text(title, style: TextStyles.getBoldStyle(fontSize: FontSize.s30)),
        AppGap.h12,
        Text(body, style: secondary),
        AppGap.h24,
        Align(alignment: AlignmentDirectional.centerStart, child: action),
        if (showTelegramTip) ...[
          AppGap.h40,
          const Divider(),
          AppGap.h24,
          Text(
            'Songs that stay inside Telegram',
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s18),
          ),
          AppGap.h8,
          Text(
            "Telegram keeps its downloads in its own folder, which other "
            "apps can't open. To bring a song over, open its menu in "
            'Telegram and tap Save to Music, or share it to Stash.',
            style: secondary,
          ),
        ],
      ],
    );
  }
}
