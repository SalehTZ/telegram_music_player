part of 'library_cubit.dart';

enum LibraryStatus { loading, needsPermission, blocked, ready, failed }

class Playlist {
  final String name;
  final List<String> songKeys;
  const Playlist(this.name, this.songKeys);
}

/// Songs grouped by artist or by folder.
class SongGroup {
  final String name;
  final List<Song> songs;
  const SongGroup(this.name, this.songs);
}

class LibraryState {
  final LibraryStatus status;

  /// Newest first.
  final List<Song> songs;

  /// Song keys in the order they were liked.
  final List<String> favorites;

  /// Song keys, last played first.
  final List<String> history;
  final List<Playlist> playlists;

  LibraryState({
    this.status = LibraryStatus.loading,
    this.songs = const [],
    this.favorites = const [],
    this.history = const [],
    this.playlists = const [],
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<Song>? songs,
    List<String>? favorites,
    List<String>? history,
    List<Playlist>? playlists,
  }) =>
      LibraryState(
        status: status ?? this.status,
        songs: songs ?? this.songs,
        favorites: favorites ?? this.favorites,
        history: history ?? this.history,
        playlists: playlists ?? this.playlists,
      );

  late final Map<int, Song> _byId = {for (final s in songs) s.id: s};
  late final Map<String, Song> _byKey = {for (final s in songs) s.key: s};
  late final Set<String> _favorites = favorites.toSet();

  Song? byId(int id) => _byId[id];
  List<Song> songsFor(Iterable<String> keys) => [
        for (final key in keys)
          if (_byKey[key] case final song?) song
      ];

  bool isFavorite(Song song) => _favorites.contains(song.key);
  List<Song> get favoriteSongs => songsFor(favorites.reversed);
  List<Song> get recentlyPlayed => songsFor(history);

  /// The edit that takes the channel stamps out of each song that has them.
  late final Map<int, TagEdit> fixes = {
    for (final s in songs)
      if (TagCleaner.fixFor(title: s.title, artist: s.artist, album: s.album)
          case final fix?)
        s.id: fix,
  };

  /// The Telegram channels and websites stamped into the library, the most
  /// songs first.
  late final List<({String name, int songs})> channels = () {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final s in songs) {
      final found = {
        for (final field in [s.title, s.artist, s.album])
          for (final name in TagCleaner.channels(field))
            if (name.startsWith('@') || name.contains('.'))
              name.toLowerCase(): name,
      };
      for (final entry in found.entries) {
        names.putIfAbsent(entry.key, () => entry.value);
        counts[entry.key] = (counts[entry.key] ?? 0) + 1;
      }
    }
    return [
      for (final key in counts.keys) (name: names[key]!, songs: counts[key]!),
    ]..sort((a, b) => b.songs.compareTo(a.songs));
  }();

  /// Telegram folders first, then the fullest.
  late final List<SongGroup> folders = () {
    final byFolder = <String, List<Song>>{};
    for (final s in songs) {
      byFolder.putIfAbsent(s.folder, () => []).add(s);
    }
    return [
      for (final e in byFolder.entries) SongGroup(e.key, e.value),
    ]..sort((a, b) {
        final telegram = a.songs.first.fromTelegram;
        if (telegram != b.songs.first.fromTelegram) return telegram ? -1 : 1;
        return b.songs.length.compareTo(a.songs.length);
      });
  }();

  /// Artists by how many songs they have. Names are cleaned first, so
  /// "Daft Punk @channel" and "Daft Punk" are one artist.
  late final List<SongGroup> artists = () {
    final names = <String, String>{};
    final byArtist = <String, List<Song>>{};
    for (final s in songs) {
      final name = TagCleaner.clean(s.artist);
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      byArtist.putIfAbsent(key, () => []).add(s);
    }
    return [
      for (final e in byArtist.entries) SongGroup(names[e.key]!, e.value),
    ]..sort((a, b) => b.songs.length.compareTo(a.songs.length));
  }();

  /// Copies of the same song: the same title and artist once cleaned, and
  /// within a few seconds of each other. The best copy comes first in each.
  late final List<List<Song>> duplicates = () {
    final byName = <String, List<Song>>{};
    for (final s in songs) {
      final key = _sameSongKey(s);
      if (key != null) byName.putIfAbsent(key, () => []).add(s);
    }
    final groups = <List<Song>>[];
    for (final named in byName.values.where((g) => g.length > 1)) {
      named.sort((a, b) => a.duration.compareTo(b.duration));
      var group = [named.first];
      for (final s in named.skip(1)) {
        if (s.duration - group.last.duration > const Duration(seconds: 3)) {
          if (group.length > 1) groups.add(group);
          group = [s];
        } else {
          group.add(s);
        }
      }
      if (group.length > 1) groups.add(group);
    }
    for (final group in groups) {
      group.sort(_betterCopy);
    }
    return groups;
  }();

  /// Title and artist with stamps, case and punctuation taken out, or null
  /// when the song has no title to go by.
  String? _sameSongKey(Song s) {
    final fix = fixes[s.id];
    final title = _plain(fix?.title ?? s.title);
    final artist = _plain(fix?.artist ?? s.artist);
    return title.isEmpty ? null : '$artist\u0000$title';
  }

  static String _plain(String value) => value
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  /// Lossless first, then the higher bitrate, the cleaner tags and the
  /// newer file.
  int _betterCopy(Song a, Song b) {
    int lossless(Song s) => s.format == 'FLAC' ? 1 : 0;
    int clean(Song s) => fixes.containsKey(s.id) ? 0 : 1;
    return switch (lossless(b) - lossless(a)) {
      0 => switch ((b.bitrate - a.bitrate) ~/ 16) {
          // * Bitrates within 16 kbps are the same quality
          0 => switch (clean(b) - clean(a)) {
              0 => b.added.compareTo(a.added),
              final c => c,
            },
          final c => c,
        },
      final c => c,
    };
  }

  Map<String, Object?> toJson() => {
        'favorites': favorites,
        'history': history,
        'playlists': [
          for (final p in playlists) {'name': p.name, 'songs': p.songKeys},
        ],
      };
}
