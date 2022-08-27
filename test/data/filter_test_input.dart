class FilterTestInput {
  final List<int> selectedTags;
  final List<int> expectedRecipeIds;
  final Map<int, bool> tagGroupMatchRelations;

  FilterTestInput(this.selectedTags, this.expectedRecipeIds, this.tagGroupMatchRelations);
}
