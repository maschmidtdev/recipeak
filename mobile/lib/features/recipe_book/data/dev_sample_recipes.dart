import '../domain/recipe_summary.dart';
import '../../recipe_document/domain/recipe_document.dart';

const devSampleRecipes = [
  RecipeSummary(
    title: 'Overnight Oats',
    description:
        'Creamy oats layered with milk and fruit for an easy make-ahead breakfast.',
    duration: '',
    yieldText: '2 jars',
    document: RecipeDocument(
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
    ),
    tags: ['Breakfast'],
  ),
  RecipeSummary(
    title: 'Tomato Toast',
    description:
        'Crisp toast topped with juicy tomato, olive oil, and a pinch of salt.',
    duration: '',
    yieldText: '',
    document: RecipeDocument(
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
    ),
    tags: ['Breakfast'],
  ),
  RecipeSummary(
    title: 'Roasted Broccoli',
    description:
        'Oven-roasted broccoli with crisp edges and a simple savory finish.',
    duration: '25 min',
    yieldText: '',
    document: RecipeDocument(
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
    ),
    tags: ['Vegetarian'],
  ),
  RecipeSummary(
    title: 'Banana Nut Bread',
    description:
        'A tender banana loaf with buttery crumb and a simple one-bowl bake flow.',
    duration: '1 hr 20 min',
    yieldText: '10 servings',
    document: RecipeDocument(
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
    ),
    tags: ['Baking'],
    isFavorite: true,
  ),
];
