import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ingredients/domain/ingredient_number_input.dart';

void main() {
  test('allows empty optional ingredient numbers', () {
    expect(
      isValidOptionalIngredientNumber(
        '',
        rule: IngredientNumberRule.positive,
      ),
      isTrue,
    );
    expect(
      isValidOptionalIngredientNumber(
        '   ',
        rule: IngredientNumberRule.nonNegative,
      ),
      isTrue,
    );
  });

  test('accepts decimal numbers with dot or comma separators', () {
    expect(
      isValidOptionalIngredientNumber(
        '1.49',
        rule: IngredientNumberRule.positive,
      ),
      isTrue,
    );
    expect(
      isValidOptionalIngredientNumber(
        '1,49',
        rule: IngredientNumberRule.positive,
      ),
      isTrue,
    );
    expect(parseIngredientNumberInput('1,49'), 1.49);
  });

  test('rejects text, units, and negative values', () {
    for (final value in ['abc', '400 g', '-1']) {
      expect(
        isValidOptionalIngredientNumber(
          value,
          rule: IngredientNumberRule.positive,
        ),
        isFalse,
      );
    }
  });

  test('requires positive values for package amount and price', () {
    expect(
      isValidOptionalIngredientNumber(
        '0',
        rule: IngredientNumberRule.positive,
      ),
      isFalse,
    );
    expect(
      isValidOptionalIngredientNumber(
        '0.1',
        rule: IngredientNumberRule.positive,
      ),
      isTrue,
    );
  });

  test('allows zero values for nutrition macros', () {
    expect(
      isValidOptionalIngredientNumber(
        '0',
        rule: IngredientNumberRule.nonNegative,
      ),
      isTrue,
    );
    expect(
      isValidOptionalIngredientNumber(
        '-0.1',
        rule: IngredientNumberRule.nonNegative,
      ),
      isFalse,
    );
  });

  test('normalizes valid input before persistence', () {
    expect(normalizeIngredientNumberInput(' 400 '), '400');
    expect(normalizeIngredientNumberInput('1,49'), '1.49');
    expect(normalizeIngredientNumberInput('1.0'), '1');
  });
}
