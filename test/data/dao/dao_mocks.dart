import 'package:lunch_me/data/dao/photo_dao.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/dao/tag_dao.dart' as tag_dao;
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:mockito/mockito.dart';

class TagDaoMock extends Mock implements tag_dao.TagDao {
  @override
  Future<Tag> addTag(int? tagGroupId, String? name) =>
      super.noSuchMethod(Invocation.method(#addTag, [tagGroupId, name]), returnValue: Future.value(Tag(id: 999, tagGroup: 422, ordering: 8, label: 'new tag name')));

  @override
  Future<void> renameTag(int? id, String? name) => super.noSuchMethod(Invocation.method(#renameTag, [id, name]), returnValue: Future.value());

  @override
  Future<void> changeTagOrdering(int? id, int? newOrdering) => super.noSuchMethod(Invocation.method(#changeTagOrdering, [id, newOrdering]), returnValue: Future.value());

  @override
  Stream<List<tag_dao.TagGroupWithTags>> watchAllTagsWithGroups() => super.noSuchMethod(Invocation.method(#watchAllTagsWithGroups, []), returnValue: const Stream<List<tag_dao.TagGroupWithTags>>.empty());
}

class RecipeDaoMock extends Mock implements RecipeDao {
  @override
  Future<List<RecipeWithTags>> filterRecipes(List<RecipeFilter>? filterList) => super.noSuchMethod(Invocation.method(#filterRecipes, [filterList]), returnValue: Future.value(<RecipeWithTags>[]));
}

class TagGroupDaoMock extends Mock implements TagGroupDao {
  @override
  Future<TagGroup> addTagGroup(String? name) => super.noSuchMethod(Invocation.method(#addTagGroup, [name]), returnValue: Future.value(TagGroup(id: 554, ordering: 8, label: 'new tagGroup name')));

  @override
  Future<void> renameTagGroup(int? tagGroupId, String? newName) => super.noSuchMethod(Invocation.method(#renameTagGroup, [tagGroupId, newName]), returnValue: Future.value());

  @override
  Future<void> changeTagGroupOrdering(int? id, int? newOrder) => super.noSuchMethod(Invocation.method(#changeTagGroupOrdering, [id, newOrder]), returnValue: Future.value());

  @override
  Future<void> deleteTagGroup(int? tagGroupId) => super.noSuchMethod(Invocation.method(#deleteTagGroup, [tagGroupId]), returnValue: Future.value());
}

class PhotoDaoMock extends Mock implements PhotoDao {}
