import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/model/RecipeFilters.dart';
import 'package:lunch_me/pages/home/widgets/exceptions.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:lunch_me/util/lunch_me_cache_manager.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/tables.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({super.key});

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  late final MyDatabase database;

  BaseCacheManager cacheManager = LunchMeCacheManager();

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              clipBehavior: Clip.antiAlias,
              height: 50,
              child: _hasImage(recipeWithTags.recipe)
                  ? CachedNetworkImage(
                      cacheManager: cacheManager,
                      progressIndicatorBuilder: (context, url, progress) => Center(
                        child: CircularProgressIndicator(
                          value: progress.progress,
                        ),
                      ),
                      key: Key(recipeWithTags.recipe.id.toString()),
                      imageUrl: _getImageUrl(recipeWithTags.recipe),
                      errorWidget: (context, url, error) => Image.asset('assets/images/recipe/error.png'),
                      fadeOutDuration: const Duration(seconds: 1),
                      fadeInDuration: const Duration(seconds: 1),
                    )
                  : Image.asset('assets/images/recipe/not_available.png'),
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
          Container(
              margin: const EdgeInsets.only(left: 10),
              child: TextButton(
                  onPressed: () {
                    _launchUrl(recipeWithTags.recipe.url);
                  },
                  child: Text(recipeWithTags.recipe.name))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeFilters>(
      builder: (context, recipeFilters, child) {
        return FutureBuilder<List<RecipeWithTags>>(
            future: database.filterRecipeByTags(recipeFilters.tagIds),
            builder: (BuildContext context, AsyncSnapshot recipesSnapshot) {
              return recipesSnapshot.connectionState == ConnectionState.waiting ? buildCustomLoader() : _buildRecipeListView(recipesSnapshot);
            });
      },
    );
  }

  bool _hasImage(Recipe recipe) {
    if (recipe.type == Source.photo) {
      return recipe.imagePhoto != null;
    } else {
      return recipe.image != null;
    }
  }

  String _getImageUrl(Recipe recipe) {
    if (!_hasImage(recipe)) {
      throw NoImageException();
    }

    if (recipe.type == Source.photo) {
      return buildImageUrl(recipe.imagePhoto!);
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
