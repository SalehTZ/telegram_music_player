import 'package:flutter/material.dart';

import '../../constants/colors_manager.dart';
import '../../constants/values_manager.dart';

class MiniPlayerControls extends StatelessWidget {
  const MiniPlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Song Name"),
                AppGap.h4,
                Text("Artist Name"),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: ColorManager.likeButtonColor,
                )
              ],
            ),
          ],
        ),
      ],
    );
  }
}
