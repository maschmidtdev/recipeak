import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/recipe_book/domain/recipe_collection_mutations.dart';
import 'package:mobile/features/recipe_book/domain/recipe_summary.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  const emptyDocument = RecipeDocument(prepRows: [], columns: []);
  const recipes = [
    RecipeSummary(
      title: 'Old Curry',
      description: 'Before edit',
      duration: '30 min',
      yieldText: '4 servings',
      document: emptyDocument,
      tags: ['Dinner'],
    ),
    RecipeSummary(
      title: 'Toast',
      description: '',
      duration: '',
      yieldText: '',
      document: emptyDocument,
      tags: ['Breakfast'],
    ),
  ];

  test('replaces an existing recipe immediately', () {
    const editedRecipe = RecipeSummary(
      title: 'Edited Curry',
      description: 'After edit',
      duration: '35 min',
      yieldText: '4 servings',
      document: emptyDocument,
      tags: ['Dinner'],
    );

    final result = saveExistingRecipeInCollection(
      recipes: recipes,
      availableTags: {'Dinner', 'Breakfast'},
      index: 0,
      recipe: editedRecipe,
    );

    expect(result.recipes.map((recipe) => recipe.title), [
      'Edited Curry',
      'Toast',
    ]);
    expect(result.availableTags, {'Dinner', 'Breakfast'});
  });

  test('uses editor tags and sanitizes all recipes against them', () {
    const editedRecipe = RecipeSummary(
      title: 'Edited Curry',
      description: '',
      duration: '',
      yieldText: '',
      document: emptyDocument,
      tags: ['Dinner', 'Vegan'],
    );

    final result = saveExistingRecipeInCollection(
      recipes: recipes,
      availableTags: {'Dinner', 'Breakfast'},
      index: 0,
      recipe: editedRecipe,
      nextAvailableTags: [' Vegan ', 'Dinner'],
    );

    expect(result.availableTags, {'Vegan', 'Dinner'});
    expect(result.recipes[0].tags, ['Dinner', 'Vegan']);
    expect(result.recipes[1].tags, isEmpty);
  });

  test('ignores invalid recipe index', () {
    const editedRecipe = RecipeSummary(
      title: 'Edited Curry',
      description: '',
      duration: '',
      yieldText: '',
      document: emptyDocument,
    );

    final result = saveExistingRecipeInCollection(
      recipes: recipes,
      availableTags: {'Dinner', 'Breakfast'},
      index: 5,
      recipe: editedRecipe,
    );

    expect(result.recipes, recipes);
    expect(result.availableTags, {'Dinner', 'Breakfast'});
  });
}
