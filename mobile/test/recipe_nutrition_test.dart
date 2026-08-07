import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ingredients/domain/ingredient_product.dart';
import 'package:mobile/features/recipe_book/domain/recipe_nutrition.dart';
import 'package:mobile/features/recipe_book/domain/recipe_summary.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  test('calculates totals from linked ingredient cells', () {
    const recipe = RecipeSummary(
      title: 'Curry',
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
                text: '200g Chickpeas',
                ingredientProductId: 'chickpeas',
                ingredientAmount: '200',
              ),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '50g Spinach',
                ingredientProductId: 'spinach',
                ingredientAmount: '50',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'chickpeas',
        name: 'Chickpeas',
        amount: '400',
        price: '1.60',
        store: '',
        kcal: 120,
        protein: 7,
        carbs: 16,
        fat: 2,
      ),
      IngredientProduct(
        id: 'spinach',
        name: 'Spinach',
        amount: '250',
        price: '1.25',
        store: '',
        kcal: 20,
        protein: 3,
        carbs: 1,
        fat: 0,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, 250);
    expect(nutrition.protein, 15.5);
    expect(nutrition.carbs, 32.5);
    expect(nutrition.fat, 4);
    expect(nutrition.cost, 1.05);
    expect(nutrition.missingItems, isEmpty);
    expect(nutrition.isPartial, isFalse);
  });

  test('reports missing nutrition inputs without blocking partial totals', () {
    const recipe = RecipeSummary(
      title: 'Mixed',
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
                text: '100g Rice',
                ingredientProductId: 'rice',
                ingredientAmount: '100',
              ),
              WorkflowCell(startRow: 2, rowSpan: 1, text: 'Garlic'),
              WorkflowCell(
                startRow: 3,
                rowSpan: 1,
                text: 'Tomatoes',
                ingredientProductId: 'missing',
                ingredientAmount: '100',
              ),
              WorkflowCell(
                startRow: 4,
                rowSpan: 1,
                text: 'Oil',
                ingredientProductId: 'oil',
              ),
              WorkflowCell(
                startRow: 5,
                rowSpan: 1,
                text: 'Water',
                ingredientProductId: 'water',
                ingredientAmount: '100',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'rice',
        name: 'Rice',
        amount: '1000',
        price: '3',
        store: '',
        kcal: 350,
        protein: 7,
        carbs: 78,
        fat: 1,
      ),
      IngredientProduct(
        id: 'oil',
        name: 'Oil',
        amount: '750',
        price: '4.50',
        store: '',
        kcal: 884,
        protein: 0,
        carbs: 0,
        fat: 100,
      ),
      IngredientProduct(
        id: 'water',
        name: 'Water',
        amount: '1000',
        price: '0.50',
        store: '',
        kcal: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, 350);
    expect(nutrition.protein, 7);
    expect(nutrition.carbs, 78);
    expect(nutrition.fat, 1);
    expect(nutrition.isPartial, isTrue);
    expect(
      nutrition.missingItems.map((item) => item.reason),
      [
        RecipeNutritionMissingReason.noLinkedIngredient,
        RecipeNutritionMissingReason.ingredientNotFound,
        RecipeNutritionMissingReason.missingAmount,
        RecipeNutritionMissingReason.missingNutrition,
      ],
    );
  });

  test('normalizes legacy and decimal ingredient amounts for calculation', () {
    const recipe = RecipeSummary(
      title: 'Decimals',
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
                text: '200g Rice',
                ingredientProductId: 'rice',
                ingredientAmount: '200 g',
              ),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '120.5g Lentils',
                ingredientProductId: 'lentils',
                ingredientAmount: '120.5',
              ),
              WorkflowCell(
                startRow: 3,
                rowSpan: 1,
                text: '50,5g Spinach',
                ingredientProductId: 'spinach',
                ingredientAmount: '50,5',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'rice',
        name: 'Rice',
        amount: '1000',
        price: '2',
        store: '',
        kcal: 100,
        protein: 10,
        carbs: 20,
        fat: 1,
      ),
      IngredientProduct(
        id: 'lentils',
        name: 'Lentils',
        amount: '500',
        price: '1.50',
        store: '',
        kcal: 200,
        protein: 20,
        carbs: 30,
        fat: 2,
      ),
      IngredientProduct(
        id: 'spinach',
        name: 'Spinach',
        amount: '250',
        price: '1.25',
        store: '',
        kcal: 10,
        protein: 1,
        carbs: 2,
        fat: 0,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, closeTo(446.05, 0.001));
    expect(nutrition.protein, closeTo(44.605, 0.001));
    expect(nutrition.carbs, closeTo(77.16, 0.001));
    expect(nutrition.fat, closeTo(4.41, 0.001));
    expect(nutrition.missingItems, isEmpty);
  });

  test('ignores empty ingredient cells and non-ingredient columns', () {
    const recipe = RecipeSummary(
      title: 'Ignore rows',
      description: '',
      duration: '',
      yieldText: '',
      document: RecipeDocument(
        prepRows: [],
        columns: [
          WorkflowColumn(
            id: 'A',
            cells: [
              WorkflowCell(startRow: 1, rowSpan: 1, text: ''),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '100g Rice',
                ingredientProductId: 'rice',
                ingredientAmount: '100',
              ),
            ],
          ),
          WorkflowColumn(
            id: 'B',
            cells: [
              WorkflowCell(startRow: 1, rowSpan: 1, text: 'cook'),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'rice',
        name: 'Rice',
        amount: '1000',
        price: '2',
        store: '',
        kcal: 100,
        protein: 10,
        carbs: 20,
        fat: 1,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, 100);
    expect(nutrition.protein, 10);
    expect(nutrition.carbs, 20);
    expect(nutrition.fat, 1);
    expect(nutrition.missingItems, isEmpty);
  });

  test('allows ingredients with some zero macro values', () {
    const recipe = RecipeSummary(
      title: 'Lean',
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
                text: '100g Protein isolate',
                ingredientProductId: 'protein',
                ingredientAmount: '100',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'protein',
        name: 'Protein isolate',
        amount: '500',
        price: '10',
        store: '',
        kcal: 360,
        protein: 90,
        carbs: 0,
        fat: 0,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, 360);
    expect(nutrition.protein, 90);
    expect(nutrition.carbs, 0);
    expect(nutrition.fat, 0);
    expect(nutrition.missingItems, isEmpty);
  });

  test('calculates total cost from package amount and price', () {
    const recipe = RecipeSummary(
      title: 'Cost',
      description: '',
      duration: '',
      yieldText: '4 servings',
      document: RecipeDocument(
        prepRows: [],
        columns: [
          WorkflowColumn(
            id: 'A',
            cells: [
              WorkflowCell(
                startRow: 1,
                rowSpan: 1,
                text: '200g Chickpeas',
                ingredientProductId: 'chickpeas',
                ingredientAmount: '200',
              ),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '100g Rice',
                ingredientProductId: 'rice',
                ingredientAmount: '100',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'chickpeas',
        name: 'Chickpeas',
        amount: '400',
        price: '1,49',
        store: '',
        kcal: 120,
        protein: 7,
        carbs: 16,
        fat: 2,
      ),
      IngredientProduct(
        id: 'rice',
        name: 'Rice',
        amount: '1000',
        price: '2.50',
        store: '',
        kcal: 350,
        protein: 7,
        carbs: 78,
        fat: 1,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.cost, closeTo(0.995, 0.001));
    expect(nutrition.servings, 4);
    expect(nutrition.missingItems, isEmpty);
  });

  test('reports missing cost inputs without blocking nutrition totals', () {
    const recipe = RecipeSummary(
      title: 'Cost gaps',
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
                text: '100g Lentils',
                ingredientProductId: 'lentils',
                ingredientAmount: '100',
              ),
              WorkflowCell(
                startRow: 2,
                rowSpan: 1,
                text: '100g Oil',
                ingredientProductId: 'oil',
                ingredientAmount: '100',
              ),
            ],
          ),
        ],
      ),
    );
    const ingredients = [
      IngredientProduct(
        id: 'lentils',
        name: 'Lentils',
        amount: '',
        price: '1.50',
        store: '',
        kcal: 200,
        protein: 20,
        carbs: 30,
        fat: 2,
      ),
      IngredientProduct(
        id: 'oil',
        name: 'Oil',
        amount: '750',
        price: '',
        store: '',
        kcal: 884,
        protein: 0,
        carbs: 0,
        fat: 100,
      ),
    ];

    final nutrition = calculateRecipeNutrition(
      recipe: recipe,
      ingredients: ingredients,
    );

    expect(nutrition.kcal, 1084);
    expect(nutrition.cost, 0);
    expect(
      nutrition.missingItems.map((item) => item.reason),
      [
        RecipeNutritionMissingReason.missingPackageAmount,
        RecipeNutritionMissingReason.missingPrice,
      ],
    );
  });

  test('parses serving counts from recipe yield text', () {
    expect(parseRecipeServings('4 servings'), 4);
    expect(parseRecipeServings('4 Portionen'), 4);
    expect(parseRecipeServings('4-5 Portionen'), 4.5);
    expect(parseRecipeServings('4,5 servings'), 4.5);
    expect(parseRecipeServings(''), isNull);
    expect(parseRecipeServings('Yield TBD'), isNull);
  });
}
