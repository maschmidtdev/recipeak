import 'package:flutter/material.dart';

import '../../../app/app_storage.dart';
import '../../../app/dev_flags.dart';
import '../data/dev_sample_recipes.dart';
import '../domain/recipe_collection_filters.dart';
import '../domain/recipe_summary.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_result.dart';
import 'recipe_editor_screen.dart';
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
  final List<RecipeSummary> _recipes = [];
  final Set<String> _availableTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _showAllFilter = true;
  bool _showFavoritesFilter = false;
  bool _matchAllTags = false;
  bool _isLoadingState = true;
  final Set<String> _selectedTagFilters = {};
  String _searchQuery = '';
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
    if (!mounted) {
      return;
    }

    setState(() {
      _recipes
        ..clear()
        ..addAll(snapshot?.recipes ?? seedRecipes);

      _availableTags
        ..clear()
        ..addAll(
          snapshot != null && snapshot.availableTags.isNotEmpty
              ? snapshot.availableTags
              : initialAvailableTags(_recipes),
        );

      _matchAllTags = snapshot?.matchAllTags ?? false;
      _selectedTagFilters.removeWhere((tag) => !_availableTags.contains(tag));
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
        ),
      ),
    );

    if (result == null) {
      return;
    }

    switch (result.action) {
      case RecipeEditorAction.save:
        final recipe = result.recipe;
        if (recipe != null) {
          setState(() {
            _applyAvailableTags(result.availableTags);
            _recipes[index] = _sanitizeRecipeTags(recipe);
          });
          _persistState();
        }
        break;
      case RecipeEditorAction.delete:
        final recipe = _recipes[index];
        _deleteRecipeWithUndo(index: index, recipe: recipe);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeEntries = filteredRecipeEntries(
      recipes: _recipes,
      searchQuery: _searchQuery,
      showAllFilter: _showAllFilter,
      showFavoritesFilter: _showFavoritesFilter,
      matchAllTags: _matchAllTags,
      selectedTagFilters: _selectedTagFilters,
    );
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).appTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: localizations.settingsTooltip,
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
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: localizations.searchRecipes,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(localizations.allFilter),
                        selected: _showAllFilter,
                        showCheckmark: false,
                        onSelected: (_) => _toggleAllFilter(),
                      ),
                      FilterChip(
                        label: Text(localizations.favoritesFilter),
                        selected: _showFavoritesFilter,
                        showCheckmark: false,
                        onSelected: (_) => _toggleFavoritesFilter(),
                      ),
                      for (final tag in sortedTags(_availableTags))
                        FilterChip(
                          label: Text(_tagLabel(context, tag)),
                          selected: _selectedTagFilters.contains(tag),
                          showCheckmark: false,
                          onSelected: (_) => _toggleTagFilter(tag),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.collectionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in recipeEntries) ...[
                    _RecipeCard(
                      recipe: entry.recipe,
                      onTap: () => _openRecipeForViewing(entry.index),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRecipeFlow,
        icon: const Icon(Icons.add),
        label: Text(localizations.newRecipe),
      ),
    );
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

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kIsDevelopmentMode) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restart_alt),
                        title: Text(localizations.resetToSeedLabel),
                        subtitle: Text(localizations.resetToSeedDescription),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _resetToSeedState();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      localizations.settingsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.languageLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7CCBE)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Locale>(
                          value: widget.localeOverride,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(16),
                          items: [
                            DropdownMenuItem<Locale>(
                              value: const Locale('en'),
                              child: Text(localizations.englishLanguage),
                            ),
                            DropdownMenuItem<Locale>(
                              value: const Locale('de'),
                              child: Text(localizations.germanLanguage),
                            ),
                          ],
                          onChanged: (locale) {
                            if (locale != null) {
                              widget.onLocaleChanged(locale);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.tagsTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.tagMatchingLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(localizations.matchAnyLabel),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(localizations.matchAllLabel),
                        ),
                      ],
                      selected: {_matchAllTags},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _matchAllTags = selection.first;
                        });
                        _persistState();
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.add),
                      title: Text(localizations.addTagLabel),
                      subtitle: Text(
                        localizations.tagsAvailableCountLabel(
                          _availableTags.length,
                        ),
                      ),
                      onTap: () async {
                        final added = await _addGlobalTag();
                        if (added) {
                          setSheetState(() {});
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline),
                      title: Text(localizations.editDeleteTagsLabel),
                      subtitle: Text(localizations.renameOrRemoveTags),
                      onTap: () async {
                        await _openDeleteTagManager();
                        if (context.mounted) {
                          setSheetState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDeleteTagManager() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final localizations = AppLocalizations.of(context);
            final tagUsage = tagUsageCounts(
              availableTags: _availableTags,
              recipes: _recipes,
            );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizations.deleteTagTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_availableTags.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F3EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          localizations.noTagsAvailableToDelete,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5E675F)),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final tag in sortedTags(_availableTags))
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE3DACD),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(_tagLabel(context, tag)),
                                  subtitle: Text(
                                    localizations.recipesCountLabel(
                                      tagUsage[tag] ?? 0,
                                    ),
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final renamed = await _renameTag(tag);
                                          if (renamed) {
                                            setSheetState(() {});
                                          }
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: localizations.edit,
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          final deleted = await _deleteTag(tag);
                                          if (deleted) {
                                            setSheetState(() {});
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: localizations.delete,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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
  const _RecipeCard({required this.recipe, required this.onTap});

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationText = recipe.duration.trim();
    final yieldText = recipe.yieldText.trim();
    final hasDuration = durationText.isNotEmpty;
    final hasYield = yieldText.isNotEmpty;

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
                  if (recipe.isFavorite)
                    const Icon(Icons.favorite, color: Color(0xFFC96A3D)),
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

String _tagLabel(BuildContext context, String tag) {
  return tag;
}
