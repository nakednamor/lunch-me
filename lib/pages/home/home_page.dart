import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:lunch_me/data/database.dart';

import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late List<TagGroupWithTags> _tagGroupsWithTags;

  bool _isLoading = true;

  final List<String> _selectedTags = <String>[];

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<MyDatabase>(context);

    var getTagGroupsWithTags = database.getAllTagsWithGroups(
        Localizations.localeOf(context));

    getTagGroupsWithTags.then((tagGroupsWithTags) {
      setState(() {
        _tagGroupsWithTags = tagGroupsWithTags;
        _isLoading = false;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.greeting),
      ),
      body: _buildTagGroups(),
    );
  }

  Widget _buildTagGroups() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: _tagGroupsWithTags.map((TagGroupWithTags tagGroupWithTags) {
          return _buildTagGroupRow(tagGroupWithTags);
        }).toList(),
      );
    }
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
        )
    );
  }
}