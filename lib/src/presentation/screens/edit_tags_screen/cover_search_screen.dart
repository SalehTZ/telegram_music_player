import 'package:flutter/material.dart';

import '../../../constants/colors_manager.dart';
import '../../../constants/fonts_manager.dart';
import '../../../constants/styles_manager.dart';
import '../../../constants/values_manager.dart';
import '../../../data/online/cover_search.dart';
import '../../../data/online/web.dart';
import '../../widgets/appbar/appbar_widget.dart';
import '../../widgets/common/artwork/artwork_image.dart';
import '../../widgets/common/page_title/page_title.dart';
import '../../widgets/search_bar/search_bar_widget.dart';

/// Album covers from iTunes and Deezer. Pops with the chosen image's bytes.
class CoverSearchScreen extends StatefulWidget {
  final String query;
  const CoverSearchScreen({super.key, required this.query});

  @override
  State<CoverSearchScreen> createState() => _CoverSearchScreenState();
}

class _CoverSearchScreenState extends State<CoverSearchScreen> {
  late String _query = widget.query;
  List<CoverResult>? _results;
  bool _failed = false;
  bool _searching = false;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    if (_query.isNotEmpty) _search();
  }

  Future<void> _search() async {
    final query = _query.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final results = await CoverSearch.search(query);
      if (mounted) setState(() => _results = results);
    } on CoverSearchException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _choose(CoverResult cover) async {
    setState(() => _downloading = cover.imageUrl);
    try {
      final bytes = await Web.getBytes(Uri.parse(cover.imageUrl));
      if (!mounted) return;
      if (bytes != null) {
        Navigator.of(context).pop(bytes);
        return;
      }
    } on Exception {
      // * Reported below
    }
    if (!mounted) return;
    setState(() => _downloading = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't download that cover")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grey = TextStyles.getRegularStyle(
      fontSize: FontSize.s16,
      color: ColorManager.secondaryText,
    );
    final results = _results;
    return Scaffold(
      appBar: const AppBarWidget(isMainScreen: false),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppPadding.p20, AppPadding.p20, AppPadding.p20, AppPadding.p16),
            sliver: SliverList.list(
              children: [
                const PageTitle(
                  title: 'Find a cover',
                  subtitle: 'From iTunes and Deezer',
                ),
                AppGap.h20,
                SearchBarWidget(
                  hintText: 'Artist and album',
                  initialText: widget.query,
                  onChanged: (value) => _query = value,
                  onSubmitted: (_) => _search(),
                ),
                AppGap.h16,
                if (_searching)
                  const LinearProgressIndicator()
                else if (_failed)
                  Text(
                      "Couldn't reach iTunes or Deezer. Check your "
                      'connection and search again.',
                      style: grey)
                else if (results != null && results.isEmpty)
                  Text(
                      'No covers for “${_query.trim()}”. Try the album '
                      'name with the artist.',
                      style: grey),
              ],
            ),
          ),
          if (results != null && results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppPadding.p20, 0, AppPadding.p20, AppPadding.p40),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSize.s16,
                  mainAxisSpacing: AppSize.s20,
                  childAspectRatio: 0.72,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) => _CoverTile(
                  cover: results[i],
                  downloading: _downloading == results[i].imageUrl,
                  onTap:
                      _downloading == null ? () => _choose(results[i]) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  final CoverResult cover;
  final bool downloading;
  final VoidCallback? onTap;
  const _CoverTile({
    required this.cover,
    required this.downloading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(AppRadius.rad12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    cover.thumbUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const ArtworkPlaceholder(),
                    errorBuilder: (_, __, ___) => const ArtworkPlaceholder(),
                  ),
                  if (downloading)
                    const ColoredBox(
                      color: ColorManager.playButtonOverlay,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          AppGap.h8,
          Text(
            cover.album.isEmpty ? cover.title : cover.album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getSemiBoldStyle(fontSize: FontSize.s14),
          ),
          Text(
            '${cover.artist} · ${cover.source}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.getRegularStyle(
              color: ColorManager.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
