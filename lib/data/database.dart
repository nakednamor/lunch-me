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

  IntColumn get ordering => integer()();
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

  IntColumn get ordering => integer()();
}

class LocalizedTags extends Table {
  @override
  String get tableName => 'localized_tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tag => integer().references(Tags, #id)();

  IntColumn get lang => integer().references(Languages, #id)();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  IntColumn get type => intEnum<Source>()();

  TextColumn get url => text().withLength(max: 255).nullable()();

  TextColumn get image => text().withLength(max: 255).nullable()();
}

enum Source { web, video, photo }

class RecipeTags extends Table {
  IntColumn get recipe => integer()();

  IntColumn get tag => integer()();

  @override
  Set<Column> get primaryKey => {recipe, tag};

  @override
  String get tableName => "recipe_has_tag";
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

@DriftDatabase(tables: [
  Languages,
  TagGroups,
  LocalizedTagGroups,
  Tags,
  LocalizedTags,
  Recipes,
  RecipeTags
])
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
      ..where(languages.lang.equals(locale.languageCode))
      ..orderBy([
        OrderingTerm(expression: tagGroups.ordering, mode: OrderingMode.asc),
        OrderingTerm(expression: tags.ordering, mode: OrderingMode.asc)
      ]);

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

  Future<List<RecipeWithTags>> getAllRecipeWithTags() async {
    var query = select(recipeTags).join([
      innerJoin(recipes, recipes.id.equalsExp(recipeTags.recipe)),
      innerJoin(tags, tags.id.equalsExp(recipeTags.tag))
    ]);

    var queryResult = query.map(
        (row) => RecipeWithTag(row.readTable(recipes), row.readTable(tags)));

    var tagsGroupedByRecipe =
        (await queryResult.get()).groupListsBy((element) => element.recipe);

    return tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.isEmpty
          ? List<Tag>.empty()
          : entry.value.map((e) => e.tag).toList();
      return RecipeWithTags(recipe, tags);
    }).toList();
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

class RecipeWithTags {
  final Recipe recipe;
  final List<Tag> tags;

  RecipeWithTags(this.recipe, this.tags);
}

class RecipeWithTag {
  final Recipe recipe;
  final Tag tag;

  RecipeWithTag(this.recipe, this.tag);
}
