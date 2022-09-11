import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/model/recipe_manager.dart';
import 'package:lunch_me/model/recipe_model.dart';
import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import '../data/dao/dao_mocks.dart';

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
    photoManager = LunchMePhotoManager(ImagePicker());
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

  group('createRecipe  for type "web"', () {
    var recipeType = Source.web;

    test('should create recipe of type with image url', () async {
      // given
      var tagGroups = await tagDao.getAllTagsWithGroups();
      var firstTagOfEachTagGroup = tagGroups.expand((tagGroup) => [tagGroup.tags.first]).toList();

      var model = RecipeModel("new recipe", recipeType);
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
    });

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
}
