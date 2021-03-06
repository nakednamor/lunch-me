import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:validators/validators.dart';

part 'recipe_dao.g.dart';

@DriftAccessor(tables: [Recipes], include: {'../queries.drift'})
class RecipeDao extends DatabaseAccessor<MyDatabase> with _$RecipeDaoMixin {
  RecipeDao(MyDatabase db) : super(db);

  Future<void> createRecipe(String name, Source type, String? url, String? imageUrl, String? photoContent, String? photoImage) async {
    await _validateRecipe(name, type);
    _validateRecipeFields(type, url, imageUrl, photoContent, photoImage);
    _validateUrls(url, imageUrl);

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

  Future<void> deleteRecipe(int recipeId) async {
    var recipe = await _getRecipeById(recipeId).getSingleOrNull();
    if (recipe == null) {
      throw RecipeNotFoundException(recipeId);
    }

    transaction(() async {
      await _deleteRecipeHasTagsByRecipeId(recipeId);
      await _deleteRecipeById(recipeId);
    });
  }

  Future<void> assignTags(int recipeId, List<int> tagIds) async {
    var recipe = await _getRecipeById(recipeId).getSingleOrNull();
    if (recipe == null) {
      throw RecipeNotFoundException(recipeId);
    }

    var allTagIds = (await _allTags().get()).map((e) => e.id);
    var notExistingTagIds = tagIds.where((tagId) => allTagIds.contains(tagId) == false);
    if (notExistingTagIds.isNotEmpty) {
      throw TagNotFoundException(notExistingTagIds.first);
    }

    await _deleteRecipeHasTagsByRecipeId(recipeId);

    var batches = tagIds.map((tagId) => RecipeTagsCompanion.insert(recipe: recipeId, tag: tagId));
    await batch((batch) => batch.insertAll(recipeTags, batches));
  }

  Future<void> _validateRecipe(String name, Source type) async {
    if (name.isEmpty) {
      throw EmptyNameException(name);
    }

    if (name.length > 50) {
      throw NameTooLongException(name);
    }

    var recipeCount = await _countRecipesWithNameAndType(name, type).getSingle();
    if (recipeCount != 0) {
      throw NameAlreadyExistsException(name);
    }
  }

  void _validateRecipeFields(Source type, String? url, String? imageUrl, String? photoContent, String? photoImage) {
    switch (type) {
      case Source.web:
      case Source.video:
        if (url == null) throw MissingValueException("url");
        break;
      case Source.photo:
        if (photoContent == null) throw MissingValueException("content photo");
        break;
      default:
        return;
    }
  }

  void _validateUrls(String? url, String? imageUrl) {
    if (url != null && !isURL(url, protocols: ["http", "https"], requireProtocol: true)) {
      throw InvalidUrlException(url);
    }

    if (imageUrl != null && !isURL(imageUrl, protocols: ["http", "https"], requireProtocol: true)) {
      throw InvalidUrlException(imageUrl);
    }
  }
}
