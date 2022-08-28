import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_filters.dart';

import 'flutter_test_config.dart';

const String testDatabasePath = 'test_resources/data/test_lunch_me_db';
const String testDatabaseTemporaryFileName = 'app.db';

void main() {
  setUp(() async {
    debugPrint('test: setup started');
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should return all recipes', () async {
    // when
    var recipeWithTags = await testDatabase.getAllRecipeWithTags();

    // then
    expect(recipeWithTags.length, 3);
    expect(recipeWithTags.map((e) => e.recipe.name), containsAllInOrder(["recipe #1", "recipe #2", "recipe #3"]));

    expect(recipeWithTags[0].tags.map((e) => e.id), containsAll([2]));
    expect(recipeWithTags[1].tags.map((e) => e.id), containsAll([2, 4, 6]));
    expect(recipeWithTags[2].tags, isEmpty);
  });

  test('should return tag-groups and tags ordered by order-column', () async {
    //when
    var actual = await testDatabase.getAllTagsWithGroups();

    // then tag-groups should be ordered
    var tagGroupIds = actual.map((e) => e.tagGroup.id);
    expect(tagGroupIds, containsAllInOrder([2, 1, 3]));

    // and tags should be ordered as well
    expect(actual[0].tags.map((e) => e.id), containsAllInOrder([2, 1]));
    expect(actual[1].tags.map((e) => e.id), containsAllInOrder([3, 5, 4]));
    expect(actual[2].tags.map((e) => e.id), containsAllInOrder([6]));
  });

  test('filter recipes should return all recipes when no tag is selected', () async {
    // when
    var recipeWithTags = await testDatabase.filterRecipes([]);

    // then
    expect(recipeWithTags.length, 3);
    expect(recipeWithTags.map((e) => e.recipe.name), containsAllInOrder(["recipe #1", "recipe #2", "recipe #3"]));

    expect(recipeWithTags[0].tags.map((e) => e.id), containsAll([2]));
    expect(recipeWithTags[1].tags.map((e) => e.id), containsAll([2, 4, 6]));
    expect(recipeWithTags[2].tags, isEmpty);
  });

  test('should filter recipes by tags', () async {
    await _clearDatabase();
    await _prepareDatabaseForFiltering();

    await _filteringRecipes([1, 5], [1], {1: false, 2: false});
    await _filteringRecipes([1, 5], [1], {1: true, 2: true});
    await _filteringRecipes([1, 2], [1, 2], {1: false});
    await _filteringRecipes([1, 2], [1], {1: true});
    await _filteringRecipes([2, 3], [2, 1, 3], {1: false});
    await _filteringRecipes([2, 3], [2], {1: true});
    await _filteringRecipes([2, 5], [1, 2], {1: false, 2: false});
    await _filteringRecipes([2, 5], [1, 2], {1: true, 2: true});
    await _filteringRecipes([1, 2, 4], [2], {1: false, 2: false});
    await _filteringRecipes([1, 2, 4], [], {1: true, 2: true});
    await _filteringRecipes([2, 3, 5, 6], [2, 1, 3], {1: false, 2: false});
    await _filteringRecipes([2, 3, 5, 6], [], {1: true, 2: true});
    await _filteringRecipes([10], [], {3: false});
    await _filteringRecipes([10], [], {3: true});
  });
}

_clearDatabase() async {
  var allRecipes = await testDatabase.getAllRecipeWithTags();
  var allTagGroups = await testDatabase.getAllTagsWithGroups();

  // remove all recipes
  for (var recipe in allRecipes) {
    await testDatabase.recipeDao.deleteRecipe(recipe.recipe.id);
  }

  // delete all tags
  var tagIds = allTagGroups.map((e) => e.tags).flattened.map((e) => e.id);
  for (var tagId in tagIds) {
    await testDatabase.tagDao.deleteTag(tagId);
  }

  // delete tag groups
  var tagGroupIds = allTagGroups.map((e) => e.tagGroup.id);
  for (var tagGroupId in tagGroupIds) {
    await testDatabase.tagGroupDao.deleteTagGroup(tagGroupId);
  }
}

_prepareDatabaseForFiltering() async {
  // create 3 tag groups with 3 tags each
  var group_1 = await testDatabase.tagGroupDao.addTagGroup("group #1");
  var group_2 = await testDatabase.tagGroupDao.addTagGroup("group #2");
  var group_3 = await testDatabase.tagGroupDao.addTagGroup("group #3");

  for (var i = 1; i <= 9; i++) {
    var tagGroupId = -1;
    if (i <= 3) {
      tagGroupId = group_1.id;
    } else if (i > 3 && i <= 6) {
      tagGroupId = group_2.id;
    } else {
      tagGroupId = group_3.id;
    }

    await testDatabase.tagDao.addTag(tagGroupId, "tag #$i");
  }

  // tag group #3 has one additional tag
  await testDatabase.tagDao.addTag(group_3.id, "tag #10");

  // create 3 recipes
  await testDatabase.recipeDao.createRecipe("recipe #1", Source.memory, null, null, null, null);
  await testDatabase.recipeDao.createRecipe("recipe #2", Source.memory, null, null, null, null);
  await testDatabase.recipeDao.createRecipe("recipe #3", Source.memory, null, null, null, null);

  var allRecipes = await testDatabase.getAllRecipeWithTags();
  var recipe_1 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #1").recipe;
  var recipe_2 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #2").recipe;
  var recipe_3 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #3").recipe;

  // assign tags to recipes
  var allTagGroupsWithTags = await testDatabase.getAllTagsWithGroups();
  var tagsRecipe_1 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[1,2,5,8,9]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_1.id, tagsRecipe_1);

  var tagsRecipe_2 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[2,3,4,5,7]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_2.id, tagsRecipe_2);

  var tagsRecipe_3 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[3,6]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_3.id, tagsRecipe_3);
}

_filteringRecipes(List<int> tagNumbers, List<int> expectedRecipeNumbers, Map<int, bool> matchRelationByTagGroupNumber) async {
  var allTags = (await testDatabase.getAllTagsWithGroups()).map((e) => e.tags).flattened;
  var selectedTags = tagNumbers.map((tagNumber) => allTags.firstWhere((tag) => tag.label.contains(tagNumber.toString()))).toList();

  var allRecipes = (await testDatabase.getAllRecipeWithTags()).map((e) => e.recipe).toList();
  var expectedRecipes = expectedRecipeNumbers.map((recipeNumber) => allRecipes.firstWhere((recipe) => recipe.name.contains(recipeNumber.toString()))).toList();
  var expectedRecipeIds = expectedRecipes.map((recipe) => recipe.id).toList();

  var allTagGroups = await testDatabase.tagGroupDao.getAllTagGroups();
  var matchRelationsByTagGroupId = Map.fromEntries(matchRelationByTagGroupNumber.entries.map((e) {
    var tagGroup = allTagGroups.firstWhere((tagGroup) => tagGroup.label.contains(e.key.toString()));
    return MapEntry(tagGroup.id, e.value);
  }));

  var recipeFilters = matchRelationsByTagGroupId.entries.map((e) {
    var tagGroupId = e.key;
    var tagGroupMatchRelation = e.value;
    var tags = selectedTags.where((tag) => tag.tagGroup == tagGroupId).map((tag) => tag.id).toList();
    return RecipeFilter(tagGroupId, tagGroupMatchRelation, tags);
  }).toList();

  // when
  var actual = await testDatabase.filterRecipes(recipeFilters);

  // then
  var selectedTagNames = selectedTags.map((tag) => tag.label).toList().join(",");
  var expectedRecipeNames = expectedRecipes.map((recipe) => recipe.name).toList().join(",");
  debugPrint('selected tagNames: $selectedTagNames, expected recipes: $expectedRecipeNames, tagGroupRelations: $matchRelationByTagGroupNumber');

  expect(actual.length, expectedRecipeIds.length);
  if (expectedRecipeIds.isNotEmpty) {
    expect(actual.map((e) => e.recipe.id), containsAllInOrder(expectedRecipeIds));
  }
}