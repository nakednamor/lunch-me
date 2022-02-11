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
    expect(recipeWithTags.length, 8);
    expect(recipeWithTags[4].recipe.name, "Erdäpfel-Paprika Gulasch");

    var tags = recipeWithTags[4].tags.map((e) => e.id);
    expect(tags, containsAll([2, 3, 5, 7]));
  });

  test('should return tag-groups and tags ordered by order-column', () async {
    //when
    var actual = await testDatabase.getAllTagsWithGroups(const Locale("en"));

    // then tag-groups should be ordered
    var tagGroupIds = actual.map((e) => e.tagGroup.tagGroup);
    expect(tagGroupIds, containsAllInOrder([2, 1, 3]));

    // and tags within group 'Type' should be ordered
    var tagGroupTime =
        actual.firstWhere((tagGroup) => tagGroup.tagGroup.tagGroup == 2);
    var tagsOfTagGroupTime = tagGroupTime.tags.map((e) => e.tag);
    expect(tagsOfTagGroupTime, containsAllInOrder([5, 12, 13, 6, 7, 8, 9, 10]));
  });
}
