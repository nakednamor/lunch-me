import 'package:drift/drift.dart';

class TagGroups extends Table {
  @override
  String get tableName => 'tag_groups';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get ordering => integer()();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Tags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get tagGroup =>
      integer().references(TagGroups, #id, onDelete: KeyAction.cascade)();

  IntColumn get ordering => integer()();

  TextColumn get label => text().withLength(min: 1, max: 50)();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  IntColumn get type => intEnum<Source>()();

  TextColumn get url => text().withLength(max: 255).nullable()();

  TextColumn get image => text().withLength(max: 255).nullable()();

  TextColumn get imagePhoto => text().withLength(max: 50).nullable()();

  TextColumn get contentPhoto => text().withLength(max: 50).nullable()();
}

enum Source { web, video, photo, memory }

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