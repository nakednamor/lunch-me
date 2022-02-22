import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/database.dart';

import 'flutter_test_config.dart';

const String testDatabasePath = 'test_resources/data/test_lunch_me_db';
const String testDatabaseTemporaryFileName = 'app.db';

void main() {
  setUp(() async {
    debugPrint('test: setup started');
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should return all languages', () async {
    // when
    var languages = await testDatabase.getAllLanguages();

    // then
    expect(languages.length, 2);
    expect(languages.map((e) => e.lang), containsAll(['de', 'en']));
  });

  test('should return all recipes', () async {
    // when
    var recipeWithTags = await testDatabase.getAllRecipeWithTags();

    // then
    expect(recipeWithTags.length, 3);
    expect(recipeWithTags.map((e) => e.recipe.name),
        containsAllInOrder(["recipe #1", "recipe #2", "recipe #3"]));

    expect(recipeWithTags[0].tags.map((e) => e.id), containsAll([2]));
    expect(recipeWithTags[1].tags.map((e) => e.id), containsAll([2, 4, 6]));
    expect(recipeWithTags[2].tags, isEmpty);
  });

  test('should return tag-groups and tags ordered by order-column', () async {
    //when
    var actual = await testDatabase.getAllTagsWithGroups(const Locale("en"));

    // then tag-groups should be ordered
    var tagGroupIds = actual.map((e) => e.tagGroup.tagGroup);
    expect(tagGroupIds, containsAllInOrder([2, 1, 3]));

    // and tags should be ordered as well
    expect(actual[0].tags.map((e) => e.id), containsAllInOrder([12, 11]));
    expect(actual[1].tags.map((e) => e.id), containsAllInOrder([7, 9, 8]));
    expect(actual[2].tags.map((e) => e.id), containsAllInOrder([10]));
  });

  test('should add new tag-group with same value for all languages', () async {
    // given
    var englishLocale = const Locale("en");
    var germanLocale = const Locale("de");

    var tagGroupsBefore =
        await testDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsBefore.map((e) => e.tagGroup.label),
        containsAllInOrder(["B en", "A en", "C en"]));

    tagGroupsBefore = await testDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsBefore.map((e) => e.tagGroup.label),
        containsAllInOrder(["B de", "A de", "C de"]));

    //when
    await testDatabase.addTagGroup("D en");

    // then
    var tagGroupsAfter = await testDatabase.getAllTagsWithGroups(englishLocale);
    expect(tagGroupsAfter.map((e) => e.tagGroup.label),
        containsAllInOrder(["B en", "A en", "C en", "D en"]));

    tagGroupsAfter = await testDatabase.getAllTagsWithGroups(germanLocale);
    expect(tagGroupsAfter.map((e) => e.tagGroup.label),
        containsAllInOrder(["B de", "A de", "C de", "D en"]));
  });

  test(
      'should throw exception when adding tag-group with already existing name',
      () async {
    // given
    var newTagGroupName = 'new tag-group name';
    await testDatabase.addTagGroup(newTagGroupName);

    // expect
    expect(() => testDatabase.addTagGroup(newTagGroupName),
        throwsA(isA<NameAlreadyExistsException>()));
  });

  test('should throw exception when new tag-group name is empty', () async {
    // given
    var newTagGroupName = '';

    // expect
    expect(() => testDatabase.addTagGroup(newTagGroupName),
        throwsA(isA<EmptyNameException>()));
  });

  test('should throw exception when new tag-group name > 50 chars', () async {
    // given
    var newTagGroupName = '012345678901234567890123456789012345678901234567890';

    // expect
    expect(() => testDatabase.addTagGroup(newTagGroupName),
        throwsA(isA<NameTooLongException>()));
  });

  test('should rename tag-group', () async {
    // given
    var localeEnglish = const Locale("en");
    var localeGerman = const Locale("de");
    var tagGroupName = 'this should be renamed';
    var tagGroup = await testDatabase.addTagGroup(tagGroupName);

    // when
    var newTagGroupName = 'updated name!';
    await testDatabase.renameTagGroup(
        tagGroup.id, newTagGroupName, localeEnglish);

    // then name from other locales should not be renamed
    var tagGroupsGerman = await testDatabase.getAllTagsWithGroups(localeGerman);
    expect(
        tagGroupsGerman
            .where((e) => e.tagGroup.tagGroup == tagGroup.id)
            .map((e) => e.tagGroup.label)
            .first,
        tagGroupName);

    // and name for english should be renamed
    var tagGroupsEnglish =
        await testDatabase.getAllTagsWithGroups(localeEnglish);
    expect(
        tagGroupsEnglish
            .where((e) => e.tagGroup.tagGroup == tagGroup.id)
            .map((e) => e.tagGroup.label)
            .first,
        newTagGroupName);
  });

  test(
      'rename tag-group should throw exception when new tag-group name is empty',
      () async {
    // given
    var localeEnglish = const Locale("en");
    var tagGroup = await testDatabase.addTagGroup('a tag-group');

    // expect
    expect(() => testDatabase.renameTagGroup(tagGroup.id, '', localeEnglish),
        throwsA(isA<EmptyNameException>()));
  });

  test(
      'rename tag-group should throw exception when new tag-group name > 50 chars',
      () async {
    // given
    var localeEnglish = const Locale("en");
    var tagGroup = await testDatabase.addTagGroup('a tag-group');
    var newTagGroupName = '012345678901234567890123456789012345678901234567890';

    // expect
    expect(
        () => testDatabase.renameTagGroup(
            tagGroup.id, newTagGroupName, localeEnglish),
        throwsA(isA<NameTooLongException>()));
  });

  test(
      'rename tag-group should throw exception when there is already tag-group with same name',
      () async {
    // given
    var localeEnglish = const Locale("en");
    await testDatabase.addTagGroup('first tag-group');
    var tagGroup = await testDatabase.addTagGroup('second tag-group');

    // expect
    expect(
        () => testDatabase.renameTagGroup(
            tagGroup.id, 'first tag-group', localeEnglish),
        throwsA(isA<NameAlreadyExistsException>()));
  });
}
