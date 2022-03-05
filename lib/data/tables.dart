import 'package:drift/drift.dart';

class Languages extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get lang => text().withLength(min: 2, max: 3)();
}

class TagGroups extends Table {
  @override
  String get tableName => 'tag_groups';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get ordering => integer()();
}

class LocalizedTagGroups extends Table {
  @override
  String get tableName => 'localized_tag_groups';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tagGroup =>
      integer().references(TagGroups, #id, onDelete: KeyAction.cascade)();

  IntColumn get lang => integer().references(Languages, #id)();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tagGroup =>
      integer().references(TagGroups, #id, onDelete: KeyAction.cascade)();

  IntColumn get ordering => integer()();
}

class LocalizedTags extends Table {
  @override
  String get tableName => 'localized_tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tag =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  IntColumn get lang => integer().references(Languages, #id)();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  IntColumn get type => intEnum<Source>()();

  TextColumn get url => text().withLength(max: 255).nullable()();

  TextColumn get image => text().withLength(max: 255).nullable()();
}

enum Source { web, video, photo }

class RecipeTags extends Table {
  IntColumn get recipe =>
      integer().references(Recipes, #id, onDelete: KeyAction.cascade)();

  IntColumn get tag =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {recipe, tag};

  @override
  String get tableName => "recipe_has_tag";
}