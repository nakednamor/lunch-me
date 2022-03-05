import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

// import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:lunch_me/widgets/custom_loader.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  late final Future<List<RecipeWithTags>> _getAllRecipes;
  late final MyDatabase database;

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    _getAllRecipes = database.getAllRecipeWithTags();
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

    final List<RecipeWithTags> _recipesWithTags = snapshot.data!;
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: _recipesWithTags.map<Widget>((RecipeWithTags recipeWithTags) {
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
                child: FadeInImage.memoryNetwork(
                  width: MediaQuery.of(context).size.width * 0.2,
                  fit: BoxFit.cover,
                  placeholder: kTransparentImage,
                  image: recipeWithTags.recipe.image ??
                      kTransparentImage.toString(),
                )),
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
    return FutureBuilder<List<RecipeWithTags>>(
        future: _getAllRecipes,
        builder: (BuildContext context, AsyncSnapshot recipesSnapshot) {
          return recipesSnapshot.connectionState == ConnectionState.waiting
              ? buildCustomLoader()
              : _buildRecipeListView(recipesSnapshot);
        });
  }
}

Future<void> _launchUrl(String? _url) async {
  if (_url != null && _url.isNotEmpty) {
    final bool _nativeAppLaunchSucceeded = await launch(
      _url,
      forceSafariVC: false,
      universalLinksOnly: true,
    );
    if (!_nativeAppLaunchSucceeded &&
        !await launch(_url,
            forceWebView: true, forceSafariVC: true, enableJavaScript: true)) {
      throw 'Could not launch $_url';
    }
  }
}
