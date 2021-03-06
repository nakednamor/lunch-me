import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';

import '../flutter_test_config.dart';

void main() {
  late TagGroupDao dao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.tagGroupDao;
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should throw exception when new tag-group name is empty', () async {
    // given
    var newTagGroupName = '';

    // expect
    expect(() => dao.addTagGroup(newTagGroupName), throwsA(isA<EmptyNameException>()));
  });

  test('should throw exception when new tag-group name > 50 chars', () async {
    // given
    var newTagGroupName = '012345678901234567890123456789012345678901234567890';

    // expect
    expect(() => dao.addTagGroup(newTagGroupName), throwsA(isA<NameTooLongException>()));
  });

  test('should add new tag-group with same value for all languages', () async {
    // given
    var englishLocale = const Locale("en");
    var germanLocale = const Locale("de");

    var tagGroupsBefore = await testDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsBefore.map((e) => e.tagGroup.label), containsAllInOrder(["B en", "A en", "C en"]));

    tagGroupsBefore = await testDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsBefore.map((e) => e.tagGroup.label), containsAllInOrder(["B de", "A de", "C de"]));

    //when
    await dao.addTagGroup("D en");

    // then
    var tagGroupsAfter = await testDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsAfter.map((e) => e.tagGroup.label), containsAllInOrder(["B en", "A en", "C en", "D en"]));

    tagGroupsAfter = await testDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsAfter.map((e) => e.tagGroup.label), containsAllInOrder(["B de", "A de", "C de", "D en"]));
  });

  test('should throw exception when adding tag-group with already existing name', () async {
    // given
    var newTagGroupName = 'new tag-group name';
    await dao.addTagGroup(newTagGroupName);

    // expect
    expect(() => dao.addTagGroup(newTagGroupName), throwsA(isA<NameAlreadyExistsException>()));
  });

  test('should rename tag-group', () async {
    // given
    var localeEnglish = const Locale("en");
    var localeGerman = const Locale("de");
    var tagGroupName = 'this should be renamed';
    var tagGroup = await dao.addTagGroup(tagGroupName);

    // when
    var newTagGroupName = 'updated name!';
    await testDatabase.tagGroupDao.renameTagGroup(tagGroup.id, newTagGroupName, localeEnglish);

    // then name from other locales should not be renamed
    var tagGroupsGerman = await testDatabase.getAllTagsWithGroups(localeGerman);
    expect(tagGroupsGerman.where((e) => e.tagGroup.tagGroup == tagGroup.id).map((e) => e.tagGroup.label).first, tagGroupName);

    // and name for english should be renamed
    var tagGroupsEnglish = await testDatabase.getAllTagsWithGroups(localeEnglish);
    expect(tagGroupsEnglish.where((e) => e.tagGroup.tagGroup == tagGroup.id).map((e) => e.tagGroup.label).first, newTagGroupName);
  });

  test('rename tag-group should throw exception when new tag-group name is empty', () async {
    // given
    var localeEnglish = const Locale("en");
    var tagGroup = await dao.addTagGroup('a tag-group');

    // expect
    expect(() => dao.renameTagGroup(tagGroup.id, '', localeEnglish), throwsA(isA<EmptyNameException>()));
  });

  test('rename tag-group should throw exception when new tag-group name > 50 chars', () async {
    // given
    var localeEnglish = const Locale("en");
    var tagGroup = await dao.addTagGroup('a tag-group');
    var newTagGroupName = '012345678901234567890123456789012345678901234567890';

    // expect
    expect(() => dao.renameTagGroup(tagGroup.id, newTagGroupName, localeEnglish), throwsA(isA<NameTooLongException>()));
  });

  test('rename tag-group should throw exception when there is already tag-group with same name', () async {
    // given
    var localeEnglish = const Locale("en");
    await dao.addTagGroup('first tag-group');
    var tagGroup = await dao.addTagGroup('second tag-group');

    // expect
    expect(() => dao.renameTagGroup(tagGroup.id, 'first tag-group', localeEnglish), throwsA(isA<NameAlreadyExistsException>()));
  });

  test('should throw exception when tag-group not found by id while changing tag-group ordering', () async {
    // expect
    expect(() => dao.changeTagGroupOrdering(999, 1), throwsA(isA<TagGroupNotFoundException>()));
  });

  test('should throw exception when new ordering value negative', () async {
    // expect
    expect(() => dao.changeTagGroupOrdering(1, -1), throwsA(isA<NegativeValueException>()));
  });

  test('should proper remove tag-groups', () async {
    // given
    var tagGroupIdToDelete = 2;
    var affectedTagIds = [1, 2];
    var affectedRecipeIds = [2, 3];

    var tagGroupsBefore = await dao.getAllTagGroups();
    expect(tagGroupsBefore.map((e) => e.id), contains(tagGroupIdToDelete));

    var tagsBefore = await testDatabase.tagDao.getAllTags();
    expect(tagsBefore.map((e) => e.id), containsAll(affectedTagIds));

    var recipesBefore = (await testDatabase.getAllRecipeWithTags()).where((element) => element.tags.any((tag) => affectedTagIds.contains(tag.id)));
    expect(recipesBefore.map((e) => e.recipe.id), containsAll(affectedRecipeIds));

    // when
    await dao.deleteTagGroup(tagGroupIdToDelete);

    // then
    var tagGroupsAfter = await dao.getAllTagGroups();
    expect(tagGroupsAfter.map((e) => e.id), isNot(contains(tagGroupIdToDelete)));

    var tagsAfter = await testDatabase.tagDao.getAllTags();
    expect(tagsAfter.map((e) => e.id), isNot(containsAll(affectedTagIds)));

    var recipesAfter = (await testDatabase.getAllRecipeWithTags()).where((element) => element.tags.any((tag) => affectedTagIds.contains(tag.id)));
    expect(recipesAfter.map((e) => e.recipe.id), isNot(containsAll(affectedRecipeIds)));
  });

  test('should proper remove empty tag-group', () async {
    // given
    var tagGroup = await dao.addTagGroup('tag-group to be deleted soon');
    var allTagGroups = await dao.getAllTagGroups();
    expect(allTagGroups.map((e) => e.id).contains(tagGroup.id), isTrue);

    // when
    await dao.deleteTagGroup(tagGroup.id);

    // then
    allTagGroups = await dao.getAllTagGroups();
    expect(allTagGroups.map((e) => e.id).contains(tagGroup.id), isFalse);
  });

  test('should throw exception when tag-group not found by id while deleting tag-group', () async {
    // expect
    expect(() => dao.deleteTagGroup(999), throwsA(isA<TagGroupNotFoundException>()));
  });

  test('tagGroupExists should return false', () async {
    // when
    var actual = await dao.tagGroupExists(666);

    // then
    expect(actual, isFalse);
  });

  test('tagGroupExists should return true', () async {
    // when
    var actual = await dao.tagGroupExists(2);

    // then
    expect(actual, isTrue);
  });

  Future<List<TagGroup>> addTagGroups(List<String> names) async {
    List<TagGroup> result = [];
    for (var name in names) {
      result.add(await dao.addTagGroup(name));
    }
    return result;
  }

  test('should allow changing order of tag-groups', () async {
    // given 7 tag-groups
    await addTagGroups(['a', 'b', 'c', 'd']);
    var initialTagGroups = await dao.getAllTagGroups();
    expect(initialTagGroups.map((e) => e.id), containsAllInOrder([2, 1, 3, 4, 5, 6, 7]));
    expect(initialTagGroups.map((e) => e.ordering), containsAllInOrder([0, 1, 2, 3, 4, 5, 6]));

    // when group #3 is moved to position with index 5
    await dao.changeTagGroupOrdering(initialTagGroups.elementAt(2).id, 5);

    // then
    var tagGroups = await dao.getAllTagGroups();
    expect(tagGroups.map((e) => e.id), containsAllInOrder([2, 1, 4, 5, 6, 3, 7]));
    expect(tagGroups.map((e) => e.ordering), containsAllInOrder([0, 1, 2, 3, 4, 5, 6]));

    // when group #6 is moved to position with index 1
    await dao.changeTagGroupOrdering(initialTagGroups.elementAt(5).id, 1);

    // then
    tagGroups = await dao.getAllTagGroups();
    expect(tagGroups.map((e) => e.id), containsAllInOrder([2, 6, 1, 4, 5, 3, 7]));
    expect(tagGroups.map((e) => e.ordering), containsAllInOrder([0, 1, 2, 3, 4, 5, 6]));
  });

  test('should keep same order when order position has not changed', () async {
    // given 7 tag-groups
    await addTagGroups(['a', 'b', 'c', 'd']);
    var initialTagGroups = await dao.getAllTagGroups();
    expect(initialTagGroups.map((e) => e.id), containsAllInOrder([2, 1, 3, 4, 5, 6, 7]));
    expect(initialTagGroups.map((e) => e.ordering), containsAllInOrder([0, 1, 2, 3, 4, 5, 6]));

    // when group #4 is moved to it's position (index 3)
    await dao.changeTagGroupOrdering(initialTagGroups.elementAt(3).id, 3);

    // then order should be the same
    var tagGroups = await dao.getAllTagGroups();
    expect(tagGroups.map((e) => e.id), containsAllInOrder([2, 1, 3, 4, 5, 6, 7]));
    expect(tagGroups.map((e) => e.ordering), containsAllInOrder([0, 1, 2, 3, 4, 5, 6]));
  });
}
