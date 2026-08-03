import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_storage.dart';
import 'package:mobile/app/app_storage_codec.dart';
import 'package:mobile/features/recipe_book/domain/recipe_summary.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  const codec = AppStorageCodec();

  test('round-trips persisted recipe state', () {
    const snapshot = AppStorageSnapshot(
      recipes: [
        RecipeSummary(
          title: 'Curry',
          description: 'Fast dinner',
          duration: '35 min',
          yieldText: '4 servings',
          tags: ['Vegan'],
          isFavorite: true,
          document: RecipeDocument(
            prepRows: [
              PrepRow(text: 'Set out skillet'),
            ],
            columns: [
              WorkflowColumn(
                id: 'A',
                widthSpec: ColumnWidthSpec.fixed(120),
                cells: [
                  WorkflowCell(
                    startRow: 1,
                    rowSpan: 2,
                    columnSpan: 2,
                    text: 'cook\nserve',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      availableTags: ['Vegan'],
      matchAllTags: true,
    );

    final json = codec.snapshotToJson(snapshot);
    final roundTripped = codec.snapshotFromJson(json);

    expect(roundTripped.availableTags, ['Vegan']);
    expect(roundTripped.matchAllTags, isTrue);
    expect(roundTripped.recipes.single.title, 'Curry');
    expect(roundTripped.recipes.single.isFavorite, isTrue);

    final document = roundTripped.recipes.single.document;
    expect(document.prepRows.single.text, 'Set out skillet');
    final column = document.columns.single;
    expect(column.id, 'A');
    expect(column.widthSpec?.kind, ColumnWidthKind.fixed);
    expect(column.widthSpec?.logicalPixels, 120);
    final cell = column.cells.single;
    expect(cell.startRow, 1);
    expect(cell.rowSpan, 2);
    expect(cell.columnSpan, 2);
    expect(cell.text, 'cook\nserve');
  });

  test('uses safe defaults for missing optional persisted fields', () {
    final snapshot = codec.snapshotFromJson({
      'recipes': [
        {
          'title': 'Untimed recipe',
          'document': {
            'columns': [
              {
                'id': 'A',
                'cells': [
                  {'text': 'cell'},
                ],
              },
            ],
          },
        },
      ],
    });

    expect(snapshot.availableTags, isEmpty);
    expect(snapshot.matchAllTags, isFalse);
    final recipe = snapshot.recipes.single;
    expect(recipe.title, 'Untimed recipe');
    expect(recipe.description, '');
    expect(recipe.duration, '');
    expect(recipe.yieldText, '');
    expect(recipe.tags, isEmpty);
    expect(recipe.isFavorite, isFalse);

    final cell = recipe.document.columns.single.cells.single;
    expect(cell.startRow, 1);
    expect(cell.rowSpan, 1);
    expect(cell.columnSpan, 1);
    expect(cell.text, 'cell');
  });
}
