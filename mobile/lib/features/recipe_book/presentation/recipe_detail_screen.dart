import 'package:flutter/material.dart';

import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import 'recipe_editor_screen.dart';
import '../../recipe_document/presentation/recipe_chart_view.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  final RecipeSummary recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late RecipeSummary _recipe;
  bool _hasUnsyncedChanges = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  Future<void> _openEditor(BuildContext context) async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: _recipe,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    switch (result.action) {
      case RecipeEditorAction.save:
        if (result.recipe != null) {
          setState(() {
            _recipe = result.recipe!;
            _hasUnsyncedChanges = true;
          });
        }
        break;
      case RecipeEditorAction.delete:
        Navigator.of(context).pop(result);
        break;
    }
  }

  void _deleteRecipe(BuildContext context) {
    Navigator.of(context).pop(const RecipeEditorResult.deleted());
  }

  Future<bool> _handleBackNavigation() async {
    if (_hasUnsyncedChanges) {
      Navigator.of(context).pop(RecipeEditorResult.saved(_recipe));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = _recipe;

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          title: Text(recipe.title),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (recipe.isFavorite)
                          const Icon(Icons.favorite, color: Color(0xFFC96A3D)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5E675F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 6),
                            Text(recipe.duration),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_menu, size: 18),
                            const SizedBox(width: 6),
                            Text(recipe.yieldText),
                          ],
                        ),
                    ],
                  ),
                ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chart Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              RecipeChartView(document: recipe.document),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _deleteRecipe(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB33A2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
