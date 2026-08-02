import 'recipe_summary.dart';

class RecipeEntry {
  const RecipeEntry({required this.index, required this.recipe});

  final int index;
  final RecipeSummary recipe;
}

List<RecipeEntry> filteredRecipeEntries({
  required List<RecipeSummary> recipes,
  required String searchQuery,
  required bool showAllFilter,
  required bool showFavoritesFilter,
  required bool matchAllTags,
  required Set<String> selectedTagFilters,
}) {
  final entries = <RecipeEntry>[
    for (final entry in recipes.indexed)
      RecipeEntry(index: entry.$1, recipe: entry.$2),
  ];

  final normalizedSearchQuery = searchQuery.trim().toLowerCase();
  final searchFilteredEntries = normalizedSearchQuery.isEmpty
      ? entries
      : entries
            .where(
              (entry) => recipeMatchesSearch(
                recipe: entry.recipe,
                searchQuery: normalizedSearchQuery,
              ),
            )
            .toList();

  if (showAllFilter) {
    return searchFilteredEntries;
  }

  return searchFilteredEntries.where((entry) {
    final matchesFavorites = !showFavoritesFilter || entry.recipe.isFavorite;
    final matchesTags = selectedTagFilters.isEmpty
        ? true
        : (matchAllTags
              ? selectedTagFilters.every(entry.recipe.tags.contains)
              : selectedTagFilters.any(entry.recipe.tags.contains));

    if (matchAllTags) {
      return matchesFavorites && matchesTags;
    }

    return (showFavoritesFilter && entry.recipe.isFavorite) ||
        (selectedTagFilters.isNotEmpty &&
            selectedTagFilters.any(entry.recipe.tags.contains));
  }).toList();
}

bool recipeMatchesSearch({
  required RecipeSummary recipe,
  required String searchQuery,
}) {
  final normalizedSearchQuery = searchQuery.trim().toLowerCase();
  if (normalizedSearchQuery.isEmpty) {
    return true;
  }

  final haystacks = <String>[
    recipe.title,
    recipe.description,
    recipe.duration,
    recipe.yieldText,
    ...recipe.tags,
  ];

  return haystacks.any(
    (value) => value.toLowerCase().contains(normalizedSearchQuery),
  );
}

RecipeSummary sanitizeRecipeTags({
  required RecipeSummary recipe,
  required Set<String> availableTags,
}) {
  return recipe.copyWith(
    tags: [
      for (final tag in recipe.tags)
        if (availableTags.contains(tag)) tag,
    ],
  );
}

Set<String> initialAvailableTags(List<RecipeSummary> recipes) {
  final tags = <String>{};
  for (final recipe in recipes) {
    tags.addAll(recipe.tags);
  }
  return tags;
}

Map<String, int> tagUsageCounts({
  required Set<String> availableTags,
  required List<RecipeSummary> recipes,
}) {
  final counts = <String, int>{};
  for (final tag in availableTags) {
    counts[tag] = 0;
  }
  for (final recipe in recipes) {
    for (final tag in recipe.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
}

List<String> sortedTags(Iterable<String> tags) {
  final values = [...tags];
  values.sort(
    (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
  );
  return values;
}

String normalizeTag(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}
