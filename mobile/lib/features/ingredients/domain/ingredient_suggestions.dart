import 'ingredient_product.dart';

IngredientProduct? suggestIngredientForCellText({
  required String cellText,
  required List<IngredientProduct> ingredients,
}) {
  final normalizedCellText = _normalize(cellText);
  if (normalizedCellText.isEmpty) {
    return null;
  }

  final cellTokens = _tokenize(normalizedCellText);
  if (cellTokens.isEmpty) {
    return null;
  }

  IngredientProduct? bestIngredient;
  var bestScore = 0;
  var bestScoreCount = 0;

  for (final ingredient in ingredients) {
    final score = _scoreIngredient(
      normalizedCellText: normalizedCellText,
      cellTokens: cellTokens,
      ingredient: ingredient,
    );

    if (score > bestScore) {
      bestIngredient = ingredient;
      bestScore = score;
      bestScoreCount = 1;
    } else if (score == bestScore && score > 0) {
      bestScoreCount += 1;
    }
  }

  if (bestScore < 20 || bestScoreCount > 1) {
    return null;
  }

  return bestIngredient;
}

int _scoreIngredient({
  required String normalizedCellText,
  required Set<String> cellTokens,
  required IngredientProduct ingredient,
}) {
  final normalizedName = _normalize(ingredient.name);
  if (normalizedName.isEmpty) {
    return 0;
  }

  var score = 0;
  if (normalizedCellText.contains(normalizedName)) {
    score += 100;
  }

  final nameTokens = _tokenize(normalizedName);
  for (final nameToken in nameTokens) {
    if (cellTokens.contains(nameToken)) {
      score += 20;
      continue;
    }

    if (cellTokens.any((cellToken) => _tokensLikelyMatch(cellToken, nameToken))) {
      score += 12;
    }
  }

  return score;
}

Set<String> _tokenize(String value) {
  return value
      .split(RegExp(r'\s+'))
      .map(_stripMeasurementToken)
      .where((token) => token.length >= 3 && !_ignoredTokens.contains(token))
      .toSet();
}

String _stripMeasurementToken(String token) {
  final withoutAmount = token.replaceFirst(
    RegExp(r'^\d+(?:[.,]\d+)?(?:g|kg|ml|l|el|tl|tbsp|tsp)?$'),
    '',
  );
  return withoutAmount;
}

bool _tokensLikelyMatch(String left, String right) {
  if (left == right) {
    return true;
  }

  final leftStem = _roughStem(left);
  final rightStem = _roughStem(right);
  return leftStem.length >= 4 && leftStem == rightStem;
}

String _roughStem(String value) {
  for (final suffix in const ['chen', 'ern', 'en', 'er', 'es', 'e', 'n', 's']) {
    if (value.length > suffix.length + 3 && value.endsWith(suffix)) {
      return value.substring(0, value.length - suffix.length);
    }
  }
  return value;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('\u00e4', 'ae')
      .replaceAll('\u00f6', 'oe')
      .replaceAll('\u00fc', 'ue')
      .replaceAll('\u00df', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

const _ignoredTokens = {
  'cup',
  'cups',
  'gram',
  'grams',
  'min',
  'minute',
  'minutes',
};
