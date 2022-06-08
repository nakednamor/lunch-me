import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/tables.dart';

import '../flutter_test_config.dart';

void main() {
  late RecipeDao dao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.recipeDao;
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

  group("should throw exception when new name and type already exists", () {});

  group("should insert recipe with existing name but different type", () {
    for (var type in Source.values) {
      _testRecipeCreationWithSameNameDifferentType(type);
    }
  });
}
