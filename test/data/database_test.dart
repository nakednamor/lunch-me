import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
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
    expect(actualTagIds, containsAllInOrder(tagIds));
  });
}
