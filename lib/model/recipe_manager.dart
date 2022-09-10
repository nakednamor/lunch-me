import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:lunch_me/data/dao/tag_dao.dart' as tag_dao; // TODO is this needed ??
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/model/recipe_model.dart';
import 'package:uuid/uuid.dart';

import '../data/dao/photo_dao.dart';
import '../data/dao/recipe_dao.dart';
import '../util/lunch_me_photo_manager.dart';

class RecipeManager {
  late RecipeDao recipeDao;
  late PhotoDao photoDao;
  late tag_dao.TagDao tagDao;
  late TagGroupDao tagGroupDao;
  late Uuid uuid;
  late LunchMePhotoManager photoManager;

  static final RecipeManager _instance = RecipeManager._internal();

  factory RecipeManager(RecipeDao recipeDao, PhotoDao photoDao, tag_dao.TagDao tagDao, TagGroupDao tagGroupDao, Uuid uuid, LunchMePhotoManager photoManager) {
    _instance.recipeDao = recipeDao;
    _instance.photoDao = photoDao;
    _instance.tagDao = tagDao;
    _instance.tagGroupDao = tagGroupDao;
    _instance.uuid = uuid;
    _instance.photoManager = photoManager;

    return _instance;
  }

  RecipeManager._internal();

  Future<void> createRecipe(RecipeModel recipeModel) async {
    switch (recipeModel.type) {
      case Source.web:
        // TODO validate if all fields of model are proper
        await _saveWebRecipe(recipeModel.name, recipeModel.url!, recipeModel.thumbnailUrl, recipeModel.thumbnailFile, recipeModel.tagIds);
        break;
      case Source.memory:
      case Source.video:
      case Source.photo:
        throw ("not yet supported");
    }
  }

  // TODO test that method is just passing by
  Future<List<RecipeWithTags>> filterRecipes(List<RecipeFilter> filterList) async {
    return recipeDao.filterRecipes(filterList);
  }

  // TODO test that method is just passing by
  Stream<List<tag_dao.TagGroupWithTags>> watchAllTagsWithGroups() {
    return tagDao.watchAllTagsWithGroups();
  }

  // TODO test that method is just passing by
  Future<void> deleteTagGroup(int tagGroupId) async {
    return tagGroupDao.deleteTagGroup(tagGroupId);
  }

  // TODO test that method is just passing by
  Future<void> deleteTag(int id) async {
    return tagDao.deleteTag(id);
  }

  // TODO test that method is just passing by
  Future<Tag> addTag(int tagGroupId, String name) async {
    _validateNameLength(name, 50);
    try {
      return await tagDao.addTag(tagGroupId, name);
    } on Exception catch (e) {
      throw TagException('cannot add tag: $e');
    }
  }

  // TODO test that method is just passing by
  Future<TagGroup> addTagGroup(String name) async {
    _validateNameLength(name, 50);
    try {
      return await tagGroupDao.addTagGroup(name);
    } on Exception catch (e) {
      throw TagGroupException('cannot add tag-group: $e');
    }
  }

  // TODO test that method is just passing by
  Future<void> renameTag(int id, String name) async {
    _validateNameLength(name, 50);
    try {
      return await tagDao.renameTag(id, name);
    } on Exception catch (e) {
      throw TagException('cannot rename tag: $e');
    }
  }

  // TODO test that method is just passing by
  Future<void> changeTagOrdering(int id, int newOrdering) async {
    if (newOrdering < 0) {
      throw TagException("newOrdering is negative");
    }

    try {
      return await tagDao.changeTagOrdering(id, newOrdering);
    } on Exception catch (e) {
      throw TagException('cannot change tag order: $e');
    }
  }
  // TODO test that method is just passing by
  Future<void> renameTagGroup(int tagGroupId, String newName) async {
    _validateNameLength(newName, 50);
    try {
      return await tagGroupDao.renameTagGroup(tagGroupId, newName);
    } on Exception catch (e) {
      throw TagGroupException('cannot add tag-group: $e');
    }
  }
  // TODO test that method is just passing by
  Future<void> changeTagGroupOrdering(int tagGroupId, int newOrder) async {
    if (newOrder < 0) {
      throw TagGroupException("newOrdering is negative");
    }
    return await tagGroupDao.changeTagGroupOrdering(tagGroupId, newOrder);
  }

  Future<void> _saveWebRecipe(String name, String url, String? thumbnailUrl, File? thumbnailFile, List<int> tagIds) async {
    int recipeId = await recipeDao.createWebRecipe(name, url, thumbnailUrl);

    if (tagIds.isNotEmpty) {
      await recipeDao.assignTags(recipeId, tagIds);
    }

    if (thumbnailFile != null) {
      var fileName = uuid.v4();
      var newFile = await photoManager.savePhotoToImageDirectory(thumbnailFile, fileName);
      debugPrint('saved image: ${newFile.path}');
      await thumbnailFile.delete();
      await photoDao.saveContentPhoto(fileName, recipeId);
      debugPrint('saved photo to db');
    }
  }

  _validateNameLength(String name, int maxLength) {
    if (name.isEmpty) {
      throw EmptyNameException(name);
    }

    if (name.length > maxLength) {
      throw NameTooLongException(name);
    }
  }
}
