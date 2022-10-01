import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:random_string/random_string.dart';

import '../../flutter_test_config.dart';

void main() {
  late RecipeDao dao;
  late TagDao tagDao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.recipeDao;
    tagDao = testDatabase.tagDao;
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  void _testRecipeCreation(String name, Source type, String? url, String? imageUrl, String? photoContent, String? photoImage) {
    test(name, () async {
      // given
      var recipesBefore = await dao.getAllRecipeWithTags();

      // when
      await dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage);

      // then
      var recipesAfter = await dao.getAllRecipeWithTags();
      expect(recipesAfter.length, recipesBefore.length + 1);

      var actualCreated = recipesAfter.where((e) => e.recipe.name == name && e.recipe.type == type && e.recipe.url == url && e.recipe.image == imageUrl && e.tags.isEmpty).toList();
      expect(actualCreated.length, 1);
    });
  }

  void _testRecipeCreationWithSameNameDifferentType(Source type) async {
    test(type, () async {
      // given recipes with same name but different types
      var name = "some recipe name";
      var url = "http://some.url";
      var imageUrl = "http://some.image";
      var photoContent = "some content photo";
      var photoImage = "some image photo";
      var differentTypes = Source.values.where((element) => element != type).toList();
      for (var type in differentTypes) {
        await dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage);
      }

      // when
      await dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage);

      // then
      var actualRecipes = await dao.getAllRecipeWithTags();
      var actualCreated = actualRecipes.where((e) => e.recipe.name == name && e.recipe.type == type).toList();
      expect(actualCreated.length, 1);
    });
  }

  void _testRecipeCreationWithSameNameSameType(Source type) async {
    test(type, () async {
      // given recipes with same name and same type
      var name = "some recipe name";
      var url = "http://some.url";
      var imageUrl = "http://some.image";
      var photoContent = "some content photo";
      var photoImage = "some image photo";
      await dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage);

      // expect
      expect(() => dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage), throwsA(isA<NameAlreadyExistsException>()));
    });
  }

  group("should insert recipe", () {
    _testRecipeCreation("new web", Source.web, "http://web.test", "http://web.image", null, null);
    _testRecipeCreation("new web without image", Source.web, "http://web.test", null, null, null);
    _testRecipeCreation("new video", Source.video, "http://video.test", "http://video.image", null, null);
    _testRecipeCreation("new video without image", Source.video, "http://video.test", null, null, null);
    _testRecipeCreation("new photo", Source.photo, null, null, "content photo", "content image");
    _testRecipeCreation("new photo without image", Source.photo, null, null, "content photo", null);
    _testRecipeCreation("new memory", Source.memory, null, null, null, "memory image");
    _testRecipeCreation("new memory without image", Source.memory, null, null, null, null);
  });

  group("should throw exception when new name and type already exists", () {
    for (var type in Source.values) {
      _testRecipeCreationWithSameNameSameType(type);
    }
  });

  group("should insert recipe with existing name but different type", () {
    for (var type in Source.values) {
      _testRecipeCreationWithSameNameDifferentType(type);
    }
  });

  group("should throw exception when inserting recipe without url", () {
    for (var type in [Source.web, Source.video]) {
      test("type: $type", () async {
        // expect
        expect(() => dao.createRecipe("some name", type, null, null, null, null), throwsA(isA<MissingValueException>()));
      });
    }
  });

  group("should throw exception when inserting recipe with empty name", () {
    for (var type in Source.values) {
      test("type: $type", () async {
        // expect
        expect(() => dao.createRecipe("", type, null, null, null, null), throwsA(isA<EmptyNameException>()));
      });
    }
  });

  group("should throw exception when inserting recipe with name longer than 50 characters", () {
    var tooLongName = randomString(51);
    for (var type in Source.values) {
      test("type: $type", () async {
        // expect
        expect(() => dao.createRecipe(tooLongName, type, null, null, null, null), throwsA(isA<NameTooLongException>()));
      });
    }
  });

  test("should throw exception when inserting recipe with type photo but no content photo", () {
    // expect
    expect(() => dao.createRecipe("some name", Source.photo, null, null, null, null), throwsA(isA<MissingValueException>()));
  });

  group("should throw exception when inserting recipe with non valid URL", () {
    var nonValidUrls = ["not a url at all", "ftp://wrong.protocol.com", "//no.protocol.com"];
    var types = [Source.web, Source.video];
    for (var invalidUrl in nonValidUrls) {
      for (var type in types) {
        test("type: $type, field: url, value: '$invalidUrl'", () async {
          expect(() => dao.createRecipe("recipe name", type, invalidUrl, null, null, null), throwsA(isA<InvalidUrlException>()));
        });
      }
    }

    for (var invalidUrl in nonValidUrls) {
      for (var type in types) {
        test("type: $type, field: image, value: '$invalidUrl'", () async {
          expect(() => dao.createRecipe("recipe name", type, "http://valid.url.com", invalidUrl, null, null), throwsA(isA<InvalidUrlException>()));
        });
      }
    }
  });

  test("should throw exception when deleting recipe by not existing ID", () async {
    // expect
    expect(() => dao.deleteRecipe(666), throwsA(isA<RecipeNotFoundException>()));
  });

  Future<Recipe> _createRecipe(String name) async {
    await dao.createRecipe(name, Source.memory, null, null, null, null);

    var recipesAfter = await dao.getAllRecipeWithTags();
    var actualCreated = recipesAfter.where((e) => e.recipe.name == name && e.recipe.type == Source.memory).toList();
    expect(actualCreated.length, 1);

    return actualCreated.first.recipe;
  }

  test("should delete recipe properly", () async {
    // given recipe with tags
    var tags = await tagDao.getAllTags();
    var tagIds = [tags.first.id, tags.last.id];
    var recipe = await _createRecipe("my new recipe");
    await dao.assignTags(recipe.id, tagIds);

    var allRecipes = await dao.getAllRecipeWithTags();
    allRecipes.firstWhere((element) => element.recipe.id == recipe.id);

    // when
    await dao.deleteRecipe(recipe.id);

    // then
    allRecipes = await dao.getAllRecipeWithTags();
    expect(allRecipes.firstWhereOrNull((element) => element.recipe.id == recipe.id), null);
  });

  test("should throw exception when assigning tags to non existing recipe", () async {
    // given
    var tags = await tagDao.getAllTags();
    var tagIds = [tags.first.id, tags.last.id];

    // expect
    expect(() => dao.assignTags(666, tagIds), throwsA(isA<RecipeNotFoundException>()));
  });

  test("should throw exception when assigning non existing tag to recipe", () async {
    // given
    var tags = await tagDao.getAllTags();
    var tagIds = [tags.first.id, tags.last.id, 666];
    var recipe = await _createRecipe("my new recipe");

    // expect
    expect(() => dao.assignTags(recipe.id, tagIds), throwsA(isA<TagNotFoundException>()));
  });

  test("should assign tags to recipe properly", () async {
    //given recipe without tags
    var tags = await tagDao.getAllTags();
    var tagIds = [tags.first.id, tags.last.id];
    var recipe = await _createRecipe("my new recipe");

    // when tags are assigned
    await dao.assignTags(recipe.id, tagIds);

    // then recipe should have only the specified tags
    var allRecipes = await dao.getAllRecipeWithTags();
    var actualRecipe = allRecipes.firstWhere((element) => element.recipe.id == recipe.id);
    expect(actualRecipe.tags.length, tagIds.length);
    expect(actualRecipe.tags.map((e) => e.id), containsAll(tagIds));

    // when different tags are assigned to recipe
    var differentTagIds = [tagIds.first, tags[1].id, tags[2].id];
    await dao.assignTags(recipe.id, differentTagIds);

    // then recipe should have only tags from last assignment
    allRecipes = await dao.getAllRecipeWithTags();
    actualRecipe = allRecipes.firstWhere((element) => element.recipe.id == recipe.id);
    expect(actualRecipe.tags.length, differentTagIds.length);
    expect(actualRecipe.tags.map((e) => e.id), containsAll(differentTagIds));
  });

  test('should return all recipes', () async {
    // when
    var recipeWithTags = await dao.getAllRecipeWithTags();

    // then
    expect(recipeWithTags.length, 3);
    expect(recipeWithTags.map((e) => e.recipe.name), containsAllInOrder(["recipe #1", "recipe #2", "recipe #3"]));

    expect(recipeWithTags[0].tags.map((e) => e.id), containsAll([2]));
    expect(recipeWithTags[1].tags.map((e) => e.id), containsAll([2, 4, 6]));
    expect(recipeWithTags[2].tags, isEmpty);
  });

  test('filter recipes should return all recipes when no tag is selected', () async {
    // when
    var recipeWithTags = await dao.filterRecipes([]);

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

  group("get recipe by id", () {
    test('should throw NegativeValueException when ID negative', () async {
      // expect
      expect(() => dao.getRecipeById(-1), throwsA(isA<NegativeValueException>()));
    });

    test('should throw RecipeNotFoundException when recipe not found', () async {
      // expect
      expect(() => dao.getRecipeById(9876788788), throwsA(isA<RecipeNotFoundException>()));
    });

    test('should return recipe', () async {
      // given
      var allRecipes = await dao.getAllRecipeWithTags();
      var recipeForTest = allRecipes.last;

      // when
      var actual = await dao.getRecipeById(recipeForTest.recipe.id);

      // then
      expect(actual.recipe.id, recipeForTest.recipe.id);
      expect(actual.tags.length, recipeForTest.tags.length);
      expect(actual.thumbnail, recipeForTest.thumbnail);
      expect(actual.images.length, recipeForTest.images.length);
    });
  });
}

_clearDatabase() async {
  var allRecipes = await testDatabase.recipeDao.getAllRecipeWithTags();
  var allTagGroups = await testDatabase.tagDao.getAllTagsWithGroups();

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

  var allRecipes = await testDatabase.recipeDao.getAllRecipeWithTags();
  var recipe_1 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #1").recipe;
  var recipe_2 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #2").recipe;
  var recipe_3 = allRecipes.firstWhere((element) => element.recipe.name == "recipe #3").recipe;

  // assign tags to recipes
  var allTagGroupsWithTags = await testDatabase.tagDao.getAllTagsWithGroups();
  var tagsRecipe_1 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[1,2,5,8,9]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_1.id, tagsRecipe_1);

  var tagsRecipe_2 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[2,3,4,5,7]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_2.id, tagsRecipe_2);

  var tagsRecipe_3 = allTagGroupsWithTags.map((e) => e.tags).flattened.where((tag) => tag.label.contains(RegExp("[3,6]\$"))).map((tag) => tag.id).toList();
  await testDatabase.recipeDao.assignTags(recipe_3.id, tagsRecipe_3);
}

_filteringRecipes(List<int> tagNumbers, List<int> expectedRecipeNumbers, Map<int, bool> matchRelationByTagGroupNumber) async {
  var allTags = (await testDatabase.tagDao.getAllTagsWithGroups()).map((e) => e.tags).flattened;
  var selectedTags = tagNumbers.map((tagNumber) => allTags.firstWhere((tag) => tag.label.contains(tagNumber.toString()))).toList();

  var allRecipes = (await testDatabase.recipeDao.getAllRecipeWithTags()).map((e) => e.recipe).toList();
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
  var actual = await testDatabase.recipeDao.filterRecipes(recipeFilters);

  // then
  var selectedTagNames = selectedTags.map((tag) => tag.label).toList().join(",");
  var expectedRecipeNames = expectedRecipes.map((recipe) => recipe.name).toList().join(",");
  debugPrint('selected tagNames: $selectedTagNames, expected recipes: $expectedRecipeNames, tagGroupRelations: $matchRelationByTagGroupNumber');

  expect(actual.length, expectedRecipeIds.length);
  if (expectedRecipeIds.isNotEmpty) {
    expect(actual.map((e) => e.recipe.id), containsAllInOrder(expectedRecipeIds));
  }
}
