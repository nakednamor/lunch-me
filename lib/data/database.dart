import 'dart:io';
import 'dart:ui';

import "package:collection/collection.dart";
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lunch_me/data/dao/language_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
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
      await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }

    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Languages, TagGroups, LocalizedTagGroups, Tags, LocalizedTags, Recipes, RecipeTags], daos: [LanguageDao, TagDao, TagGroupDao, RecipeDao], include: {'queries.drift'})
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  MyDatabase.testDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      });

  Future<List<TagGroupWithTags>> getAllTagsWithGroups(Locale locale) async {
    return _allTagGroupsWithTags(locale.languageCode).get();
  }

  Stream<List<TagGroupWithTags>> watchAllTagsWithGroups(Locale locale) {
    return _allTagGroupsWithTags(locale.languageCode).watch();
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

      return _RecipeWithTag(recipe, tag);
    });

    var tagsGroupedByRecipe = (await queryResult.get()).groupListsBy((element) => element.recipe);

    return tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.map((e) => e.tag).whereType<Tag>().toList();
      return RecipeWithTags(recipe, tags);
    }).toList();
  }

  Future<List<RecipeWithTags>> filterRecipeByTags(List<int> tagIds) async {
    if(tagIds.isEmpty){
      return getAllRecipeWithTags();
    }

    var recipeIds = await _getRecipeIdsHavingTags(tagIds);

    var query = select(recipes).join([
      leftOuterJoin(recipeTags, recipeTags.recipe.equalsExp(recipes.id)),
      leftOuterJoin(tags, tags.id.equalsExp(recipeTags.tag)),
    ])
      ..where(recipes.id.isIn(recipeIds))
      ..orderBy([OrderingTerm(expression: recipes.name)]);

    var queryResult = query.map((row) {
      var recipe = row.readTable(recipes);
      var tag = row.readTableOrNull(tags);

      return _RecipeWithTag(recipe, tag);
    });

    var tagsGroupedByRecipe =
        (await queryResult.get()).groupListsBy((element) => element.recipe);

    var result = tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.map((e) => e.tag).whereType<Tag>().toList();
      return RecipeWithTags(recipe, tags);
    }).toList();

    result.sort((a, b) => a.tags.length.compareTo(b.tags.length));

    return result.reversed.toList();
  }

  Future<List<int>> _getRecipeIdsHavingTags(List<int> tagIds) async {
    var query = select(recipeTags)..where((tbl) => tbl.tag.isIn(tagIds));
    return query.map((row) => row.recipe).get();
  }
}

class RecipeWithTags {
  final Recipe recipe;
  final List<Tag> tags;

  RecipeWithTags(this.recipe, this.tags);
}

class _RecipeWithTag {
  final Recipe recipe;
  final Tag? tag;

  _RecipeWithTag(this.recipe, this.tag);
}
