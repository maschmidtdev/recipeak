import '../domain/recipe_summary.dart';

class RecipeEditorResult {
  const RecipeEditorResult._({
    required this.action,
    this.recipe,
  });

  const RecipeEditorResult.saved(RecipeSummary recipe)
    : this._(action: RecipeEditorAction.save, recipe: recipe);

  const RecipeEditorResult.deleted()
    : this._(action: RecipeEditorAction.delete);

  final RecipeEditorAction action;
  final RecipeSummary? recipe;
}

enum RecipeEditorAction {
  save,
  delete,
}
