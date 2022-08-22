import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/tables.dart';

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
    var actual = await testDatabase.getAllTagsWithGroups(const Locale("en"));

    // then tag-groups should be ordered
    var tagGroupIds = actual.map((e) => e.tagGroup.tagGroup);
    expect(tagGroupIds, containsAllInOrder([2, 1, 3]));

    // and tags should be ordered as well
    expect(actual[0].tags.map((e) => e.id), containsAllInOrder([12, 11]));
    expect(actual[1].tags.map((e) => e.id), containsAllInOrder([7, 9, 8]));
    expect(actual[2].tags.map((e) => e.id), containsAllInOrder([10]));
  });

  test('filter recipes by tags should return empty list', () async {
    // when
    var actual = await testDatabase.filterRecipeByTags([1]);

    // then
    expect(actual.length, 0);
  });

  test('should filter recipes by tags', () async {
    await _filteringRecipes([4], [2], {2: [2,4,6]});
    await _filteringRecipes([2], [2,3], {2: [2,4,6], 3: [2]});
    await _filteringRecipes([6], [2], {2: [2,4,6]});
    await _filteringRecipes([6,2], [2,3], {2: [2,4,6], 3: [2]});
    await _filteringRecipes([], [3,2,1], {1: [], 2: [2,4,6], 3: [2]});
  });

  test('should filter recipes by tags XXXXXXXXXXXXX', () async {
    await _clearDatabase();
    await _prepareDatabaseForFiltering();

//    await _filteringRecipesXXX([1,2], [1,2], {1: [1,2,5,8,9], 2: [2,3,4,5,7]});
 //   await _filteringRecipesXXX([2,3], [1,2,3], {1: [1,2,5,8,9], 2: [2,3,4,5,7], 3: [3,6]});
    await _filteringRecipesXXX([2,5], [1,2], {1: [1,2,5,8,9], 2: [2,3,4,5,7]});
    await _filteringRecipesXXX([1,2,4], [2], {2: [2,3,4,5,7]});
    await _filteringRecipesXXX([2,3,5,6], [1,3], {1: [1,2,5,8,9], 3: [3,6]});
    await _filteringRecipesXXX([], [1,2,3], {1: [1,2,5,8,9], 2: [2,3,4,5,7], 3: [3,6]});
  });
}

_clearDatabase() async {
  var allRecipes = await testDatabase.getAllRecipeWithTags();
  var allTagGroups = await testDatabase.getAllTagsWithGroups(const Locale("en"));

  // remove all recipes
  for (var recipe in allRecipes) {
    await testDatabase.recipeDao.deleteRecipe(recipe.recipe.id);
  }

  // delete all tags
  var tagIds = allTagGroups.map((e) => e.tags).flattened.map((e) => e.tag);
  for (var tagId in tagIds) {
    await testDatabase.tagDao.deleteTag(tagId);
  }

  // delete tag groups
  var tagGroupIds = allTagGroups.map((e) => e.tagGroup.tagGroup);
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

  // create 3 recipes
  await testDatabase.recipeDao.createRecipe("recipe #1", Source.memory, null, null, null, null);
  await testDatabase.recipeDao.createRecipe("recipe #2", Source.memory, null, null, null, null);
  await testDatabase.recipeDao.createRecipe("recipe #3", Source.memory, null, null, null, null);

  var allRecipes = await testDatabase.getAllRecipeWithTags();
  var recipe_1 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #1").recipe;
  var recipe_2 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #2").recipe;
  var recipe_3 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #3").recipe;

  // assign tags to recipes
  var allTagGroupsWithTags = await testDatabase.getAllTagsWithGroups(const Locale("en"));
  var tagsRecipe_1 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[1,2,5,8,9]"))).map((tag) => tag.tag).toList();
  await testDatabase.recipeDao.assignTags(recipe_1.id, tagsRecipe_1);

  var tagsRecipe_2 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[2,3,4,5,7]"))).map((tag) => tag.tag).toList();
  await testDatabase.recipeDao.assignTags(recipe_2.id, tagsRecipe_2);

  var tagsRecipe_3 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[3,6]"))).map((tag) => tag.tag).toList();
  await testDatabase.recipeDao.assignTags(recipe_3.id, tagsRecipe_3);


  var xxx = await testDatabase.getAllRecipeWithTags();
  var a = 2;
}

_filteringRecipes(List<int> tagIds, List<int> expectedRecipeIds,
    Map<int, List<int>> expectedTagIdsByRecipeId) async {
  // when
  var actual = await testDatabase.filterRecipeByTags(tagIds);

  // then
  expect(actual.length, expectedRecipeIds.length);
  expect(
      actual.map((e) => e.recipe.id), containsAllInOrder(expectedRecipeIds));

  expectedTagIdsByRecipeId.forEach((recipeId, tagIds) {
    var actualRecipe =
    actual.firstWhere((element) => element.recipe.id == recipeId);
    var actualTagIds = actualRecipe.tags.map((e) => e.id);
    expect(actualTagIds.length, tagIds.length);
    if (tagIds.isNotEmpty) {
      expect(actualTagIds, containsAllInOrder(tagIds));
    }
  });
}

_filteringRecipesXXX(List<int> tagNumbers, List<int> expectedRecipeNumbers, Map<int, List<int>> expectedTagNumbersByRecipeNumbers) async {
  print("XXXXXXXXXXXXXX" +tagNumbers.join(",")+ "XXXXXXXXXXXXX" + expectedRecipeNumbers.join(","));
  var allTags = (await testDatabase.getAllTagsWithGroups(const Locale("en"))).map((e) => e.tags).flattened;
  var tagIds = tagNumbers.map((tagNumber) => allTags.firstWhere((tag) => tag.label.contains(tagNumber.toString()))).map((e) => e.tag).toList();

  var allRecipes = (await testDatabase.getAllRecipeWithTags()).map((e) => e.recipe).toList();
  var expectedRecipeIds = expectedRecipeNumbers.map((recipeNumber) => allRecipes.firstWhere((recipe) => recipe.name.contains(recipeNumber.toString()))).map((recipe) => recipe.id).toList();

  // when
  var actual = await testDatabase.filterRecipeByTagsXXX(tagIds);

  // then
  expect(actual.length, expectedRecipeIds.length);
  expect(
      actual.map((e) => e.recipe.id), containsAllInOrder(expectedRecipeIds));

  expectedTagNumbersByRecipeNumbers.forEach((recipeNumber, tagNumbers) {
    var actualRecipe =    actual.firstWhere((element) => element.recipe.name.contains(recipeNumber.toString()));
    var actualTagIds = actualRecipe.tags.map((e) => e.id);
    var tagIds  = tagNumbers.map((tagNumber) => allTags.firstWhere((tag) => tag.label.contains(tagNumber.toString()))).map((e) => e.tag).toList();

    expect(actualTagIds.length, tagIds.length);
    if (tagIds.isNotEmpty) {
      expect(actualTagIds, containsAllInOrder(tagIds));
    }
  });
}