import '../domain/recipe_summary.dart';

class RecipeEditorResult {
  const RecipeEditorResult._({
    required this.action,
    this.recipe,
    this.availableTags,
  });

  const RecipeEditorResult.saved(
    RecipeSummary recipe, {
    List<String>? availableTags,
  }) : this._(
         action: RecipeEditorAction.save,
         recipe: recipe,
         availableTags: availableTags,
       );

  const RecipeEditorResult.deleted()
    : this._(action: RecipeEditorAction.delete);

  final RecipeEditorAction action;
  final RecipeSummary? recipe;
  final List<String>? availableTags;
}

enum RecipeEditorAction {
  save,
  delete,
}
