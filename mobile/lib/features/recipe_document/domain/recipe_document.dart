class RecipeDocument {
  const RecipeDocument({
    required this.prepRows,
    required this.columns,
  });

  final List<PrepRow> prepRows;
  final List<WorkflowColumn> columns;

  int get rowCount {
    var highestRow = 0;
    for (final column in columns) {
      for (final cell in column.cells) {
        final endRow = cell.endRow;
        if (endRow > highestRow) {
          highestRow = endRow;
        }
      }
    }
    return highestRow;
  }

  RecipeDocument copyWith({
    List<PrepRow>? prepRows,
    List<WorkflowColumn>? columns,
  }) {
    return RecipeDocument(
      prepRows: prepRows ?? this.prepRows,
      columns: columns ?? this.columns,
    );
  }
}

class PrepRow {
  const PrepRow({required this.text});

  final String text;
}

class WorkflowColumn {
  const WorkflowColumn({
    required this.id,
    required this.cells,
    this.widthSpec,
  });

  final String id;
  final ColumnWidthSpec? widthSpec;
  final List<WorkflowCell> cells;
}

class WorkflowCell {
  const WorkflowCell({
    required this.startRow,
    required this.rowSpan,
    required this.text,
    this.columnSpan = 1,
    this.ingredientProductId,
    this.ingredientAmount = '',
  });

  final int startRow;
  final int rowSpan;
  final int columnSpan;
  final String text;
  final String? ingredientProductId;
  final String ingredientAmount;

  int get endRow => startRow + rowSpan - 1;
  int endColumnIndex(int startColumnIndex) => startColumnIndex + columnSpan - 1;

  WorkflowCell copyWith({
    int? startRow,
    int? rowSpan,
    int? columnSpan,
    String? text,
    String? ingredientProductId,
    bool clearIngredientProductId = false,
    String? ingredientAmount,
  }) {
    return WorkflowCell(
      startRow: startRow ?? this.startRow,
      rowSpan: rowSpan ?? this.rowSpan,
      columnSpan: columnSpan ?? this.columnSpan,
      text: text ?? this.text,
      ingredientProductId: clearIngredientProductId
          ? null
          : ingredientProductId ?? this.ingredientProductId,
      ingredientAmount: ingredientAmount ?? this.ingredientAmount,
    );
  }
}

class ColumnWidthSpec {
  const ColumnWidthSpec.fixed(this.logicalPixels) : kind = ColumnWidthKind.fixed;

  const ColumnWidthSpec.fit()
    : kind = ColumnWidthKind.fit,
      logicalPixels = null;

  final ColumnWidthKind kind;
  final double? logicalPixels;
}

enum ColumnWidthKind {
  fixed,
  fit,
}
