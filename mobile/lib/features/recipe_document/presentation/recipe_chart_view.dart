import 'package:flutter/material.dart';

import '../domain/recipe_document.dart';

class RecipeChartView extends StatelessWidget {
  const RecipeChartView({super.key, required this.document});

  final RecipeDocument document;

  static const _borderColor = Color(0xFFD7CCBE);
  static const _chartRadius = 16.0;
  static const _cellMinHeight = 48.0;
  static const _cellHorizontalPadding = 6.0;
  static const _cellVerticalPadding = 6.0;
  static const _columnGapSafety = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = _BasicChartLayout.tryFrom(document);

    if (layout == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chart preview is currently limited.',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This preview currently supports simple vertical spans only. More advanced chart behavior will come next.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E675F),
              ),
            ),
          ],
        ),
      );
    }

    final workflowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.15,
    );
    final fittedColumnWidths = _buildColumnWidths(
      context: context,
      columns: document.columns,
      textStyle: workflowTextStyle,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_chartRadius),
        border: Border.all(color: _borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_chartRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidths = _distributeExtraWidth(
              baseWidths: fittedColumnWidths,
              availableWidth: constraints.maxWidth,
            );
            final chartWidth = columnWidths.fold<double>(
              0,
              (sum, width) => sum + width,
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final prepRow in document.prepRows)
                      _PrepRow(text: prepRow.text),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          layout.columns.length,
                          (index) => SizedBox(
                            width: columnWidths[index],
                            child: _WorkflowColumn(
                              rows: layout.rowCount,
                              cells: layout.columns[index],
                              columnWidth: columnWidths[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<double> _buildColumnWidths({
    required BuildContext context,
    required List<WorkflowColumn> columns,
    required TextStyle? textStyle,
  }) {
    final textDirection = Directionality.of(context);
    final widths = <double>[];
    final sortedColumns = [...columns]
      ..sort((left, right) => left.id.compareTo(right.id));

    for (final column in sortedColumns) {
      final widthSpec = column.widthSpec;
      if (widthSpec?.kind == ColumnWidthKind.fixed &&
          widthSpec?.logicalPixels != null) {
        widths.add(widthSpec!.logicalPixels!);
        continue;
      }

      var widestWord = 0.0;
      for (final cell in column.cells) {
        for (final paragraph in cell.text.split('\n')) {
          for (final word in paragraph.split(RegExp(r'\s+'))) {
            final trimmedWord = word.trim();
            if (trimmedWord.isEmpty) {
              continue;
            }

            final wordWidth = _measureTextWidth(
              text: trimmedWord,
              textStyle: textStyle,
              textDirection: textDirection,
            );
            if (wordWidth > widestWord) {
              widestWord = wordWidth;
            }
          }
        }
      }

      widths.add(
        widestWord +
            (_cellHorizontalPadding * 2) +
            _columnGapSafety,
      );
    }

    return widths;
  }

  List<double> _distributeExtraWidth({
    required List<double> baseWidths,
    required double availableWidth,
  }) {
    if (baseWidths.isEmpty) {
      return baseWidths;
    }

    final totalBaseWidth = baseWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    final extraWidth = availableWidth - totalBaseWidth;

    if (extraWidth <= 0) {
      return baseWidths;
    }

    final extraPerColumn = extraWidth / baseWidths.length;
    return [
      for (final width in baseWidths) width + extraPerColumn,
    ];
  }

  double _measureTextWidth({
    required String text,
    required TextStyle? textStyle,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

class _PrepRow extends StatelessWidget {
  const _PrepRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RecipeChartView._borderColor)),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WorkflowColumn extends StatelessWidget {
  const _WorkflowColumn({
    required this.rows,
    required this.cells,
    required this.columnWidth,
  });

  final int rows;
  final List<_BasicChartCell> cells;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var rowIndex = 1; rowIndex <= rows; rowIndex++)
          if (_cellStartingAt(rowIndex) case final cell?)
            Expanded(
              flex: cell.rowSpan,
              child: _WorkflowCell(
                text: cell.text,
                columnWidth: columnWidth,
                showLeftBorder: cell.columnIndex > 0,
                showTopBorder: rowIndex > 1,
              ),
            )
          else if (!_isCoveredBySpan(rowIndex))
            Expanded(
              child: _EmptyWorkflowCell(
                showLeftBorder: cells.isNotEmpty && cells.first.columnIndex > 0,
                showTopBorder: rowIndex > 1,
              ),
            ),
      ],
    );
  }

  _BasicChartCell? _cellStartingAt(int row) {
    for (final cell in cells) {
      if (cell.startRow == row) {
        return cell;
      }
    }
    return null;
  }

  bool _isCoveredBySpan(int row) {
    for (final cell in cells) {
      if (row > cell.startRow && row < cell.startRow + cell.rowSpan) {
        return true;
      }
    }
    return false;
  }

}

class _WorkflowCell extends StatelessWidget {
  const _WorkflowCell({
    required this.text,
    required this.columnWidth,
    required this.showLeftBorder,
    required this.showTopBorder,
  });

  final String text;
  final double columnWidth;
  final bool showLeftBorder;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: RecipeChartView._cellMinHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RecipeChartView._cellHorizontalPadding,
        vertical: RecipeChartView._cellVerticalPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: showLeftBorder
              ? const BorderSide(color: RecipeChartView._borderColor)
              : BorderSide.none,
          top: showTopBorder
              ? const BorderSide(color: RecipeChartView._borderColor)
              : BorderSide.none,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _wrapAtWordBoundaries(
            context: context,
            text: text,
            maxContentWidth:
                columnWidth - (RecipeChartView._cellHorizontalPadding * 2),
          ),
          softWrap: true,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  String _wrapAtWordBoundaries({
    required BuildContext context,
    required String text,
    required double maxContentWidth,
  }) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.15,
    );
    final textDirection = Directionality.of(context);
    final wrappedParagraphs = <String>[];

    for (final paragraph in text.split('\n')) {
      final words = paragraph.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
      if (words.isEmpty) {
        wrappedParagraphs.add('');
        continue;
      }

      var currentLine = '';
      final lines = <String>[];

      for (final word in words) {
        final candidate = currentLine.isEmpty ? word : '$currentLine $word';
        final candidateWidth = _measureTextWidth(
          text: candidate,
          textStyle: style,
          textDirection: textDirection,
        );

        if (currentLine.isNotEmpty && candidateWidth > maxContentWidth) {
          lines.add(currentLine);
          currentLine = word;
          continue;
        }

        currentLine = candidate;
      }

      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      wrappedParagraphs.add(lines.join('\n'));
    }

    return wrappedParagraphs.join('\n');
  }

  double _measureTextWidth({
    required String text,
    required TextStyle? textStyle,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

class _BasicChartLayout {
  const _BasicChartLayout({required this.rowCount, required this.columns});

  final int rowCount;
  final List<List<_BasicChartCell>> columns;

  static _BasicChartLayout? tryFrom(RecipeDocument document) {
    if (document.columns.isEmpty || document.rowCount < 1) {
      return null;
    }

    final sortedColumns = [...document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));
    final columns = <List<_BasicChartCell>>[];

    for (
      var columnIndex = 0;
      columnIndex < sortedColumns.length;
      columnIndex++
    ) {
      final column = sortedColumns[columnIndex];
      final orderedCells = [...column.cells]
        ..sort((left, right) => left.startRow.compareTo(right.startRow));
      var nextOpenRow = 1;
      final mappedCells = <_BasicChartCell>[];

      for (final cell in orderedCells) {
        final endRow = cell.startRow + cell.rowSpan - 1;
        if (cell.startRow < 1 ||
            cell.rowSpan < 1 ||
            cell.startRow > document.rowCount ||
            endRow > document.rowCount) {
          return null;
        }
        if (cell.startRow < nextOpenRow) {
          return null;
        }

        mappedCells.add(
          _BasicChartCell(
            columnIndex: columnIndex,
            startRow: cell.startRow,
            rowSpan: cell.rowSpan,
            text: cell.text,
          ),
        );
        nextOpenRow = endRow + 1;
      }

      columns.add(mappedCells);
    }

    return _BasicChartLayout(rowCount: document.rowCount, columns: columns);
  }
}

class _BasicChartCell {
  const _BasicChartCell({
    required this.columnIndex,
    required this.startRow,
    required this.rowSpan,
    required this.text,
  });

  final int columnIndex;
  final int startRow;
  final int rowSpan;
  final String text;
}

class _EmptyWorkflowCell extends StatelessWidget {
  const _EmptyWorkflowCell({
    required this.showLeftBorder,
    required this.showTopBorder,
  });

  final bool showLeftBorder;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: RecipeChartView._cellMinHeight,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: showLeftBorder
              ? const BorderSide(color: RecipeChartView._borderColor)
              : BorderSide.none,
          top: showTopBorder
              ? const BorderSide(color: RecipeChartView._borderColor)
              : BorderSide.none,
        ),
      ),
    );
  }
}
