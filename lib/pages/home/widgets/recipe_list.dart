import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/pages/home/widgets/recipe_item.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/util/lunch_me_cache_manager.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:provider/provider.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({super.key});

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  late final RecipeManager recipeManager;
  late final LunchMeCacheManager cacheManager;
  late final RecipeFilters recipeFilters;

  void initializeData() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);
    cacheManager = Provider.of<LunchMeCacheManager>(context, listen: false);
    recipeFilters = Provider.of<RecipeFilters>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    initializeData();

    super.didChangeDependencies();
  }

  Widget _buildRecipeListView(AsyncSnapshot snapshot) {
    if (!snapshot.hasData) {
      return errorMessage(AppLocalizations.of(context)!.errorNoRecipesFound);
    }

    final List<RecipeWithTags> recipesWithTags = snapshot.data!;

    return ListView.builder(
        itemCount: recipesWithTags.length,
        itemBuilder: (BuildContext context, int index) {
          final RecipeWithTags recipeWithTags = recipesWithTags[index];
          return RecipeItem(
            key: ValueKey(recipeWithTags.recipe.id),
            recipeWithTags: recipeWithTags,
            removeRecipeCallback: () {
              removeRecipe(recipeWithTags.recipe.id);
            },
          );
        },
        scrollDirection: Axis.vertical,
        shrinkWrap: true);
  }

  void removeRecipe(int recipeId) async {
    await recipeManager.recipeDao.deleteRecipe(recipeId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeFilters>(
      builder: (context, recipeFilters, child) {
        return FutureBuilder<List<RecipeWithTags>>(
            future: recipeManager.filterRecipes(recipeFilters.filter),
            builder: (BuildContext context, AsyncSnapshot recipesSnapshot) {
              return recipesSnapshot.connectionState == ConnectionState.waiting
                  ? buildCustomLoader()
                  : _buildRecipeListView(recipesSnapshot);
            });
      },
    );
  }
}
