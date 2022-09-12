import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
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

    var newTagGroupId = await into(tagGroups).insert(TagGroupsCompanion.insert(ordering: newOrdering, label: name));

    var newTagGroup = await _getTagGroupById(newTagGroupId).getSingle();

    return newTagGroup;
  }

  Future<void> renameTagGroup(int tagGroupId, String newName) async {
    await _validateTagGroupName(newName);
    await _renameTagGroupLabel(newName, tagGroupId);
  }

  Future<void> deleteTagGroup(int tagGroupId) async {
    var deletedGroupCount = await _deleteTagGroupById(tagGroupId);
    if (deletedGroupCount != 1) {
      throw TagGroupNotFoundException(tagGroupId);
    }
  }

  Future<void> changeTagGroupOrdering(int tagGroupId, int newOrder) async {
    var target = await _getTagGroupById(tagGroupId).getSingleOrNull();
    if (target == null) {
      throw TagGroupNotFoundException(tagGroupId);
    }

    var currentOrdering = target.ordering;

    if (currentOrdering == newOrder) {
      return;
    }

    var lastOrdering = (await _getMaxTagGroupOrdering().getSingle()) ?? 0;
    await _updateOrderingOfTagGroup((lastOrdering + 1), target.id);

    if (currentOrdering < newOrder) {
      await _tagGroupRightPositionChange(currentOrdering, newOrder);
    } else {
      await _tagGroupLeftPositionChange_1(newOrder, currentOrdering);
      await _tagGroupLeftPositionChange_2();
    }

    await _updateOrderingOfTagGroup(newOrder, target.id);
  }

  Future<List<TagGroup>> getAllTagGroups() {
    return _allTagGroups().get();
  }

  Future<bool> tagGroupExists(int id) async {
    var tagGroup = await _getTagGroupById(id).getSingleOrNull();
    return tagGroup != null;
  }

  Future<void> _validateTagGroupName(String name) async {
    var groupCountWithSameName = await _countTagGroupsWithName(name);
    if (groupCountWithSameName != 0) {
      throw NameAlreadyExistsException(name);
    }
  }

  Future<int> _countTagGroupsWithName(String name) async {
    return _countTagGroupByLabel(name).getSingle();
  }
}
