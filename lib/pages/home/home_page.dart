import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/widgets/custom_loader.dart';

import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<TagGroupWithTags>>? getTagGroupsWithTags;
  Future<List<RecipeWithTags>>? getAllRecipes;
  late final MyDatabase database;
  late final Locale locale;
  late final Future<String> test;

  final List<String> _selectedTags = <String>[];

  void initializeDatabaseFutures() async {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    getTagGroupsWithTags = database.getAllTagsWithGroups(locale);
    getAllRecipes = database.getAllRecipeWithTags();
  }

  @override
  void initState() {
    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => initializeDatabaseFutures());

    super.initState();
  }

  Widget _createRecipesListView(AsyncSnapshot snapshot) {
    final List<RecipeWithTags>? _recipesWithTags = snapshot.data;
    if(_recipesWithTags == null) return Text("Could not fetch recipes");
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: FadeInImage.memoryNetwork(
                width: MediaQuery.of(context).size.width * 0.2,
                fit: BoxFit.cover,
                placeholder: kTransparentImage,
                image:
                    recipeWithTags.recipe.image ?? kTransparentImage.toString(),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(left: 10),
                child: Text(recipeWithTags.recipe.name)),
          ],
        ));
  }

  Widget _createTagGroupsListView(AsyncSnapshot snapshot) {
    final List<TagGroupWithTags>? _tagGroupsWithTags = snapshot.data;
    if(_tagGroupsWithTags == null) return Text("Could not fetch tags");
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children:
          _tagGroupsWithTags.map<Widget>((TagGroupWithTags tagGroupWithTags) {
        return _buildTagGroupRow(tagGroupWithTags);
      }).toList(),
    );
  }

  Widget _buildTagGroupRow(TagGroupWithTags tagGroupWithTags) {
    return Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(tagGroupWithTags.tagGroup.label),
            Wrap(
              children: tagGroupWithTags.tags.map<Widget>((LocalizedTag tag) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: FilterChip(
                    label: Text(tag.label),
                    selected: _selectedTags.contains(tag.label),
                    backgroundColor: Colors.blueGrey.withAlpha(50),
                    selectedColor: Colors.lime,
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          _selectedTags.add(tag.label);
                        } else {
                          _selectedTags.removeWhere((String label) {
                            return label == tag.label;
                          });
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.greeting),
        ),
        //body: _buildTagGroups(),
        body: Column(children: [
          Flexible(
            child: FutureBuilder(
                future: getAllRecipes,
                initialData: const [],
                builder:
                    (BuildContext context, AsyncSnapshot recipesSnapshot) {
                  if (!recipesSnapshot.hasData)
                    return Text("Could not fetch recipes!");
                  return recipesSnapshot.connectionState ==
                          ConnectionState.waiting
                      ? CustomLoader()
                      : _createRecipesListView(recipesSnapshot);
                }),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), //color of shadow
                  spreadRadius: 5, //spread radius
                  blurRadius: 7, // blur radius
                  offset: Offset(0, 2), // changes position of shadow
                  //first paramerter of offset is left-right
                  //second parameter is top to down
                ),
                //you can set more BoxShadow() here
              ],
            ),
            child: FutureBuilder(
                future: getTagGroupsWithTags,
                initialData: const [],
                builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
                  if (!tagsSnapshot.hasData)
                    return Text("Could not fetch tags!");
                  return tagsSnapshot.connectionState == ConnectionState.waiting
                      ? CustomLoader()
                      : _createTagGroupsListView(tagsSnapshot);
                }),
          ),
        ]));
  }
}
