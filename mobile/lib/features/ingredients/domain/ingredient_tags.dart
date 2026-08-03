const ingredientTagVegetables = 'vegetables';
const ingredientTagFruits = 'fruits';
const ingredientTagLegumes = 'legumes';
const ingredientTagGrains = 'grains';
const ingredientTagNutsSeeds = 'nuts_seeds';
const ingredientTagSpices = 'spices';
const ingredientTagSaucesPastes = 'sauces_pastes';
const ingredientTagOilsFats = 'oils_fats';
const ingredientTagCannedJarred = 'canned_jarred';

const defaultIngredientTags = [
  ingredientTagVegetables,
  ingredientTagFruits,
  ingredientTagLegumes,
  ingredientTagGrains,
  ingredientTagNutsSeeds,
  ingredientTagSpices,
  ingredientTagSaucesPastes,
  ingredientTagOilsFats,
  ingredientTagCannedJarred,
];

List<String> orderedIngredientTags(Iterable<String> tags) {
  final values = tags.toSet();
  final ordered = [
    for (final tag in defaultIngredientTags)
      if (values.remove(tag)) tag,
  ];
  final customTags = values.toList()
    ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
  return [...ordered, ...customTags];
}
