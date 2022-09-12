import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/dao/tag_dao.dart' as tag_dao; // TODO workaround unambigous imports
import 'package:lunch_me/model/recipe_filters.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:provider/provider.dart';

class TagGroupList extends StatefulWidget {
  const TagGroupList({super.key});

  @override
  State<TagGroupList> createState() => _TagGroupListState();
}

class _TagGroupListState extends State<TagGroupList> {
  late final Stream<List<tag_dao.TagGroupWithTags>> _watchTagGroupsWithTags;
  late final RecipeManager recipeManager;

  final List<RecipeFilter> _selectedTags = <RecipeFilter>[];

  void initializeData() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);
    _watchTagGroupsWithTags = recipeManager.watchAllTagsWithGroups();
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

    final List<tag_dao.TagGroupWithTags> tagGroupsWithTags = snapshot.data!;
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children:
          tagGroupsWithTags.map<Widget>((tag_dao.TagGroupWithTags tagGroupWithTags) {
        return _buildTagGroupRow(tagGroupWithTags);
      }).toList(),
    );
  }

  Widget _buildTagGroupRow(tag_dao.TagGroupWithTags tagGroupWithTags) {
    return Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(tagGroupWithTags.tagGroup.label),
            Wrap(
              children: tagGroupWithTags.tags.map<Widget>((Tag tag) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: FilterChip(
                    label: Text(tag.label),
                    selected: _isTagSelected(_selectedTags, tag),
                    backgroundColor: Colors.blueGrey.withAlpha(50),
                    selectedColor: Colors.lime,
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          _addRecipeFilter(_selectedTags, true, tag);
                        } else {
                          _removeRecipeFilter(_selectedTags, tag);
                        }
                        Provider.of<RecipeFilters>(context, listen: false).setFilter(_selectedTags);
                      });
                    },
                  ),
                );
              }).toList(),
            )
          ],
        ));
  }

  bool _isTagSelected(List<RecipeFilter> filterList, Tag tag) {
    return filterList.firstWhereOrNull((filter) => filter.tags.contains(tag.id)) != null;
  }

  void _addRecipeFilter(List<RecipeFilter> filterList, bool allMatch, Tag tag) {
    var filter = filterList.firstWhereOrNull((filter) => filter.tagGroup == tag.tagGroup);
    bool firstTimeFilter = false;
    if (filter == null) {
      filter = RecipeFilter(tag.tagGroup, allMatch, []);
      firstTimeFilter = true;
    }

    filter.tags.add(tag.id);

    if (firstTimeFilter) {
      filterList.add(filter);
    }
  }

  void _removeRecipeFilter(List<RecipeFilter> filterList, Tag tag) {
    var filter = filterList.firstWhere((filter) => filter.tagGroup == tag.tagGroup);
    filter.tags.remove(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<tag_dao.TagGroupWithTags>>(
        stream: _watchTagGroupsWithTags,
        builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
          return tagsSnapshot.connectionState == ConnectionState.waiting
              ? buildCustomLoader()
              : _buildTagGroupListView(tagsSnapshot);
        });
  }
}
