import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/pages/home/widgets/exceptions.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:lunch_me/util/lunch_me_cache_manager.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({super.key});

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  late final RecipeManager recipeManager;
  late final LunchMeCacheManager cacheManager;

  void initializeData() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);
    cacheManager = Provider.of<LunchMeCacheManager>(context, listen: false);
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
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: recipesWithTags.map<Widget>((RecipeWithTags recipeWithTags) {
        return _buildRecipeRow(recipeWithTags);
      }).toList(),
    );
  }

  Widget _buildRecipeRow(RecipeWithTags recipeWithTags) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Stack(children: [
            Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              clipBehavior: Clip.antiAlias,
              width: MediaQuery.of(context).size.width * 0.2,
              constraints: const BoxConstraints(maxWidth: 160),
              child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _hasImage(recipeWithTags.recipe, recipeWithTags.thumbnail) // TODO pass recipeWithTags
                      ? CachedNetworkImage(
                          cacheManager: cacheManager,
                          progressIndicatorBuilder: (context, url, progress) =>
                              Center(
                            child: CircularProgressIndicator(
                              value: progress.progress,
                            ),
                          ),
                          fit: BoxFit.cover,
                          key: Key(recipeWithTags.recipe.id.toString()),
                          imageUrl: _getImageUrl(recipeWithTags.recipe, recipeWithTags.thumbnail), // TODO pass recipeWithTags
                          errorWidget: (context, url, error) =>
                              Image.asset('assets/images/recipe/error.jpg'),
                          fadeOutDuration: const Duration(seconds: 1),
                          fadeInDuration: const Duration(seconds: 1),
                        )
                      : const Image(
                          image: AssetImage(
                              'assets/images/recipe/not-available.jpg'),
                          fit: BoxFit.cover)),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _launchUrl(recipeWithTags.recipe.url);
                  },
                ),
              ),
            ),
          ]),
          Expanded(

              child: Container(
                alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 10),
                  child: TextButton(
                      onPressed: () {
                        _launchUrl(recipeWithTags.recipe.url);
                      },
                      child: Text(recipeWithTags.recipe.name)))),
        ],
      ),
    );
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

  bool _hasImage(Recipe recipe, String? thumbnailPhoto) {
    return thumbnailPhoto != null || recipe.image != null;
  }

  String _getImageUrl(Recipe recipe, String? thumbnail) {
    if (!_hasImage(recipe, thumbnail)) {
      throw NoImageException();
    }

    if(thumbnail != null) {
      return buildImageUrl(thumbnail);
    } else {
      return recipe.image!;
    }
  }
}

Future<void> _launchUrl(String? url) async {
  if (url != null && url.isNotEmpty) {
    try {
      final uri = Uri.parse(url);

      if (!await launchUrl(uri)) throw 'Could not launch $url';
    } catch (e) {
      throw 'Could not parse url: $url';
    }
  }
}
