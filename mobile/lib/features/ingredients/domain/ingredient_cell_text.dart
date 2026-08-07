import 'ingredient_product.dart';

String ingredientCellText({
  required IngredientProduct ingredient,
  required String recipeAmount,
}) {
  final amount = normalizedIngredientAmount(recipeAmount);
  if (amount.isEmpty) {
    return ingredient.name;
  }

  return '$amount${ingredient.baseUnit.storageValue} ${ingredient.name}';
}

String ingredientAmountText(IngredientProduct ingredient) {
  final amount = normalizedIngredientAmount(ingredient.amount);
  if (amount.isEmpty) {
    return '';
  }
  return '$amount ${ingredient.baseUnit.storageValue}';
}

String normalizedIngredientAmount(String recipeAmount) {
  final amount = recipeAmount.trim();
  if (amount.isEmpty) {
    return '';
  }

  final amountMatch = _amountWithOptionalUnitPattern.firstMatch(amount);
  if (amountMatch != null) {
    return _normalizedNumber(amountMatch.group(1)!);
  }

  return '';
}

String _normalizedNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.endsWith('.0')) {
    return normalized.substring(0, normalized.length - 2);
  }
  return normalized;
}

final _amountWithOptionalUnitPattern = RegExp(
  r'^(\d+(?:[,.]\d+)?)\s*(?:g|ml)?$',
  caseSensitive: false,
);
