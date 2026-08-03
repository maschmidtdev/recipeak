import '../../../l10n/app_localizations.dart';
import '../domain/ingredient_tags.dart';

String ingredientTagLabel(AppLocalizations localizations, String tag) {
  return switch (tag) {
    ingredientTagVegetables => localizations.ingredientTagVegetables,
    ingredientTagFruits => localizations.ingredientTagFruits,
    ingredientTagLegumes => localizations.ingredientTagLegumes,
    ingredientTagGrains => localizations.ingredientTagGrains,
    ingredientTagNutsSeeds => localizations.ingredientTagNutsSeeds,
    ingredientTagSpices => localizations.ingredientTagSpices,
    ingredientTagSaucesPastes => localizations.ingredientTagSaucesPastes,
    ingredientTagOilsFats => localizations.ingredientTagOilsFats,
    ingredientTagCannedJarred => localizations.ingredientTagCannedJarred,
    _ => tag,
  };
}
