import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
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
    expect(
        () => dao.addTag(3, newTagName), throwsA(isA<NameTooLongException>()));
  });

  test('should throw exception when tag-group not found by given id', () async {
    // expect
    expect(() => dao.addTag(666, "some tag name"),
        throwsA(isA<TagGroupNotFoundException>()));
  });

  test('should throw exception when adding tag with existing name', () async {
    // given
    var tagGroupId = 3;
    var newTagName = 'a new tag';
    await dao.addTag(tagGroupId, newTagName);

    var x = await dao.attachedDatabase.getAllTagsWithGroups(Locale("en"));

    // when
    expect(() => dao.addTag(tagGroupId, newTagName),
        throwsA(isA<NameAlreadyExistsException>()));
  });

  test('should add new tag at the last position within tag-group', () async {
    // given
    var tagGroupId = 3;
    var newTagName = 'new tag';
    var locale = const Locale("en");
    
    var tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups(locale);
    var lastTagOrderingBefore = tagGroupsWithTagsBefore.firstWhere((element) => element.tagGroup.tagGroup == tagGroupId).tags.length - 1;

    // when
    var actual = await dao.addTag(tagGroupId, newTagName);
    
    // then
    expect(actual.tagGroup, tagGroupId);
    expect(actual.ordering, lastTagOrderingBefore + 1);
  });
  
  test('should add new tag with same value for all languages', () async {
    // given
    var englishLocale = const Locale("en");
    var germanLocale = const Locale("de");
    
    var tagGroupId = 3;
    var newTagName = 'new tag';

    var tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsWithTagsBefore.where((tagGroup) => tagGroup.tags.any((tag) => tag.label == newTagName)).length, 0);

    tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsWithTagsBefore.where((tagGroup) => tagGroup.tags.any((tag) => tag.label == newTagName)).length, 0);

    // when
    var actual = await dao.addTag(tagGroupId, newTagName);

    // then
    tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsWithTagsBefore.where((tagGroup) => tagGroup.tags.any((tag) => tag.label == newTagName)).length, 1);

    tagGroupsWithTagsBefore = await dao.attachedDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsWithTagsBefore.where((tagGroup) => tagGroup.tags.any((tag) => tag.label == newTagName)).length, 1);
  });

  test('should allow tags with same name in different tag-groups', () async {
    // given
    var newTagName = 'new tag';
    var firstTag = await dao.addTag(1, newTagName);

    // expect no exception
    await dao.addTag(2, newTagName);
    await dao.addTag(3, newTagName);
  });

  test('should rename tag', () async {});
  test('rename tag should throw exception when name already exists', () async {});
  test('rename tag should throw exception when name is empty', () async {});
  test('rename tag should throw exception when name > 50 chars', () async {});

  test('should allow changing order of tag', () async {});
  test('reordering should throw exception when there is no tag with given id', () async {});
  test('reordering should throw exception when new position is negative', () async {});

  test('should remove tag properly', () async {});
  test('removing tag should throw exception when there is no tag with given id', () async {});



}
