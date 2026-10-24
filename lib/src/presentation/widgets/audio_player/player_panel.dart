import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/player/player_cubit.dart';
import '../../../constants/assets_manager.dart';
import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../screens/player_screen/player_screen.dart';
import '../common/round_button/round_button_widget.dart';
import '../song_options/song_options_sheet.dart';

/// The player beside the pages of a wide window, where the phone has its
/// mini player and player page.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s360,
      decoration: const BoxDecoration(
        color: ColorManager.searchBarBackground,
        border: BorderDirectional(
          start: BorderSide(color: ColorManager.hairline),
        ),
      ),
      child: SafeArea(
        left: false,
        child: BlocBuilder<PlayerCubit, PlayerState>(
          buildWhen: (a, b) => (a.song == null) != (b.song == null),
          builder: (context, state) {
            if (state.song == null) return const _NothingPlaying();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppPadding.p20, AppPadding.p20, AppPadding.p20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Now playing',
                          style: TextStyles.getSemiBoldStyle(
                              fontSize: FontSize.s20),
                        ),
                      ),
                      RoundButtonWidget(
                        svgIcon: AssetsManager.dotsMenuIcon,
                        onTap: () {
                          final song = context.read<PlayerCubit>().state.song;
                          if (song != null) showSongOptions(context, song);
                        },
                      ),
                    ],
                  ),
                ),
                const Expanded(child: NowPlaying()),
                AppGap.h20,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p40),
        child: Text(
          'Pick a song and it plays here.',
          textAlign: TextAlign.center,
          style: TextStyles.getRegularStyle(
            fontSize: FontSize.s16,
            color: ColorManager.secondaryText,
          ),
        ),
      ),
    );
  }
}
