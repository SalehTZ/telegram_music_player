part of 'audio_player_bloc.dart';

// abstract class AudioPlayerState {}

sealed class AudioPlayerState extends Equatable {
  const AudioPlayerState();

  @override
  List<Object> get props => [];
}

final class AudioPlayerInitial extends AudioPlayerState {}

final class AudioPlayerPlaying extends AudioPlayerState {}

final class AudioPlayerPaused extends AudioPlayerState {}

final class AudioPlayerStopped extends AudioPlayerState {}
