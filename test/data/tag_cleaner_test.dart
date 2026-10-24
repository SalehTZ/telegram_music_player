import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/tags/tag_cleaner.dart';

void main() {
  test('takes out channel stamps and what they leave behind', () {
    const cases = {
      'Do I Wanna Know? @MusicArchive': 'Do I Wanna Know?',
      'Arctic Monkeys | t.me/MusicArchive': 'Arctic Monkeys',
      'Song (@chan_nel)': 'Song',
      'Song [Join @PersianHits]': 'Song',
      'Artist - Title - @channel': 'Artist - Title',
      'Title — https://t.me/joinchat/AbCdEf': 'Title',
      '🆔 @NightTunes': '',
      'آهنگ زیبا @PersianMusic': 'آهنگ زیبا',
      'کانال: @PersianMusic': '',
      'خواننده | https://t.me/xyz': 'خواننده',
      'Live www.example.com': 'Live',
    };
    cases.forEach((input, expected) =>
        expect(TagCleaner.clean(input), expected, reason: input));
  });

  test('leaves real titles alone', () {
    for (final title in [
      'Do I Wanna Know?',
      'Squid Game',
      '.38 Special',
      'Tyler @ Night',
      'mail me@example.com',
      'Rock - Live',
      'Anti-Hero',
    ]) {
      expect(TagCleaner.clean(title), title, reason: title);
    }
  });

  test('names the channels it finds', () {
    expect(
      TagCleaner.channels('Song @MusicArchive t.me/NightTunes t.me/+AbCd'),
      ['@MusicArchive', '@NightTunes', 't.me link'],
    );
    expect(TagCleaner.channels('Clean title'), isEmpty);
  });

  test('suggests an edit only when something changes', () {
    expect(TagCleaner.fixFor(title: 'Get Lucky', artist: 'Daft Punk'), isNull);

    final fix = TagCleaner.fixFor(
      title: 'Get Lucky @Music_Box',
      artist: 'Daft Punk',
      album: 'Random Access Memories | t.me/music_box',
    )!;
    expect(fix.title, 'Get Lucky');
    expect(fix.artist, isNull);
    expect(fix.album, 'Random Access Memories');
  });

  test('splits "Artist - Title" when the artist is missing', () {
    final fix = TagCleaner.fixFor(
      title: 'Arctic Monkeys - Do I Wanna Know @Music_Box',
      artist: '<unknown>',
    )!;
    expect(fix.artist, 'Arctic Monkeys');
    expect(fix.title, 'Do I Wanna Know');

    final kept = TagCleaner.fixFor(title: 'Rock - Live', artist: 'Band');
    expect(kept, isNull);
  });
}
