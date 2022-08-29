import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_manager.dart';
import 'package:lunch_me/model/recipe_model.dart';
import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../flutter_test_config.dart';

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
    recipeDao = testDatabase.recipeDao;
    photoDao = testDatabase.photoDao;
    tagDao = testDatabase.tagDao;
    tagGroupDao = testDatabase.tagGroupDao;
    uuid = const Uuid();
    photoManager = LunchMePhotoManager(ImagePicker());
    recipeManager = RecipeManager(recipeDao, photoDao, tagDao, tagGroupDao, uuid, photoManager);
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
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
    });

    test('should throw exception when new tag name > 50 chars', () async {
      // given
      var newTagName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.addTag(3, newTagName), throwsA(isA<NameTooLongException>()));
    });

    test('should throw exception when tag-group does not exit', () async {
      // expect
      expect(() => recipeManager.addTag(666, "some tag name"), throwsA(isA<TagException>()));
    });

    test('should throw exception when name already exists', () async {
      // given
      var tagGroupId = 3;
      var newTagName = 'a new tag';
      await recipeManager.addTag(tagGroupId, newTagName);

      // when
      expect(() => recipeManager.addTag(tagGroupId, newTagName), throwsA(isA<TagException>()));
    });
  });

  group('renaming tag ', () {
    test('should throw exception when name is empty', () async {
      // given
      var tag = await recipeManager.addTag(3, 'a tag');

      // expect
      expect(() => recipeManager.renameTag(tag.id, ''), throwsA(isA<EmptyNameException>()));
    });

    test('should throw exception when name > 50 chars', () async {
      // given
      var tag = await recipeManager.addTag(3, 'a tag');

      // expect
      expect(() => recipeManager.renameTag(tag.id, '012345678901234567890123456789012345678901234567890'), throwsA(isA<NameTooLongException>()));
    });

    test('throw exception when name already exists', () async {
      // given
      var tagToRename = await recipeManager.addTag(3, 'this should be renamed');
      var tagName = 'a different tag name';
      await recipeManager.addTag(3, tagName);

      // expect
      expect(() => recipeManager.renameTag(tagToRename.id, tagName), throwsA(isA<TagException>()));
    });
  });

  group('reordering tag ', (){
    test('should throw exception when there is no tag with given id', () async {
      // expect
      expect(() => recipeManager.changeTagOrdering(666, 5), throwsA(isA<TagException>()));
    });

    test('should throw exception when new position is negative', () async {
      // expect
      expect(() => recipeManager.changeTagOrdering(1, -1), throwsA(isA<TagException>()));
    });
  });

  group('adding tag-group ', (){
    test('should throw exception when new tag-group name is empty', () async {
      // given
      var newTagGroupName = '';

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<EmptyNameException>()));
    });

    test('should throw exception when new tag-group name > 50 chars', () async {
      // given
      var newTagGroupName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<NameTooLongException>()));
    });

    test('should throw exception when adding tag-group with already existing name', () async {
      // given
      var newTagGroupName = 'new tag-group name';
      await recipeManager.addTagGroup(newTagGroupName);

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<TagGroupException>()));
    });
  });

  group('renaming tag-group ', (){
    test('should throw exception when new tag-group name is empty', () async {
      // given
      var tagGroup = await recipeManager.addTagGroup('a tag-group');

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroup.id, ''), throwsA(isA<EmptyNameException>()));
    });

    test('should throw exception when new tag-group name > 50 chars', () async {
      // given
      var tagGroup = await recipeManager.addTagGroup('a tag-group');
      var newTagGroupName = '012345678901234567890123456789012345678901234567890';

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroup.id, newTagGroupName), throwsA(isA<NameTooLongException>()));
    });

    test('should throw exception when there is already tag-group with same name', () async {
      // given
      await recipeManager.addTagGroup('first tag-group');
      var tagGroup = await recipeManager.addTagGroup('second tag-group');

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroup.id, 'first tag-group'), throwsA(isA<TagGroupException>()));
    });

    group('reordering tag-group', (){
      test('should throw exception when new ordering value negative', () async {
        // expect
        expect(() => recipeManager.changeTagGroupOrdering(1, -1), throwsA(isA<TagGroupException>()));
      });
    });
  });
}
