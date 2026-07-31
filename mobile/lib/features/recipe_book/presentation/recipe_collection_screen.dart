import 'package:flutter/material.dart';

import '../../../app/dev_flags.dart';
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
  late final List<RecipeSummary> _recipes = List.of(_seedRecipes);
  final Set<String> _availableTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _showAllFilter = true;
  bool _showFavoritesFilter = false;
  bool _matchAllTags = false;
  final Set<String> _selectedTagFilters = {};
  String _searchQuery = '';
  static const _deleteUndoDuration = Duration(seconds: 4);
  static const _deleteToastDismissBuffer = Duration(milliseconds: 500);
  int _deleteToastToken = 0;

  @override
  void initState() {
    super.initState();
    if (_availableTags.isEmpty) {
      _availableTags.addAll(_initialAvailableTags(_recipes));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteRecipeWithUndo({
    required int index,
    required RecipeSummary recipe,
  }) async {
    setState(() {
      _recipes.removeAt(index);
    });

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
  }

  Future<void> _openNewRecipeFlow() async {
    final localizations = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: RecipeSummary(
            title: '',
            description: '',
            duration: '',
            yieldText: '',
            document: RecipeDocument(
              title: '',
              yieldText: localizations.yieldTbd,
              prepRows: [],
              columns: [],
              rowCount: 0,
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
  }

  Future<void> _openRecipeForViewing(int index) async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: _recipes[index],
          availableTags: _availableTags.toList()..sort(),
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
    final recipeEntries = _filteredRecipeEntries;
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
      body: SafeArea(
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
                for (final tag in _sortedTags(_availableTags))
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

  List<_RecipeEntry> get _filteredRecipeEntries {
    final entries = <_RecipeEntry>[
      for (final entry in _recipes.indexed)
        _RecipeEntry(index: entry.$1, recipe: entry.$2),
    ];

    final searchFilteredEntries = _searchQuery.isEmpty
        ? entries
        : entries.where((entry) => _matchesSearch(entry.recipe)).toList();

    if (_showAllFilter) {
      return searchFilteredEntries;
    }

    return searchFilteredEntries.where((entry) {
      final matchesFavorites = !_showFavoritesFilter || entry.recipe.isFavorite;
      final matchesTags = _selectedTagFilters.isEmpty
          ? true
          : (_matchAllTags
                ? _selectedTagFilters.every(entry.recipe.tags.contains)
                : _selectedTagFilters.any(entry.recipe.tags.contains));

      if (_matchAllTags) {
        return matchesFavorites && matchesTags;
      }

      return (_showFavoritesFilter && entry.recipe.isFavorite) ||
          (_selectedTagFilters.isNotEmpty &&
              _selectedTagFilters.any(entry.recipe.tags.contains));
    }).toList();
  }

  bool _matchesSearch(RecipeSummary recipe) {
    final haystacks = <String>[
      recipe.title,
      recipe.description,
      recipe.duration,
      recipe.yieldText,
      ...recipe.tags,
    ];

    return haystacks.any((value) => value.toLowerCase().contains(_searchQuery));
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
    return recipe.copyWith(
      tags: [
        for (final tag in recipe.tags)
          if (_availableTags.contains(tag)) tag,
      ],
    );
  }

  void _applyAvailableTags(List<String>? nextAvailableTags) {
    if (nextAvailableTags == null) {
      return;
    }

    _availableTags
      ..clear()
      ..addAll(
        nextAvailableTags.map(_normalizeTag).where((tag) => tag.isNotEmpty),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              value: Locale('en'),
                              child: Text(localizations.englishLanguage),
                            ),
                            DropdownMenuItem<Locale>(
                              value: Locale('de'),
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
            final tagUsage = _tagUsageCounts();
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
                            for (final tag in _sortedTags(_availableTags))
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

  Map<String, int> _tagUsageCounts() {
    final counts = <String, int>{};
    for (final tag in _availableTags) {
      counts[tag] = 0;
    }
    for (final recipe in _recipes) {
      for (final tag in recipe.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
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

    final normalizedTag = _normalizeTag(tag);
    if (normalizedTag.isEmpty) {
      return false;
    }

    setState(() {
      _availableTags.add(normalizedTag);
    });
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

    final normalizedTag = _normalizeTag(nextTag);
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

final _seedRecipes = List<RecipeSummary>.unmodifiable([
  ..._productionSampleRecipes,
  if (kIncludeDevSeedContent)
    ..._devSampleRecipes.where((recipe) => recipe.title != 'Banana Nut Bread'),
]);

const _productionSampleRecipes = [
  RecipeSummary(
    title: 'Skillet Chickpea Curry',
    description:
        'A realistic stovetop dinner with parallel aromatics, sauce reduction, and a final simmer.',
    duration: '35 min',
    yieldText: '4 servings',
    document: RecipeDocument(
      title: 'Skillet Chickpea Curry',
      yieldText: '4 servings',
      prepRows: [
        PrepRow(text: 'Set out a large skillet and a pot of rice'),
        PrepRow(text: 'Warm oil over medium heat'),
      ],
      columns: [
        WorkflowColumn(
          id: 'A',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'onion'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'garlic'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'curry paste'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'tomatoes'),
            WorkflowCell(startRow: 5, rowSpan: 1, text: 'chickpeas'),
            WorkflowCell(startRow: 6, rowSpan: 1, text: 'spinach'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'dice'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'mince'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'stir in'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'pour'),
            WorkflowCell(startRow: 5, rowSpan: 1, text: 'add'),
            WorkflowCell(startRow: 6, rowSpan: 1, text: 'fold in'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 3, text: 'cook until fragrant'),
            WorkflowCell(startRow: 4, rowSpan: 2, text: 'simmer gently'),
          ],
        ),
        WorkflowColumn(
          id: 'D',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 6, text: 'serve over rice'),
          ],
        ),
      ],
      rowCount: 6,
    ),
    isFavorite: true,
  ),
];

const _devSampleRecipes = [
  RecipeSummary(
    title: 'Overnight Oats',
    description:
        'A cold breakfast jar with layered prep and a quick morning finish.',
    duration: '',
    yieldText: '2 jars',
    document: RecipeDocument(
      title: 'Overnight Oats',
      yieldText: '2 jars',
      prepRows: [PrepRow(text: 'Set out two jars with lids')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'rolled oats'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'milk'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'berries'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'divide'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'pour'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'top'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 2, text: 'stir together'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'chill overnight'),
          ],
        ),
      ],
      rowCount: 3,
    ),
    tags: [recipeTagBreakfast],
  ),
  RecipeSummary(
    title: 'Tomato Toast',
    description:
        'A quick savory toast with almost no metadata except the core recipe.',
    duration: '',
    yieldText: '',
    document: RecipeDocument(
      title: 'Tomato Toast',
      yieldText: '',
      prepRows: [PrepRow(text: 'Toast two slices of bread')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'tomato'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'olive oil'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'slice'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'drizzle'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 2, text: 'finish with salt'),
          ],
        ),
      ],
      rowCount: 2,
    ),
    tags: [recipeTagBreakfast],
  ),
  RecipeSummary(
    title: 'Roasted Broccoli',
    description: 'A simple sheet-pan side dish with a clear timed workflow.',
    duration: '25 min',
    yieldText: '',
    document: RecipeDocument(
      title: 'Roasted Broccoli',
      yieldText: '',
      prepRows: [
        PrepRow(text: 'Heat oven to 425°F (220°C)'),
        PrepRow(text: 'Line a tray with parchment'),
      ],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'broccoli'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'olive oil'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'pepper'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'spread'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'coat'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'season'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 3, text: 'roast until browned'),
          ],
        ),
      ],
      rowCount: 3,
    ),
    tags: ['vegetarian'],
  ),
  RecipeSummary(
    title: 'Banana Nut Bread',
    description:
        'End-state reference chart with prep rows, ingredient columns, and merged workflow steps.',
    duration: '1 hr 20 min',
    yieldText: '10 servings',
    document: RecipeDocument(
      title: 'Banana Nut Bread',
      yieldText: '10 servings',
      prepRows: [
        PrepRow(text: 'Butter and flour a loaf pan'),
        PrepRow(text: 'Preheat oven to 350°F (170°C)'),
      ],
      columns: [
        WorkflowColumn(
          id: 'A',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: '2 ripe bananas'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: '6 Tbs. butter'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: '1 tsp. vanilla'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: '2 eggs'),
            WorkflowCell(startRow: 5, rowSpan: 1, text: '1 1/3 cups flour'),
            WorkflowCell(startRow: 6, rowSpan: 1, text: '2/3 cup sugar'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'mash'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'melt'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'stir in'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'lightly beat'),
            WorkflowCell(startRow: 5, rowSpan: 2, text: 'whisk'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 4, text: 'mash until smooth'),
          ],
        ),
        WorkflowColumn(
          id: 'D',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 6, text: 'fold everything'),
          ],
        ),
        WorkflowColumn(
          id: 'E',
          widthSpec: ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 6, text: 'bake 350°F\n55 min.'),
          ],
        ),
      ],
      rowCount: 6,
    ),
    tags: [recipeTagBaking],
    isFavorite: true,
  ),
];

class _RecipeEntry {
  const _RecipeEntry({required this.index, required this.recipe});

  final int index;
  final RecipeSummary recipe;
}

String _tagLabel(BuildContext context, String tag) {
  final localizations = AppLocalizations.of(context);
  return switch (tag) {
    recipeTagBreakfast => localizations.breakfastFilter,
    recipeTagBaking => localizations.bakingFilter,
    _ => tag,
  };
}

Set<String> _initialAvailableTags(List<RecipeSummary> recipes) {
  final tags = <String>{};
  for (final recipe in recipes) {
    tags.addAll(recipe.tags);
  }
  return tags;
}

List<String> _sortedTags(Iterable<String> tags) {
  final values = [...tags];
  values.sort(
    (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
  );
  return values;
}

String _normalizeTag(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}
