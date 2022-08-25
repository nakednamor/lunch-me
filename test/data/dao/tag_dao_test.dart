import "package:collection/collection.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';

import '../flutter_test_config.dart';

void main() {
  late TagDao dao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.tagDao;
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should throw exception when new tag name is empty', () async {
    // given
    var newTagName = '';

    // expect
    expect(() => dao.addTag(3, newTagName), throwsA(isA<EmptyNameException>()));
  });

  test('should throw exception when new tag name > 50 chars', () async {
    // given
    var newTagName = '012345678901234567890123456789012345678901234567890';

    // expect
    expect(() => dao.addTag(3, newTagName), throwsA(isA<NameTooLongException>()));
  });

  test('should throw exception when tag-group not found by given id', () async {
    // expect
    expect(() => dao.addTag(666, "some tag name"), throwsA(isA<TagGroupNotFoundException>()));
  });

  test('should throw exception when adding tag with existing name', () async {
    // given
    var tagGroupId = 3;
    var newTagName = 'a new tag';
    await dao.addTag(tagGroupId, newTagName);

    await dao.attachedDatabase.getAllTagsWithGroups();

    // when
    expect(() => dao.addTag(tagGroupId, newTagName), throwsA(isA<NameAlreadyExistsException>()));
  });

  test('should add new tag at the last position within tag-group', () async {
    // given
    var tagGroupId = 3;
    var newTagName = 'new tag';

    var tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups();
    var lastTagOrderingBefore = tagGroupsWithTagsBefore.firstWhere((element) => element.tagGroup.id == tagGroupId).tags.length - 1;

    // when
    var actual = await dao.addTag(tagGroupId, newTagName);

    // then
    expect(actual.tagGroup, tagGroupId);
    expect(actual.ordering, lastTagOrderingBefore + 1);
  });

  test('should allow tags with same name in different tag-groups', () async {
    // given
    var newTagName = 'new tag';
    await dao.addTag(1, newTagName);

    // expect no exception
    await dao.addTag(2, newTagName);
    await dao.addTag(3, newTagName);
  });

  test('rename tag should throw exception when name already exists', () async {
    // given
    var tagToRename = await dao.addTag(3, 'this should be renamed');
    var tagName = 'a different tag name';
    await dao.addTag(3, tagName);

    // expect
    expect(() => dao.renameTag(tagToRename.id, tagName), throwsA(isA<NameAlreadyExistsException>()));
  });

  test('rename tag should throw exception when name is empty', () async {
    // given
    var tag = await dao.addTag(3, 'a tag');

    // expect
    expect(() => dao.renameTag(tag.id, ''), throwsA(isA<EmptyNameException>()));
  });

  test('rename tag should throw exception when name > 50 chars', () async {
    // given
    var tag = await dao.addTag(3, 'a tag');

    // expect
    expect(() => dao.renameTag(tag.id, '012345678901234567890123456789012345678901234567890'), throwsA(isA<NameTooLongException>()));
  });

  test('should rename tag', () async {
    // given
    var tagGroupId = 3;
    var previousTagName = 'previous name';
    var tag = await dao.addTag(tagGroupId, previousTagName);

    // when
    var newTagName = 'this is new';
    await dao.renameTag(tag.id, newTagName);

    // then
    var tagGroupsWithTags = await dao.attachedDatabase.getAllTagsWithGroups();
    var renamedTag = tagGroupsWithTags.firstWhere((tagGroup) => tagGroup.tagGroup.id == tagGroupId).tags.firstWhere((t) => t.id == tag.id);
    expect(renamedTag.label, newTagName);
  });

  test('reordering should throw exception when there is no tag with given id', () async {
    // expect
    expect(() => dao.changeTagOrdering(666, 5), throwsA(isA<TagNotFoundException>()));
  });

  test('reordering should throw exception when new position is negative', () async {
    // given
    var tag = await dao.addTag(2, 'some tag');

    // expect
    expect(() => dao.changeTagOrdering(tag.id, -1), throwsA(isA<NegativeValueException>()));
  });

  test('should remove tag properly', () async {
    // given
    var tagToDelete = await dao.addTag(2, 'new tag');
    var allTagIds = (await dao.getAllTags()).map((e) => e.id);
    expect(allTagIds, contains(tagToDelete.id));

    // when
    dao.deleteTag(tagToDelete.id);

    // then
    allTagIds = (await dao.getAllTags()).map((e) => e.id);
    expect(allTagIds.contains(tagToDelete.id), isFalse);

    var tagGroupsWithTags = await dao.attachedDatabase.getAllTagsWithGroups();
    var localizedTags = tagGroupsWithTags.where((tagGroup) => tagGroup.tags.map((tag) => tag.id).contains(tagToDelete.id)).length;
    expect(localizedTags, 0);

    tagGroupsWithTags = await dao.attachedDatabase.getAllTagsWithGroups();
    localizedTags = tagGroupsWithTags.where((tagGroup) => tagGroup.tags.map((tag) => tag.id).contains(tagToDelete.id)).length;
    expect(localizedTags, 0);
  });

  test('removing tag should throw exception when there is no tag with given id', () async {
    // expect
    expect(() => dao.deleteTag(666), throwsA(isA<TagNotFoundException>()));
  });

  Future<List<Tag>> addTags(int tagGroupId, List<String> names) async {
    List<Tag> result = [];
    for (var name in names) {
      result.add(await dao.addTag(tagGroupId, name));
    }
    return result;
  }

  test('should allow changing order of tag', () async {
    // given
    var tagGroupId = 1;
    await addTags(1, ["A", "B", "C", "D"]);

    var tags = (await dao.getAllTags()).groupListsBy((element) => element.tagGroup)[tagGroupId] ?? (throw Exception("no tags with group $tagGroupId"));
    expect(tags.map((e) => e.id), containsAllInOrder([3, 5, 4, 7, 8, 9, 10]));

    // when tag #4 is moved to position with index 5
    await dao.changeTagOrdering(4, 5);

    // then
    tags = (await dao.getAllTags()).groupListsBy((element) => element.tagGroup)[tagGroupId] ?? (throw Exception("no tags with group $tagGroupId"));
    expect(tags.map((e) => e.id), containsAllInOrder([3, 5, 7, 8, 9, 4, 10]));

    // when tag #9 is moved to position wit index 0
    await dao.changeTagOrdering(9, 0);

    // then
    tags = (await dao.getAllTags()).groupListsBy((element) => element.tagGroup)[tagGroupId] ?? (throw Exception("no tags with group $tagGroupId"));
    expect(tags.map((e) => e.id), containsAllInOrder([9, 3, 5, 7, 8, 4, 10]));
  });

  test('should keep same order when order position has not changed', () async {
    var tagGroupId = 1;
    await addTags(1, ["A", "B", "C", "D"]);

    var tags = (await dao.getAllTags()).groupListsBy((element) => element.tagGroup)[tagGroupId] ?? (throw Exception("no tags with group $tagGroupId"));
    expect(tags.map((e) => e.id), containsAllInOrder([3, 5, 4, 7, 8, 9, 10]));

    // when tag #5 is moved to it's position (index 1)
    await dao.changeTagOrdering(5, 1);

    // then order should be the same
    tags = (await dao.getAllTags()).groupListsBy((element) => element.tagGroup)[tagGroupId] ?? (throw Exception("no tags with group $tagGroupId"));
    expect(tags.map((e) => e.id), containsAllInOrder([3, 5, 4, 7, 8, 9, 10]));
  });
}
