import 'recipe_document.dart';

class ChartDocumentEditResult {
  const ChartDocumentEditResult({
    required this.document,
    required this.selectedColumnId,
    required this.selectedStartRow,
  });

  final RecipeDocument document;
  final String selectedColumnId;
  final int selectedStartRow;
}

enum HorizontalMergeTextOrder {
  baseThenTarget,
  targetThenBase,
}

class ChartDocumentEditor {
  const ChartDocumentEditor({
    required this.document,
    required this.workflowRowCount,
  });

  final RecipeDocument document;
  final int workflowRowCount;

  String? nextColumnId() {
    for (var code = 65; code <= 90; code++) {
      final id = String.fromCharCode(code);
      if (!document.columns.any((column) => column.id == id)) {
        return id;
      }
    }
    return null;
  }

  RecipeDocument deleteColumn(String columnId) {
    final columns = [
      for (final column in document.columns)
        if (column.id != columnId) column,
    ];
    return document.copyWith(columns: columns);
  }

  RecipeDocument addColumn(String columnId) {
    return document.copyWith(
      columns: [
        ...document.columns,
        WorkflowColumn(id: columnId, cells: const []),
      ],
    );
  }

  bool canPlaceCell({
    required String columnId,
    required int startRow,
    required int endRow,
    WorkflowCell? excluding,
  }) {
    final column = document.columns.firstWhere((item) => item.id == columnId);
    for (final cell in column.cells) {
      if (sameCell(cell, excluding)) {
        continue;
      }
      final overlaps = rangesOverlap(startRow, endRow, cell.startRow, cell.endRow);
      if (overlaps) {
        return false;
      }
    }
    return true;
  }

  ChartDocumentEditResult replaceCell({
    required String columnId,
    required WorkflowCell oldCell,
    required WorkflowCell newCell,
  }) {
    final columns = [
      for (final column in document.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: _updatedCells(column.cells, oldCell, newCell),
          )
        else
          column,
    ];
    return ChartDocumentEditResult(
      document: document.copyWith(columns: columns),
      selectedColumnId: columnId,
      selectedStartRow: newCell.startRow,
    );
  }

  RecipeDocument upsertCell({
    required String columnId,
    WorkflowCell? existingCell,
    required WorkflowCell newCell,
  }) {
    final columns = [
      for (final column in document.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: _updatedCells(column.cells, existingCell, newCell),
          )
        else
          column,
    ];
    return document.copyWith(columns: columns);
  }

  RecipeDocument deleteCell({
    required String columnId,
    required WorkflowCell targetCell,
  }) {
    final columns = [
      for (final column in document.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final cell in column.cells)
                if (!sameCell(cell, targetCell)) cell,
            ],
          )
        else
          column,
    ];
    return document.copyWith(columns: columns);
  }

  ChartDocumentEditResult? moveCellByDelta({
    required String columnId,
    required WorkflowCell cell,
    required int rowDelta,
    required int columnDelta,
  }) {
    final movePlan = _rectangleMovePlan(
      columnId: columnId,
      cell: cell,
      rowDelta: rowDelta,
      columnDelta: columnDelta,
    );
    if (movePlan == null) {
      return null;
    }

    final movedCell = cell.copyWith(
      startRow: movePlan.targetStartRow,
    );
    WorkflowCell? displacedCell;
    final planDisplacedCell = movePlan.displacedCell;
    final displacedTargetStartRow = movePlan.displacedTargetStartRow;
    if (planDisplacedCell != null && displacedTargetStartRow != null) {
      displacedCell = planDisplacedCell.cell.copyWith(
        startRow: displacedTargetStartRow,
      );
    }

    final removedCells = [
      _AbsorbedWorkflowCell(columnId: columnId, cell: cell),
      ...movePlan.absorbedCells,
    ];

    final columns = [
      for (final column in document.columns)
        WorkflowColumn(
          id: column.id,
          widthSpec: column.widthSpec,
          cells: [
            for (final existing in column.cells)
              if (!removedCells.any(
                (entry) => sameColumnCell(
                  column.id,
                  existing,
                  entry.columnId,
                  entry.cell,
                ),
              ))
                existing,
            if (column.id == movePlan.targetColumnId) movedCell,
            if (displacedCell != null &&
                column.id == movePlan.displacedTargetColumnId)
              displacedCell,
          ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
        ),
    ];

    return ChartDocumentEditResult(
      document: document.copyWith(columns: columns),
      selectedColumnId: movePlan.targetColumnId,
      selectedStartRow: movePlan.targetStartRow,
    );
  }

  ChartDocumentEditResult? mergeCellUp(String columnId, WorkflowCell cell) {
    if (!canMergeUp(columnId, cell)) {
      return null;
    }
    final aboveCell = cellCoveringRow(columnId, cell.startRow - 1, excluding: cell);
    final newStartRow = aboveCell?.startRow ?? (cell.startRow - 1);
    return _mergeIntoRange(
      columnId: columnId,
      baseCell: cell,
      startRow: newStartRow,
      endRow: cell.endRow,
    );
  }

  ChartDocumentEditResult? mergeCellDown(String columnId, WorkflowCell cell) {
    if (!canMergeDown(columnId, cell)) {
      return null;
    }
    final belowCell = cellCoveringRow(columnId, cell.endRow + 1, excluding: cell);
    final newEndRow =
        belowCell == null ? cell.endRow + 1 : belowCell.endRow;
    return _mergeIntoRange(
      columnId: columnId,
      baseCell: cell,
      startRow: cell.startRow,
      endRow: newEndRow,
    );
  }

  ChartDocumentEditResult? mergeCellLeft(String columnId, WorkflowCell cell) {
    if (!canMergeLeft(columnId, cell)) {
      return null;
    }
    final targetColumnId = columnIdByOffset(columnId, -1);
    if (targetColumnId == null) {
      return null;
    }
    return _mergeIntoColumnRange(
      baseColumnId: columnId,
      targetColumnId: targetColumnId,
      baseCell: cell,
      textOrder: HorizontalMergeTextOrder.targetThenBase,
    );
  }

  ChartDocumentEditResult? mergeCellRight(String columnId, WorkflowCell cell) {
    if (!canMergeRight(columnId, cell)) {
      return null;
    }
    final targetColumnId = columnIdByOffset(columnId, cell.columnSpan);
    if (targetColumnId == null) {
      return null;
    }
    return _mergeIntoColumnRange(
      baseColumnId: columnId,
      targetColumnId: targetColumnId,
      baseCell: cell,
      textOrder: HorizontalMergeTextOrder.baseThenTarget,
    );
  }

  ChartDocumentEditResult? unmergeCell(String columnId, WorkflowCell cell) {
    if (cell.rowSpan == 1 && cell.columnSpan == 1) {
      return null;
    }
    return replaceCell(
      columnId: columnId,
      oldCell: cell,
      newCell: cell.copyWith(
        rowSpan: 1,
        columnSpan: 1,
      ),
    );
  }

  ChartDocumentEditResult? unmergeCellUp(String columnId, WorkflowCell cell) {
    if (!canUnmergeUp(cell)) {
      return null;
    }
    return replaceCell(
      columnId: columnId,
      oldCell: cell,
      newCell: cell.copyWith(
        rowSpan: cell.rowSpan - 1,
      ),
    );
  }

  ChartDocumentEditResult? unmergeCellDown(String columnId, WorkflowCell cell) {
    if (!canUnmergeDown(cell)) {
      return null;
    }
    return replaceCell(
      columnId: columnId,
      oldCell: cell,
      newCell: cell.copyWith(
        startRow: cell.startRow + 1,
        rowSpan: cell.rowSpan - 1,
      ),
    );
  }

  ChartDocumentEditResult? unmergeCellLeft(String columnId, WorkflowCell cell) {
    if (!canUnmergeLeft(cell)) {
      return null;
    }
    return replaceCell(
      columnId: columnId,
      oldCell: cell,
      newCell: cell.copyWith(
        columnSpan: cell.columnSpan - 1,
      ),
    );
  }

  ChartDocumentEditResult? unmergeCellRight(String columnId, WorkflowCell cell) {
    if (!canUnmergeRight(columnId, cell)) {
      return null;
    }
    final nextColumnId = columnIdByOffset(columnId, 1);
    if (nextColumnId == null) {
      return null;
    }

    final columns = [
      for (final column in document.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final existing in column.cells)
                if (!sameCell(existing, cell)) existing,
            ],
          )
        else if (column.id == nextColumnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              ...column.cells,
              cell.copyWith(
                columnSpan: cell.columnSpan - 1,
              ),
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else
          column,
    ];

    return ChartDocumentEditResult(
      document: document.copyWith(columns: columns),
      selectedColumnId: nextColumnId,
      selectedStartRow: cell.startRow,
    );
  }

  bool canMergeUp(String columnId, WorkflowCell cell) {
    if (cell.startRow <= 1) {
      return false;
    }
    final aboveCell = cellCoveringRow(columnId, cell.startRow - 1, excluding: cell);
    final newStartRow = aboveCell?.startRow ?? (cell.startRow - 1);
    return canAbsorbVerticalRange(
      columnId: columnId,
      cell: cell,
      startRow: newStartRow,
      endRow: cell.endRow,
    );
  }

  bool canMergeDown(String columnId, WorkflowCell cell) {
    if (cell.endRow >= workflowRowCount) {
      return false;
    }
    final belowCell = cellCoveringRow(columnId, cell.endRow + 1, excluding: cell);
    final newEndRow = belowCell == null ? cell.endRow + 1 : belowCell.endRow;
    return newEndRow <= workflowRowCount &&
        canAbsorbVerticalRange(
          columnId: columnId,
          cell: cell,
          startRow: cell.startRow,
          endRow: newEndRow,
        );
  }

  bool canMergeLeft(String columnId, WorkflowCell cell) {
    final targetColumnId = columnIdByOffset(columnId, -1);
    return targetColumnId != null &&
        canAbsorbHorizontalTargetColumn(
          targetColumnId: targetColumnId,
          cell: cell,
        );
  }

  bool canMergeRight(String columnId, WorkflowCell cell) {
    final targetColumnId = columnIdByOffset(columnId, cell.columnSpan);
    return targetColumnId != null &&
        canAbsorbHorizontalTargetColumn(
          targetColumnId: targetColumnId,
          cell: cell,
        );
  }

  bool canAbsorbHorizontalTargetColumn({
    required String targetColumnId,
    required WorkflowCell cell,
  }) {
    final targetColumn = document.columns.firstWhere(
      (column) => column.id == targetColumnId,
    );
    for (final targetCell in targetColumn.cells) {
      if (!rangesOverlap(
        cell.startRow,
        cell.endRow,
        targetCell.startRow,
        targetCell.endRow,
      )) {
        continue;
      }
      if (targetCell.text.trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  bool canAbsorbVerticalRange({
    required String columnId,
    required WorkflowCell cell,
    required int startRow,
    required int endRow,
  }) {
    for (final column in columnsInsideSpan(columnId, cell.columnSpan)) {
      for (final targetCell in column.cells) {
        if (column.id == columnId && sameCell(targetCell, cell)) {
          continue;
        }
        if (!rangesOverlap(startRow, endRow, targetCell.startRow, targetCell.endRow)) {
          continue;
        }
        if (targetCell.text.trim().isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  bool canMove({
    required String columnId,
    required WorkflowCell cell,
    required int rowDelta,
    required int columnDelta,
  }) {
    return _rectangleMovePlan(
          columnId: columnId,
          cell: cell,
          rowDelta: rowDelta,
          columnDelta: columnDelta,
        ) !=
        null;
  }

  bool canUnmergeUp(WorkflowCell cell) => cell.rowSpan > 1;

  bool canUnmergeDown(WorkflowCell cell) => cell.rowSpan > 1;

  bool canUnmergeLeft(WorkflowCell cell) => cell.columnSpan > 1;

  bool canUnmergeRight(String columnId, WorkflowCell cell) {
    return cell.columnSpan > 1 && columnIdByOffset(columnId, 1) != null;
  }

  String? columnIdByOffset(String columnId, int offset) {
    final columnIds = document.columns.map((column) => column.id).toList();
    final index = columnIds.indexOf(columnId);
    if (index < 0) {
      return null;
    }
    final nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= columnIds.length) {
      return null;
    }
    return columnIds[nextIndex];
  }

  WorkflowCell? cellCoveringRow(
    String columnId,
    int row, {
    WorkflowCell? excluding,
  }) {
    final column = document.columns.firstWhere((item) => item.id == columnId);
    for (final cell in column.cells) {
      if (sameCell(cell, excluding)) {
        continue;
      }
      if (row >= cell.startRow && row <= cell.endRow) {
        return cell;
      }
    }
    return null;
  }

  Iterable<WorkflowColumn> columnsInsideSpan(String columnId, int columnSpan) {
    final startIndex = columnIndex(columnId);
    if (startIndex < 0) {
      return const [];
    }
    final endIndex = startIndex + columnSpan - 1;
    return [
      for (var index = startIndex;
          index < document.columns.length && index <= endIndex;
          index++)
        document.columns[index],
    ];
  }

  bool columnIsInsideSpan(
    String startColumnId,
    int columnSpan,
    String targetColumnId,
  ) {
    final startIndex = columnIndex(startColumnId);
    final targetIndex = columnIndex(targetColumnId);
    return startIndex >= 0 &&
        targetIndex >= startIndex &&
        targetIndex <= startIndex + columnSpan - 1;
  }

  _RectangleMovePlan? _rectangleMovePlan({
    required String columnId,
    required WorkflowCell cell,
    required int rowDelta,
    required int columnDelta,
  }) {
    final sourceColumnIndex = columnIndex(columnId);
    if (sourceColumnIndex < 0) {
      return null;
    }
    var targetColumnIndex = sourceColumnIndex + columnDelta;
    var targetStartRow = cell.startRow + rowDelta;
    if (!rectIsInBounds(
      columnIndex: targetColumnIndex,
      columnSpan: cell.columnSpan,
      startRow: targetStartRow,
      rowSpan: cell.rowSpan,
    )) {
      return null;
    }
    final sourceEntry = _AbsorbedWorkflowCell(columnId: columnId, cell: cell);
    var targetColumnId = document.columns[targetColumnIndex].id;
    var targetIntersections = _cellsIntersectingRect(
      startColumnId: targetColumnId,
      columnSpan: cell.columnSpan,
      startRow: targetStartRow,
      endRow: targetStartRow + cell.rowSpan - 1,
      excludingColumnId: columnId,
      excludingCell: cell,
    );
    var nonEmptyTargetIntersections = [
      for (final entry in targetIntersections)
        if (entry.cell.text.trim().isNotEmpty) entry,
    ];
    if (nonEmptyTargetIntersections.length > 1) {
      return null;
    }
    final displacedCell = nonEmptyTargetIntersections.isEmpty
        ? null
        : nonEmptyTargetIntersections.single;

    if (displacedCell != null) {
      final displacedColumnIndex = columnIndex(displacedCell.columnId);
      if (displacedColumnIndex < 0) {
        return null;
      }
      if (rowDelta < 0) {
        targetStartRow = displacedCell.cell.startRow;
      } else if (rowDelta > 0) {
        targetStartRow = displacedCell.cell.endRow - cell.rowSpan + 1;
      }
      if (columnDelta < 0) {
        targetColumnIndex = displacedColumnIndex;
      } else if (columnDelta > 0) {
        targetColumnIndex =
            displacedColumnIndex + displacedCell.cell.columnSpan - cell.columnSpan;
      }
      if (!rectIsInBounds(
        columnIndex: targetColumnIndex,
        columnSpan: cell.columnSpan,
        startRow: targetStartRow,
        rowSpan: cell.rowSpan,
      )) {
        return null;
      }
      targetColumnId = document.columns[targetColumnIndex].id;
      targetIntersections = _cellsIntersectingRect(
        startColumnId: targetColumnId,
        columnSpan: cell.columnSpan,
        startRow: targetStartRow,
        endRow: targetStartRow + cell.rowSpan - 1,
        excludingColumnId: columnId,
        excludingCell: cell,
      );
      nonEmptyTargetIntersections = [
        for (final entry in targetIntersections)
          if (entry.cell.text.trim().isNotEmpty) entry,
      ];
      if (nonEmptyTargetIntersections.length != 1 ||
          !sameColumnCell(
            nonEmptyTargetIntersections.single.columnId,
            nonEmptyTargetIntersections.single.cell,
            displacedCell.columnId,
            displacedCell.cell,
          )) {
        return null;
      }
    }

    final absorbedCells = <_AbsorbedWorkflowCell>[...targetIntersections];
    String? displacedTargetColumnId;
    int? displacedTargetStartRow;

    if (displacedCell != null) {
      var displacedTargetColumnIndex = sourceColumnIndex;
      var resolvedDisplacedTargetStartRow = cell.startRow;
      if (rowDelta < 0) {
        resolvedDisplacedTargetStartRow = targetStartRow + cell.rowSpan;
      } else if (rowDelta > 0) {
        resolvedDisplacedTargetStartRow =
            targetStartRow - displacedCell.cell.rowSpan;
      }
      if (columnDelta < 0) {
        displacedTargetColumnIndex = targetColumnIndex + cell.columnSpan;
      } else if (columnDelta > 0) {
        displacedTargetColumnIndex =
            targetColumnIndex - displacedCell.cell.columnSpan;
      }
      if (!rectIsInBounds(
        columnIndex: displacedTargetColumnIndex,
        columnSpan: displacedCell.cell.columnSpan,
        startRow: resolvedDisplacedTargetStartRow,
        rowSpan: displacedCell.cell.rowSpan,
      )) {
        return null;
      }
      final resolvedDisplacedTargetColumnId =
          document.columns[displacedTargetColumnIndex].id;
      displacedTargetColumnId = resolvedDisplacedTargetColumnId;
      displacedTargetStartRow = resolvedDisplacedTargetStartRow;
      if (rectanglesOverlap(
        leftColumnId: targetColumnId,
        leftCell: WorkflowCell(
          startRow: targetStartRow,
          rowSpan: cell.rowSpan,
          columnSpan: cell.columnSpan,
          text: cell.text,
        ),
        rightColumnId: resolvedDisplacedTargetColumnId,
        rightCell: WorkflowCell(
          startRow: resolvedDisplacedTargetStartRow,
          rowSpan: displacedCell.cell.rowSpan,
          columnSpan: displacedCell.cell.columnSpan,
          text: displacedCell.cell.text,
        ),
      )) {
        return null;
      }
      final displacedTargetIntersections = _cellsIntersectingRect(
        startColumnId: resolvedDisplacedTargetColumnId,
        columnSpan: displacedCell.cell.columnSpan,
        startRow: resolvedDisplacedTargetStartRow,
        endRow: resolvedDisplacedTargetStartRow + displacedCell.cell.rowSpan - 1,
        excludingColumnId: columnId,
        excludingCell: cell,
      );
      for (final entry in displacedTargetIntersections) {
        if (sameColumnCell(
          entry.columnId,
          entry.cell,
          displacedCell.columnId,
          displacedCell.cell,
        )) {
          continue;
        }
        if (entry.cell.text.trim().isNotEmpty) {
          return null;
        }
        absorbedCells.add(entry);
      }
    }

    return _RectangleMovePlan(
      targetColumnId: targetColumnId,
      targetStartRow: targetStartRow,
      absorbedCells: _dedupeAbsorbedCells(absorbedCells, except: sourceEntry),
      displacedCell: displacedCell,
      displacedTargetColumnId: displacedTargetColumnId,
      displacedTargetStartRow: displacedTargetStartRow,
    );
  }

  List<_AbsorbedWorkflowCell> _cellsIntersectingRect({
    required String startColumnId,
    required int columnSpan,
    required int startRow,
    required int endRow,
    String? excludingColumnId,
    WorkflowCell? excludingCell,
  }) {
    final entries = <_AbsorbedWorkflowCell>[];
    final queryCell = WorkflowCell(
      startRow: startRow,
      rowSpan: endRow - startRow + 1,
      columnSpan: columnSpan,
      text: '',
    );
    for (final column in document.columns) {
      for (final cell in column.cells) {
        if (excludingColumnId != null &&
            column.id == excludingColumnId &&
            sameCell(cell, excludingCell)) {
          continue;
        }
        if (rectanglesOverlap(
          leftColumnId: startColumnId,
          leftCell: queryCell,
          rightColumnId: column.id,
          rightCell: cell,
        )) {
          entries.add(_AbsorbedWorkflowCell(columnId: column.id, cell: cell));
        }
      }
    }
    return entries;
  }

  bool rectanglesOverlap({
    required String leftColumnId,
    required WorkflowCell leftCell,
    required String rightColumnId,
    required WorkflowCell rightCell,
  }) {
    final leftColumnIndex = columnIndex(leftColumnId);
    final rightColumnIndex = columnIndex(rightColumnId);
    if (leftColumnIndex < 0 || rightColumnIndex < 0) {
      return false;
    }
    final leftEndColumnIndex = leftColumnIndex + leftCell.columnSpan - 1;
    final rightEndColumnIndex = rightColumnIndex + rightCell.columnSpan - 1;
    return rangesOverlap(
          leftCell.startRow,
          leftCell.endRow,
          rightCell.startRow,
          rightCell.endRow,
        ) &&
        leftColumnIndex <= rightEndColumnIndex &&
        leftEndColumnIndex >= rightColumnIndex;
  }

  bool rectIsInBounds({
    required int columnIndex,
    required int columnSpan,
    required int startRow,
    required int rowSpan,
  }) {
    return columnIndex >= 0 &&
        columnIndex + columnSpan - 1 < document.columns.length &&
        startRow >= 1 &&
        startRow + rowSpan - 1 <= workflowRowCount;
  }

  bool sameColumnCell(
    String leftColumnId,
    WorkflowCell leftCell,
    String rightColumnId,
    WorkflowCell rightCell,
  ) {
    return leftColumnId == rightColumnId && sameCell(leftCell, rightCell);
  }

  int columnIndex(String columnId) {
    return document.columns.indexWhere((column) => column.id == columnId);
  }

  static bool sameCell(WorkflowCell cell, WorkflowCell? other) {
    if (other == null) {
      return false;
    }
    return cell.startRow == other.startRow &&
        cell.rowSpan == other.rowSpan &&
        cell.columnSpan == other.columnSpan &&
        cell.text == other.text;
  }

  static bool rangesOverlap(
    int startA,
    int endA,
    int startB,
    int endB,
  ) {
    return startA <= endB && endA >= startB;
  }

  ChartDocumentEditResult _mergeIntoRange({
    required String columnId,
    required WorkflowCell baseCell,
    required int startRow,
    required int endRow,
  }) {
    final absorbedCells = _absorbedCellsForVerticalMerge(
      columnId: columnId,
      baseCell: baseCell,
      startRow: startRow,
      endRow: endRow,
    );
    final mergedText = absorbedCells
        .map((entry) => entry.cell.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');

    final replacement = baseCell.copyWith(
      startRow: startRow,
      rowSpan: endRow - startRow + 1,
      text: mergedText.isEmpty ? baseCell.text : mergedText,
    );

    final columns = [
      for (final item in document.columns)
        if (item.id == columnId)
          WorkflowColumn(
            id: item.id,
            widthSpec: item.widthSpec,
            cells: [
              for (final cell in item.cells)
                if (!_absorbedCellsContain(absorbedCells, item.id, cell)) cell,
              replacement,
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else if (columnIsInsideSpan(columnId, baseCell.columnSpan, item.id))
          WorkflowColumn(
            id: item.id,
            widthSpec: item.widthSpec,
            cells: [
              for (final cell in item.cells)
                if (!_absorbedCellsContain(absorbedCells, item.id, cell)) cell,
            ],
          )
        else
          item,
    ];

    return ChartDocumentEditResult(
      document: document.copyWith(columns: columns),
      selectedColumnId: columnId,
      selectedStartRow: startRow,
    );
  }

  ChartDocumentEditResult _mergeIntoColumnRange({
    required String baseColumnId,
    required String targetColumnId,
    required WorkflowCell baseCell,
    required HorizontalMergeTextOrder textOrder,
  }) {
    final startRow = baseCell.startRow;
    final endRow = baseCell.endRow;
    final targetColumn = document.columns.firstWhere(
      (column) => column.id == targetColumnId,
    );
    final absorbedTargetCells = [
      for (final cell in targetColumn.cells)
        if (rangesOverlap(startRow, endRow, cell.startRow, cell.endRow)) cell,
    ]..sort((left, right) => left.startRow.compareTo(right.startRow));

    final targetText = absorbedTargetCells
        .map((cell) => cell.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
    final baseText = baseCell.text.trim();
    final mergedTextParts = textOrder == HorizontalMergeTextOrder.baseThenTarget
        ? [baseText, targetText]
        : [targetText, baseText];
    final mergedText = mergedTextParts
        .where((text) => text.isNotEmpty)
        .join('\n');
    final replacementColumnId = textOrder == HorizontalMergeTextOrder.baseThenTarget
        ? baseColumnId
        : targetColumnId;
    final replacement = baseCell.copyWith(
      columnSpan: baseCell.columnSpan + 1,
      text: mergedText.isEmpty ? baseCell.text : mergedText,
    );

    final columns = [
      for (final column in document.columns)
        if (column.id == baseColumnId && column.id == targetColumnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final cell in column.cells)
                if (!sameCell(cell, baseCell) &&
                    !absorbedTargetCells.any((absorbed) => sameCell(cell, absorbed)))
                  cell,
              replacement,
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else if (column.id == baseColumnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final cell in column.cells)
                if (!sameCell(cell, baseCell)) cell,
              if (replacementColumnId == baseColumnId) replacement,
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else if (column.id == targetColumnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final cell in column.cells)
                if (!absorbedTargetCells.any((absorbed) => sameCell(cell, absorbed)))
                  cell,
              if (replacementColumnId == targetColumnId) replacement,
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else
          column,
    ];

    return ChartDocumentEditResult(
      document: document.copyWith(columns: columns),
      selectedColumnId: replacementColumnId,
      selectedStartRow: startRow,
    );
  }

  List<_AbsorbedWorkflowCell> _absorbedCellsForVerticalMerge({
    required String columnId,
    required WorkflowCell baseCell,
    required int startRow,
    required int endRow,
  }) {
    final absorbedCells = <_AbsorbedWorkflowCell>[];
    for (final column in columnsInsideSpan(columnId, baseCell.columnSpan)) {
      for (final cell in column.cells) {
        if (rangesOverlap(startRow, endRow, cell.startRow, cell.endRow)) {
          absorbedCells.add(_AbsorbedWorkflowCell(columnId: column.id, cell: cell));
        }
      }
    }
    absorbedCells.sort((left, right) {
      final rowComparison = left.cell.startRow.compareTo(right.cell.startRow);
      if (rowComparison != 0) {
        return rowComparison;
      }
      return columnIndex(left.columnId).compareTo(columnIndex(right.columnId));
    });
    return absorbedCells;
  }

  bool _absorbedCellsContain(
    List<_AbsorbedWorkflowCell> absorbedCells,
    String columnId,
    WorkflowCell cell,
  ) {
    return absorbedCells.any(
      (absorbed) => absorbed.columnId == columnId && sameCell(absorbed.cell, cell),
    );
  }

  List<_AbsorbedWorkflowCell> _dedupeAbsorbedCells(
    List<_AbsorbedWorkflowCell> cells, {
    required _AbsorbedWorkflowCell except,
  }) {
    final result = <_AbsorbedWorkflowCell>[];
    for (final cell in cells) {
      if (sameColumnCell(cell.columnId, cell.cell, except.columnId, except.cell)) {
        continue;
      }
      if (result.any(
        (existing) =>
            sameColumnCell(existing.columnId, existing.cell, cell.columnId, cell.cell),
      )) {
        continue;
      }
      result.add(cell);
    }
    return result;
  }

  List<WorkflowCell> _updatedCells(
    List<WorkflowCell> cells,
    WorkflowCell? existingCell,
    WorkflowCell replacement,
  ) {
    final nextCells = [
      for (final cell in cells)
        if (!sameCell(cell, existingCell)) cell,
      replacement,
    ]..sort((left, right) => left.startRow.compareTo(right.startRow));
    return nextCells;
  }
}

class _AbsorbedWorkflowCell {
  const _AbsorbedWorkflowCell({
    required this.columnId,
    required this.cell,
  });

  final String columnId;
  final WorkflowCell cell;
}

class _RectangleMovePlan {
  const _RectangleMovePlan({
    required this.targetColumnId,
    required this.targetStartRow,
    required this.absorbedCells,
    this.displacedCell,
    this.displacedTargetColumnId,
    this.displacedTargetStartRow,
  });

  final String targetColumnId;
  final int targetStartRow;
  final List<_AbsorbedWorkflowCell> absorbedCells;
  final _AbsorbedWorkflowCell? displacedCell;
  final String? displacedTargetColumnId;
  final int? displacedTargetStartRow;
}
