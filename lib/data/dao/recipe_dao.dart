import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/tables.dart';

part 'recipe_dao.g.dart';

@DriftAccessor(tables: [Recipes], include: {'../queries.drift'})
class RecipeDao extends DatabaseAccessor<MyDatabase> with _$RecipeDaoMixin {
  RecipeDao(MyDatabase db) : super(db);

  Future<void> createRecipe(String name, Source type, String? url, String? imageUrl, String? photoContent, String? photoImage) async {
    late Insertable<Recipe> record;

    switch (type) {
      case Source.web:
      case Source.video:
        record = RecipesCompanion.insert(name: name, type: type, url: Value(url), image: Value(imageUrl));
        break;
      case Source.photo:
        record = RecipesCompanion.insert(name: name, type: type, contentPhoto: Value(photoContent), imagePhoto: Value(photoImage));
        break;
      case Source.memory:
        record = RecipesCompanion.insert(name: name, type: type, imagePhoto: Value(photoImage));
        break;
    }

    await recipes.insertOne(record);
  }
}
