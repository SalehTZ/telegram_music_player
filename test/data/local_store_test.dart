import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stash/src/data/library/local_store.dart';

void main() {
  test('saves in order and reads back what was saved last', () async {
    final dir = await Directory.systemTemp.createTemp('stash');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(File('${dir.path}/library.json'));

    expect(await store.load(), isEmpty);
    store.save({
      'favorites': [1]
    });
    await store.save({
      'favorites': [1, 2]
    });
    expect(await store.load(), {
      'favorites': [1, 2],
    });
  });

  test('starts over from a damaged file', () async {
    final dir = await Directory.systemTemp.createTemp('stash');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/library.json')..writeAsStringSync('{"fav');
    expect(await LocalStore(file).load(), isEmpty);
  });
}
