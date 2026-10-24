part of 'library_cubit.dart';

enum LibraryStatus { loading, needsPermission, blocked, ready, failed }

class Playlist {
  final String name;
  final List<int> songIds;
  const Playlist(this.name, this.songIds);
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

  /// Song ids in the order they were liked.
  final List<int> favorites;

  /// Song ids, last played first.
  final List<int> history;
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
    List<int>? favorites,
    List<int>? history,
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
  late final Set<int> _favorites = favorites.toSet();

  Song? byId(int id) => _byId[id];
  List<Song> songsFor(Iterable<int> ids) => [
        for (final id in ids)
          if (_byId[id] case final song?) song
      ];

  bool isFavorite(Song song) => _favorites.contains(song.id);
  List<Song> get favoriteSongs => songsFor(favorites.reversed);
  List<Song> get recentlyPlayed => songsFor(history);

  /// The edit that takes the channel stamps out of each song that has them.
  late final Map<int, TagEdit> fixes = {
    for (final s in songs)
      if (TagCleaner.fixFor(title: s.title, artist: s.artist, album: s.album)
          case final fix?)
        s.id: fix,
  };

  /// The Telegram channels stamped into the library, the most songs first.
  late final List<({String name, int songs})> channels = () {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final s in songs) {
      final found = {
        for (final field in [s.title, s.artist, s.album])
          for (final name in TagCleaner.channels(field))
            if (name.startsWith('@')) name.toLowerCase(): name,
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

  Map<String, Object?> toJson() => {
        'favorites': favorites,
        'history': history,
        'playlists': [
          for (final p in playlists) {'name': p.name, 'songs': p.songIds},
        ],
      };
}
