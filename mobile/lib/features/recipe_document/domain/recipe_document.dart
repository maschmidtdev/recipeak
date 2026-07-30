class RecipeDocument {
  const RecipeDocument({
    required this.title,
    required this.yieldText,
    required this.prepRows,
    required this.columns,
    required this.rowCount,
  });

  final String title;
  final String yieldText;
  final List<PrepRow> prepRows;
  final List<WorkflowColumn> columns;
  final int rowCount;

  RecipeDocument copyWith({
    String? title,
    String? yieldText,
    List<PrepRow>? prepRows,
    List<WorkflowColumn>? columns,
    int? rowCount,
  }) {
    return RecipeDocument(
      title: title ?? this.title,
      yieldText: yieldText ?? this.yieldText,
      prepRows: prepRows ?? this.prepRows,
      columns: columns ?? this.columns,
      rowCount: rowCount ?? this.rowCount,
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
