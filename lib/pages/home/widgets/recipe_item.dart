import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lunch_me/data/dao/recipe_dao.dart';
import 'package:lunch_me/pages/home/widgets/exceptions.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:lunch_me/util/lunch_me_cache_manager.dart';
import 'package:lunch_me/util/recipe_manager.dart';

class RecipeItem extends StatefulWidget {
  final RecipeWithTags recipeWithTags;
  final VoidCallback removeRecipeCallback;

  const RecipeItem({
    Key? key,
    required this.recipeWithTags,
    required this.removeRecipeCallback,
  }) : super(key: key);

  @override
  State<RecipeItem> createState() => _RecipeItemState();
}

class _RecipeItemState extends State<RecipeItem> {
  BaseCacheManager cacheManager = LunchMeCacheManager();
  late final RecipeManager recipeManager;

  @override
  void didChangeDependencies() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);

    super.didChangeDependencies();
  }

  bool _hasImage(RecipeWithTags recipeWithTags) {
    return recipeWithTags.thumbnail != null ||
        recipeWithTags.recipe.image != null;
  }

  String _getImageUrl(RecipeWithTags recipeWithTags) {
    if (!_hasImage(recipeWithTags)) {
      throw NoImageException();
    }

    if (recipeWithTags.thumbnail != null) {
      return buildImageUrl(recipeWithTags.thumbnail!);
    } else {
      return recipeWithTags.recipe.image!;
    }
  }

  void _onPressEdit(int recipeId) {
    Navigator.pushNamed(context,
        '/edit-recipes'); // TODO add routes for certain recipes and functionality to edit
    return;
  }

  @override
  Widget build(BuildContext context) {
    var recipeWithTags = widget.recipeWithTags;

    return SlidableAutoCloseBehavior(
        closeWhenOpened: true,
        closeWhenTapped: true,
        child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                    onPressed: (_) => _onPressEdit(recipeWithTags.recipe.id),
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    icon: Icons.edit),
                SlidableAction(
                  onPressed: (_) => widget.removeRecipeCallback(),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                ),
              ],
            ),
            child: Container(
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
                          child: _hasImage(recipeWithTags)
                              ? CachedNetworkImage(
                                  cacheManager: cacheManager,
                                  progressIndicatorBuilder:
                                      (context, url, progress) => Center(
                                    child: CircularProgressIndicator(
                                      value: progress.progress,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                  key: Key(recipeWithTags.recipe.id.toString()),
                                  imageUrl: _getImageUrl(recipeWithTags),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                          'assets/images/recipe/error.jpg'),
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
            )));
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
