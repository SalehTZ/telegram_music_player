import 'models/song_model.dart';

const _telegramMusicFolder = "/storage/emulated/0/Music/Telegram";

var fakeSongsList = [
  Song(
    title: "Happier Than Ever",
    artist: "Billie Eilish",
    album: "Happier Than Ever",
    filePath: "$_telegramMusicFolder/Happier Than Ever.mp3",
    duration: const Duration(minutes: 4, seconds: 58),
  ),
  Song(
    title: "Do I Wanna Know?",
    artist: "Arctic Monkeys",
    album: "AM",
    filePath: "$_telegramMusicFolder/Do I Wanna Know.mp3",
    duration: const Duration(minutes: 4, seconds: 14),
    lyrics: "Crawlin' back to you\nEver thought of callin' when",
  ),
  Song(
    title: "Save Your Tears",
    artist: "Weeknd",
    album: "After Hours",
    filePath: "$_telegramMusicFolder/Save Your Tears.mp3",
    duration: const Duration(minutes: 3, seconds: 35),
  ),
  Song(
    title: "Blinding Lights",
    artist: "The Weeknd",
    album: "After Hours",
    filePath: "$_telegramMusicFolder/Blinding Lights.mp3",
    duration: const Duration(minutes: 3, seconds: 20),
  ),
  Song(
    title: "Cruel Summer",
    artist: "Taylor Swift",
    album: "Lover",
    filePath: "$_telegramMusicFolder/Cruel Summer.mp3",
    duration: const Duration(minutes: 3, seconds: 35),
  ),
  Song(
    title: "Get Lucky",
    artist: "Daft Punk",
    album: "Random Access Memories",
    filePath: "$_telegramMusicFolder/Get Lucky.mp3",
    duration: const Duration(minutes: 3, seconds: 25),
  ),
];

// * Temporary playback values used by the player UI until the
// * audio player bloc is wired up.
final fakeNowPlayingSong = fakeSongsList[1];
const fakeNowPlayingPosition = Duration(minutes: 2, seconds: 34);
