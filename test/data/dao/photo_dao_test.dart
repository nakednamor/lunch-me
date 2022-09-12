import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:uuid/uuid.dart';

import '../../flutter_test_config.dart';

void main() {
  late PhotoDao dao;
  late RecipeDao recipeDao;
  late Uuid uuid;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.photoDao;
    recipeDao = testDatabase.recipeDao;
    uuid = const Uuid();
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('saveContentPhoto should save photo', () async {
    // given
    var photoName = uuid.v4();
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;
    expect((await dao.getPhotoByUuid(photoName)), isNull);

    // when
    var actual = await dao.saveContentPhoto(photoName, recipeId);

    // then
    expect(actual, isNotNull);
    expect(actual.uuid, equals(photoName));
    expect(actual.id, isNotNull);
    expect(actual.contentPhoto, isTrue);
    expect(actual.ordering, equals(0));
    expect(actual.recipe, equals(recipeId));

    // and
    var actualFromDb = await dao.getPhotoByUuid(photoName);
    expect(actualFromDb, isNotNull);
    expect(actualFromDb?.id, equals(actual.id));
    expect(actualFromDb?.uuid, equals(photoName));
    expect(actualFromDb?.contentPhoto, isTrue);
    expect(actualFromDb?.ordering, equals(0));
    expect(actualFromDb?.recipe, equals(recipeId));
  });

  test('saveContentPhoto should throw exception when there is already a content photo for the given recipe', () async {
    // given
    var photoName = uuid.v4();
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;
    await dao.saveContentPhoto(photoName, recipeId);

    // expect
    expect(() => dao.saveContentPhoto(photoName, recipeId), throwsA(isA<RecipeAlreadyExistsException>()));
  });

  test('saveContentPhoto should throw exception when recipe does not exist', () async {
    // given
    var photoName = uuid.v4();
    var recipeId = -1;

    // expect
    expect(() => dao.saveContentPhoto(photoName, recipeId), throwsA(isA<RecipeNotFoundException>()));
  });

  test('saveContentPhoto should throw exception when name is no valid UUID', () async {
    // given
    var photoName = "this is not a valid UUID v4";
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;

    // expect
    expect(() => dao.saveContentPhoto(photoName, recipeId), throwsA(isA<NameNotUUIDException>()));
  });

  test('savePhoto should save regular photo', () async {
    // given
    var photoName = uuid.v4();
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;
    expect((await dao.getPhotoByUuid(photoName)), isNull);

    // when
    var actual = await dao.savePhoto(photoName, recipeId, 0);

    // then
    expect(actual, isNotNull);
    expect(actual.uuid, equals(photoName));
    expect(actual.id, isNotNull);
    expect(actual.contentPhoto, isFalse);
    expect(actual.ordering, equals(0));
    expect(actual.recipe, equals(recipeId));

    // and
    var actualFromDb = await dao.getPhotoByUuid(photoName);
    expect(actualFromDb, isNotNull);
    expect(actualFromDb?.id, equals(actual.id));
    expect(actualFromDb?.uuid, equals(photoName));
    expect(actualFromDb?.contentPhoto, isFalse);
    expect(actualFromDb?.ordering, equals(0));
    expect(actualFromDb?.recipe, equals(recipeId));
  });

  test('savePhoto should throw exception when recipe does not exist', () async {
    // given
    var photoName = uuid.v4();
    var recipeId = -1;

    // expect
    expect(() => dao.savePhoto(photoName, recipeId, 0), throwsA(isA<RecipeNotFoundException>()));
  });

  test('savePhoto should throw exception when name is no valid UUID', () async {
    // given
    var photoName = "this is not a valid UUID v4";
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;

    // expect
    expect(() => dao.savePhoto(photoName, recipeId, 0), throwsA(isA<NameNotUUIDException>()));
  });

  test('savePhoto should throw exception when combination of ordering,recipeId and contentPhoto already exists', () async {
    // given
    var ordering = 44;
    var recipeId = (await recipeDao.getAllRecipeWithTags()).first.recipe.id;
    await dao.savePhoto(uuid.v4(), recipeId, ordering);

    // expect
    expect(() => dao.savePhoto(uuid.v4(), recipeId, ordering), throwsA(isA<PhotoAlreadyExistsException>()));
  });
}
