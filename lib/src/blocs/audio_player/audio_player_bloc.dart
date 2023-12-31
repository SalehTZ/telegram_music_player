import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

part 'audio_player_event.dart';
part 'audio_player_state.dart';

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayerBloc() : super(AudioPlayerStopped()) {
    on<AudioPlayerEvent>(_onPlayerStateChange);
  }

  _onPlayerStateChange(
      AudioPlayerEvent event, Emitter<AudioPlayerState> emit) async* {
    if (event is PlayPauseEvent) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        yield AudioPlayerPaused();
      } else {
        await _audioPlayer.play();
        yield AudioPlayerPlaying();
      }
    } else if (event is StopEvent) {
      await _audioPlayer.stop();
      yield AudioPlayerStopped();
    }
  }
}
