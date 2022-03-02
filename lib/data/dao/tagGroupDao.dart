import 'dart:ui';

import 'package:lunch_me/data/database.dart';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/tables.dart';

import '../exceptions.dart';

part 'tagGroupDao.g.dart';

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
    return countTagGroupByLabel(name).getSingle();
  }
}
