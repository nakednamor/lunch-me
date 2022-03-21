import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:lunch_me/pages/home/widgets/recipe_list.dart';
import 'package:lunch_me/pages/home/widgets/tag_group_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.titleHome),
        ),
        body: Column(children: [
          const Flexible(child: RecipeList()),
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
              child: const TagGroupList()),
        ]),
        floatingActionButton: SpeedDial(
            icon: Icons.edit,
            childPadding: const EdgeInsets.all(4),
            spacing: 5,
            spaceBetweenChildren: 10,
            children: [
              SpeedDialChild(
                  child: const Icon(Icons.article),
                  label: AppLocalizations.of(context)!.floatingMenuRecipes,
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-recipes');
                  }),
              SpeedDialChild(
                  child: const Icon(Icons.local_offer),
                  label: AppLocalizations.of(context)!.floatingMenuTags,
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-tags');
                  })
            ]));
  }
}
