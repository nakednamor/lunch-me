import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lunch_me/data/dao/language_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'app.db'));

    if (!await file.exists()) {
      // Extract the pre-populated database file from assets
      final blob = await rootBundle.load('assets/db/lunch_me_db');
      final buffer = blob.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }

    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [
  Languages,
  TagGroups,
  LocalizedTagGroups,
  Tags,
  LocalizedTags,
  Recipes,
  RecipeTags
], daos: [
  LanguageDao,
  TagDao,
  TagGroupDao
], include: {
  'queries.drift'
})
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  MyDatabase.testDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      });

  Future<List<TagGroupWithTags>> getAllTagsWithGroups(Locale locale) async {
    var query = select(tagGroups).join([
      innerJoin(languages, localizedTagGroups.lang.equalsExp(languages.id)),
      innerJoin(
          localizedTagGroups,
          localizedTagGroups.tagGroup.equalsExp(tagGroups.id) &
          localizedTagGroups.lang.equalsExp(languages.id)),
      leftOuterJoin(tags, tags.tagGroup.equalsExp(tagGroups.id)),
      leftOuterJoin(
          localizedTags,
          localizedTags.tag.equalsExp(tags.id) &
          localizedTags.lang.equalsExp(languages.id)),
    ])
      ..where(languages.lang.equals(locale.languageCode))
      ..orderBy([
        OrderingTerm(expression: tagGroups.ordering, mode: OrderingMode.asc),
        OrderingTerm(expression: tags.ordering, mode: OrderingMode.asc)
      ]);

    var tagGroupWithTagList = query.map((row) =>
        TagGroupWithTag(
            row.readTable(localizedTagGroups),
            row.readTableOrNull(localizedTags)));

    var tagGroupWithTagByTagGroup = (await tagGroupWithTagList.get())
        .groupListsBy((element) => element.tagGroup);

    return tagGroupWithTagByTagGroup.entries.map((entry) {
      var tagGroup = entry.key;
      var tags = entry.value.isEmpty
          ? List<LocalizedTag>.empty()
          : entry.value.map((e) => e.tag).whereType<LocalizedTag>().toList();

      return TagGroupWithTags(tagGroup, tags);
    }).toList();
  }

  Future<List<RecipeWithTags>> getAllRecipeWithTags() async {
    return _allRecipesWithTags().get();
  }
}

class TagGroupWithTag {
  final LocalizedTagGroup tagGroup;
  final LocalizedTag? tag;

  TagGroupWithTag(this.tagGroup, this.tag);
}

class TagGroupWithTags {
  final LocalizedTagGroup tagGroup;
  final List<LocalizedTag> tags;

  TagGroupWithTags(this.tagGroup, this.tags);
}