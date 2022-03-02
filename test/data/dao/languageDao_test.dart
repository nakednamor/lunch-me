import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/languageDao.dart';

import '../flutter_test_config.dart';

void main() {

  late LanguageDao dao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.languageDao;
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should return all languages', () async {
    // when
    var languages = await dao.getAllLanguages();

    // then
    expect(languages.length, 2);
    expect(languages.map((e) => e.lang), containsAll(['de', 'en']));
  });
}