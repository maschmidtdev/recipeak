import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ingredients/domain/ingredient_cell_text.dart';
import 'package:mobile/features/ingredients/domain/ingredient_product.dart';

void main() {
  const tomatoes = IngredientProduct(
    id: 'ingredient-tomatoes',
    name: 'Tomatoes',
    amount: '400',
    price: '',
    store: '',
    kcal: 22,
    protein: 1.1,
    carbs: 3.9,
    fat: 0.2,
  );

  const soyMilk = IngredientProduct(
    id: 'ingredient-soy-milk',
    name: 'Soy milk',
    amount: '1000',
    price: '',
    store: '',
    kcal: 43,
    protein: 3.3,
    carbs: 0.7,
    fat: 2,
    baseUnit: IngredientBaseUnit.milliliters,
  );

  test('uses ingredient name when recipe amount is empty', () {
    expect(
      ingredientCellText(ingredient: tomatoes, recipeAmount: ''),
      'Tomatoes',
    );
  });

  test('normalizes explicit gram amount and uses ingredient base unit', () {
    expect(
      ingredientCellText(ingredient: tomatoes, recipeAmount: '200 g'),
      '200g Tomatoes',
    );
  });

  test('uses gram base unit when recipe amount is numeric', () {
    expect(
      ingredientCellText(ingredient: tomatoes, recipeAmount: '200'),
      '200g Tomatoes',
    );
  });

  test('uses ml base unit when recipe amount is numeric', () {
    expect(
      ingredientCellText(ingredient: soyMilk, recipeAmount: '150'),
      '150ml Soy milk',
    );
  });

  test('drops non-numeric recipe amounts from generated linked text', () {
    expect(
      ingredientCellText(ingredient: tomatoes, recipeAmount: '1/2 pack'),
      'Tomatoes',
    );
  });

  test('normalizes structured recipe amount to number only', () {
    expect(normalizedIngredientAmount('200 g'), '200');
    expect(normalizedIngredientAmount('150ml'), '150');
    expect(normalizedIngredientAmount('120,5'), '120.5');
    expect(normalizedIngredientAmount('120.0'), '120');
    expect(normalizedIngredientAmount('1/2 pack'), '');
    expect(normalizedIngredientAmount(''), '');
  });

  test('ignores mismatched explicit unit and uses ingredient base unit', () {
    expect(
      ingredientCellText(ingredient: soyMilk, recipeAmount: '150 g'),
      '150ml Soy milk',
    );
  });

  test('renders product amount with base unit', () {
    expect(ingredientAmountText(tomatoes), '400 g');
    expect(ingredientAmountText(soyMilk), '1000 ml');
  });
}
