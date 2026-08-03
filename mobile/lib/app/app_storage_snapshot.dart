import '../features/recipe_book/domain/recipe_summary.dart';

class AppStorageSnapshot {
  const AppStorageSnapshot({
    required this.recipes,
    required this.availableTags,
    required this.matchAllTags,
  });

  final List<RecipeSummary> recipes;
  final List<String> availableTags;
  final bool matchAllTags;
}
