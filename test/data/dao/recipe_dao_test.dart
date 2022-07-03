import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:random_string/random_string.dart';

import '../flutter_test_config.dart';

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
      var recipesBefore = await testDatabase.getAllRecipeWithTags();

      // when
      await dao.createRecipe(name, type, url, imageUrl, photoContent, photoImage);

      // then
      var recipesAfter = await testDatabase.getAllRecipeWithTags();
      expect(recipesAfter.length, recipesBefore.length + 1);

      var actualCreated = recipesAfter
          .where((e) =>
              e.recipe.name == name &&
              e.recipe.type == type &&
              e.recipe.url == url &&
              e.recipe.image == imageUrl &&
              e.recipe.contentPhoto == photoContent &&
              e.recipe.imagePhoto == photoImage &&
              e.tags.isEmpty)
          .toList();
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
      var actualRecipes = await testDatabase.getAllRecipeWithTags();
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

    var recipesAfter = await testDatabase.getAllRecipeWithTags();
    var actualCreated = recipesAfter.where((e) => e.recipe.name == name && e.recipe.type == Source.memory).toList();
    expect(actualCreated.length, 1);

    return actualCreated.first.recipe;
  }

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
    var allRecipes = await testDatabase.getAllRecipeWithTags();
    var actualRecipe = allRecipes.firstWhere((element) => element.recipe.id == recipe.id);
    expect(actualRecipe.tags.length, tagIds.length);
    expect(actualRecipe.tags.map((e) => e.id), containsAll(tagIds));

    // when different tags are assigned to recipe
    var differentTagIds = [tagIds.first, tags[1].id, tags[2].id];
    await dao.assignTags(recipe.id, differentTagIds);

    // then recipe should have only tags from last assignment
    allRecipes = await testDatabase.getAllRecipeWithTags();
    actualRecipe = allRecipes.firstWhere((element) => element.recipe.id == recipe.id);
    expect(actualRecipe.tags.length, differentTagIds.length);
    expect(actualRecipe.tags.map((e) => e.id), containsAll(differentTagIds));
  });
}
