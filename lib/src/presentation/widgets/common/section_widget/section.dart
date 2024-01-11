import 'package:flutter/material.dart';

class SectionWidget extends StatelessWidget {
  final Widget header;
  final Widget? slot;

  const SectionWidget({
    super.key,
    required this.header,
    this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(children: [
        // * Header of Section
        header,

        // * Child of Section
        if (slot != null) slot!,
      ]),
    );
  }
}
