part of 'audio_player_bloc.dart';

sealed class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object> get props => [];
}

class PlayPauseEvent extends AudioPlayerEvent {}

class StopEvent extends AudioPlayerEvent {}
