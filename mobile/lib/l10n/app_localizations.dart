import 'package:flutter/widgets.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static const supportedLocales = [Locale('en'), Locale('de')];

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
  String get editRecipe;
  String get searchRecipes;
  String get allFilter;
  String get favoritesFilter;
  String get breakfastFilter;
  String get bakingFilter;
  String get languageLabel;
  String get englishLanguage;
  String get germanLanguage;
  String get settingsTitle;
  String get settingsTooltip;
  String get resetToSeedLabel;
  String get resetToSeedDescription;
  String get resetToSeedTitle;
  String get resetToSeedMessage;
  String get tagsTitle;
  String get tagMatchingLabel;
  String get matchAnyLabel;
  String get matchAllLabel;
  String get matchAnySelectedTags;
  String get matchAllSelectedTags;
  String get addTagLabel;
  String get addTagTitle;
  String get editDeleteTagsLabel;
  String get deleteTagLabel;
  String get deleteTagTitle;
  String get tagsAvailableLabel;
  String get renameOrRemoveTags;
  String get removeTagsFromAllRecipes;
  String get noTagsAvailableToDelete;
  String get cancel;
  String get deleteDialogCancel;
  String get addDialogConfirm;
  String get delete;
  String get edit;
  String get save;
  String get discard;
  String get chartPreview;
  String get exportChartImage;
  String get shareChartImage;
  String get chartImageSaved;
  String get chartImageSaveFailed;
  String get chartPreviewLimitedTitle;
  String get chartPreviewLimitedMessage;
  String get chartPreviewUnavailable;
  String get timeTbd;
  String get yieldTbd;
  String get undo;
  String get tagNameHint;
  String get recipeTitleLabel;
  String get recipeTitleHint;
  String get recipeTitleRequired;
  String get yieldLabel;
  String get yieldHint;
  String get durationLabel;
  String get durationHint;
  String get notesLabel;
  String get notesHint;
  String get favoriteLabel;
  String get chartDslLabel;
  String get chartDslDescription;
  String get chartDslInfoBody;
  String get chartDslHint;
  String get newRecipeEditorHeadline;
  String get editRecipeEditorHeadline;
  String get editorIntroBody;
  String get createCell;
  String get editCell;
  String get deleteCell;
  String get moveUp;
  String get moveDown;
  String get mergeUp;
  String get mergeDown;
  String get mergeWithAbove;
  String get mergeWithBelow;
  String get unmerge;
  String get done;
  String get prepLabel;
  String get rowLabel;
  String get columnLabel;
  String get cellsLabel;
  String get addLabel;
  String get addColumnLabel;
  String get prepRowsTitle;
  String get workflowCellsTitle;
  String get noPrepRowsPlaceholder;
  String get noWorkflowColumnsPlaceholder;
  String get noCellsInColumnPlaceholder;
  String get addPrepRowTitle;
  String get editPrepRowTitle;
  String get prepRowHint;
  String get addCellTitle;
  String get cellTextHint;
  String get startRowLabel;
  String get endRowLabel;
  String get noMoreColumnLetters;
  String get optionalAdvancedEditing;
  String get createTopInstructionsHint;

  String deletedMessage(String title);
  String recipesCountLabel(int count);
  String tagsAvailableCountLabel(int count);
  String tagDeleteConfirmation(int count);
  String invalidRowRangeMessage(int maxRow);
  String overlappingRowRangeMessage(String columnId);
  String prepRowNumberLabel(int index);
  String singleRowLabel(int row);
  String rowRangeLabel(int startRow, int endRow);
  String chartStructureSummary(int prepRows, int workflowRows, int columns);
}

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  @override
  String get addCellTitle => 'Add Cell';

  @override
  String get addColumnLabel => 'Add Column';

  @override
  String get addDialogConfirm => 'Add';

  @override
  String get addLabel => 'Add';

  @override
  String get addPrepRowTitle => 'Add Prep Row';

  @override
  String get addTagLabel => 'Add Tag';

  @override
  String get addTagTitle => 'Add Tag';

  @override
  String get allFilter => 'All';

  @override
  String get appTitle => 'Recipeek';

  @override
  String get bakingFilter => 'Baking';

  @override
  String get breakfastFilter => 'Breakfast';

  @override
  String get cancel => 'Cancel';

  @override
  String get cellTextHint => 'Cell text';

  @override
  String get cellsLabel => 'Cells';

  @override
  String get chartDslDescription =>
      'Advanced text format for direct editing and recipe import/export.';

  @override
  String get chartDslInfoBody =>
      "DSL is the recipe's text format. Use it for direct editing, to paste or import recipes, or to copy and export a recipe as text.";

  @override
  String get chartDslHint =>
      'title: Chickpea Curry\ndescription: A weeknight chickpea curry with tomato, spinach, and warm spices.\nduration: 35 min\nyield: 4 servings\ntags: Vegan\n\nprep:\n- Set out a large skillet and a medium pot\n- Warm oil over medium heat\n\nA:\n1. 240 g rice\n2. 150 g onion\n\nB:\n1. rinse + boil\n2. dice';

  @override
  String get chartDslLabel => 'Chart DSL';

  @override
  String get chartPreview => 'Recipe Flow';

  @override
  String get exportChartImage => 'Export chart image';

  @override
  String get shareChartImage => 'Share chart image';

  @override
  String get chartImageSaved => 'Chart image saved';

  @override
  String get chartImageSaveFailed => 'Could not save chart image';

  @override
  String chartStructureSummary(int prepRows, int workflowRows, int columns) =>
      'Prep rows: $prepRows  |  Workflow rows: $workflowRows  |  Columns: $columns';

  @override
  String get chartPreviewLimitedMessage =>
      'This preview currently supports simple vertical spans only. More advanced chart behavior will come next.';

  @override
  String get chartPreviewLimitedTitle => 'Chart preview is currently limited.';

  @override
  String get chartPreviewUnavailable => 'Chart preview unavailable';

  @override
  String get collectionTitle => 'My Recipes';

  @override
  String get columnLabel => 'Column';

  @override
  String get createCell => 'Create Cell';

  @override
  String get createTopInstructionsHint =>
      'Add one to create the top instructions.';

  @override
  String deletedMessage(String title) => '$title deleted';

  @override
  String get delete => 'Delete';

  @override
  String get deleteCell => 'Delete Cell';

  @override
  String get deleteDialogCancel => 'Cancel';

  @override
  String get deleteTagLabel => 'Delete Tag';

  @override
  String get deleteTagTitle => 'Delete Tag';

  @override
  String get discard => 'Discard';

  @override
  String get done => 'Done';

  @override
  String get durationHint => '1 hr 20 min';

  @override
  String get durationLabel => 'Duration';

  @override
  String get edit => 'Edit';

  @override
  String get editCell => 'Edit Cell';

  @override
  String get editDeleteTagsLabel => 'Edit / delete tags';

  @override
  String get editPrepRowTitle => 'Edit Prep Row';

  @override
  String get editRecipeEditorHeadline =>
      'Edit the recipe visually and keep DSL as an advanced option.';

  @override
  String get englishLanguage => 'English';

  @override
  String get endRowLabel => 'End row';

  @override
  String get editorIntroBody =>
      'Use buttons to build prep rows, workflow rows, columns, and merged chart cells. The DSL stays available as a fallback.';

  @override
  String get favoriteLabel => 'Favorite';

  @override
  String get favoritesFilter => 'Favorites';

  @override
  String get germanLanguage => 'German';

  @override
  String invalidRowRangeMessage(int maxRow) =>
      'Rows must stay between 1 and $maxRow, and end row must be after start row.';

  @override
  String get languageLabel => 'Language';

  @override
  String get matchAllLabel => 'All';

  @override
  String get matchAllSelectedTags => 'Match all selected tags';

  @override
  String get matchAnyLabel => 'Any';

  @override
  String get matchAnySelectedTags => 'Match any selected tags';

  @override
  String get mergeDown => 'Merge Down';

  @override
  String get mergeUp => 'Merge Up';

  @override
  String get moveDown => 'Move Down';

  @override
  String get moveUp => 'Move Up';

  @override
  String get mergeWithAbove => 'Merge With Above';

  @override
  String get mergeWithBelow => 'Merge With Below';

  @override
  String get newRecipe => 'New Recipe';

  @override
  String get editRecipe => 'Edit Recipe';

  @override
  String get newRecipeEditorHeadline =>
      'Start visually and use DSL only when you want it.';

  @override
  String get noCellsInColumnPlaceholder => 'No cells in this column yet.';

  @override
  String get noMoreColumnLetters => 'No more column letters available.';

  @override
  String get noPrepRowsPlaceholder => 'No prep rows yet.';

  @override
  String get notesHint =>
      'Optional notes about the recipe before you build the workflow chart.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get noTagsAvailableToDelete => 'No tags available to delete.';

  @override
  String get noWorkflowColumnsPlaceholder =>
      'No workflow columns yet. Add a column to start placing cells.';

  @override
  String get optionalAdvancedEditing =>
      'Optional advanced editing and paste/import flow.';

  @override
  String overlappingRowRangeMessage(String columnId) =>
      'That row range overlaps another cell in column $columnId.';

  @override
  String get prepLabel => 'Prep';

  @override
  String get prepRowHint => 'Preheat oven';

  @override
  String prepRowNumberLabel(int index) => 'Prep row $index';

  @override
  String get prepRowsTitle => 'Prep Rows';

  @override
  String get recipeTitleHint => 'Banana Nut Bread';

  @override
  String get recipeTitleLabel => 'Recipe title';

  @override
  String get recipeTitleRequired => 'Enter a recipe title.';

  @override
  String recipesCountLabel(int count) => '$count recipes';

  @override
  String get removeTagsFromAllRecipes => 'Remove tags from all recipes';

  @override
  String get renameOrRemoveTags => 'Rename or remove tags';

  @override
  String rowRangeLabel(int startRow, int endRow) => 'Rows $startRow-$endRow';

  @override
  String get rowLabel => 'Row';

  @override
  String get save => 'Save';

  @override
  String get searchRecipes => 'Search recipes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get resetToSeedLabel => 'Reset to seed';

  @override
  String get resetToSeedDescription =>
      'Restore the initial example recipes and clear saved recipe state.';

  @override
  String get resetToSeedTitle => 'Reset to seed';

  @override
  String get resetToSeedMessage =>
      'This clears saved recipes, tags, and tag matching, then restores the seeded examples.';

  @override
  String singleRowLabel(int row) => 'Row $row';

  @override
  String get startRowLabel => 'Start row';

  @override
  String get tagMatchingLabel => 'Tag matching';

  @override
  String tagDeleteConfirmation(int count) =>
      'Tag used in $count recipes, delete?';

  @override
  String get tagNameHint => 'Dessert';

  @override
  String get tagsAvailableLabel => 'tags available';

  @override
  String tagsAvailableCountLabel(int count) => '$count tags available';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get timeTbd => 'Time TBD';

  @override
  String get undo => 'Undo';

  @override
  String get unmerge => 'Unmerge';

  @override
  String get workflowCellsTitle => 'Workflow Cells';

  @override
  String get yieldHint => '10 servings';

  @override
  String get yieldLabel => 'Yield';

  @override
  String get yieldTbd => 'Yield TBD';
}

class AppLocalizationsDe extends AppLocalizations {
  const AppLocalizationsDe();

  @override
  String get addCellTitle => 'Zelle hinzuf\u00fcgen';

  @override
  String get addColumnLabel => 'Spalte hinzuf\u00fcgen';

  @override
  String get addDialogConfirm => 'Hinzuf\u00fcgen';

  @override
  String get addLabel => 'Hinzuf\u00fcgen';

  @override
  String get addPrepRowTitle => 'Vorbereitungszeile hinzuf\u00fcgen';

  @override
  String get addTagLabel => 'Tag hinzuf\u00fcgen';

  @override
  String get addTagTitle => 'Tag hinzuf\u00fcgen';

  @override
  String get allFilter => 'Alle';

  @override
  String get appTitle => 'Recipeek';

  @override
  String get bakingFilter => 'Backen';

  @override
  String get breakfastFilter => 'Fr\u00fchst\u00fcck';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cellTextHint => 'Zellentext';

  @override
  String get cellsLabel => 'Zellen';

  @override
  String get chartDslDescription =>
      'Erweitertes Textformat f\u00fcr direkte Bearbeitung sowie Rezept-Import und -Export.';

  @override
  String get chartDslInfoBody =>
      'DSL ist das Textformat des Rezepts. Du kannst es f\u00fcr direkte Bearbeitung nutzen, um Rezepte einzuf\u00fcgen oder zu importieren, oder um ein Rezept als Text zu kopieren und zu exportieren.';

  @override
  String get chartDslHint =>
      'title: Kichererbsen-Curry aus der Pfanne\ndescription: Ein schnelles Kichererbsen-Curry mit Tomaten, Spinat und warmen Gew\u00fcrzen.\nduration: 35 min\nyield: 4 Portionen\ntags: Vegan\n\nprep:\n- Gro\u00dfe Pfanne und mittleren Topf bereitstellen\n- \u00d6l bei mittlerer Hitze erw\u00e4rmen\n\nA:\n1. 240 g Reis\n2. 150 g Zwiebel\n\nB:\n1. waschen + kochen\n2. w\u00fcrfeln';

  @override
  String get chartDslLabel => 'Chart-DSL';

  @override
  String get chartPreview => 'Rezeptablauf';

  @override
  String get exportChartImage => 'Diagramm als Bild exportieren';

  @override
  String get shareChartImage => 'Diagramm als Bild teilen';

  @override
  String get chartImageSaved => 'Diagramm als Bild gespeichert';

  @override
  String get chartImageSaveFailed => 'Diagramm konnte nicht gespeichert werden';

  @override
  String chartStructureSummary(int prepRows, int workflowRows, int columns) =>
      'Vorbereitung: $prepRows  |  Workflow-Zeilen: $workflowRows  |  Spalten: $columns';

  @override
  String get chartPreviewLimitedMessage =>
      'Diese Vorschau unterst\u00fctzt derzeit nur einfache vertikale Zellspannen. Erweiterteres Chart-Verhalten folgt als N\u00e4chstes.';

  @override
  String get chartPreviewLimitedTitle =>
      'Die Diagrammvorschau ist derzeit eingeschr\u00e4nkt.';

  @override
  String get chartPreviewUnavailable => 'Diagrammvorschau nicht verf\u00fcgbar';

  @override
  String get collectionTitle => 'Meine Rezepte';

  @override
  String get columnLabel => 'Spalte';

  @override
  String get createCell => 'Zelle erstellen';

  @override
  String get createTopInstructionsHint =>
      'F\u00fcge eine hinzu, um die oberen Anweisungen anzulegen.';

  @override
  String deletedMessage(String title) => '$title gel\u00f6scht';

  @override
  String get delete => 'L\u00f6schen';

  @override
  String get deleteCell => 'Zelle l\u00f6schen';

  @override
  String get deleteDialogCancel => 'Abbrechen';

  @override
  String get deleteTagLabel => 'Tag l\u00f6schen';

  @override
  String get deleteTagTitle => 'Tag l\u00f6schen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get done => 'Fertig';

  @override
  String get durationHint => '1 Std. 20 Min.';

  @override
  String get durationLabel => 'Dauer';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editCell => 'Zelle bearbeiten';

  @override
  String get editDeleteTagsLabel => 'Tags bearbeiten / l\u00f6schen';

  @override
  String get editPrepRowTitle => 'Vorbereitungszeile bearbeiten';

  @override
  String get editRecipeEditorHeadline =>
      'Bearbeite das Rezept visuell und nutze DSL nur bei Bedarf als erweiterte Option.';

  @override
  String get englishLanguage => 'Englisch';

  @override
  String get endRowLabel => 'Endzeile';

  @override
  String get editorIntroBody =>
      'Nutze die Buttons, um Vorbereitungszeilen, Workflow-Zeilen, Spalten und verbundene Chart-Zellen zu bauen. Die DSL bleibt als Fallback verf\u00fcgbar.';

  @override
  String get favoriteLabel => 'Favorit';

  @override
  String get favoritesFilter => 'Favoriten';

  @override
  String get germanLanguage => 'Deutsch';

  @override
  String invalidRowRangeMessage(int maxRow) =>
      'Zeilen m\u00fcssen zwischen 1 und $maxRow liegen, und die Endzeile muss nach der Startzeile kommen.';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get matchAllLabel => 'Alle';

  @override
  String get matchAllSelectedTags => 'Alle gew\u00e4hlten Tags treffen';

  @override
  String get matchAnyLabel => 'Beliebig';

  @override
  String get matchAnySelectedTags =>
      'Mindestens einen gew\u00e4hlten Tag treffen';

  @override
  String get mergeDown => 'Nach unten verbinden';

  @override
  String get mergeUp => 'Nach oben verbinden';

  @override
  String get moveDown => 'Nach unten verschieben';

  @override
  String get moveUp => 'Nach oben verschieben';

  @override
  String get mergeWithAbove => 'Mit oberer Zelle verbinden';

  @override
  String get mergeWithBelow => 'Mit unterer Zelle verbinden';

  @override
  String get newRecipe => 'Neues Rezept';

  @override
  String get editRecipe => 'Rezept bearbeiten';

  @override
  String get newRecipeEditorHeadline =>
      'Starte visuell und nutze DSL nur dann, wenn du es m\u00f6chtest.';

  @override
  String get noCellsInColumnPlaceholder =>
      'In dieser Spalte gibt es noch keine Zellen.';

  @override
  String get noMoreColumnLetters =>
      'Keine weiteren Spaltenbuchstaben verf\u00fcgbar.';

  @override
  String get noPrepRowsPlaceholder => 'Noch keine Vorbereitungszeilen.';

  @override
  String get notesHint =>
      'Optionale Notizen zum Rezept, bevor du den Workflow-Chart baust.';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get noTagsAvailableToDelete =>
      'Keine Tags zum L\u00f6schen verf\u00fcgbar.';

  @override
  String get noWorkflowColumnsPlaceholder =>
      'Noch keine Workflow-Spalten. F\u00fcge eine Spalte hinzu, um Zellen zu platzieren.';

  @override
  String get optionalAdvancedEditing =>
      'Optionale erweiterte Bearbeitung und Einf\u00fcgen/Import per DSL.';

  @override
  String overlappingRowRangeMessage(String columnId) =>
      'Dieser Zeilenbereich \u00fcberschneidet eine andere Zelle in Spalte $columnId.';

  @override
  String get prepLabel => 'Vorb.';

  @override
  String get prepRowHint => 'Ofen vorheizen';

  @override
  String prepRowNumberLabel(int index) => 'Vorbereitungszeile $index';

  @override
  String get prepRowsTitle => 'Vorbereitungszeilen';

  @override
  String get recipeTitleHint => 'Bananenbrot';

  @override
  String get recipeTitleLabel => 'Rezepttitel';

  @override
  String get recipeTitleRequired => 'Bitte einen Rezepttitel eingeben.';

  @override
  String recipesCountLabel(int count) => '$count Rezepte';

  @override
  String get removeTagsFromAllRecipes => 'Tags aus allen Rezepten entfernen';

  @override
  String get renameOrRemoveTags => 'Tags umbenennen oder l\u00f6schen';

  @override
  String rowRangeLabel(int startRow, int endRow) => 'Zeilen $startRow-$endRow';

  @override
  String get rowLabel => 'Zeile';

  @override
  String get save => 'Speichern';

  @override
  String get searchRecipes => 'Rezepte suchen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get resetToSeedLabel => 'Auf Seed zurücksetzen';

  @override
  String get resetToSeedDescription =>
      'Stellt die ursprünglichen Beispielrezepte wieder her und löscht den gespeicherten Rezeptzustand.';

  @override
  String get resetToSeedTitle => 'Auf Seed zurücksetzen';

  @override
  String get resetToSeedMessage =>
      'Dadurch werden gespeicherte Rezepte, Tags und der Tag-Abgleich gelöscht und die Beispielinhalte wiederhergestellt.';

  @override
  String singleRowLabel(int row) => 'Zeile $row';

  @override
  String get startRowLabel => 'Startzeile';

  @override
  String get tagMatchingLabel => 'Tag-Abgleich';

  @override
  String tagDeleteConfirmation(int count) =>
      'Tag wird in $count Rezepten verwendet, l\u00f6schen?';

  @override
  String get tagNameHint => 'Dessert';

  @override
  String get tagsAvailableLabel => 'Tags verf\u00fcgbar';

  @override
  String tagsAvailableCountLabel(int count) => '$count Tags verf\u00fcgbar';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get timeTbd => 'Zeit offen';

  @override
  String get undo => 'R\u00fcckg\u00e4ngig';

  @override
  String get unmerge => 'Verbindung aufheben';

  @override
  String get workflowCellsTitle => 'Workflow-Zellen';

  @override
  String get yieldHint => '10 Portionen';

  @override
  String get yieldLabel => 'Portionen';

  @override
  String get yieldTbd => 'Portionen offen';
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
