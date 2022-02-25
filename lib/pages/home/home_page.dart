import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';

import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<TagGroupWithTags>> _getTagGroupsWithTags;
  late final Future<List<RecipeWithTags>> _getAllRecipes;
  late final MyDatabase database;
  late final Locale locale;
  late final Future<String> test;

  final List<String> _selectedTags = <String>[];

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    _getTagGroupsWithTags = database.getAllTagsWithGroups(locale);
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
    if (!snapshot.hasData) {
      return errorMessage(AppLocalizations.of(context)!.errorNoTagsFound);
    }

    final List<TagGroupWithTags> _tagGroupsWithTags = snapshot.data!;
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
        body: Column(children: [
          Flexible(
            child: FutureBuilder<List<RecipeWithTags>>(
                future: _getAllRecipes,
                builder: (BuildContext context, AsyncSnapshot recipesSnapshot) {
                  return recipesSnapshot.connectionState ==
                          ConnectionState.waiting
                      ? buildCustomLoader()
                      : _buildRecipeListView(recipesSnapshot);
                }),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5, //spread radius
                  blurRadius: 7, // blur radius
                  offset: const Offset(0, 2),
                ),
                //you can set more BoxShadow() here
              ],
            ),
            child: FutureBuilder<List<TagGroupWithTags>>(
                future: _getTagGroupsWithTags,
                builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
                  return tagsSnapshot.connectionState == ConnectionState.waiting
                      ? buildCustomLoader()
                      : _createTagGroupsListView(tagsSnapshot);
                }),
          ),
        ]));
  }
}
