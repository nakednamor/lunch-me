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
    var languages = await testDatabase.getAllLanguages();
    expect(languages.length, 2);
    expect(languages.map((e) => e.lang), containsAll(['de', 'en']));
  });

  test('should return all recipes', () async {
    var recipeWithTags = await testDatabase.getAllRecipeWithTags();
    expect(recipeWithTags.length, 8);

    expect(recipeWithTags[4].recipe.name, "Erdäpfel-Paprika Gulasch");

    var tags = recipeWithTags[4].tags.map((e) => e.id);
    expect(tags, containsAll([2, 3, 5, 7]));
  });
}
