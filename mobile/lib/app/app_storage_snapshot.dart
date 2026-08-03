import '../features/ingredients/domain/ingredient_product.dart';
import '../features/recipe_book/domain/recipe_summary.dart';

class AppStorageSnapshot {
  const AppStorageSnapshot({
    required this.recipes,
    required this.availableTags,
    required this.matchAllTags,
    this.ingredients = const [],
    this.availableIngredientTags = const [],
  });

  final List<RecipeSummary> recipes;
  final List<String> availableTags;
  final bool matchAllTags;
  final List<IngredientProduct> ingredients;
  final List<String> availableIngredientTags;
}
