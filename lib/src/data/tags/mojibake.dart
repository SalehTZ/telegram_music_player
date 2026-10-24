import 'dart:convert';

/// Text that a program saved in one encoding and a player then read as
/// Latin-1: Persian and Arabic in Windows-1256, so "سلام" shows as "ÓáÇã",
/// and UTF-8 of any language, so "سلام" shows as "Ø³Ù„Ø§Ù…" and "Beyoncé" as
/// "BeyoncÃ©". Returns the text as it was meant, or null when [value] isn't
/// garbled.
String? repairMojibake(String value) {
  final bytes = _bytes(value);
  if (bytes == null || !bytes.any((b) => b >= 0x80)) return null;

  // * UTF-8 read as Latin-1 can be told for sure: real Latin-1 text almost
  // * never happens to be valid UTF-8
  try {
    return utf8.decode(bytes);
  } on FormatException {
    // * Not UTF-8, try Windows-1256
  }
  final text = String.fromCharCodes([
    for (final b in bytes) b < 0x80 ? b : _windows1256.codeUnitAt(b - 0x80),
  ]);
  if (!_mostlyArabicScript(text)) return null;
  // * Windows-1256 has no Persian ye and kaf, so Persian text borrowed the
  // * Arabic ones
  return _persian.hasMatch(text)
      ? text.replaceAll('ي', 'ی').replaceAll('ك', 'ک')
      : text;
}

/// The bytes [value] was read from, if every character came from one byte.
List<int>? _bytes(String value) {
  final bytes = <int>[];
  for (final c in value.runes) {
    final b = c < 0x100 ? c : _windows1252[c];
    if (b == null) return null;
    bytes.add(b);
  }
  return bytes;
}

/// Arabic script made of whole words, so accented Latin like "Beyoncé" or
/// "Sigur Rós" (which would become "Rَs") is left alone. ASCII words, like a
/// channel name next to the title, don't count either way.
bool _mostlyArabicScript(String text) {
  var arabic = 0;
  var other = 0;
  for (final word in text.split(RegExp(r'\s+'))) {
    final hasArabic = word.runes.any(_isArabic);
    if (hasArabic && _asciiLetter.hasMatch(word)) return false;
    for (final c in word.runes) {
      if (_isArabic(c)) {
        arabic++;
      } else if (c >= 0x80 && _letter.hasMatch(String.fromCharCode(c))) {
        other++;
      }
    }
  }
  return arabic >= 2 && arabic > other;
}

bool _isArabic(int c) => c >= 0x0600 && c <= 0x06ff;

final _asciiLetter = RegExp('[A-Za-z]');
final _letter = RegExp(r'\p{L}', unicode: true);
final _persian = RegExp('[پچژگ]');

/// Bytes 0x80 to 0xFF in Windows-1256.
const _windows1256 =
    '\u{20ac}\u{67e}\u{201a}\u{192}\u{201e}\u{2026}\u{2020}\u{2021}\u{2c6}\u{2030}\u{679}\u{2039}\u{152}\u{686}\u{698}\u{688}'
    '\u{6af}\u{2018}\u{2019}\u{201c}\u{201d}\u{2022}\u{2013}\u{2014}\u{6a9}\u{2122}\u{691}\u{203a}\u{153}\u{200c}\u{200d}\u{6ba}'
    '\u{a0}\u{60c}\u{a2}\u{a3}\u{a4}\u{a5}\u{a6}\u{a7}\u{a8}\u{a9}\u{6be}\u{ab}\u{ac}\u{ad}\u{ae}\u{af}'
    '\u{b0}\u{b1}\u{b2}\u{b3}\u{b4}\u{b5}\u{b6}\u{b7}\u{b8}\u{b9}\u{61b}\u{bb}\u{bc}\u{bd}\u{be}\u{61f}'
    '\u{6c1}\u{621}\u{622}\u{623}\u{624}\u{625}\u{626}\u{627}\u{628}\u{629}\u{62a}\u{62b}\u{62c}\u{62d}\u{62e}\u{62f}'
    '\u{630}\u{631}\u{632}\u{633}\u{634}\u{635}\u{636}\u{d7}\u{637}\u{638}\u{639}\u{63a}\u{640}\u{641}\u{642}\u{643}'
    '\u{e0}\u{644}\u{e2}\u{645}\u{646}\u{647}\u{648}\u{e7}\u{e8}\u{e9}\u{ea}\u{eb}\u{649}\u{64a}\u{ee}\u{ef}'
    '\u{64b}\u{64c}\u{64d}\u{64e}\u{f4}\u{64f}\u{650}\u{f7}\u{651}\u{f9}\u{652}\u{fb}\u{fc}\u{200e}\u{200f}\u{6d2}';

/// Players that read Windows-1252 rather than Latin-1 turn bytes 0x80 to
/// 0x9F into these.
const _windows1252 = {
  0x20ac: 0x80, // €
  0x201a: 0x82, // ‚
  0x0192: 0x83, // ƒ
  0x201e: 0x84, // „
  0x2026: 0x85, // …
  0x2020: 0x86, // †
  0x2021: 0x87, // ‡
  0x02c6: 0x88, // ˆ
  0x2030: 0x89, // ‰
  0x0160: 0x8a, // Š
  0x2039: 0x8b, // ‹
  0x0152: 0x8c, // Œ
  0x017d: 0x8e, // Ž
  0x2018: 0x91, // ‘
  0x2019: 0x92, // ’
  0x201c: 0x93, // “
  0x201d: 0x94, // ”
  0x2022: 0x95, // •
  0x2013: 0x96, // –
  0x2014: 0x97, // —
  0x02dc: 0x98, // ˜
  0x2122: 0x99, // ™
  0x0161: 0x9a, // š
  0x203a: 0x9b, // ›
  0x0153: 0x9c, // œ
  0x017e: 0x9e, // ž
  0x0178: 0x9f, // Ÿ
};
