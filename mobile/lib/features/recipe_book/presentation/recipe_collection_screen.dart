import 'package:flutter/material.dart';

import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import 'recipe_editor_screen.dart';
import '../../recipe_document/domain/recipe_document.dart';

class RecipeCollectionScreen extends StatefulWidget {
  const RecipeCollectionScreen({super.key});

  @override
  State<RecipeCollectionScreen> createState() => _RecipeCollectionScreenState();
}

class _RecipeCollectionScreenState extends State<RecipeCollectionScreen> {
  late final List<RecipeSummary> _recipes = List.of(_sampleRecipes);
  static const _deleteUndoDuration = Duration(seconds: 4);
  static const _deleteToastDismissBuffer = Duration(milliseconds: 500);
  int _deleteToastToken = 0;

  Future<void> _deleteRecipeWithUndo({
    required int index,
    required RecipeSummary recipe,
  }) async {
    setState(() {
      _recipes.removeAt(index);
    });

    final messenger = ScaffoldMessenger.of(context);
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
              message: '${recipe.title} deleted',
              duration: _deleteUndoDuration,
            ),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
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
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: const RecipeSummary(
            title: '',
            description: '',
            duration: 'Draft',
            yieldText: '',
            document: RecipeDocument(
              title: '',
              yieldText: '',
              prepRows: [],
              columns: [],
              rowCount: 0,
            ),
            isDraft: true,
          ),
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
      _recipes.insert(0, newRecipe);
    });
  }

  Future<void> _openEditorForRecipe(int index) async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: _recipes[index],
          allowDelete: true,
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
            _recipes[index] = recipe;
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
    final recipes = _recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipeak',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visual recipes, not walls of text.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Build and read recipes as workflow charts designed for phone screens.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFF3F8F5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes',
                prefixIcon: const Icon(Icons.search),
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
              children: const [
                Chip(label: Text('All')),
                Chip(label: Text('Favorites')),
                Chip(label: Text('Breakfast')),
                Chip(label: Text('Baking')),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'My Recipes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in recipes.indexed) ...[
              _RecipeCard(
                recipe: entry.$2,
                onTap: () => _openEditorForRecipe(entry.$1),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRecipeFlow,
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
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
  const _RecipeCard({required this.recipe, required this.onTap});

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  if (recipe.isDraft)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E0D1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Draft',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text(recipe.duration),
                  const SizedBox(width: 16),
                  const Icon(Icons.restaurant_menu, size: 18),
                  const SizedBox(width: 6),
                  Text(recipe.yieldText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _sampleRecipes = [
  RecipeSummary(
    title: 'Single Ingredient Flow',
    description:
        'First DSL example: one prep row, one ingredient row, and sequential workflow steps.',
    duration: '10 min',
    yieldText: '1 serving',
    document: RecipeDocument(
      title: 'Single Ingredient Flow',
      yieldText: '1 serving',
      prepRows: [PrepRow(text: 'Warm a small pan')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [WorkflowCell(startRow: 1, rowSpan: 1, text: '1 egg')],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [WorkflowCell(startRow: 1, rowSpan: 1, text: 'crack')],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [WorkflowCell(startRow: 1, rowSpan: 1, text: 'whisk')],
        ),
      ],
      rowCount: 1,
    ),
  ),
  RecipeSummary(
    title: 'Two Rows With Merge',
    description:
        'Second DSL example: two ingredient rows that merge into one final workflow step.',
    duration: '15 min',
    yieldText: '2 servings',
    document: RecipeDocument(
      title: 'Two Rows With Merge',
      yieldText: '2 servings',
      prepRows: [PrepRow(text: 'Set out a mixing bowl')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'flour'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'water'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'measure'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'pour'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [WorkflowCell(startRow: 1, rowSpan: 2, text: 'mix together')],
        ),
      ],
      rowCount: 2,
    ),
  ),
  RecipeSummary(
    title: 'Three Rows With Merge',
    description:
        'Third DSL example: three ingredient rows with one merge over rows 1-2 and another over rows 1-3.',
    duration: '20 min',
    yieldText: '3 servings',
    document: RecipeDocument(
      title: 'Three Rows With Merge',
      yieldText: '3 servings',
      prepRows: [PrepRow(text: 'Set out a large mixing bowl')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'flour'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'water'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'salt'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'measure'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'pour'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'sprinkle'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [WorkflowCell(startRow: 1, rowSpan: 2, text: 'mix wet base')],
        ),
        WorkflowColumn(
          id: 'D',
          cells: [WorkflowCell(startRow: 1, rowSpan: 3, text: 'combine fully')],
        ),
      ],
      rowCount: 3,
    ),
  ),
  RecipeSummary(
    title: 'Five Rows With Staged Merge',
    description:
        'Fourth DSL example: separate early rows, a later merged step, a mid-column merge, and a final merge spanning rows 1-5.',
    duration: '25 min',
    yieldText: '4 servings',
    document: RecipeDocument(
      title: 'Five Rows With Staged Merge',
      yieldText: '4 servings',
      prepRows: [PrepRow(text: 'Set out a prep tray and mixing bowl')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'bananas'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'butter'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'vanilla'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'flour'),
            WorkflowCell(startRow: 5, rowSpan: 1, text: 'sugar'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'mash'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'melt'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'stir in'),
            WorkflowCell(startRow: 4, rowSpan: 2, text: 'whisk dry'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [WorkflowCell(startRow: 1, rowSpan: 3, text: 'mix wet base')],
        ),
        WorkflowColumn(
          id: 'D',
          cells: [WorkflowCell(startRow: 1, rowSpan: 5, text: 'combine everything')],
        ),
      ],
      rowCount: 5,
    ),
  ),
  RecipeSummary(
    title: 'Six Rows With Full Finish Merge',
    description:
        'Fifth DSL example: an extra ingredient row, a taller early merge, and two full-height finishing columns.',
    duration: '30 min',
    yieldText: '5 servings',
    document: RecipeDocument(
      title: 'Six Rows With Full Finish Merge',
      yieldText: '5 servings',
      prepRows: [PrepRow(text: 'Set out a prep tray and loaf pan')],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'bananas'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'butter'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'vanilla'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'eggs'),
            WorkflowCell(startRow: 5, rowSpan: 1, text: 'flour'),
            WorkflowCell(startRow: 6, rowSpan: 1, text: 'sugar'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'mash'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'melt'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'stir in'),
            WorkflowCell(startRow: 4, rowSpan: 1, text: 'beat'),
            WorkflowCell(startRow: 5, rowSpan: 2, text: 'whisk dry'),
          ],
        ),
        WorkflowColumn(
          id: 'C',
          cells: [WorkflowCell(startRow: 1, rowSpan: 4, text: 'mix wet base')],
        ),
        WorkflowColumn(
          id: 'D',
          cells: [WorkflowCell(startRow: 1, rowSpan: 6, text: 'combine everything')],
        ),
        WorkflowColumn(
          id: 'E',
          cells: [WorkflowCell(startRow: 1, rowSpan: 6, text: 'finish loaf')],
        ),
      ],
      rowCount: 6,
    ),
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
        PrepRow(text: 'Preheat oven to 350Ã‚Â°F (170Ã‚Â°C)'),
      ],
      columns: [
        WorkflowColumn(
          id: 'A',
          widthSpec: const ColumnWidthSpec.fit(),
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
          widthSpec: const ColumnWidthSpec.fit(),
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
          widthSpec: const ColumnWidthSpec.fit(),
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
          widthSpec: const ColumnWidthSpec.fit(),
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 6, text: 'bake 350°F\n55 min.'),
          ],
        ),
      ],
      rowCount: 6,
    ),
    isFavorite: true,
  ),
];

