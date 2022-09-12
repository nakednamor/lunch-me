import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:uuid/uuid.dart';

import '../flutter_test_config.dart';

// TODO this should call real daos and test happy paths
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

  group('adding tag ', () {
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
    test('throw exception when name already exists', () async {
      // given
      var tagToRename = await recipeManager.addTag(3, 'this should be renamed');
      var tagName = 'a different tag name';
      await recipeManager.addTag(3, tagName);

      // expect
      expect(() => recipeManager.renameTag(tagToRename.id, tagName), throwsA(isA<TagException>()));
    });
  });

  group('reordering tag ', () {
    test('should throw exception when there is no tag with given id', () async {
      // expect
      expect(() => recipeManager.changeTagOrdering(666, 5), throwsA(isA<TagException>()));
    });
  });

  group('adding tag-group ', () {
    test('should throw exception when adding tag-group with already existing name', () async {
      // given
      var newTagGroupName = 'new tag-group name';
      await recipeManager.addTagGroup(newTagGroupName);

      // expect
      expect(() => recipeManager.addTagGroup(newTagGroupName), throwsA(isA<TagGroupException>()));
    });
  });

  group('renaming tag-group ', (){
    test('should throw exception when there is already tag-group with same name', () async {
      // given
      await recipeManager.addTagGroup('first tag-group');
      var tagGroup = await recipeManager.addTagGroup('second tag-group');

      // expect
      expect(() => recipeManager.renameTagGroup(tagGroup.id, 'first tag-group'), throwsA(isA<TagGroupException>()));
    });
  });
}
