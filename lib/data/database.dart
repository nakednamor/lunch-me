import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  include: {'queries.drift'}
)
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
    return allLanguages().get();
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

    var lastOrdering = await getMaxTagGroupOrdering().getSingleOrNull();

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

  Future<List<TagGroup>> getAllTagGroups() {
    return allTagGroups().get();
  }

  Future<List<Tag>> getAllTags() {
    return allTags().get();
  }

  Future<void> changeTagGroupOrdering(int tagGroupId, int newOrder) async {
    if (newOrder < 0) {
      throw NegativeValueException(newOrder);
    }

    var target = await getTagGroupById(tagGroupId).getSingleOrNull();
    if(target == null) {
      throw TagGroupNotFoundException(tagGroupId);
    }

    var otherTarget = await getTagGroupByOrdering(newOrder).getSingle();  // TODO potential bug if newOrder > max(ordering)

    var currentOrdering = target.ordering;

    var lastOrdering = (await getMaxTagGroupOrdering().getSingle()) ?? 0;

    await updateOrderingOfTagGroup( (lastOrdering + 1), otherTarget.id);
    await updateOrderingOfTagGroup( newOrder, target.id);
    await updateOrderingOfTagGroup( currentOrdering, otherTarget.id);
  }

  Future<void> deleteTagGroup(int tagGroupId) async {
    var deletedGroupCount = await deleteTagGroupById(tagGroupId);
    if(deletedGroupCount != 1) {
      throw TagGroupNotFoundException(tagGroupId);
    }
  }

  Future<Language> _getLanguage(Locale locale) async {
    return getLanguageByLang(locale.languageCode).getSingle();
  }

  Future<int> _countTagGroupsWithName(String name) async {
    return countTagGroupByLabel(name).getSingle();
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

class TagGroupNotFoundException implements Exception {
  int cause;

  TagGroupNotFoundException(this.cause);
}

class NegativeValueException implements Exception {
  int cause;

  NegativeValueException(this.cause);
}
