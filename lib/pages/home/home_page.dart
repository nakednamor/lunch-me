import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:lunch_me/data/database.dart';

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

  void initializeData() async {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    getTagGroupsWithTags = database.getAllTagsWithGroups(locale);
    getAllRecipes = database.getAllRecipeWithTags();
  }

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => initializeData());

    super.initState();
  }

  Widget _createRecipesListView(AsyncSnapshot snapshot) {
    final _recipesWithTags = snapshot.data;
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children:
      _recipesWithTags.map<Widget>((RecipeWithTags recipeWithTags) {
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
                image: recipeWithTags.recipe.image ?? kTransparentImage.toString(),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: Text(recipeWithTags.recipe.name)
            ),
          ],
        ));
  }

  Widget _createTagGroupsListView(AsyncSnapshot snapshot) {
    final _tagGroupsWithTags = snapshot.data;
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
              children: tagGroupWithTags.tags.map((LocalizedTag tag) {
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

          Expanded(
            child: FutureBuilder(
                future: getAllRecipes,
                initialData: const [],
                builder: (context, recipesSnapshot) {
                  if(!recipesSnapshot.hasData) return const CircularProgressIndicator();
                  return recipesSnapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : _createRecipesListView(recipesSnapshot);
                }),
          ),
          Expanded(
            child: FutureBuilder(
                future: getTagGroupsWithTags,
                initialData: const [],
                builder: (context, tagsSnapshot) {
                  return tagsSnapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : _createTagGroupsListView(tagsSnapshot);
                }),
          ),
        ]));
  }
}
