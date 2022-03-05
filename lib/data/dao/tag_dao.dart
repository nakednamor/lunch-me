import 'package:lunch_me/data/database.dart';

import 'package:drift/drift.dart';
import 'package:lunch_me/data/tables.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags], include: {'../queries.drift'})
class TagDao extends DatabaseAccessor<MyDatabase> with _$TagDaoMixin {
  TagDao(MyDatabase db) : super(db);

  Future<List<Tag>> getAllTags() {
    return _allTags().get();
  }
}
