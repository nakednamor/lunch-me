import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart' as tag_dao;
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/model/recipe_model.dart';
import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/dao/dao_mocks.dart';
import '../util/lunch_me_photo_manager_mock.dart';

void main() {
  late RecipeDao recipeDao;
  late PhotoDao photoDao;
  late TagDao tagDao;
  late TagGroupDao tagGroupDao;
  late RecipeManager recipeManager;
  late Uuid uuid;
  late LunchMePhotoManager photoManager;

  setUp(() async {
    debugPrint('test: setup started');
    recipeDao = RecipeDaoMock();
    photoDao = PhotoDaoMock();
    tagDao = TagDaoMock();
    tagGroupDao = TagGroupDaoMock();
    uuid = const Uuid();
    photoManager = LunchMePhotoManagerMock();
    recipeManager = RecipeManager(recipeDao, photoDao, tagDao, tagGroupDao, uuid, photoManager);
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  group('filterRecipes ', () {
    test('should just by-pass to recipe-dao', () async {
      // given
      List<RecipeFilter> filterList = [];
      List<RecipeWithTags> expected = [];

      when(recipeDao.filterRecipes(filterList)).thenAnswer((_) async => expected);

      // when
      var actual = await recipeManager.filterRecipes(filterList);

      // then
      expect(actual, same(expected));
      verify(recipeDao.filterRecipes(filterList)).called(1);
    });
  });

  group('watchAllTagsWithGroups ', () {
    test('should just by-pass to tagGroup-dao', () async {
      // given
      Stream<List<tag_dao.TagGroupWithTags>> expected = const Stream.empty();

      when(tagDao.watchAllTagsWithGroups()).thenAnswer((_) => expected);

      // when
      var actual = tagDao.watchAllTagsWithGroups();

      // then
      expect(actual, same(expected));
      verify(tagDao.watchAllTagsWithGroups()).called(1);
    });
  });

  group('deleteTagGroup ', () {
    test('should just by-pass to tagGroup-dao', () async {
      // given
      var tagGroupId = 32;
      when(tagGroupDao.deleteTagGroup(tagGroupId)).thenAnswer((_) async => {});

      // when
      await recipeManager.deleteTagGroup(tagGroupId);

      // then
      verify(tagGroupDao.deleteTagGroup(tagGroupId)).called(1);
    });

    test('should catch exceptions from tagGroupDao and throw TagGroupException', () async {
      // given
      var tagGroupId = 65;
      when(tagGroupDao.deleteTagGroup(tagGroupId)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.deleteTagGroup(tagGroupId), throwsA(isA<TagGroupException>()));
    });
  });

  group('deleteTag ', () {
    test('should just by-pass to tag-dao', () async {
      // given
      var tagId = 112;
      when(tagDao.deleteTag(tagId)).thenAnswer((_) async => {});

      // when
      await recipeManager.deleteTag(tagId);

      // then
      verify(tagDao.deleteTag(tagId)).called(1);
    });

    test('should catch exceptions from tagDao and throw TagException', () async {
      // given
      var tagId = 873;
      when(tagDao.deleteTag(tagId)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.deleteTag(tagId), throwsA(isA<TagException>()));
    });
  });

  group('createRecipe  for type "web"', () {
    var recipeType = Source.web;

    test('should create recipe of type with image url', () async {
      // given
      var tagGroups = await tagDao.getAllTagsWithGroups();
      var firstTagOfEachTagGroup = tagGroups.expand((tagGroup) => [tagGroup.tags.first]).toList();

      var model = RecipeModel.newRecipe("new recipe", recipeType);
      model.url = "https://some-url.com";
      model.thumbnailUrl = "https://some-image-url.com";
      model.tagIds = firstTagOfEachTagGroup.map((tag) => tag.id).toList();

      var recipesBefore = await recipeDao.getAllRecipeWithTags();

      // when
      await recipeManager.createRecipe(model);

      // then
      var recipesAfter = await recipeDao.getAllRecipeWithTags();
      expect(recipesAfter.length, recipesBefore.length + 1);

      var actualCreated = recipesAfter.where((e) => e.recipe.name == model.name && e.recipe.type == Source.web && e.recipe.url == model.url && e.recipe.image == model.thumbnailUrl).toList();
      expect(actualCreated.length, 1);

      expect(actualCreated.first.tags.map((t) => t.id), firstTagOfEachTagGroup.map((t) => t.id));
    }, skip: "re-write to use mocks and check only workflow");

    /*  TODO test this
    test('should create recipe of type with image photo', () async {
      // given
      fail("not yet implemented");
      // when

      // then
    });

     */
  });

  group('adding tag ', () {
    test('should throw exception when new tag name is empty', () async {
      // given
      var newTagName = '';

      // expect
      expect(() => recipeManager.addTag(3, newTagName), throwsA(isA<EmptyNameException>()));
      verifyZeroInteractions(tagDao);
    });

    test('should throw exception when new tag name > 50 chars', () async {
      // given
      var newTagName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.addTag(3, newTagName), throwsA(isA<NameTooLongException>()));
      verifyZeroInteractions(tagDao);
    });

    test('should by-pass to tag-dao', () async {
      // given
      var tagGroupId = 422;
      var newTagName = 'new tag name';
      var expected = Tag(id: 999, tagGroup: tagGroupId, ordering: 8, label: newTagName);

      when(tagDao.addTag(tagGroupId, newTagName)).thenAnswer((_) async => expected);

      // when
      var actual = await recipeManager.addTag(tagGroupId, newTagName);

      // then
      expect(actual, same(expected));
      verify(tagDao.addTag(tagGroupId, newTagName)).called(1);
    });

    test('should catch exceptions from tag-dao and throw TagException', () async {
      // given
      var tagGroupId = 422;
      var newTagName = 'new tag name';
      when(tagDao.addTag(tagGroupId, newTagName)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.addTag(tagGroupId, newTagName), throwsA(isA<TagException>()));
    });
  });

  group('renaming tag ', () {
    test('should throw exception when name is empty', () async {
      // expect
      expect(() => recipeManager.renameTag(432, ''), throwsA(isA<EmptyNameException>()));
      verifyZeroInteractions(tagDao);
    });

    test('should throw exception when name > 50 chars', () async {
      // expect
      expect(() => recipeManager.renameTag(432, '012345678901234567890123456789012345678901234567890'), throwsA(isA<NameTooLongException>()));
    });

    test('should by-pass to tag-dao', () async {
      // given
      var tagId = 422;
      var newTagName = 'new tag name';

      when(tagDao.renameTag(tagId, newTagName)).thenAnswer((_) async => {});

      // when
      await recipeManager.renameTag(tagId, newTagName);

      // then
      verify(tagDao.renameTag(tagId, newTagName)).called(1);
    });

    test('should catch exceptions from tag-dao and throw TagException', () async {
      // given
      var tagId = 422;
      var newTagName = 'new tag name';
      when(tagDao.renameTag(tagId, newTagName)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.renameTag(tagId, newTagName), throwsA(isA<TagException>()));
    });
  });

  group('reordering tag ', () {
    test('should throw exception when new position is negative', () async {
      // expect
      expect(() => recipeManager.changeTagOrdering(1, -1), throwsA(isA<TagException>()));
      verifyZeroInteractions(tagDao);
    });

    test('should by-pass to tag-dao', () async {
      // given
      var tagId = 422;
      var newOrdering = 93;

      when(tagDao.changeTagOrdering(tagId, newOrdering)).thenAnswer((_) async => {});

      // when
      await recipeManager.changeTagOrdering(tagId, newOrdering);

      // then
      verify(tagDao.changeTagOrdering(tagId, newOrdering)).called(1);
    });

    test('should catch exceptions from tag-dao and throw TagException', () async {
      // given
      var tagId = 422;
      var newOrdering = 93;
      when(tagDao.changeTagOrdering(tagId, newOrdering)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.changeTagOrdering(tagId, newOrdering), throwsA(isA<TagException>()));
    });
  });

  group('adding tag-group ', () {
    test('should throw exception when new tag-group name is empty', () async {
      // given
      var newTagGroupName = '';

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<EmptyNameException>()));
      verifyZeroInteractions(tagGroupDao);
    });

    test('should throw exception when new tag-group name > 50 chars', () async {
      // given
      var newTagGroupName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<NameTooLongException>()));
      verifyZeroInteractions(tagGroupDao);
    });

    test('should by-pass to tagGroup-dao', () async {
      // given
      var newName = 'new tagGroup name';
      var expected = TagGroup(id: 554, ordering: 8, label: newName);

      when(tagGroupDao.addTagGroup(newName)).thenAnswer((_) async => expected);

      // when
      var actual = await recipeManager.addTagGroup(newName);

      // then
      expect(actual, same(expected));
      verify(tagGroupDao.addTagGroup(newName)).called(1);
    });

    test('should catch exceptions from tagGroup-dao and throw TagException', () async {
      // given
      var newName = 'new tagGroup name';
      when(tagGroupDao.addTagGroup(newName)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.addTagGroup(newName), throwsA(isA<TagGroupException>()));
    });
  });

  group('renaming tag-group ', () {
    test('should throw exception when new tag-group name is empty', () async {
      // given
      var tagGroupId = 533;
      var newName = '';

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroupId, newName), throwsA(isA<EmptyNameException>()));
      verifyZeroInteractions(tagGroupDao);
    });

    test('should throw exception when new tag-group name > 50 chars', () async {
      // given
      var tagGroupId = 533;
      var newName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroupId, newName), throwsA(isA<NameTooLongException>()));
      verifyZeroInteractions(tagGroupDao);
    });

    test('should by-pass to tagGroup-dao', () async {
      // given
      var tagGroupId = 533;
      var newName = 'new tagGroup name';

      when(tagGroupDao.renameTagGroup(tagGroupId, newName)).thenAnswer((_) async => {});

      // when
      await recipeManager.renameTagGroup(tagGroupId, newName);

      // then
      verify(tagGroupDao.renameTagGroup(tagGroupId, newName)).called(1);
    });

    test('should catch exceptions from tagGroup-dao and throw TagException', () async {
      // given
      var tagGroupId = 533;
      var newName = 'new tagGroup name';

      when(tagGroupDao.renameTagGroup(tagGroupId, newName)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroupId, newName), throwsA(isA<TagGroupException>()));
    });
  });

  group('reordering tag-group', () {
    test('should throw exception when new ordering value negative', () async {
      // expect
      expect(() => recipeManager.changeTagGroupOrdering(1, -1), throwsA(isA<TagGroupException>()));
      verifyZeroInteractions(tagGroupDao);
    });

    test('should by-pass to tagGroup-dao', () async {
      // given
      var tagGroupId = 533;
      var newOrder = 24;

      when(tagGroupDao.changeTagGroupOrdering(tagGroupId, newOrder)).thenAnswer((_) async => {});

      // when
      await recipeManager.changeTagGroupOrdering(tagGroupId, newOrder);

      // then
      verify(tagGroupDao.changeTagGroupOrdering(tagGroupId, newOrder)).called(1);
    });

    test('should catch exceptions from tagGroup-dao and throw TagException', () async {
      // given
      var tagGroupId = 533;
      var newOrder = 24;

      when(tagGroupDao.changeTagGroupOrdering(tagGroupId, newOrder)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.changeTagGroupOrdering(tagGroupId, newOrder), throwsA(isA<TagGroupException>()));
    });
  });

  group('getRecipeModel', () {
    var uuid = const Uuid();

    test('should catch exceptions from recipe-dao and throw RecipeException', () async {
      // given
      var recipeId = 2232;
      when(recipeDao.getRecipeById(recipeId)).thenThrow(Exception('some exception from dao or DB'));

      // expect
      expect(() => recipeManager.getRecipeModel(recipeId), throwsA(isA<RecipeException>()));
    });

    // TODO add more tests for other types
    group('should return recipe-model of type web', () {
      test('with thumbnail photo', () async {
        // given
        var recipeTags = [
          Tag(id: 33, tagGroup: 1, ordering: 0, label: 'tag #1'),
          Tag(id: 34, tagGroup: 1, ordering: 1, label: 'tag #1'),
          Tag(id: 35, tagGroup: 2, ordering: 0, label: 'tag #1'),
        ];
        var recipe = Recipe(id: 432, name: 'recipe #1', type: Source.web, url: 'https://my-recipe.com');
        var expectedRecipeWithTags = RecipeWithTags(recipe, recipeTags, uuid.v4(), []);

        when(recipeDao.getRecipeById(recipe.id)).thenAnswer((_) async => expectedRecipeWithTags);

        var tempDirectory = await getTemporaryDirectory();
        var thumbnailFile = File(join(tempDirectory.path, expectedRecipeWithTags.thumbnail!));
        when(photoManager.getPhotoFile(expectedRecipeWithTags.thumbnail!)).thenAnswer((_) async => thumbnailFile);

        // when
        var actual = await recipeManager.getRecipeModel(recipe.id);

        // then
        expect(actual.id, expectedRecipeWithTags.recipe.id);
        expect(actual.name, expectedRecipeWithTags.recipe.name);
        expect(actual.type, expectedRecipeWithTags.recipe.type);
        expect(actual.url, expectedRecipeWithTags.recipe.url);
        expect(actual.thumbnailUrl, isNull);
        expect(actual.tagIds, containsAll(expectedRecipeWithTags.tags.map((e) => e.id).toList()));
        expect(actual.photos, isEmpty);
        expect(actual.thumbnailFile, isNotNull);
        expect(basename((actual.thumbnailFile!).path), expectedRecipeWithTags.thumbnail);
      });

      test('with thumbnail url', () async {
        // given
        var recipeTags = [
          Tag(id: 33, tagGroup: 1, ordering: 0, label: 'tag #1'),
          Tag(id: 34, tagGroup: 1, ordering: 1, label: 'tag #1'),
          Tag(id: 35, tagGroup: 2, ordering: 0, label: 'tag #1'),
        ];
        var recipe = Recipe(id: 432, name: 'recipe #1', type: Source.web, url: 'https://my-recipe.com', image: 'https://thumbnail-image.com');
        var expectedRecipeWithTags = RecipeWithTags(recipe, recipeTags, null, []);

        when(recipeDao.getRecipeById(recipe.id)).thenAnswer((_) async => expectedRecipeWithTags);

        // when
        var actual = await recipeManager.getRecipeModel(recipe.id);

        // then
        expect(actual.id, expectedRecipeWithTags.recipe.id);
        expect(actual.name, expectedRecipeWithTags.recipe.name);
        expect(actual.type, expectedRecipeWithTags.recipe.type);
        expect(actual.url, expectedRecipeWithTags.recipe.url);
        expect(actual.thumbnailUrl, expectedRecipeWithTags.recipe.image);
        expect(actual.thumbnailFile, isNull);
        expect(actual.tagIds, containsAll(expectedRecipeWithTags.tags.map((e) => e.id).toList()));
        expect(actual.photos, isEmpty);
      });
    });
  });
}
