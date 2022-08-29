import "package:collection/collection.dart";
import 'package:drift/drift.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/exceptions.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:validators/validators.dart';

import '../../model/recipe_filters.dart';

part 'recipe_dao.g.dart';

@DriftAccessor(tables: [Recipes], include: {'../queries.drift'})
class RecipeDao extends DatabaseAccessor<MyDatabase> with _$RecipeDaoMixin {
  RecipeDao(MyDatabase db) : super(db);

  // TODO test this
  Future<int> createWebRecipe(String name, String url, String? imageUrl) async {
    await _validateRecipe(name, Source.web);
    _validateUrls(url, imageUrl);
    Insertable<Recipe> record = RecipesCompanion.insert(name: name, type: Source.web, url: Value(url), image: Value(imageUrl));
    return recipes.insertOne(record);
  }

  // TODO change this !!
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
        // record = RecipesCompanion.insert(name: name, type: type, contentPhoto: Value(photoContent), imagePhoto: Value(photoImage));
        record = RecipesCompanion.insert(name: name, type: type, url: Value(url), image: Value(imageUrl));
        break;
      case Source.memory:
        // record = RecipesCompanion.insert(name: name, type: type, imagePhoto: Value(photoImage));
        record = RecipesCompanion.insert(name: name, type: type, url: Value(url), image: Value(imageUrl));
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

  Future<List<RecipeWithTags>> getAllRecipeWithTags() async {
    var query = select(recipes).join([
      leftOuterJoin(recipeTags, recipeTags.recipe.equalsExp(recipes.id)),
      leftOuterJoin(tags, tags.id.equalsExp(recipeTags.tag)),
    ])
      ..orderBy([OrderingTerm(expression: recipes.name)]);

    var queryResult = query.map((row) {
      var recipe = row.readTable(recipes);
      var tag = row.readTableOrNull(tags);

      return _RecipeWithTag(recipe, tag);
    });

    var tagsGroupedByRecipe = (await queryResult.get()).groupListsBy((element) => element.recipe);

    var recipeIds = tagsGroupedByRecipe.keys.map((recipe) => recipe.id).toList();
    var imagesByRecipeId = await _getImagesByRecipeId(recipeIds);
    var emptyRecipeImage = _RecipeImages(null, []);

    return tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.map((e) => e.tag).whereType<Tag>().toList();
      var photo = imagesByRecipeId[recipe.id] ?? emptyRecipeImage;
      return RecipeWithTags(recipe, tags, photo.thumbnail, photo.images);
    }).toList();
  }

  Future<List<RecipeWithTags>> filterRecipes(List<RecipeFilter> filterList) async {
    var selectedTagIds = filterList.map((filter) => filter.tags).flattened.toList();
    if (filterList.isEmpty || selectedTagIds.isEmpty) {
      return getAllRecipeWithTags();
    }

    var recipeIds = await _getRecipeIds(filterList);

    var query = select(recipes).join([
      leftOuterJoin(recipeTags, recipeTags.recipe.equalsExp(recipes.id)),
      leftOuterJoin(tags, tags.id.equalsExp(recipeTags.tag)),
    ])
      ..where(recipes.id.isIn(recipeIds))
      ..orderBy([OrderingTerm(expression: recipes.name)]);

    var queryResult = query.map((row) {
      var recipe = row.readTable(recipes);
      var tag = row.readTableOrNull(tags);

      return _RecipeWithTag(recipe, tag);
    });

    var tagsGroupedByRecipe = (await queryResult.get()).groupListsBy((element) => element.recipe);
    var imagesByRecipeId = await _getImagesByRecipeId(recipeIds);
    var emptyRecipeImage = _RecipeImages(null, []);

    var result = tagsGroupedByRecipe.entries.map((entry) {
      var recipe = entry.key;
      var tags = entry.value.map((e) => e.tag).whereType<Tag>().toList();
      var photo = imagesByRecipeId[recipe.id] ?? emptyRecipeImage;
      return RecipeWithTags(recipe, tags, photo.thumbnail, photo.images);
    }).toList();

    _sortRecipesByMatchingTagsAndName(result, selectedTagIds);

    return result;
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

  Future<Map<int, _RecipeImages>> _getImagesByRecipeId(List<int> recipeIds) async {
    var photos = await _getPhotosByRecipeId(recipeIds).get();

    Map<int, _RecipeImages> result = {};
    for (var photo in photos) {
      var resultEntry = result[photo.recipe] ?? _RecipeImages(null, []);
      if (photo.contentPhoto == true) {
        resultEntry.thumbnail = photo.uuid;
      } else {
        resultEntry.images.add(photo.uuid);
      }
      result[photo.recipe] = resultEntry;
    }

    return result;
  }

  void _sortRecipesByMatchingTagsAndName(List<RecipeWithTags> recipes, List<int> selectedTagIds) {
    recipes.sort((a, b) {
      var matchingTagsA = a.tags.where((tag) => selectedTagIds.contains(tag.id)).length;
      var matchingTagsB = b.tags.where((tag) => selectedTagIds.contains(tag.id)).length;

      if (matchingTagsA > matchingTagsB) {
        return -1;
      } else if (matchingTagsA < matchingTagsB) {
        return 1;
      } else {
        return a.recipe.name.compareTo(b.recipe.name);
      }
    });
  }

  Future<List<int>> _getRecipeIds(List<RecipeFilter> filterList) async {
    var futures = filterList.where((filter) => filter.tags.isNotEmpty).map((filter) async {
      List<int> result;
      if (filter.allMatch) {
        result = await _getRecipeIdsHavingAllTags(filter);
      } else {
        result = await _getRecipeIdsHavingTags(filter.tags);
      }

      return result;
    }).toList();

    var recipeIdsOfGroups = await Future.wait(futures);
    var recipeIds = recipeIdsOfGroups.map((e) => e.toSet()).reduce((a, b) => a.intersection(b)).toList();

    return recipeIds;
  }

  Future<List<int>> _getRecipeIdsHavingTags(List<int> tagIds) async {
    var query = select(recipeTags)..where((tbl) => tbl.tag.isIn(tagIds));
    return query.map((row) => row.recipe).get();
  }

  Future<List<int>> _getRecipeIdsHavingAllTags(RecipeFilter filter) async {
    var tagString = filter.tags.join(",");
    var tagCount = filter.tags.length;
    var result = await customSelect('SELECT recipe FROM recipe_has_tag WHERE tag IN ($tagString) GROUP BY recipe HAVING COUNT(*) = $tagCount;', readsFrom: {recipeTags})
        .map((row) => row.read<int>('recipe'))
        .get();

    return result;
  }
}

class RecipeWithTags {
  final Recipe recipe;
  final List<Tag> tags;
  final String? thumbnail;
  final List<String> images;

  RecipeWithTags(this.recipe, this.tags, this.thumbnail, this.images);
}

class _RecipeWithTag {
  final Recipe recipe;
  final Tag? tag;

  _RecipeWithTag(this.recipe, this.tag);
}

class _RecipeImages {
  String? thumbnail;
  List<String> images;

  _RecipeImages(this.thumbnail, this.images);
}
