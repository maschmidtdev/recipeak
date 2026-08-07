import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ingredients/domain/ingredient_product.dart';
import 'package:mobile/features/recipe_book/domain/recipe_ingredient_links.dart';
import 'package:mobile/features/recipe_book/domain/recipe_summary.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  test('clears ingredient references without changing visible cell text', () {
    const recipe = RecipeSummary(
      title: 'Pasta',
      description: '',
      duration: '',
      yieldText: '',
      document: RecipeDocument(
        prepRows: [],
        columns: [
          WorkflowColumn(
            id: 'A',
            cells: [
              WorkflowCell(
                startRow: 1,
                rowSpan: 1,
                text: '200g Tomatoes',
                ingredientProductId: 'ingredient-tomatoes',
                ingredientAmount: '200',
              ),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '100g Pasta',
                ingredientProductId: 'ingredient-pasta',
                ingredientAmount: '100',
              ),
            ],
          ),
        ],
      ),
    );

    final cleaned = clearIngredientReference(recipe, 'ingredient-tomatoes');
    final cells = cleaned.document.columns.single.cells;

    expect(cells.first.text, '200g Tomatoes');
    expect(cells.first.ingredientProductId, isNull);
    expect(cells.first.ingredientAmount, '');
    expect(cells.last.ingredientProductId, 'ingredient-pasta');
    expect(cells.last.ingredientAmount, '100');
  });

  test('refreshes linked cell text when ingredient unit changes', () {
    const recipe = RecipeSummary(
      title: 'Smoothie',
      description: '',
      duration: '',
      yieldText: '',
      document: RecipeDocument(
        prepRows: [],
        columns: [
          WorkflowColumn(
            id: 'A',
            cells: [
              WorkflowCell(
                startRow: 1,
                rowSpan: 1,
                text: '200ml Coconut milk',
                ingredientProductId: 'ingredient-coconut-milk',
                ingredientAmount: '200',
              ),
            ],
          ),
        ],
      ),
    );
    const updatedIngredient = IngredientProduct(
      id: 'ingredient-coconut-milk',
      name: 'Coconut milk',
      amount: '400',
      price: '',
      store: '',
      kcal: 180,
      protein: 1.6,
      carbs: 2.8,
      fat: 18,
    );

    final updated = refreshIngredientReferenceText(recipe, updatedIngredient);
    final cell = updated.document.columns.single.cells.single;

    expect(cell.text, '200g Coconut milk');
    expect(cell.ingredientProductId, 'ingredient-coconut-milk');
    expect(cell.ingredientAmount, '200');
  });
}
