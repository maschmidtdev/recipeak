import '../../ingredients/domain/ingredient_cell_text.dart';
import '../../ingredients/domain/ingredient_product.dart';
import '../../recipe_document/domain/recipe_document.dart';
import 'recipe_summary.dart';

class RecipeNutritionSummary {
  const RecipeNutritionSummary({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.cost,
    required this.servings,
    required this.missingItems,
  });

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double cost;
  final double? servings;
  final List<RecipeNutritionMissingItem> missingItems;

  bool get hasIncludedNutrition =>
      kcal > 0 || protein > 0 || carbs > 0 || fat > 0;

  bool get hasIncludedValues => hasIncludedNutrition || cost > 0;

  bool get isPartial => missingItems.isNotEmpty;
}

class RecipeNutritionMissingItem {
  const RecipeNutritionMissingItem({
    required this.label,
    required this.reason,
  });

  final String label;
  final RecipeNutritionMissingReason reason;
}

enum RecipeNutritionMissingReason {
  noLinkedIngredient,
  ingredientNotFound,
  missingAmount,
  missingNutrition,
  missingPackageAmount,
  missingPrice,
}

RecipeNutritionSummary calculateRecipeNutrition({
  required RecipeSummary recipe,
  required List<IngredientProduct> ingredients,
}) {
  final ingredientsById = {
    for (final ingredient in ingredients) ingredient.id: ingredient,
  };
  var kcal = 0.0;
  var protein = 0.0;
  var carbs = 0.0;
  var fat = 0.0;
  var cost = 0.0;
  final missingItems = <RecipeNutritionMissingItem>[];

  for (final cell in _ingredientCells(recipe.document)) {
    final label = cell.text.trim().isEmpty ? 'Row ${cell.startRow}' : cell.text;
    final ingredientId = cell.ingredientProductId;
    if (ingredientId == null) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: label,
          reason: RecipeNutritionMissingReason.noLinkedIngredient,
        ),
      );
      continue;
    }

    final ingredient = ingredientsById[ingredientId];
    if (ingredient == null) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: label,
          reason: RecipeNutritionMissingReason.ingredientNotFound,
        ),
      );
      continue;
    }

    final amount = _parseDecimal(
      normalizedIngredientAmount(cell.ingredientAmount),
    );
    if (amount == null || amount <= 0) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: ingredient.name,
          reason: RecipeNutritionMissingReason.missingAmount,
        ),
      );
      continue;
    }

    if (_hasNoNutritionData(ingredient)) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: ingredient.name,
          reason: RecipeNutritionMissingReason.missingNutrition,
        ),
      );
    } else {
      final factor = amount / 100;
      kcal += ingredient.kcal * factor;
      protein += ingredient.protein * factor;
      carbs += ingredient.carbs * factor;
      fat += ingredient.fat * factor;
    }

    final packageAmount = _parseDecimal(
      normalizedIngredientAmount(ingredient.amount),
    );
    if (packageAmount == null || packageAmount <= 0) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: ingredient.name,
          reason: RecipeNutritionMissingReason.missingPackageAmount,
        ),
      );
      continue;
    }

    final packagePrice = _parseDecimal(ingredient.price);
    if (packagePrice == null || packagePrice <= 0) {
      missingItems.add(
        RecipeNutritionMissingItem(
          label: ingredient.name,
          reason: RecipeNutritionMissingReason.missingPrice,
        ),
      );
      continue;
    }

    cost += packagePrice / packageAmount * amount;
  }

  return RecipeNutritionSummary(
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    cost: cost,
    servings: parseRecipeServings(recipe.yieldText),
    missingItems: missingItems,
  );
}

double? parseRecipeServings(String yieldText) {
  final text = yieldText.trim();
  if (text.isEmpty) {
    return null;
  }

  final rangeMatch = _servingRangePattern.firstMatch(text);
  if (rangeMatch != null) {
    final start = _parseDecimal(rangeMatch.group(1)!);
    final end = _parseDecimal(rangeMatch.group(2)!);
    if (start == null || end == null || start <= 0 || end <= 0) {
      return null;
    }
    return (start + end) / 2;
  }

  final numberMatch = _servingNumberPattern.firstMatch(text);
  if (numberMatch == null) {
    return null;
  }

  final servings = _parseDecimal(numberMatch.group(1)!);
  if (servings == null || servings <= 0) {
    return null;
  }
  return servings;
}

Iterable<WorkflowCell> _ingredientCells(RecipeDocument document) sync* {
  for (final column in document.columns) {
    if (column.id != 'A') {
      continue;
    }
    for (final cell in column.cells) {
      if (cell.text.trim().isNotEmpty) {
        yield cell;
      }
    }
  }
}

bool _hasNoNutritionData(IngredientProduct ingredient) {
  return ingredient.kcal == 0 &&
      ingredient.protein == 0 &&
      ingredient.carbs == 0 &&
      ingredient.fat == 0;
}

double? _parseDecimal(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

final _servingRangePattern = RegExp(
  r'(\d+(?:[,.]\d+)?)\s*[-\u2013]\s*(\d+(?:[,.]\d+)?)',
);

final _servingNumberPattern = RegExp(r'(\d+(?:[,.]\d+)?)');
