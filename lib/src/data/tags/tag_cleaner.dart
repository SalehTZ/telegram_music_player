import 'mojibake.dart';
import 'tags.dart';

/// Telegram channels stamp themselves into the tags of the songs they share
/// ("Song @SomeChannel", "Artist | t.me/somechannel"), and download sites do
/// the same ("Song (Downloaded from Music-Site.com)"). This takes those stamps
/// out again, along with video leftovers like "(Official Audio)", and repairs
/// garbled Persian and Arabic text.
class TagCleaner {
  // * A Telegram username is 5-32 letters, digits or underscores, starting
  // * with a letter. The lookbehinds keep e-mail addresses and words that only
  // * end in "join" or "id" out.
  static final _stamp = RegExp(
    r'(?:(?<![\p{L}\p{N}_])(?:join|id|telegram|channel|کانال|تلگرام)\s*[:：\-–—]?\s*)?'
    r'(?:🆔\s*)?'
    r'(?:(?<![\w.@])@([A-Za-z][A-Za-z0-9_]{4,31})\b'
    r'|(?:https?://)?(?:www\.)?(?:t\.me|telegram\.me|telegram\.dog)/([^\s)\]}>]+))',
    caseSensitive: false,
    unicode: true,
  );
  static final _link = RegExp(
    r'(?:(?<![\p{L}\p{N}_])(?:(?:free\s+)?downloaded?\s+(?:from|at|by)|from|'
    r'دانلود\s+از|منبع)\s*[:：\-–—]?\s*)?'
    r'(?:(?:https?://|www\.)\S+|(?<![\w.@/-])([a-z0-9][a-z0-9-]*\.'
    '$_domains'
    r')\b(?!\.\w))',
    caseSensitive: false,
    unicode: true,
  );

  // * Endings that are rarely part of a real name, so "Mr.Brightside" and
  // * "Will.i.am" stay
  static const _domains = '(?:com|net|org|ir|info|xyz|biz|ru|fm|cc|tv|io)';

  /// What video rips and download sites add around a title.
  static final _junk = RegExp(
    r'[(\[]\s*(?:official\s+)?(?:(?:music|lyrics?|audio|hd|hq)\s+)?'
    r'(?:video|audio|lyrics?|visuali[sz]er|hd|hq|4k|high\s+quality)\s*[)\]]'
    r'|\b\d{2,3}\s*kbps\b'
    r'|^\s*دانلود(?:\s+آهنگ)?\s+(?:جدید\s+)?',
    caseSensitive: false,
    unicode: true,
  );
  static final _emptyBrackets = RegExp(r'\(\s*\)|\[\s*\]|\{\s*\}|<\s*>|«\s*»');
  static final _separatorRun = RegExp(r'\s*([\-–—|•·])\s*(?:[\-–—|•·]\s*)+');
  static final _edges = RegExp(r'^[\s\-–—|•·:_~/\\,]+|[\s\-–—|•·:_~/\\,]+$');
  static final _spaces = RegExp(r'\s{2,}');

  /// [value] without channel stamps, links or junk, and with garbled text
  /// repaired. Empty if nothing else was left.
  static String clean(String value) => (repairMojibake(value) ?? value)
      .replaceAll(_stamp, ' ')
      .replaceAll(_link, ' ')
      .replaceAll(_junk, ' ')
      .replaceAll(_emptyBrackets, ' ')
      .replaceAllMapped(_separatorRun, (m) => ' ${m[1]} ')
      .replaceAll(_spaces, ' ')
      .replaceAll(_edges, '')
      .trim();

  /// The channels and websites stamped into [value], as "@name" or
  /// "site.com".
  static List<String> channels(String value) => [
        for (final m in _stamp.allMatches(value))
          if (m[1] != null)
            '@${m[1]}'
          else if (!m[2]!.startsWith('+') && !m[2]!.startsWith('joinchat'))
            '@${m[2]!.split('/').first}'
          else
            't.me link',
        for (final m in _link.allMatches(value))
          if (m[1] case final site?) site,
      ];

  /// The edit that cleans one song's tags, or null when they're already clean.
  /// A song with no artist whose title reads "Artist - Title" (Telegram files
  /// often only have a file name) is split in two.
  static TagEdit? fixFor({
    required String title,
    String? artist,
    String? album,
  }) {
    var newTitle = clean(title);
    var newArtist = artist == null ? null : clean(artist);
    final newAlbum = album == null ? null : clean(album);

    final noArtist =
        newArtist == null || newArtist.isEmpty || isUnknown(newArtist);
    final dash = newTitle.indexOf(' - ');
    if (noArtist && dash > 0 && dash < newTitle.length - 3) {
      newArtist = newTitle.substring(0, dash).trim();
      newTitle = newTitle.substring(dash + 3).trim();
    }
    if (newTitle.isEmpty) newTitle = title;

    final edit = TagEdit(
      title: newTitle != title ? newTitle : null,
      artist: newArtist != null && newArtist != artist && !isUnknown(newArtist)
          ? newArtist
          : null,
      album: newAlbum != null && newAlbum != album ? newAlbum : null,
    );
    return edit.isEmpty ? null : edit;
  }

  /// Android's media library fills missing artists and albums with this.
  static bool isUnknown(String value) => value == '<unknown>';
}
