import '../../ingredients/domain/ingredient_cell_text.dart';
import '../../ingredients/domain/ingredient_product.dart';
import 'recipe_summary.dart';
import '../../recipe_document/domain/recipe_document.dart';

RecipeSummary clearIngredientReference(
  RecipeSummary recipe,
  String ingredientProductId,
) {
  return recipe.copyWith(
    document: _clearDocumentIngredientReference(
      recipe.document,
      ingredientProductId,
    ),
  );
}

RecipeSummary refreshIngredientReferenceText(
  RecipeSummary recipe,
  IngredientProduct ingredient,
) {
  return recipe.copyWith(
    document: _refreshDocumentIngredientReferenceText(
      recipe.document,
      ingredient,
    ),
  );
}

RecipeDocument _clearDocumentIngredientReference(
  RecipeDocument document,
  String ingredientProductId,
) {
  return document.copyWith(
    columns: [
      for (final column in document.columns)
        WorkflowColumn(
          id: column.id,
          widthSpec: column.widthSpec,
          cells: [
            for (final cell in column.cells)
              if (cell.ingredientProductId == ingredientProductId)
                cell.copyWith(
                  clearIngredientProductId: true,
                  ingredientAmount: '',
                )
              else
                cell,
          ],
        ),
    ],
  );
}

RecipeDocument _refreshDocumentIngredientReferenceText(
  RecipeDocument document,
  IngredientProduct ingredient,
) {
  return document.copyWith(
    columns: [
      for (final column in document.columns)
        WorkflowColumn(
          id: column.id,
          widthSpec: column.widthSpec,
          cells: [
            for (final cell in column.cells)
              if (cell.ingredientProductId == ingredient.id)
                cell.copyWith(
                  ingredientAmount: normalizedIngredientAmount(
                    cell.ingredientAmount,
                  ),
                  text: ingredientCellText(
                    ingredient: ingredient,
                    recipeAmount: cell.ingredientAmount,
                  ),
                )
              else
                cell,
          ],
        ),
    ],
  );
}
