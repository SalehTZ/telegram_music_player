import 'package:flutter/foundation.dart';

class Song {
  final String title;
  final String artist;
  final String album;
  final String filePath; // Or a URL if streaming from the internet
  final Duration duration;
  final Uint8List? albumArtUrl; // URL to the album art image
  final int? rating; // Rating out of 5
  final String? genre;
  final int? releaseDate;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.duration,
    this.albumArtUrl,
    this.rating,
    this.genre,
    this.releaseDate,
  });
}
