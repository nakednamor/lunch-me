import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags], include: {'../queries.drift'})
class TagDao extends DatabaseAccessor<MyDatabase> with _$TagDaoMixin {
  TagDao(MyDatabase db) : super(db);

  Future<List<Tag>> getAllTags() {
    return _allTags().get();
  }

  Future<List<TagGroupWithTags>> getAllTagsWithGroups() async {
    return _allTagGroupsWithTags().get();
  }

  Stream<List<TagGroupWithTags>> watchAllTagsWithGroups() {
    return _allTagGroupsWithTags().watch();
  }

  Future<Tag> addTag(int tagGroupId, String name) async {
    var lastOrdering = await _getMaxTagOrdering(tagGroupId).getSingleOrNull();
    var newOrdering = lastOrdering == null ? 0 : lastOrdering + 1;

    var newTagId = await into(tags).insert(TagsCompanion.insert(tagGroup: tagGroupId, ordering: newOrdering, label: name));

    return Tag(id: newTagId, tagGroup: tagGroupId, ordering: newOrdering, label: name);
  }

  Future<void> deleteTag(int id) async {
    var deleteCount = await _deleteTagById(id);
    if (deleteCount != 1) {
      throw TagNotFoundException(id);
    }
  }

  Future<void> renameTag(int id, String name) async {
    var tag = await _getTagById(id).getSingle();

    await _renameTag(name, tag.id);
  }

  Future<void> changeTagOrdering(int id, int newOrdering) async {
    var target = await _getTagById(id).getSingleOrNull();
    if (target == null) {
      throw TagNotFoundException(id);
    }

    var tagGroupId = target.tagGroup;
    var currentOrdering = target.ordering;

    if(currentOrdering == newOrdering){
      return;
    }

    var lastOrdering = (await _getMaxTagOrdering(tagGroupId).getSingleOrNull()) ?? 0;

    await _updateOrderingOfTag((lastOrdering + 1), target.id);

    if(currentOrdering < newOrdering) {
      await _tagRightPositionChange(currentOrdering, newOrdering);
    } else {
      await _tagLeftPositionChange_1(newOrdering, currentOrdering);
      await _tagLeftPositionChange_2();
    }

    await _updateOrderingOfTag(newOrdering, target.id);
  }
}
