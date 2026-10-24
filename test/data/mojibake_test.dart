import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/tags/mojibake.dart';

void main() {
  test('repairs Windows-1256 text read as Latin-1', () {
    expect(repairMojibake('ÓáÇã'), 'سلام');
    expect(repairMojibake('ÚãÑæ ÏíÇÈ'), 'عمرو دياب', reason: 'Arabic keeps ي');
  });

  test('gives Persian text its own ye and kaf back', () {
    expect(repairMojibake('ãÍÓä \x8dÇæÔí'), 'محسن چاوشی');
    expect(repairMojibake('ÇãíÑ Èí \x90ÒäÏ'), 'امیر بی گزند');
  });

  test('repairs UTF-8 read as Latin-1', () {
    expect(
      repairMojibake('Ù\x85Ø\xadØ³Ù\x86 Ú\x86Ø§Ù\x88Ø´Û\x8c'),
      'محسن چاوشی',
    );
    expect(repairMojibake('BeyoncÃ©'), 'Beyoncé');
  });

  test('leaves text that is fine alone', () {
    for (final value in [
      'Get Lucky',
      'Beyoncé',
      'Sigur Rós – Hoppípolla',
      'Mötley Crüe',
      'Café del Mar…',
      'Ça plane pour moi',
      'Ólafur Arnalds',
      'Déjà Vu',
      'Für Elise',
      'Señorita',
      '© 2013 ½ Price',
      'محسن چاوشی',
      '',
    ]) {
      expect(repairMojibake(value), isNull, reason: value);
    }
  });
}
