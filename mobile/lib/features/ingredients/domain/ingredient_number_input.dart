enum IngredientNumberRule {
  positive,
  nonNegative,
}

String normalizeIngredientNumberInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final parsed = parseIngredientNumberInput(trimmed);
  if (parsed == null) {
    return trimmed;
  }
  if (parsed == parsed.roundToDouble()) {
    return parsed.toInt().toString();
  }
  return parsed.toString();
}

double? parseIngredientNumberInput(String value) {
  final trimmed = value.trim();
  if (!_decimalPattern.hasMatch(trimmed)) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

bool isValidOptionalIngredientNumber(
  String value, {
  required IngredientNumberRule rule,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return true;
  }

  final parsed = parseIngredientNumberInput(trimmed);
  if (parsed == null) {
    return false;
  }

  return switch (rule) {
    IngredientNumberRule.positive => parsed > 0,
    IngredientNumberRule.nonNegative => parsed >= 0,
  };
}

final _decimalPattern = RegExp(r'^\d+(?:[,.]\d+)?$');
