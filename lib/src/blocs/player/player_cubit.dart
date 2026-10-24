import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../data/models/song_model.dart';

class PlayerState {
  /// In the order they were queued; shuffle only changes what plays next.
  final List<Song> queue;
  final int? index;
  final bool playing;
  final bool shuffle;
  final LoopMode loop;

  const PlayerState({
    this.queue = const [],
    this.index,
    this.playing = false,
    this.shuffle = false,
    this.loop = LoopMode.off,
  });

  Song? get song {
    final i = index;
    return i == null || i >= queue.length ? null : queue[i];
  }

  PlayerState copyWith({
    List<Song>? queue,
    int? index,
    bool? playing,
    bool? shuffle,
    LoopMode? loop,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        shuffle: shuffle ?? this.shuffle,
        loop: loop ?? this.loop,
      );
}

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayer _player;

  /// Called once each time a song starts, for the play history.
  final void Function(Song song)? onSongStarted;
  final _errors = StreamController<String>.broadcast();
  late final List<StreamSubscription> _subscriptions;
  ConcatenatingAudioSource? _source;
  int? _reported;

  PlayerCubit({AudioPlayer? player, this.onSongStarted})
      : _player = player ?? AudioPlayer(),
        super(const PlayerState()) {
    _subscriptions = [
      _player.currentIndexStream.listen((index) {
        if (index == null || index == state.index) return;
        emit(state.copyWith(index: index));
        _reportStart();
      }),
      _player.playingStream.listen((p) => emit(state.copyWith(playing: p))),
      _player.shuffleModeEnabledStream
          .listen((s) => emit(state.copyWith(shuffle: s))),
      _player.loopModeStream.listen((m) => emit(state.copyWith(loop: m))),
      _player.playbackEventStream.listen(
        null,
        onError: (Object _) => _errors.add(_cantPlay(state.song)),
      ),
    ];
  }

  Stream<Duration> get position => _player.positionStream;
  Duration get positionNow => _player.position;

  /// "Couldn't play" messages for a snack bar.
  Stream<String> get errors => _errors.stream;

  Future<void> play(List<Song> songs, int index) async {
    if (songs.isEmpty) return;
    final source = ConcatenatingAudioSource(
      children: [for (final song in songs) _sourceFor(song)],
    );
    _source = source;
    _reported = null;
    emit(state.copyWith(queue: List.unmodifiable(songs), index: index));
    _reportStart();
    try {
      await _player.setAudioSource(source, initialIndex: index);
      // * play() only returns once playback stops, so don't wait for it
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // * Another song was picked while this one loaded
    } on PlayerException {
      _errors.add(_cantPlay(state.song));
    }
  }

  /// Plays [songs] in a random order.
  Future<void> playShuffled(List<Song> songs) async {
    if (songs.isEmpty) return;
    await _player.setShuffleModeEnabled(true);
    await play(songs, Random().nextInt(songs.length));
  }

  void toggle() {
    if (_player.playing) {
      _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero, index: _player.effectiveIndices?.first);
      }
      unawaited(_player.play());
    }
  }

  void next() {
    if (_player.hasNext) _player.seekToNext();
  }

  /// Back to the start of the song, or to the one before when it just began.
  void previous() {
    if (_player.position > const Duration(seconds: 3) || !_player.hasPrevious) {
      _player.seek(Duration.zero);
    } else {
      _player.seekToPrevious();
    }
  }

  void seek(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() async {
    final on = !_player.shuffleModeEnabled;
    if (on) await _player.shuffle();
    await _player.setShuffleModeEnabled(on);
  }

  /// Off, then the whole queue, then the one song.
  void cycleLoop() => _player.setLoopMode(switch (_player.loopMode) {
        LoopMode.off => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.off,
      });

  Future<void> playNext(Song song) async {
    final index = state.index;
    final source = _source;
    if (index == null || source == null) return play([song], 0);
    await source.insert(index + 1, _sourceFor(song));
    emit(state.copyWith(queue: [...state.queue]..insert(index + 1, song)));
  }

  /// Puts the edited versions of queued songs in the queue.
  void refresh(Song? Function(int id) byId) => emit(state.copyWith(
        queue: [for (final s in state.queue) byId(s.id) ?? s],
      ));

  void _reportStart() {
    final song = state.song;
    if (song == null || song.id == _reported) return;
    _reported = song.id;
    onSongStarted?.call(song);
  }

  static String _cantPlay(Song? song) =>
      song == null ? "Couldn't play the song" : "Couldn't play ${song.title}";

  static AudioSource _sourceFor(Song song) => AudioSource.uri(
        Uri.parse(song.uri),
        tag: MediaItem(
          id: '${song.id}',
          title: song.title,
          artist: song.artistOrUnknown,
          album: song.album,
          duration: song.duration,
          // * shortcut: the notification shows the cover on Android 10 and
          // * later only; older ones would need the album art URI. Computers
          // * can't read a cover out of a song file, so they go without.
          artUri: Platform.isAndroid ? Uri.parse(song.uri) : null,
          extras: const {'loadThumbnailUri': true},
        ),
      );

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    // * Not awaited: it only completes once every listener has gone
    _errors.close();
    await _player.dispose();
    return super.close();
  }
}
