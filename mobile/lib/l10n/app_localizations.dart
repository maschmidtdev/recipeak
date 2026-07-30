import 'package:flutter/widgets.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static const supportedLocales = [
    Locale('en'),
    Locale('de'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  String get appTitle;
  String get collectionTitle;
  String get newRecipe;
  String get searchRecipes;
  String get allFilter;
  String get favoritesFilter;
  String get breakfastFilter;
  String get bakingFilter;
  String get languageLabel;
  String get delete;
  String get edit;
  String get save;
  String get discard;
  String get chartPreview;
  String get timeTbd;
  String get yieldTbd;
  String get undo;

  String deletedMessage(String title);
}

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  @override
  String get allFilter => 'All';

  @override
  String get appTitle => 'Recipeak';

  @override
  String get bakingFilter => 'Baking';

  @override
  String get breakfastFilter => 'Breakfast';

  @override
  String get chartPreview => 'Chart Preview';

  @override
  String get collectionTitle => 'My Recipes';

  @override
  String get delete => 'Delete';

  @override
  String deletedMessage(String title) => '$title deleted';

  @override
  String get discard => 'Discard';

  @override
  String get edit => 'Edit';

  @override
  String get favoritesFilter => 'Favorites';

  @override
  String get languageLabel => 'Language';

  @override
  String get newRecipe => 'New Recipe';

  @override
  String get save => 'Save';

  @override
  String get searchRecipes => 'Search recipes';

  @override
  String get timeTbd => 'Time TBD';

  @override
  String get undo => 'Undo';

  @override
  String get yieldTbd => 'Yield TBD';
}

class AppLocalizationsDe extends AppLocalizations {
  const AppLocalizationsDe();

  @override
  String get allFilter => 'Alle';

  @override
  String get appTitle => 'Recipeak';

  @override
  String get bakingFilter => 'Backen';

  @override
  String get breakfastFilter => 'Frühstück';

  @override
  String get chartPreview => 'Diagrammvorschau';

  @override
  String get collectionTitle => 'Meine Rezepte';

  @override
  String get delete => 'Löschen';

  @override
  String deletedMessage(String title) => '$title gelöscht';

  @override
  String get discard => 'Verwerfen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get favoritesFilter => 'Favoriten';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get newRecipe => 'Neues Rezept';

  @override
  String get save => 'Speichern';

  @override
  String get searchRecipes => 'Rezepte suchen';

  @override
  String get timeTbd => 'Zeit offen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get yieldTbd => 'Menge offen';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'de':
        return const AppLocalizationsDe();
      case 'en':
      default:
        return const AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
