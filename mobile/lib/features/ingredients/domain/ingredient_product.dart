class IngredientProduct {
  const IngredientProduct({
    required this.id,
    required this.name,
    required this.amount,
    required this.price,
    required this.store,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.baseUnit = IngredientBaseUnit.grams,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String amount;
  final String price;
  final String store;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final IngredientBaseUnit baseUnit;
  final List<String> tags;

  IngredientProduct copyWith({
    String? id,
    String? name,
    String? amount,
    String? price,
    String? store,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    IngredientBaseUnit? baseUnit,
    List<String>? tags,
  }) {
    return IngredientProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      store: store ?? this.store,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      baseUnit: baseUnit ?? this.baseUnit,
      tags: tags ?? this.tags,
    );
  }
}

enum IngredientBaseUnit {
  grams('g'),
  milliliters('ml');

  const IngredientBaseUnit(this.storageValue);

  final String storageValue;
}
