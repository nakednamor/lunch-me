import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:lunch_me/widgets/custom_loader.dart';

class TagGroupList extends StatefulWidget {
  const TagGroupList({Key? key}) : super(key: key);

  @override
  _TagGroupListState createState() => _TagGroupListState();
}

class _TagGroupListState extends State<TagGroupList> {
  late final Stream<List<TagGroupWithTags>> _watchTagGroupsWithTags;
  late final MyDatabase database;
  late final Locale locale;

  final List<String> _selectedTags = <String>[];

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    _watchTagGroupsWithTags = database.watchAllTagsWithGroups(locale);
  }

  @override
  void didChangeDependencies() {
    initializeData();

    super.didChangeDependencies();
  }

  Widget _buildTagGroupListView(AsyncSnapshot snapshot) {
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
            Text(
                '${tagGroupWithTags.tagGroup.label} (ID: ${tagGroupWithTags.tagGroup.id})'), // Temporary ID added as info
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
    return StreamBuilder<List<TagGroupWithTags>>(
        stream: _watchTagGroupsWithTags,
        builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
          return tagsSnapshot.connectionState == ConnectionState.waiting
              ? buildCustomLoader()
              : _buildTagGroupListView(tagsSnapshot);
        });
  }
}
