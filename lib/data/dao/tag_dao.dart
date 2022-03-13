import 'package:lunch_me/data/database.dart';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/tables.dart';

import '../exceptions.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags], include: {'../queries.drift'})
class TagDao extends DatabaseAccessor<MyDatabase> with _$TagDaoMixin {
  TagDao(MyDatabase db) : super(db);

  Future<List<Tag>> getAllTags() {
    return _allTags().get();
  }

  Future<Tag> addTag(int tagGroupId, String name) async {
    await _validateNewTag(name);
    await _validateTagGroupExists(tagGroupId);
    await _validateTagNameDoesNotExist(tagGroupId, name);

    var lastOrdering = await _getMaxTagOrdering(tagGroupId).getSingleOrNull();
    var newOrdering = lastOrdering == null ? 0 : lastOrdering + 1;

    var newTagId = await into(tags).insert(
        TagsCompanion.insert(tagGroup: tagGroupId, ordering: newOrdering));

    var availableLanguages =
        await attachedDatabase.languageDao.getAllLanguages();
    var languageIds = availableLanguages.map((e) => e.id);

    var batches = languageIds.map((language) => LocalizedTagsCompanion.insert(
        tag: newTagId, lang: language, label: name));
    await batch((batch) => batch.insertAll(localizedTags, batches));

    return Tag(id: newTagId, tagGroup: tagGroupId, ordering: newOrdering);
  }

  Future<void> deleteTag(int id) async {
    var deleteCount = await _deleteTagById(id);
    if (deleteCount != 1) {
      throw TagNotFoundException(id);
    }
  }

  Future<void> _validateNewTag(String name) async {
    if (name.isEmpty) {
      throw EmptyNameException(name);
    }

    if (name.length > 50) {
      throw NameTooLongException(name);
    }
  }

  Future<void> _validateTagGroupExists(int tagGroup) async {
    var tagGroupExists =
        await attachedDatabase.tagGroupDao.tagGroupExists(tagGroup);
    if (!tagGroupExists) {
      throw TagGroupNotFoundException(tagGroup);
    }
  }

  Future<void> _validateTagNameDoesNotExist(int tagGroupId, String name) async {
    var tagCount = await _countByTagGroupAndName(tagGroupId, name).getSingle();
    if (tagCount != 0) {
      throw NameAlreadyExistsException(name);
    }
  }
}
