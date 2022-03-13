import 'dart:ui';

import 'package:lunch_me/data/database.dart';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/tables.dart';

import '../exceptions.dart';

part 'taggroup_dao.g.dart';

@DriftAccessor(tables: [TagGroups], include: {'../queries.drift'})
class TagGroupDao extends DatabaseAccessor<MyDatabase> with _$TagGroupDaoMixin {
  TagGroupDao(MyDatabase db) : super(db);

  Future<TagGroup> addTagGroup(String name) async {
    await _validateTagGroupName(name);

    var lastOrdering = await _getMaxTagGroupOrdering().getSingleOrNull();

    var newOrdering = lastOrdering == null ? 0 : lastOrdering + 1;

    var newTagGroupId = await into(tagGroups)
        .insert(TagGroupsCompanion.insert(ordering: newOrdering));

    var newTagGroup = await _getTagGroupById(newTagGroupId).getSingle();

    var availableLanguages = await attachedDatabase.languageDao.getAllLanguages();
    var languageIds = availableLanguages.map((e) => e.id);

    var batches = languageIds.map((language) =>
        LocalizedTagGroupsCompanion.insert(
            tagGroup: newTagGroup.id, lang: language, label: name));

    await batch((batch) => batch.insertAll(localizedTagGroups, batches));

    return newTagGroup;
  }

  Future<void> renameTagGroup(
      int tagGroupId, String newName, Locale locale) async {
    await _validateTagGroupName(newName);
    var language = await attachedDatabase.languageDao.getLanguage(locale);
    await _renameTagGroupLabel(newName, tagGroupId, language.id);
  }

  Future<void> deleteTagGroup(int tagGroupId) async {
    var deletedGroupCount = await _deleteTagGroupById(tagGroupId);
    if(deletedGroupCount != 1) {
      throw TagGroupNotFoundException(tagGroupId);
    }
  }

  Future<void> changeTagGroupOrdering(int tagGroupId, int newOrder) async {
    if (newOrder < 0) {
      throw NegativeValueException(newOrder);
    }

    var target = await _getTagGroupById(tagGroupId).getSingleOrNull();
    if(target == null) {
      throw TagGroupNotFoundException(tagGroupId);
    }

    var otherTarget = await _getTagGroupByOrdering(newOrder).getSingle();  // TODO potential bug if newOrder > max(ordering)

    var currentOrdering = target.ordering;

    var lastOrdering = (await _getMaxTagGroupOrdering().getSingle()) ?? 0;

    await _updateOrderingOfTagGroup( (lastOrdering + 1), otherTarget.id);
    await _updateOrderingOfTagGroup( newOrder, target.id);
    await _updateOrderingOfTagGroup( currentOrdering, otherTarget.id);
  }

  Future<List<TagGroup>> getAllTagGroups() {
    return _allTagGroups().get();
  }

  Future<bool> tagGroupExists(int id) async {
    var tagGroup = await _getTagGroupById(id).getSingleOrNull();
    return tagGroup != null;
  }

  Future<void> _validateTagGroupName(String name) async {
    if (name.isEmpty) {
      throw EmptyNameException(name);
    }

    if (name.length > 50) {
      throw NameTooLongException(name);
    }

    var groupCountWithSameName = await _countTagGroupsWithName(name);
    if (groupCountWithSameName != 0) {
      throw NameAlreadyExistsException(name);
    }
  }

  Future<int> _countTagGroupsWithName(String name) async {
    return _countTagGroupByLabel(name).getSingle();
  }
}
