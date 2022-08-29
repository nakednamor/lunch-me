import 'dart:async';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:validators/validators.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [Photo], include: {'../queries.drift'})
class PhotoDao extends DatabaseAccessor<MyDatabase> with _$PhotoDaoMixin {
  PhotoDao(MyDatabase db) : super(db);

  Future<PhotoData> saveContentPhoto(String name, int recipeId) async {
    _validatePhotoName(name);
    await _validateRecipeExists(recipeId);

    var existingContentPhotoCount = await _countPhotoByRecipeIdAndContentPhoto(recipeId, true).getSingle();
    if (existingContentPhotoCount != 0) {
      throw RecipeAlreadyExistsException(recipeId);
    }

    var newPhotoId = await into(photo).insert(PhotoCompanion.insert(uuid: name, ordering: 0, contentPhoto: true, recipe: recipeId));
    return PhotoData(id: newPhotoId, contentPhoto: true, uuid: name, ordering: 0, recipe: recipeId);
  }

  Future<PhotoData?> getPhotoByUuid(String name) async {
    return await _getPhotoByUuid(name).getSingleOrNull();
  }

  Future<PhotoData> savePhoto(String name, int recipeId, int ordering) async {
    _validatePhotoName(name);
    await _validateRecipeExists(recipeId);

    var existingPhotoCount = await _countPhotoByRecipeIdAndContentPhotoAndOrdering(recipeId, false, ordering).getSingle();
    if (existingPhotoCount != 0) {
      throw PhotoAlreadyExistsException();
    }

    var newPhotoId = await into(photo).insert(PhotoCompanion.insert(uuid: name, ordering: ordering, contentPhoto: false, recipe: recipeId));
    return PhotoData(id: newPhotoId, uuid: name, ordering: 0, contentPhoto: false, recipe: recipeId);
  }

  _validatePhotoName(String name) {
    if (!isUUID(name)) {
      throw NameNotUUIDException(name);
    }
  }

  _validateRecipeExists(int recipeId) async {
    var recipeCount = await _countRecipeById(recipeId).getSingle();
    if (recipeCount != 1) {
      throw RecipeNotFoundException(recipeId);
    }
  }
}
