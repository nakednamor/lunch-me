import 'dart:io';

import "package:collection/collection.dart";
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/model/recipe_filters.dart';
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

@DriftDatabase(tables: [TagGroups, Tags, Recipes, RecipeTags], daos: [TagDao, TagGroupDao, RecipeDao], include: {'queries.drift'})
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  MyDatabase.testDb(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      });

  Future<List<TagGroupWithTags>> getAllTagsWithGroups() async {
    return _allTagGroupsWithTags().get();
  }

  Stream<List<TagGroupWithTags>> watchAllTagsWithGroups() {
    return _allTagGroupsWithTags().watch();
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

  Future<List<RecipeWithTags>> filterRecipes(List<RecipeFilter> filterList) async {
    var selectedTagIds = filterList.map((filter) => filter.tags).flattened.toList();
    if (filterList.isEmpty || selectedTagIds.isEmpty) {
      return getAllRecipeWithTags();
    }

    var recipeIds = await _getRecipeIds(filterList);

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

    _sortRecipesByMatchingTagsAndName(result, selectedTagIds);

    return result;
  }

  void _sortRecipesByMatchingTagsAndName(List<RecipeWithTags> recipes, List<int> selectedTagIds) {
    recipes.sort((a, b) {
      var matchingTagsA = a.tags.where((tag) => selectedTagIds.contains(tag.id)).length;
      var matchingTagsB = b.tags.where((tag) => selectedTagIds.contains(tag.id)).length;

      if (matchingTagsA > matchingTagsB) {
        return -1;
      } else if (matchingTagsA < matchingTagsB) {
        return 1;
      } else {
        return a.recipe.name.compareTo(b.recipe.name);
      }
    });
  }

  Future<List<int>> _getRecipeIds(List<RecipeFilter> filterList) async {
    var futures = filterList.where((filter) => filter.tags.isNotEmpty).map((filter) async {
      List<int> result;
      if (filter.allMatch) {
        result = await _getRecipeIdsHavingAllTags(filter);
      } else {
        result = await _getRecipeIdsHavingTags(filter.tags);
      }

      return result;
    }).toList();

    var recipeIdsOfGroups = await Future.wait(futures);
    var recipeIds = recipeIdsOfGroups.map((e) => e.toSet()).reduce((a, b) => a.intersection(b)).toList();

    return recipeIds;
  }

  Future<List<int>> _getRecipeIdsHavingTags(List<int> tagIds) async {
    var query = select(recipeTags)..where((tbl) => tbl.tag.isIn(tagIds));
    return query.map((row) => row.recipe).get();
  }

  Future<List<int>> _getRecipeIdsHavingAllTags(RecipeFilter filter) async {
    var tagString = filter.tags.join(",");
    var tagCount = filter.tags.length;
    var result = await customSelect('SELECT recipe FROM recipe_has_tag WHERE tag IN ($tagString) GROUP BY recipe HAVING COUNT(*) = $tagCount;', readsFrom: {recipeTags})
        .map((row) => row.read<int>('recipe'))
        .get();

    return result;
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
