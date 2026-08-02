import 'package:flutter_test/flutter_test.dart';
import 'package:recipeek_mobile/features/recipe_book/domain/recipe_collection_filters.dart';
import 'package:recipeek_mobile/features/recipe_book/domain/recipe_summary.dart';
import 'package:recipeek_mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  const emptyDocument = RecipeDocument(prepRows: [], columns: []);
  const recipes = [
    RecipeSummary(
      title: 'Curry',
      description: 'Tomato and chickpeas',
      duration: '35 min',
      yieldText: '4 servings',
      document: emptyDocument,
      tags: ['Vegan', 'Dinner'],
      isFavorite: true,
    ),
    RecipeSummary(
      title: 'Toast',
      description: 'Tomato toast',
      duration: '',
      yieldText: '',
      document: emptyDocument,
      tags: ['Breakfast'],
    ),
  ];

  test('filters by any selected tag', () {
    final entries = filteredRecipeEntries(
      recipes: recipes,
      searchQuery: '',
      showAllFilter: false,
      showFavoritesFilter: false,
      matchAllTags: false,
      selectedTagFilters: {'Vegan', 'Breakfast'},
    );

    expect(entries.map((entry) => entry.recipe.title), ['Curry', 'Toast']);
  });

  test('filters by all selected tags', () {
    final entries = filteredRecipeEntries(
      recipes: recipes,
      searchQuery: '',
      showAllFilter: false,
      showFavoritesFilter: false,
      matchAllTags: true,
      selectedTagFilters: {'Vegan', 'Dinner'},
    );

    expect(entries.map((entry) => entry.recipe.title), ['Curry']);
  });

  test('search includes title, description, metadata, and tags', () {
    expect(
      recipeMatchesSearch(recipe: recipes.first, searchQuery: 'chickpeas'),
      isTrue,
    );
    expect(
      recipeMatchesSearch(recipe: recipes.first, searchQuery: 'vegan'),
      isTrue,
    );
    expect(
      recipeMatchesSearch(recipe: recipes.first, searchQuery: 'missing'),
      isFalse,
    );
  });

  test('normalizes, sorts, and counts tags', () {
    expect(normalizeTag('  high   protein  '), 'high protein');
    expect(sortedTags(['b', 'A', 'c']), ['A', 'b', 'c']);
    expect(initialAvailableTags(recipes), {'Vegan', 'Dinner', 'Breakfast'});
    expect(
      tagUsageCounts(availableTags: {'Vegan', 'Dinner'}, recipes: recipes),
      {'Vegan': 1, 'Dinner': 1},
    );
  });

  test('sanitizes recipe tags against available tags', () {
    final sanitized = sanitizeRecipeTags(
      recipe: recipes.first,
      availableTags: {'Dinner'},
    );

    expect(sanitized.tags, ['Dinner']);
  });
}
