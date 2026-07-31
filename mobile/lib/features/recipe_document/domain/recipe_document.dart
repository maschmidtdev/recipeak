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
        final endRow = cell.startRow + cell.rowSpan - 1;
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
  });

  final int startRow;
  final int rowSpan;
  final String text;
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
