import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('should add new tag-group at last position', () async {
    // given
    var locale = const Locale("en");
    var tagGroupsBefore = await testDatabase.getAllTagsWithGroups(locale);
    expect(tagGroupsBefore.map((e) => e.tagGroup.label),
        containsAllInOrder(["B en", "A en", "C en"]));

    //when
    await testDatabase.addTagGroup("D en", locale);

    // then
    var tagGroupsAfter = await testDatabase.getAllTagsWithGroups(locale);
    expect(tagGroupsAfter.map((e) => e.tagGroup.label),
        containsAllInOrder(["B en", "A en", "C en", "D en"]));

    // and for different locale same localization should have been added
    var tagGroupsAfterDifferentLocale =
        await testDatabase.getAllTagsWithGroups(const Locale("de"));
    expect(tagGroupsAfterDifferentLocale.map((e) => e.tagGroup.label),
        containsAllInOrder(["B en", "A en", "C en", "D en"]));
  });
}
