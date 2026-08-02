import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/recipe_document/domain/chart_document_editor.dart';
import 'package:mobile/features/recipe_document/domain/recipe_document.dart';

void main() {
  test('moves a single cell into an empty neighboring slot', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'onion'),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 2, rowSpan: 1, text: 'onion');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 2,
    ).moveCellByDelta(
      columnId: 'A',
      cell: cell,
      rowDelta: -1,
      columnDelta: 0,
    );

    expect(result, isNotNull);
    expect(result!.selectedColumnId, 'A');
    expect(result.selectedStartRow, 1);
    expect(result.document.columns.single.cells.single.startRow, 1);
  });

  test('swaps with one non-empty target cell when moving vertically', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'top'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'bottom'),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 2, rowSpan: 1, text: 'bottom');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 2,
    ).moveCellByDelta(
      columnId: 'A',
      cell: cell,
      rowDelta: -1,
      columnDelta: 0,
    );

    expect(result, isNotNull);
    final cells = result!.document.columns.single.cells;
    expect(cells.firstWhere((cell) => cell.text == 'bottom').startRow, 1);
    expect(cells.firstWhere((cell) => cell.text == 'top').startRow, 2);
  });

  test('blocks a move that would displace multiple non-empty cells', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 2, rowSpan: 2, text: 'mix'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 2, rowSpan: 1, text: 'one'),
            WorkflowCell(startRow: 3, rowSpan: 1, text: 'two'),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 2, rowSpan: 2, text: 'mix');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 3,
    ).moveCellByDelta(
      columnId: 'A',
      cell: cell,
      rowDelta: 0,
      columnDelta: 1,
    );

    expect(result, isNull);
  });

  test('merges vertically and absorbs empty neighbor text only when present', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'flour'),
            WorkflowCell(startRow: 2, rowSpan: 1, text: ''),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 1, rowSpan: 1, text: 'flour');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 2,
    ).mergeCellDown('A', cell);

    expect(result, isNotNull);
    final merged = result!.document.columns.single.cells.single;
    expect(merged.startRow, 1);
    expect(merged.rowSpan, 2);
    expect(merged.text, 'flour');
  });

  test('blocks horizontal merge into non-empty neighboring cell', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'base'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'occupied'),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 1, rowSpan: 1, text: 'base');

    final editor = ChartDocumentEditor(document: document, workflowRowCount: 1);

    expect(editor.canMergeRight('A', cell), isFalse);
    expect(editor.mergeCellRight('A', cell), isNull);
  });

  test('merges horizontally into empty neighbor and preserves selection', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: 'base'),
          ],
        ),
        WorkflowColumn(
          id: 'B',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, text: ''),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 1, rowSpan: 1, text: 'base');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 1,
    ).mergeCellRight('A', cell);

    expect(result, isNotNull);
    expect(result!.selectedColumnId, 'A');
    expect(result.selectedStartRow, 1);
    final merged = result.document.columns.first.cells.single;
    expect(merged.columnSpan, 2);
    expect(merged.text, 'base');
    expect(result.document.columns[1].cells, isEmpty);
  });

  test('unmerge down removes top row from a vertical span', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 3, text: 'mix'),
          ],
        ),
      ],
    );
    const cell = WorkflowCell(startRow: 1, rowSpan: 3, text: 'mix');

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 3,
    ).unmergeCellDown('A', cell);

    expect(result, isNotNull);
    expect(result!.selectedColumnId, 'A');
    expect(result.selectedStartRow, 2);
    final updated = result.document.columns.single.cells.single;
    expect(updated.startRow, 2);
    expect(updated.rowSpan, 2);
  });

  test('unmerge right shifts remaining horizontal span into the next column', () {
    const document = RecipeDocument(
      prepRows: [],
      columns: [
        WorkflowColumn(
          id: 'A',
          cells: [
            WorkflowCell(startRow: 1, rowSpan: 1, columnSpan: 3, text: 'finish'),
          ],
        ),
        WorkflowColumn(id: 'B', cells: []),
        WorkflowColumn(id: 'C', cells: []),
      ],
    );
    const cell = WorkflowCell(
      startRow: 1,
      rowSpan: 1,
      columnSpan: 3,
      text: 'finish',
    );

    final result = ChartDocumentEditor(
      document: document,
      workflowRowCount: 1,
    ).unmergeCellRight('A', cell);

    expect(result, isNotNull);
    expect(result!.selectedColumnId, 'B');
    final shifted = result.document.columns[1].cells.single;
    expect(shifted.columnSpan, 2);
    expect(shifted.text, 'finish');
    expect(result.document.columns.first.cells, isEmpty);
  });
}
