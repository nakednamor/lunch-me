import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/data/database.dart';


part 'languageDao.g.dart';

@DriftAccessor(
    tables: [Languages],
  include: {'../queries.drift'}
)
class LanguageDao extends DatabaseAccessor<MyDatabase> with _$LanguageDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  LanguageDao(MyDatabase db) : super(db);

  Future<List<Language>> getAllLanguages() {
    return _allLanguages().get();
  }

  Future<Language> getLanguage(Locale locale) async {
    return _getLanguageByLang(locale.languageCode).getSingle();
  }
}
