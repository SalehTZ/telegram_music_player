import 'package:flutter/material.dart';

import '../../../constants/values_manager.dart';

class CustomListBuilder extends StatelessWidget {
  const CustomListBuilder({
    super.key,
    required this.widgetList,
    this.buildAxis = Axis.horizontal,
    this.scrollController,
    this.gutter = AppSize.s16,
    this.itemCount,
    this.listPadding,
    required this.crossAxisSize,
  });

  final List<Widget> widgetList;
  final ScrollController? scrollController;
  final Axis buildAxis;
  final double crossAxisSize;
  final double gutter;
  final int? itemCount;
  final EdgeInsets? listPadding;

  static grid({
    required List<Widget> widgetList,
    Axis buildAxis = Axis.horizontal,
    required double crossAxisSize,
    double gutter = AppSize.s16,
    double rowGutter = AppSize.s12,
    int? itemCount,
  }) {
    return _CustomGridBuilder(
      crossAxisSize: crossAxisSize,
      widgetList: widgetList,
      gutter: gutter,
      itemCount: itemCount,
      rowGutter: rowGutter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buildAxis == Axis.horizontal ? crossAxisSize : null,
      width: buildAxis == Axis.vertical ? crossAxisSize : null,
      child: ListView.builder(
        scrollDirection: buildAxis,
        shrinkWrap: true,
        physics: buildAxis == Axis.horizontal
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: itemCount ?? widgetList.length,
        controller: scrollController ?? ScrollController(),
        padding: listPadding ?? const EdgeInsets.fromLTRB(16, 0, 16, 2),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right:
                  buildAxis == Axis.horizontal && index != widgetList.length - 1
                      ? gutter
                      : 0,
              bottom:
                  buildAxis == Axis.vertical && index != widgetList.length - 1
                      ? gutter
                      : 0,
            ),
            child: widgetList[index],
          );
        },
      ),
    );
  }
}

class _CustomGridBuilder extends StatelessWidget {
  const _CustomGridBuilder({
    required this.widgetList,
    this.gutter = 16,
    this.rowGutter = 12,
    this.itemCount,
    required this.crossAxisSize,
  });

  final List<Widget> widgetList;
  final double crossAxisSize;
  final double gutter;
  final double rowGutter;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: crossAxisSize,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: rowGutter,
          mainAxisSpacing: gutter,
          childAspectRatio: 1.8,
          mainAxisExtent: 96,
        ),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: itemCount ?? widgetList.length,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        itemBuilder: (context, index) {
          return SizedBox(child: widgetList[index]);
        },
      ),
    );
  }
}
