import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lunch_me/model/recipe_filters.dart';

import 'package:lunch_me/pages/home/widgets/recipe_list.dart';
import 'package:lunch_me/pages/home/widgets/tag_group_list.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecipeFilters(),
      child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.titleHome),
          ),
          body: Column(children: [
            const Flexible(child: RecipeList()),
            ExpandableNotifier(
                initialExpanded: true,
                child: ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                    tapBodyToExpand: true,
                    tapBodyToCollapse: true,
                    hasIcon: false,
                  ),
                  collapsed: Container(),
                  expanded: Container(
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
                  header: Container(
                    color: Colors.cyan,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          ExpandableIcon(
                            theme: const ExpandableThemeData(
                              expandIcon: Icons.arrow_right,
                              collapseIcon: Icons.arrow_drop_down,
                              iconColor: Colors.black,
                              iconSize: 28.0,
                              iconRotationAngle: math.pi / 2,
                              iconPadding: EdgeInsets.only(right: 5),
                              hasIcon: false,
                            ),
                          ),
                          Expanded(
                            child: Text(
                                AppLocalizations.of(context)!
                                    .titleFilterRecipes,
                                style: Theme.of(context).textTheme.bodyText1!),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
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
              ])),
    );
  }
}
