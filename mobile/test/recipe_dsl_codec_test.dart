import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/recipe_document/domain/recipe_dsl_codec.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  test('round-trips complete recipe metadata and chart structure', () {
    const source = '''
title: Chickpea Curry
description: Tomato curry with rice.
duration: 35 min
yield: 4 servings
tags: Vegan, Dinner
favorite: true

prep:
- Set out skillet
- Start rice pot

widths:
B: 120

A:
1. rice
2. onion
3. chickpeas

B-C:
1-2: start cooking

D:
1-3: finish curry
with rice
''';

    final parsed = RecipeDslCodec.parseRecipe(source: source);
    final encoded = RecipeDslCodec.encodeRecipe(parsed);
    final roundTripped = RecipeDslCodec.parseRecipe(source: encoded);

    expect(roundTripped.title, 'Chickpea Curry');
    expect(roundTripped.description, 'Tomato curry with rice.');
    expect(roundTripped.duration, '35 min');
    expect(roundTripped.yieldText, '4 servings');
    expect(roundTripped.tags, ['Vegan', 'Dinner']);
    expect(roundTripped.isFavorite, isTrue);
    expect(
      roundTripped.document.prepRows.map((row) => row.text),
      ['Set out skillet', 'Start rice pot'],
    );

    final columnB = roundTripped.document.columns.firstWhere(
      (column) => column.id == 'B',
    );
    expect(columnB.widthSpec?.kind, ColumnWidthKind.fixed);
    expect(columnB.widthSpec?.logicalPixels, 120);
    expect(columnB.cells.single.startRow, 1);
    expect(columnB.cells.single.rowSpan, 2);
    expect(columnB.cells.single.columnSpan, 2);
    expect(columnB.cells.single.text, 'start cooking');

    final columnD = roundTripped.document.columns.firstWhere(
      (column) => column.id == 'D',
    );
    expect(columnD.cells.single.rowSpan, 3);
    expect(columnD.cells.single.text, 'finish curry\nwith rice');
  });

  test('parses full recipe metadata and rectangular cells', () {
    final parsed = RecipeDslCodec.parseRecipe(
      source: '''
title: Lasagne high protein
description: Layered test recipe.
duration: 60 min
yield: 4 servings
tags: Vegan, Dinner, vegan
favorite: true

prep:
- Set out a pan

A:
1. noodles
2. sauce

B-C:
1-2: layer everything
''',
    );

    expect(parsed.title, 'Lasagne high protein');
    expect(parsed.description, 'Layered test recipe.');
    expect(parsed.duration, '60 min');
    expect(parsed.yieldText, '4 servings');
    expect(parsed.tags, ['Vegan', 'Dinner']);
    expect(parsed.isFavorite, isTrue);
    expect(parsed.document.prepRows.single.text, 'Set out a pan');
    expect(parsed.document.rowCount, 2);

    final spannedCell = parsed.document.columns
        .firstWhere((column) => column.id == 'B')
        .cells
        .single;
    expect(spannedCell.startRow, 1);
    expect(spannedCell.rowSpan, 2);
    expect(spannedCell.columnSpan, 2);
    expect(spannedCell.text, 'layer everything');
  });

  test('encodes fit widths as the default by omitting widths section', () {
    final encoded = RecipeDslCodec.encodeRecipe(
      RecipeDslData(
        title: 'Toast',
        description: '',
        duration: '',
        yieldText: '',
        tags: const [],
        isFavorite: false,
        document: const RecipeDocument(
          prepRows: [],
          columns: [
            WorkflowColumn(
              id: 'A',
              widthSpec: ColumnWidthSpec.fit(),
              cells: [
                WorkflowCell(startRow: 1, rowSpan: 1, text: 'bread'),
              ],
            ),
          ],
        ),
      ),
    );

    expect(encoded, isNot(contains('widths:')));
    expect(encoded, contains('A:\n1. bread'));
  });

  test('round-trips multiline cell text', () {
    final parsed = RecipeDslCodec.parseRecipe(
      source: '''
title: Multiline

A:
1-2: first paragraph

second paragraph
''',
    );

    final cell = parsed.document.columns.single.cells.single;
    expect(cell.text, 'first paragraph\n\nsecond paragraph');

    final encoded = RecipeDslCodec.encodeRecipe(parsed);
    expect(encoded, contains('1-2: first paragraph\n\nsecond paragraph'));
  });

  test('rejects overlapping rectangular spans', () {
    expect(
      () => RecipeDslCodec.parseRecipe(
        source: '''
A-B:
1-2: first

B:
2. overlap
''',
      ),
      throwsFormatException,
    );
  });
}
