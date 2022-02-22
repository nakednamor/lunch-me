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

@DriftDatabase(
  tables: [
    Languages,
    TagGroups,
    LocalizedTagGroups,
    Tags,
    LocalizedTags,
    Recipes,
    RecipeTags
  ],
  queries: {'lastTagGroupOrdering': 'SELECT MAX(ordering) FROM tag_groups;'},
)
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  MyDatabase.testDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

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

    var tagGroupWithTagList = query.map((row) => TagGroupWithTag(
        row.readTable(localizedTagGroups), row.readTableOrNull(localizedTags)));

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

  Future<List<Language>> getAllLanguages() {
    return select(languages).get();
  }

  Future<List<RecipeWithTags>> getAllRecipeWithTags() async {
    var query = select(recipes).join([
      leftOuterJoin(recipeTags, recipeTags.recipe.equalsExp(recipes.id)),
      leftOuterJoin(tags, tags.id.equalsExp(recipeTags.tag)),
    ])
      ..orderBy([OrderingTerm(expression: recipes.name)]);

    var queryResult = query.map((row) {
      var recipe = row.readTable(recipes);
      var tag = row.readTableOrNull(tags);

      return RecipeWithTag(recipe, tag);
    });

    var tagsGroupedByRecipe =
        (await queryResult.get()).groupListsBy((element) => element.recipe);

    return tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.map((e) => e.tag).whereType<Tag>().toList();
      return RecipeWithTags(recipe, tags);
    }).toList();
  }

  Future<TagGroup> addTagGroup(String name) async {
    await _validateTagGroupName(name);

    var lastOrdering = (await lastTagGroupOrdering().getSingle());
    var newOrdering = lastOrdering == null ? 0 : lastOrdering + 1;

    await into(tagGroups)
        .insert(TagGroupsCompanion.insert(ordering: newOrdering));

    var newTagGroup = await (select(tagGroups)
          ..where((tbl) => tbl.ordering.equals(newOrdering)))
        .getSingle();

    var availableLanguages = await select(languages).get();
    var languageIds = availableLanguages.map((e) => e.id);

    var batches = languageIds.map((language) =>
        LocalizedTagGroupsCompanion.insert(
            tagGroup: newTagGroup.id, lang: language, label: name));

    await batch((batch) => batch.insertAll(localizedTagGroups, batches));

    return newTagGroup;
  }

  Future<void> renameTagGroup(
      int tagGroupId, String newName, Locale locale) async {
    await _validateTagGroupName(newName);
    var language = await _getLanguage(locale);
    (update(localizedTagGroups)
          ..where((tbl) =>
              tbl.tagGroup.equals(tagGroupId) & tbl.lang.equals(language.id)))
        .write(LocalizedTagGroupsCompanion(label: Value(newName)));
  }

  Future<Language> _getLanguage(Locale locale) async {
    return (select(languages)
          ..where((tbl) => tbl.lang.equals(locale.languageCode)))
        .getSingle();
  }

  Future<int> _countTagGroupsWithName(String name) async {
    var countExpression = countAll();
    var countFilter = localizedTagGroups.label.equals(name);
    var query = selectOnly(localizedTagGroups)
      ..addColumns([countExpression])
      ..where(countFilter);

    return await query.map((p0) => p0.read(countExpression)).getSingle();
  }

  Future<void> _validateTagGroupName(String name) async {
    if (name.isEmpty) {
      throw EmptyNameException(name);
    }

    if (name.length > 50) {
      throw NameTooLongException(name);
    }

    var groupCountWithSameName = await _countTagGroupsWithName(name);
    if (groupCountWithSameName != 0) {
      throw NameAlreadyExistsException(name);
    }
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

class RecipeWithTags {
  final Recipe recipe;
  final List<Tag> tags;

  RecipeWithTags(this.recipe, this.tags);
}

class RecipeWithTag {
  final Recipe recipe;
  final Tag? tag;

  RecipeWithTag(this.recipe, this.tag);
}

class NameAlreadyExistsException implements Exception {
  String cause;

  NameAlreadyExistsException(this.cause);
}

class EmptyNameException implements Exception {
  String cause;

  EmptyNameException(this.cause);
}

class NameTooLongException implements Exception {
  String cause;

  NameTooLongException(this.cause);
}
