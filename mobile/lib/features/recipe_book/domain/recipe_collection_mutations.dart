import 'recipe_collection_filters.dart';
import 'recipe_summary.dart';

class SavedRecipeCollection {
  const SavedRecipeCollection({
    required this.recipes,
    required this.availableTags,
  });

  final List<RecipeSummary> recipes;
  final Set<String> availableTags;
}

SavedRecipeCollection saveExistingRecipeInCollection({
  required List<RecipeSummary> recipes,
  required Set<String> availableTags,
  required int index,
  required RecipeSummary recipe,
  List<String>? nextAvailableTags,
}) {
  if (index < 0 || index >= recipes.length) {
    return SavedRecipeCollection(
      recipes: List.of(recipes),
      availableTags: Set.of(availableTags),
    );
  }

  final effectiveTags = nextAvailableTags == null
      ? Set<String>.of(availableTags)
      : {
          for (final tag in nextAvailableTags)
            if (normalizeTag(tag).isNotEmpty) normalizeTag(tag),
        };

  final nextRecipes = [
    for (final currentRecipe in recipes)
      sanitizeRecipeTags(recipe: currentRecipe, availableTags: effectiveTags),
  ];
  nextRecipes[index] = sanitizeRecipeTags(
    recipe: recipe,
    availableTags: effectiveTags,
  );

  return SavedRecipeCollection(
    recipes: nextRecipes,
    availableTags: effectiveTags,
  );
}
