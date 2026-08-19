import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_storage_codec.dart';
import '../../../app/app_storage.dart';
import '../../../app/dev_flags.dart';
import '../../ingredients/data/dev_sample_ingredients.dart';
import '../../ingredients/domain/ingredient_cell_text.dart';
import '../../ingredients/domain/ingredient_product.dart';
import '../../ingredients/domain/ingredient_tags.dart';
import '../../ingredients/presentation/ingredient_editor_screen.dart';
import '../../ingredients/presentation/ingredient_tag_labels.dart';
import '../data/dev_sample_recipes.dart';
import '../domain/recipe_collection_filters.dart';
import '../domain/recipe_collection_mutations.dart';
import '../domain/recipe_ingredient_links.dart';
import '../domain/recipe_summary.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_result.dart';
import 'recipe_editor_screen.dart';
import 'widgets/collection_settings_sheet.dart';
import '../../recipe_document/domain/recipe_document.dart';
import '../../../l10n/app_localizations.dart';

class RecipeCollectionScreen extends StatefulWidget {
  const RecipeCollectionScreen({
    super.key,
    required this.localeOverride,
    required this.onLocaleChanged,
  });

  final Locale localeOverride;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<RecipeCollectionScreen> createState() => _RecipeCollectionScreenState();
}

class _RecipeCollectionScreenState extends State<RecipeCollectionScreen> {
  static const _storageCodec = AppStorageCodec();

  final List<RecipeSummary> _recipes = [];
  final List<IngredientProduct> _ingredients = [];
  final Set<String> _availableTags = {};
  final Set<String> _availableIngredientTags = {...defaultIngredientTags};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ingredientSearchController =
      TextEditingController();
  bool _showAllFilter = true;
  bool _showFavoritesFilter = false;
  bool _matchAllTags = false;
  bool _isLoadingState = true;
  final Set<String> _selectedTagFilters = {};
  final Set<String> _selectedIngredientTagFilters = {};
  String _searchQuery = '';
  String _ingredientSearchQuery = '';
  _CollectionTab _selectedTab = _CollectionTab.recipes;
  bool _useCompactRecipeCards = false;
  bool _useCompactIngredientCards = false;
  static const _deleteUndoDuration = Duration(seconds: 4);
  static const _deleteToastDismissBuffer = Duration(milliseconds: 500);
  int _deleteToastToken = 0;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    final snapshot = await AppStorage.instance.loadRecipeState();
    final productionSeedRecipes = await AppStorage.instance
        .loadProductionSeedRecipes();
    final seedRecipes = [
      ...productionSeedRecipes,
      if (kIsDevelopmentMode) ...devSampleRecipes,
    ];
    const seedIngredients = [
      if (kIsDevelopmentMode) ...devSampleIngredients,
    ];
    if (!mounted) {
      return;
    }

    setState(() {
      _recipes
        ..clear()
        ..addAll(snapshot?.recipes ?? seedRecipes);
      _ingredients
        ..clear()
        ..addAll(snapshot?.ingredients ?? seedIngredients);

      _availableTags
        ..clear()
        ..addAll(
          snapshot != null && snapshot.availableTags.isNotEmpty
              ? snapshot.availableTags
              : initialAvailableTags(_recipes),
        );
      _availableIngredientTags
        ..clear()
        ..addAll(defaultIngredientTags)
        ..addAll(snapshot?.availableIngredientTags ?? const [])
        ..addAll(_ingredients.expand((ingredient) => ingredient.tags));

      _matchAllTags = snapshot?.matchAllTags ?? false;
      _selectedTagFilters.removeWhere((tag) => !_availableTags.contains(tag));
      _selectedIngredientTagFilters.removeWhere(
        (tag) => !_availableIngredientTags.contains(tag),
      );
      _restoreAllIfNoSpecificFilters();
      _isLoadingState = false;
    });

    if (snapshot == null) {
      _persistState();
    }
  }

  Future<void> _resetToSeedState() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.resetToSeedTitle),
          content: Text(localizations.resetToSeedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations.resetToSeedLabel),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await AppStorage.instance.clearRecipeState();
    _searchController.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _showAllFilter = true;
      _showFavoritesFilter = false;
      _selectedTagFilters.clear();
      _selectedIngredientTagFilters.clear();
      _ingredientSearchQuery = '';
      _ingredientSearchController.clear();
      _isLoadingState = true;
    });

    await _loadPersistedState();
  }

  Future<void> _persistState() {
    return AppStorage.instance.saveRecipeState(
      AppStorageSnapshot(
        recipes: _recipes,
        availableTags: sortedTags(_availableTags),
        matchAllTags: _matchAllTags,
        ingredients: _ingredients,
        availableIngredientTags: sortedTags(_availableIngredientTags),
      ),
    );
  }

  Future<void> _deleteRecipeWithUndo({
    required int index,
    required RecipeSummary recipe,
  }) async {
    setState(() {
      _recipes.removeAt(index);
    });
    _persistState();

    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    messenger.hideCurrentSnackBar();
    final toastToken = ++_deleteToastToken;

    Future<void>.delayed(_deleteUndoDuration + _deleteToastDismissBuffer, () {
      if (!mounted || toastToken != _deleteToastToken) {
        return;
      }

      messenger.hideCurrentSnackBar();
    });

    final didUndo = await messenger
        .showSnackBar(
          SnackBar(
            duration: const Duration(minutes: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2A2C2A),
            content: _UndoToastContent(
              message: localizations.deletedMessage(recipe.title),
              duration: _deleteUndoDuration,
            ),
            action: SnackBarAction(label: localizations.undo, onPressed: () {}),
          ),
        )
        .closed;

    if (!mounted || didUndo != SnackBarClosedReason.action) {
      return;
    }

    setState(() {
      final safeIndex = index.clamp(0, _recipes.length);
      _recipes.insert(safeIndex, recipe);
    });
    _persistState();
  }

  Future<void> _openNewRecipeFlow() async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: RecipeSummary(
            title: '',
            description: '',
            duration: '',
            yieldText: '',
            document: RecipeDocument(
              prepRows: [],
              columns: [],
            ),
          ),
          availableTags: _availableTags.toList()..sort(),
          ingredients: _ingredients,
        ),
      ),
    );

    final newRecipe = result?.recipe;
    if (result == null ||
        result.action != RecipeEditorAction.save ||
        newRecipe == null) {
      return;
    }

    setState(() {
      _applyAvailableTags(result.availableTags);
      _recipes.insert(0, _sanitizeRecipeTags(newRecipe));
    });
    _persistState();
  }

  Future<void> _openRecipeForViewing(int index) async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: _recipes[index],
          availableTags: sortedTags(_availableTags),
          ingredients: _ingredients,
          onRecipeSaved: (result) => _saveExistingRecipe(
            index: index,
            result: result,
          ),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    switch (result.action) {
      case RecipeEditorAction.save:
        await _saveExistingRecipe(index: index, result: result);
        break;
      case RecipeEditorAction.delete:
        final recipe = _recipes[index];
        _deleteRecipeWithUndo(index: index, recipe: recipe);
        break;
    }
  }

  Future<void> _saveExistingRecipe({
    required int index,
    required RecipeEditorResult result,
  }) async {
    final recipe = result.recipe;
    if (recipe == null || index < 0 || index >= _recipes.length) {
      return;
    }

    final nextCollection = saveExistingRecipeInCollection(
      recipes: _recipes,
      availableTags: _availableTags,
      index: index,
      recipe: recipe,
      nextAvailableTags: result.availableTags,
    );

    setState(() {
      _availableTags
        ..clear()
        ..addAll(nextCollection.availableTags);
      _recipes
        ..clear()
        ..addAll(nextCollection.recipes);
    });
    await _persistState();
  }

  void _toggleRecipeFavorite(int index) {
    setState(() {
      final recipe = _recipes[index];
      _recipes[index] = recipe.copyWith(isFavorite: !recipe.isFavorite);
    });
    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    final recipeEntries = filteredRecipeEntries(
      recipes: _recipes,
      searchQuery: _searchQuery,
      showAllFilter: _showAllFilter,
      showFavoritesFilter: _showFavoritesFilter,
      matchAllTags: _matchAllTags,
      selectedTagFilters: _selectedTagFilters,
    );
    final ingredientEntries = _filteredIngredientEntries();
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openMenu,
            icon: const Icon(Icons.menu),
            tooltip: localizations.menuTooltip,
          ),
        ],
      ),
      body: _isLoadingState
          ? const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
                children: [
                  SegmentedButton<_CollectionTab>(
                    segments: [
                      ButtonSegment<_CollectionTab>(
                        value: _CollectionTab.recipes,
                        label: Text(localizations.recipesTabLabel),
                      ),
                      ButtonSegment<_CollectionTab>(
                        value: _CollectionTab.ingredients,
                        label: Text(localizations.ingredientsTabLabel),
                      ),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedTab = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTab == _CollectionTab.recipes)
                    _RecipeCollectionBody(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      recipeEntries: recipeEntries,
                      availableTags: _availableTags,
                      selectedTagFilters: _selectedTagFilters,
                      showAllFilter: _showAllFilter,
                      showFavoritesFilter: _showFavoritesFilter,
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      onToggleAll: _toggleAllFilter,
                      onToggleFavorites: _toggleFavoritesFilter,
                      onToggleTag: _toggleTagFilter,
                      onOpenRecipe: _openRecipeForViewing,
                      onToggleFavorite: _toggleRecipeFavorite,
                      useCompactCards: _useCompactRecipeCards,
                      onToggleCompactCards: () {
                        setState(() {
                          _useCompactRecipeCards = !_useCompactRecipeCards;
                        });
                      },
                    )
                  else
                    _IngredientCollectionBody(
                      searchController: _ingredientSearchController,
                      searchQuery: _ingredientSearchQuery,
                      ingredients: ingredientEntries,
                      availableTags: _availableIngredientTags,
                      selectedTagFilters: _selectedIngredientTagFilters,
                      onSearchChanged: (value) {
                        setState(() {
                          _ingredientSearchQuery = value.trim().toLowerCase();
                        });
                      },
                      onClearSearch: () {
                        _ingredientSearchController.clear();
                        setState(() {
                          _ingredientSearchQuery = '';
                        });
                      },
                      onToggleTag: _toggleIngredientTagFilter,
                      onEditIngredient: _openIngredientEditor,
                      onDeleteIngredient: _deleteIngredient,
                      useCompactCards: _useCompactIngredientCards,
                      onToggleCompactCards: () {
                        setState(() {
                          _useCompactIngredientCards =
                              !_useCompactIngredientCards;
                        });
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedTab == _CollectionTab.recipes
            ? _openNewRecipeFlow
            : () => _openIngredientEditor(null),
        icon: const Icon(Icons.add),
        label: Text(
          _selectedTab == _CollectionTab.recipes
              ? localizations.newRecipe
              : localizations.newIngredient,
        ),
      ),
    );
  }

  List<_IngredientEntry> _filteredIngredientEntries() {
    final query = _ingredientSearchQuery.trim().toLowerCase();
    final entries = <_IngredientEntry>[
      for (final entry in _ingredients.indexed)
        _IngredientEntry(index: entry.$1, ingredient: entry.$2),
    ];

    return entries.where((entry) {
      final ingredient = entry.ingredient;
      final matchesSearch = query.isEmpty ||
          [
            ingredient.name,
            ingredient.amount,
            ingredientAmountText(ingredient),
            ingredient.price,
            ingredient.store,
            ...ingredient.tags,
          ].any((value) => value.toLowerCase().contains(query));
      final matchesTags = _selectedIngredientTagFilters.isEmpty ||
          _selectedIngredientTagFilters.any(ingredient.tags.contains);
      return matchesSearch && matchesTags;
    }).toList();
  }

  void _toggleIngredientTagFilter(String tag) {
    setState(() {
      if (_selectedIngredientTagFilters.contains(tag)) {
        _selectedIngredientTagFilters.remove(tag);
      } else {
        _selectedIngredientTagFilters.add(tag);
      }
    });
  }

  Future<void> _openIngredientEditor(int? index) async {
    final result = await Navigator.of(context).push<IngredientProduct>(
      MaterialPageRoute(
        builder: (context) => IngredientEditorScreen(
          initialIngredient: index == null
              ? const IngredientProduct(
                  id: '',
                  name: '',
                  amount: '',
                  price: '',
                  store: '',
                  kcal: 0,
                  protein: 0,
                  carbs: 0,
                  fat: 0,
                )
              : _ingredients[index],
          availableTags: orderedIngredientTags(_availableIngredientTags),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _availableIngredientTags.addAll(result.tags);
      if (index == null) {
        _ingredients.insert(0, result);
      } else {
        _ingredients[index] = result;
        for (final entry in _recipes.indexed) {
          _recipes[entry.$1] = refreshIngredientReferenceText(entry.$2, result);
        }
      }
    });
    _persistState();
  }

  void _deleteIngredient(int index) {
    final ingredientId = _ingredients[index].id;
    setState(() {
      _ingredients.removeAt(index);
      for (final entry in _recipes.indexed) {
        _recipes[entry.$1] = clearIngredientReference(entry.$2, ingredientId);
      }
    });
    _persistState();
  }

  void _toggleAllFilter() {
    setState(() {
      _showAllFilter = true;
      _showFavoritesFilter = false;
      _selectedTagFilters.clear();
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      if (_showFavoritesFilter) {
        _showFavoritesFilter = false;
      } else {
        _showFavoritesFilter = true;
        _showAllFilter = false;
      }

      _restoreAllIfNoSpecificFilters();
    });
  }

  void _toggleTagFilter(String tag) {
    setState(() {
      if (_selectedTagFilters.contains(tag)) {
        _selectedTagFilters.remove(tag);
      } else {
        _selectedTagFilters.add(tag);
        _showAllFilter = false;
      }

      _restoreAllIfNoSpecificFilters();
    });
  }

  void _restoreAllIfNoSpecificFilters() {
    if (!_showFavoritesFilter && _selectedTagFilters.isEmpty) {
      _showAllFilter = true;
    } else {
      _showAllFilter = false;
    }
  }

  RecipeSummary _sanitizeRecipeTags(RecipeSummary recipe) {
    return sanitizeRecipeTags(
      recipe: recipe,
      availableTags: _availableTags,
    );
  }

  void _applyAvailableTags(List<String>? nextAvailableTags) {
    if (nextAvailableTags == null) {
      return;
    }

    _availableTags
      ..clear()
      ..addAll(
        nextAvailableTags.map(normalizeTag).where((tag) => tag.isNotEmpty),
      );

    for (var index = 0; index < _recipes.length; index++) {
      _recipes[index] = _sanitizeRecipeTags(_recipes[index]);
    }

    _selectedTagFilters.removeWhere((tag) => !_availableTags.contains(tag));
    _restoreAllIfNoSpecificFilters();
  }

  Future<void> _openMenu() async {
    final action = await showModalBottomSheet<CollectionMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return CollectionMenuSheet(
          onSelectAction: (action) => Navigator.of(context).pop(action),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case CollectionMenuAction.settings:
        await _openSettings();
        break;
      case CollectionMenuAction.tags:
        await _openTagsMenu();
        break;
      case CollectionMenuAction.backups:
        await _openBackupsMenu();
        break;
      case CollectionMenuAction.about:
        await _openAbout();
        break;
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return CollectionSettingsSheet(
          locale: widget.localeOverride,
          matchAllTags: _matchAllTags,
          showResetToSeed: kIsDevelopmentMode,
          onLocaleChanged: widget.onLocaleChanged,
          onMatchAllTagsChanged: (value) {
            setState(() {
              _matchAllTags = value;
            });
            _persistState();
          },
          onResetToSeed: _resetToSeedState,
        );
      },
    );
  }

  Future<void> _openTagsMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return CollectionTagsSheet(
          availableTagCountBuilder: () => _availableTags.length,
          onAddTag: _addGlobalTag,
          onOpenTagManager: _openDeleteTagManager,
        );
      },
    );
  }

  Future<void> _openBackupsMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return CollectionBackupsSheet(
          onBackupIngredients: _backupIngredientsToAppStorage,
          onExportIngredients: _exportIngredientsToFile,
          onImportIngredients: _chooseIngredientImportSource,
        );
      },
    );
  }

  Future<void> _openAbout() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const CollectionAboutSheet(),
    );
  }

  Future<void> _exportIngredientsToFile() async {
    final localizations = AppLocalizations.of(context);
    final fileName = _ingredientBackupFileName();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(_ingredientExportPayload(), flush: true);

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'application/json',
          name: fileName,
        ),
      ],
      subject: fileName,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.ingredientsExportedMessage)),
    );
  }

  Future<void> _backupIngredientsToAppStorage() async {
    final localizations = AppLocalizations.of(context);
    final file = await _ingredientAppBackupFile();
    await file.writeAsString(_ingredientExportPayload(), flush: true);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.ingredientsBackedUpMessage)),
    );
  }

  Future<void> _chooseIngredientImportSource() async {
    final localizations = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_IngredientImportSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(localizations.importIngredientsFromFileLabel),
                  subtitle: Text(
                    localizations.importIngredientsFromFileDescription,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_IngredientImportSource.file),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(localizations.importIngredientsFromBackupLabel),
                  subtitle: Text(
                    localizations.importIngredientsFromBackupDescription,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_IngredientImportSource.backup),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) {
      return;
    }

    switch (source) {
      case _IngredientImportSource.file:
        await _importIngredientsFromFile();
        break;
      case _IngredientImportSource.backup:
        await _importIngredientsFromAppBackup();
        break;
    }
  }

  Future<void> _importIngredientsFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    final path = result?.files.single.path;
    if (!mounted || path == null) {
      return;
    }

    try {
      await _importIngredientsFromRawJson(await File(path).readAsString());
    } catch (_) {
      if (!mounted) {
        return;
      }
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.ingredientsImportFailedMessage)),
      );
    }
  }

  Future<void> _importIngredientsFromAppBackup() async {
    final localizations = AppLocalizations.of(context);
    try {
      final file = await _ingredientAppBackupFile();
      if (!await file.exists()) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.ingredientsBackupMissingMessage),
          ),
        );
        return;
      }
      await _importIngredientsFromRawJson(await file.readAsString());
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.ingredientsImportFailedMessage)),
      );
    }
  }

  Future<void> _importIngredientsFromRawJson(String rawJson) async {
    final localizations = AppLocalizations.of(context);

    final imported = _parseIngredientImport(rawJson);
    if (imported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.ingredientsImportFailedMessage)),
      );
      return;
    }

    var addedCount = 0;
    var updatedCount = 0;
    final importedById = {
      for (final ingredient in imported.ingredients) ingredient.id: ingredient,
    };

    setState(() {
      for (var index = 0; index < _ingredients.length; index++) {
        final importedIngredient = importedById.remove(_ingredients[index].id);
        if (importedIngredient != null) {
          _ingredients[index] = importedIngredient;
          updatedCount += 1;
        }
      }

      _ingredients.addAll(importedById.values);
      addedCount = importedById.length;

      _availableIngredientTags
        ..addAll(imported.availableIngredientTags)
        ..addAll(imported.ingredients.expand((ingredient) => ingredient.tags));
    });
    await _persistState();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.ingredientsImportedMessage(addedCount, updatedCount),
        ),
      ),
    );
  }

  String _ingredientExportPayload() {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'recipeek.ingredients.v1',
      'ingredients': [
        for (final ingredient in _ingredients)
          _storageCodec.ingredientProductToJson(ingredient),
      ],
      'availableIngredientTags': sortedTags(_availableIngredientTags),
    });
  }

  String _ingredientBackupFileName() {
    final now = DateTime.now();
    final date = [
      now.year.toString().padLeft(4, '0'),
      now.month.toString().padLeft(2, '0'),
      now.day.toString().padLeft(2, '0'),
    ].join('-');
    return 'recipeek-ingredients-$date.json';
  }

  Future<File> _ingredientAppBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}recipeek-ingredients-backup.json',
    );
  }

  _IngredientImportPayload? _parseIngredientImport(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rawIngredients = decoded['ingredients'];
      if (rawIngredients is! List<dynamic>) {
        return null;
      }

      final ingredients = <IngredientProduct>[];
      for (final entry in rawIngredients) {
        if (entry is! Map<String, dynamic>) {
          return null;
        }

        final ingredient = _storageCodec.ingredientProductFromJson(entry);
        if (ingredient.id.trim().isEmpty || ingredient.name.trim().isEmpty) {
          return null;
        }
        ingredients.add(ingredient);
      }

      final availableIngredientTags =
          (decoded['availableIngredientTags'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map(normalizeTag)
              .where((tag) => tag.isNotEmpty)
              .toList();

      return _IngredientImportPayload(
        ingredients: ingredients,
        availableIngredientTags: availableIngredientTags,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDeleteTagManager() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return TagManagerSheet(
          availableTags: _availableTags,
          recipes: _recipes,
          tagLabelBuilder: _tagLabel,
          onRenameTag: _renameTag,
          onDeleteTag: _deleteTag,
        );
      },
    );
  }

  Future<bool> _addGlobalTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations.addTagTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: localizations.tagNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.discard),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(localizations.addTagLabel),
            ),
          ],
        );
      },
    );

    if (!mounted || tag == null || tag.isEmpty) {
      return false;
    }

    final normalizedTag = normalizeTag(tag);
    if (normalizedTag.isEmpty) {
      return false;
    }

    setState(() {
      _availableTags.add(normalizedTag);
    });
    _persistState();
    return true;
  }

  Future<bool> _deleteTag(String tag) async {
    final usageCount = _recipes
        .where((recipe) => recipe.tags.contains(tag))
        .length;

    if (usageCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final localizations = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(localizations.deleteTagTitle),
            content: Text(localizations.tagDeleteConfirmation(usageCount)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.discard),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(localizations.delete),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return false;
      }
    }

    setState(() {
      _availableTags.remove(tag);
      _selectedTagFilters.remove(tag);
      for (var index = 0; index < _recipes.length; index++) {
        _recipes[index] = _recipes[index].copyWith(
          tags: [
            for (final recipeTag in _recipes[index].tags)
              if (recipeTag != tag) recipeTag,
          ],
        );
      }
      _restoreAllIfNoSpecificFilters();
    });
    _persistState();

    return true;
  }

  Future<bool> _renameTag(String tag) async {
    final controller = TextEditingController(text: tag);
    final nextTag = await showDialog<String>(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text('${localizations.edit} ${localizations.tagsTitle}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: localizations.tagNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.deleteDialogCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );

    if (!mounted || nextTag == null) {
      return false;
    }

    final normalizedTag = normalizeTag(nextTag);
    if (normalizedTag.isEmpty || normalizedTag == tag) {
      return false;
    }

    setState(() {
      _availableTags.remove(tag);
      _availableTags.add(normalizedTag);

      if (_selectedTagFilters.remove(tag)) {
        _selectedTagFilters.add(normalizedTag);
      }

      for (var index = 0; index < _recipes.length; index++) {
        final updatedTags =
            <String>{
              for (final recipeTag in _recipes[index].tags)
                if (recipeTag == tag) normalizedTag else recipeTag,
            }.toList()..sort(
              (left, right) =>
                  left.toLowerCase().compareTo(right.toLowerCase()),
            );

        _recipes[index] = _recipes[index].copyWith(tags: updatedTags);
      }
    });
    _persistState();

    return true;
  }
}

enum _CollectionTab {
  recipes,
  ingredients,
}

class _IngredientImportPayload {
  const _IngredientImportPayload({
    required this.ingredients,
    required this.availableIngredientTags,
  });

  final List<IngredientProduct> ingredients;
  final List<String> availableIngredientTags;
}

enum _IngredientImportSource {
  file,
  backup,
}

class _IngredientEntry {
  const _IngredientEntry({required this.index, required this.ingredient});

  final int index;
  final IngredientProduct ingredient;
}

class _RecipeCollectionBody extends StatelessWidget {
  const _RecipeCollectionBody({
    required this.searchController,
    required this.searchQuery,
    required this.recipeEntries,
    required this.availableTags,
    required this.selectedTagFilters,
    required this.showAllFilter,
    required this.showFavoritesFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleAll,
    required this.onToggleFavorites,
    required this.onToggleTag,
    required this.onOpenRecipe,
    required this.onToggleFavorite,
    required this.useCompactCards,
    required this.onToggleCompactCards,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final List<RecipeEntry> recipeEntries;
  final Set<String> availableTags;
  final Set<String> selectedTagFilters;
  final bool showAllFilter;
  final bool showFavoritesFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleAll;
  final VoidCallback onToggleFavorites;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<int> onOpenRecipe;
  final ValueChanged<int> onToggleFavorite;
  final bool useCompactCards;
  final VoidCallback onToggleCompactCards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          controller: searchController,
          query: searchQuery,
          hintText: localizations.searchRecipes,
          onChanged: onSearchChanged,
          onClear: onClearSearch,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(localizations.allFilter),
              selected: showAllFilter,
              showCheckmark: false,
              onSelected: (_) => onToggleAll(),
            ),
            FilterChip(
              label: Semantics(
                label: localizations.favoritesFilter,
                child: Icon(
                  Icons.favorite,
                  size: 18,
                  color: showFavoritesFilter
                      ? theme.colorScheme.onPrimary
                      : const Color(0xFFC96A3D),
                ),
              ),
              selected: showFavoritesFilter,
              showCheckmark: false,
              onSelected: (_) => onToggleFavorites(),
            ),
            for (final tag in sortedTags(availableTags))
              FilterChip(
                label: Text(_tagLabel(context, tag)),
                selected: selectedTagFilters.contains(tag),
                showCheckmark: false,
                onSelected: (_) => onToggleTag(tag),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _CollectionSectionHeader(
          title: localizations.collectionTitle,
          useCompactCards: useCompactCards,
          onToggleCompactCards: onToggleCompactCards,
        ),
        const SizedBox(height: 12),
        for (final entry in recipeEntries) ...[
          _RecipeCard(
            recipe: entry.recipe,
            onTap: () => onOpenRecipe(entry.index),
            onToggleFavorite: () => onToggleFavorite(entry.index),
            isCompact: useCompactCards,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _IngredientCollectionBody extends StatelessWidget {
  const _IngredientCollectionBody({
    required this.searchController,
    required this.searchQuery,
    required this.ingredients,
    required this.availableTags,
    required this.selectedTagFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleTag,
    required this.onEditIngredient,
    required this.onDeleteIngredient,
    required this.useCompactCards,
    required this.onToggleCompactCards,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final List<_IngredientEntry> ingredients;
  final Set<String> availableTags;
  final Set<String> selectedTagFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<int> onEditIngredient;
  final ValueChanged<int> onDeleteIngredient;
  final bool useCompactCards;
  final VoidCallback onToggleCompactCards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          controller: searchController,
          query: searchQuery,
          hintText: localizations.searchIngredients,
          onChanged: onSearchChanged,
          onClear: onClearSearch,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in orderedIngredientTags(availableTags))
              FilterChip(
                label: Text(ingredientTagLabel(localizations, tag)),
                selected: selectedTagFilters.contains(tag),
                showCheckmark: false,
                onSelected: (_) => onToggleTag(tag),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _CollectionSectionHeader(
          title: localizations.ingredientsTitle,
          useCompactCards: useCompactCards,
          onToggleCompactCards: onToggleCompactCards,
        ),
        const SizedBox(height: 12),
        if (ingredients.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD7CCBE)),
            ),
            child: Text(
              localizations.noIngredientsPlaceholder,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E675F),
              ),
            ),
          )
        else
          for (final entry in ingredients) ...[
            _IngredientCard(
              ingredient: entry.ingredient,
              onTap: () => onEditIngredient(entry.index),
              onDelete: () => onDeleteIngredient(entry.index),
              isCompact: useCompactCards,
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CollectionSectionHeader extends StatelessWidget {
  const _CollectionSectionHeader({
    required this.title,
    required this.useCompactCards,
    required this.onToggleCompactCards,
  });

  final String title;
  final bool useCompactCards;
  final VoidCallback onToggleCompactCards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: onToggleCompactCards,
          icon: Icon(
            useCompactCards
                ? Icons.view_agenda_outlined
                : Icons.view_headline_outlined,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _UndoToastContent extends StatelessWidget {
  const _UndoToastContent({required this.message, required this.duration});

  final String message;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: duration,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: const Color(0xFF525652),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFC96A3D),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onToggleFavorite,
    required this.isCompact,
  });

  final RecipeSummary recipe;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationText = recipe.duration.trim();
    final yieldText = recipe.yieldText.trim();
    final hasDuration = durationText.isNotEmpty;
    final hasYield = yieldText.isNotEmpty;

    if (isCompact) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFC96A3D),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: const Color(0xFFC96A3D),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5E675F),
                ),
              ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in recipe.tags)
                      Chip(
                        label: Text(_tagLabel(context, tag)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (hasDuration || hasYield) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (hasDuration) ...[
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      Text(durationText),
                    ],
                    if (hasDuration && hasYield) const SizedBox(width: 16),
                    if (hasYield) ...[
                      const Icon(Icons.restaurant_menu, size: 18),
                      const SizedBox(width: 6),
                      Text(yieldText),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.ingredient,
    required this.onTap,
    required this.onDelete,
    required this.isCompact,
  });

  final IngredientProduct ingredient;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final amountText = ingredientAmountText(ingredient);
    final metadata = [
      if (amountText.isNotEmpty) amountText,
      if (ingredient.price.trim().isNotEmpty) ingredient.price.trim(),
      if (ingredient.store.trim().isNotEmpty) ingredient.store.trim(),
    ];

    if (isCompact) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ingredient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: localizations.delete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: localizations.delete,
                  ),
                ],
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metadata.join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E675F),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _MacroPill(
                    label: localizations.ingredientKcalLabel,
                    value: ingredient.kcal,
                  ),
                  _MacroPill(
                    label: localizations.ingredientProteinLabel,
                    value: ingredient.protein,
                  ),
                  _MacroPill(
                    label: localizations.ingredientCarbsLabel,
                    value: ingredient.carbs,
                  ),
                  _MacroPill(
                    label: localizations.ingredientFatLabel,
                    value: ingredient.fat,
                  ),
                ],
              ),
              if (ingredient.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in ingredient.tags)
                      Chip(
                        label: Text(ingredientTagLabel(localizations, tag)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Text('${_formatMacroValue(value)} $label');
  }
}

String _formatMacroValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _tagLabel(BuildContext context, String tag) {
  return tag;
}
