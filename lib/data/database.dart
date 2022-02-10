import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Languages extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get lang => text().withLength(min: 2, max: 3)();
}

class TagGroups extends Table {
  @override
  String get tableName => 'tag_groups';

  IntColumn get id => integer().autoIncrement()();

  BoolColumn get system => boolean().withDefault(const Constant(false))();
}

class LocalizedTagGroups extends Table {
  @override
  String get tableName => 'localized_tag_groups';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tagGroup => integer().references(TagGroups, #id)();

  IntColumn get lang => integer().references(Languages, #id)();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tagGroup => integer().references(TagGroups, #id)();

  BoolColumn get system => boolean().withDefault(const Constant(false))();
}

class LocalizedTags extends Table {
  @override
  String get tableName => 'localized_tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tag => integer().references(Tags, #id)();

  IntColumn get lang => integer().references(Languages, #id)();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

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

@DriftDatabase(
    tables: [Languages, TagGroups, LocalizedTagGroups, Tags, LocalizedTags])
class MyDatabase extends _$MyDatabase {
  // MyDatabase() : super(_openConnection());
  // MyDatabase(QueryExecutor? e) : super(e == null ? _openConnection() : e!);

  MyDatabase() : super(_openConnection());

  MyDatabase.testDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<List<TagGroupWithTags>> getAllTagsWithGroups(Locale locale) async {
    var query = select(tagGroups).join([
      innerJoin(localizedTagGroups,
          localizedTagGroups.tagGroup.equalsExp(tagGroups.id)),
      innerJoin(tags, tags.tagGroup.equalsExp(tagGroups.id)),
      innerJoin(localizedTags, localizedTags.tag.equalsExp(tags.id)),
      innerJoin(
          languages,
          localizedTags.lang.equalsExp(languages.id) &
              localizedTagGroups.lang.equalsExp(languages.id))
    ])
      ..where(languages.lang.equals(locale.languageCode))
      ..where(languages.lang.equals(locale.languageCode));

    var tagGroupWithTagList = query.map((row) => TagGroupWithTag(
        row.readTable(localizedTagGroups), row.readTable(localizedTags)));

    var tagGroupWithTagByTaGroup = (await tagGroupWithTagList.get())
        .groupListsBy((element) => element.tagGroup);

    return tagGroupWithTagByTaGroup.entries.map((entry) {
      var tagGroup = entry.key;
      var tags = entry.value.isEmpty
          ? List<LocalizedTag>.empty()
          : entry.value.map((e) => e.tag).toList();

      return TagGroupWithTags(tagGroup, tags);
    }).toList();
  }

  Future<List<TagGroup>> getAllTagGroups() {
    return select(tagGroups).get();
  }

  Future<List<Language>> getAllLanguages() {
    return select(languages).get();
  }
}

class TagGroupWithTag {
  final LocalizedTagGroup tagGroup;
  final LocalizedTag tag;

  TagGroupWithTag(this.tagGroup, this.tag);
}

class TagGroupWithTags {
  final LocalizedTagGroup tagGroup;
  final List<LocalizedTag> tags;

  TagGroupWithTags(this.tagGroup, this.tags);
}
