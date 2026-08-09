import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ingredients/domain/ingredient_product.dart';
import 'package:mobile/features/ingredients/domain/ingredient_suggestions.dart';

void main() {
  test('suggests ingredient from amount-prefixed cell text', () {
    final suggestion = suggestIngredientForCellText(
      cellText: '240g Chickpeas',
      ingredients: const [
        _onion,
        _chickpeas,
      ],
    );

    expect(suggestion, _chickpeas);
  });

  test('matches German umlaut variants', () {
    final suggestion = suggestIngredientForCellText(
      cellText: '1L Tomatenso\u00dfe',
      ingredients: const [
        _chickpeas,
        _tomatensosse,
      ],
    );

    expect(suggestion, _tomatensosse);
  });

  test('does not suggest when the best match is ambiguous', () {
    final suggestion = suggestIngredientForCellText(
      cellText: '200g Tomaten',
      ingredients: const [
        _tomatoes,
        _tomatoesOther,
      ],
    );

    expect(suggestion, isNull);
  });
}

const _chickpeas = IngredientProduct(
  id: 'chickpeas',
  name: 'Chickpeas',
  amount: '400',
  price: '',
  store: '',
  kcal: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
);

const _onion = IngredientProduct(
  id: 'onion',
  name: 'Onion',
  amount: '100',
  price: '',
  store: '',
  kcal: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
);

const _tomatensosse = IngredientProduct(
  id: 'tomatensosse',
  name: 'Tomatensosse',
  amount: '1000',
  price: '',
  store: '',
  kcal: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
);

const _tomatoes = IngredientProduct(
  id: 'tomatoes',
  name: 'Tomaten',
  amount: '400',
  price: '',
  store: '',
  kcal: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
);

const _tomatoesOther = IngredientProduct(
  id: 'tomatoes-other',
  name: 'Tomaten',
  amount: '1000',
  price: '',
  store: '',
  kcal: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
);
