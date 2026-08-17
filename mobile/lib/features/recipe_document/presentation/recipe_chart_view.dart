import 'package:flutter/material.dart';

import '../domain/recipe_document.dart';
import '../../../l10n/app_localizations.dart';

class RecipeChartView extends StatelessWidget {
  const RecipeChartView({
    super.key,
    required this.document,
    this.rowCountOverride,
    this.selectedCell,
    this.markedCells = const {},
    this.onCellTap,
    this.allowHorizontalScroll = true,
    this.expandToAvailableWidth = true,
  });

  final RecipeDocument document;
  final int? rowCountOverride;
  final RecipeChartSelection? selectedCell;
  final Set<RecipeChartSelection> markedCells;
  final ValueChanged<RecipeChartSelection>? onCellTap;
  final bool allowHorizontalScroll;
  final bool expandToAvailableWidth;

  static const _borderColor = Color(0xFFD7CCBE);
  static const _chartRadius = 16.0;
  static const _cellMinHeight = 48.0;
  static const _cellHorizontalPadding = 6.0;
  static const _cellVerticalPadding = 6.0;
  static const _cellLineHeightSafety = 2.0;
  static const _columnGapSafety = 2.0;
  static const _emptyColumnWidth = 96.0;
  static const _fitColumnMinWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final layout = _BasicChartLayout.tryFrom(
      document,
      rowCountOverride: rowCountOverride,
    );

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
              localizations.chartPreviewLimitedTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.chartPreviewLimitedMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E675F),
              ),
            ),
          ],
        ),
      );
    }

    final workflowTextStyle = _workflowTextStyle(theme);
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
            final columnWidths = expandToAvailableWidth
                ? _distributeExtraWidth(
                    baseWidths: fittedColumnWidths,
                    availableWidth: constraints.maxWidth,
                  )
                : fittedColumnWidths;
            final chartWidth = columnWidths.fold<double>(
              0,
              (sum, width) => sum + width,
            );

            final chart = SizedBox(
              width: chartWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final prepRow in document.prepRows)
                    _PrepRow(text: prepRow.text),
                  _WorkflowGrid(
                    layout: layout,
                    columnWidths: columnWidths,
                    selectedCell: selectedCell,
                    markedCells: markedCells,
                    onCellTap: onCellTap,
                  ),
                ],
              ),
            );

            if (!allowHorizontalScroll) {
              return chart;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chart,
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
    if (sortedColumns.isEmpty) {
      return [_emptyColumnWidth];
    }

    for (final column in sortedColumns) {
      final widthSpec = column.widthSpec;
      if (widthSpec?.kind == ColumnWidthKind.fixed &&
          widthSpec?.logicalPixels != null) {
        widths.add(widthSpec!.logicalPixels!);
        continue;
      }

      var widestWord = 0.0;
      for (final cell in column.cells) {
        final cellWidestWord = _widestWordWidth(
          cell.text,
          textStyle: textStyle,
          textDirection: textDirection,
        );
        if (cellWidestWord > widestWord) {
          widestWord = cellWidestWord;
        }
      }

      widths.add(
        (widestWord + (_cellHorizontalPadding * 2) + _columnGapSafety)
            .clamp(_fitColumnMinWidth, double.infinity),
      );
    }

    for (var columnIndex = 0; columnIndex < sortedColumns.length; columnIndex++) {
      final column = sortedColumns[columnIndex];
      for (final cell in column.cells) {
        if (cell.columnSpan <= 1) {
          continue;
        }

        final endColumnIndex = columnIndex + cell.columnSpan - 1;
        if (endColumnIndex >= widths.length) {
          continue;
        }

        final neededWidth = _widestWordWidth(
              cell.text,
              textStyle: textStyle,
              textDirection: textDirection,
            ) +
            (_cellHorizontalPadding * 2) +
            _columnGapSafety;
        final currentWidth = widths
            .skip(columnIndex)
            .take(cell.columnSpan)
            .fold<double>(0, (sum, width) => sum + width);
        final deficit = neededWidth - currentWidth;
        if (deficit <= 0) {
          continue;
        }

        final extraPerColumn = deficit / cell.columnSpan;
        for (var index = columnIndex; index <= endColumnIndex; index++) {
          widths[index] += extraPerColumn;
        }
      }
    }

    return widths;
  }

  double _widestWordWidth(
    String text, {
    required TextStyle? textStyle,
    required TextDirection textDirection,
  }) {
    var widestWord = 0.0;
    for (final paragraph in text.split('\n')) {
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
    return widestWord;
  }

  List<double> _distributeExtraWidth({
    required List<double> baseWidths,
    required double availableWidth,
  }) {
    if (baseWidths.isEmpty) {
      return [_emptyColumnWidth];
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

class RecipeChartSelection {
  const RecipeChartSelection({
    required this.columnId,
    required this.startRow,
  });

  final String columnId;
  final int startRow;

  @override
  bool operator ==(Object other) {
    return other is RecipeChartSelection &&
        other.columnId == columnId &&
        other.startRow == startRow;
  }

  @override
  int get hashCode => Object.hash(columnId, startRow);
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

class _WorkflowGrid extends StatelessWidget {
  const _WorkflowGrid({
    required this.layout,
    required this.columnWidths,
    this.selectedCell,
    this.markedCells = const {},
    this.onCellTap,
  });

  final _BasicChartLayout layout;
  final List<double> columnWidths;
  final RecipeChartSelection? selectedCell;
  final Set<RecipeChartSelection> markedCells;
  final ValueChanged<RecipeChartSelection>? onCellTap;

  @override
  Widget build(BuildContext context) {
    final totalWidth = columnWidths.fold<double>(0, (sum, width) => sum + width);
    final rowHeights = _buildRowHeights(context);
    final totalHeight = rowHeights.fold<double>(0, (sum, height) => sum + height);
    final positionedCells = layout.cells;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        children: [
          for (var columnIndex = 0; columnIndex < layout.columnIds.length; columnIndex++)
            for (var row = 1; row <= layout.rowCount; row++)
              Positioned(
                left: _columnLeft(columnIndex),
                top: _rowTop(row, rowHeights),
                width: columnWidths[columnIndex],
                height: rowHeights[row - 1],
                child: _EmptyWorkflowCell(
                  isMarked: markedCells.contains(
                    RecipeChartSelection(
                      columnId: layout.columnIds[columnIndex],
                      startRow: row,
                    ),
                  ),
                  isSelected:
                      selectedCell?.columnId == layout.columnIds[columnIndex] &&
                      selectedCell?.startRow == row,
                  onTap: onCellTap == null
                      ? null
                      : () => onCellTap!(
                            RecipeChartSelection(
                              columnId: layout.columnIds[columnIndex],
                              startRow: row,
                            ),
                          ),
                  showLeftBorder: columnIndex > 0,
                  showTopBorder: row > 1,
                ),
              ),
          for (final cell in positionedCells)
            Positioned(
              left: _columnLeft(cell.columnIndex),
              top: _rowTop(cell.startRow, rowHeights),
              width: _spannedWidth(cell.columnIndex, cell.columnSpan),
              height: _spannedHeight(cell.startRow, cell.rowSpan, rowHeights),
              child: _WorkflowCell(
                text: cell.text,
                columnWidth: _spannedWidth(cell.columnIndex, cell.columnSpan),
                rowSpan: cell.rowSpan,
                isMarked: markedCells.contains(
                  RecipeChartSelection(
                    columnId: cell.columnId,
                    startRow: cell.startRow,
                  ),
                ),
                isSelected:
                    selectedCell?.columnId == cell.columnId &&
                    selectedCell?.startRow == cell.startRow,
                onTap: onCellTap == null
                    ? null
                    : () => onCellTap!(
                          RecipeChartSelection(
                            columnId: cell.columnId,
                            startRow: cell.startRow,
                          ),
                        ),
                showLeftBorder: cell.columnIndex > 0,
                showTopBorder: cell.startRow > 1,
              ),
            ),
        ],
      ),
    );
  }

  double _columnLeft(int columnIndex) {
    var left = 0.0;
    for (var index = 0; index < columnIndex; index++) {
      left += columnWidths[index];
    }
    return left;
  }

  double _spannedWidth(int columnIndex, int columnSpan) {
    var width = 0.0;
    for (var index = columnIndex; index < columnIndex + columnSpan; index++) {
      width += columnWidths[index];
    }
    return width;
  }

  double _rowTop(int row, List<double> rowHeights) {
    var top = 0.0;
    for (var index = 0; index < row - 1; index++) {
      top += rowHeights[index];
    }
    return top;
  }

  double _spannedHeight(int startRow, int rowSpan, List<double> rowHeights) {
    var height = 0.0;
    for (var index = startRow - 1; index < startRow - 1 + rowSpan; index++) {
      height += rowHeights[index];
    }
    return height;
  }

  List<double> _buildRowHeights(BuildContext context) {
    final rowHeights = List<double>.filled(
      layout.rowCount,
      RecipeChartView._cellMinHeight,
    );

    final style = _workflowTextStyle(Theme.of(context));
    final textDirection = Directionality.of(context);

    for (final cell in layout.cells) {
      final width = _spannedWidth(cell.columnIndex, cell.columnSpan);
      final contentWidth = (width - (RecipeChartView._cellHorizontalPadding * 2))
          .clamp(1.0, double.infinity);
      final wrappedText = _wrapAtWordBoundaries(
        text: cell.text,
        maxContentWidth: contentWidth,
        textStyle: style,
        textDirection: textDirection,
      );
      final requiredHeight = _measureWrappedTextHeight(
        text: wrappedText,
        maxContentWidth: contentWidth,
        textStyle: style,
        textDirection: textDirection,
      ) +
          (RecipeChartView._cellVerticalPadding * 2);
      final heightPerRow = requiredHeight / cell.rowSpan;

      for (var row = cell.startRow; row <= cell.endRow; row++) {
        final index = row - 1;
        if (heightPerRow > rowHeights[index]) {
          rowHeights[index] = heightPerRow;
        }
      }
    }

    return rowHeights;
  }

  double _measureWrappedTextHeight({
    required String text,
    required double maxContentWidth,
    required TextStyle? textStyle,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
    )..layout(maxWidth: maxContentWidth);
    final lineCount = painter.computeLineMetrics().length;
    return painter.height +
        (RecipeChartView._cellLineHeightSafety * lineCount);
  }
}

TextStyle? _workflowTextStyle(ThemeData theme) {
  return theme.textTheme.bodyMedium?.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.15,
  );
}

String _wrapAtWordBoundaries({
  required String text,
  required double maxContentWidth,
  required TextStyle? textStyle,
  required TextDirection textDirection,
}) {
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
        textStyle: textStyle,
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

class _WorkflowCell extends StatelessWidget {
  const _WorkflowCell({
    required this.text,
    required this.columnWidth,
    required this.rowSpan,
    required this.isMarked,
    required this.isSelected,
    required this.showLeftBorder,
    required this.showTopBorder,
    this.onTap,
  });

  final String text;
  final double columnWidth;
  final int rowSpan;
  final bool isMarked;
  final bool isSelected;
  final bool showLeftBorder;
  final bool showTopBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = _workflowTextStyle(theme);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : isMarked
              ? const Color(0xFFFFF2C8)
              : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: RecipeChartView._cellMinHeight * rowSpan,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: RecipeChartView._cellHorizontalPadding,
            vertical: RecipeChartView._cellVerticalPadding,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: showLeftBorder
                  ? BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : RecipeChartView._borderColor,
                      width: isSelected ? 2 : 1,
                    )
                  : BorderSide.none,
              top: showTopBorder
                  ? BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : RecipeChartView._borderColor,
                      width: isSelected ? 2 : 1,
                    )
                  : BorderSide.none,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _wrapAtWordBoundaries(
                text: text,
                maxContentWidth:
                    (columnWidth - (RecipeChartView._cellHorizontalPadding * 2))
                        .clamp(1.0, double.infinity),
                textStyle: textStyle,
                textDirection: Directionality.of(context),
              ),
              softWrap: true,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _BasicChartLayout {
  const _BasicChartLayout({
    required this.rowCount,
    required this.columns,
    required this.columnIds,
    required this.cells,
  });

  final int rowCount;
  final List<List<_BasicChartCell>> columns;
  final List<String> columnIds;
  final List<_BasicChartCell> cells;

  static _BasicChartLayout? tryFrom(
    RecipeDocument document, {
    int? rowCountOverride,
  }) {
    final rowCount = rowCountOverride ?? document.rowCount;

    if (rowCount < 0) {
      return null;
    }

    if (rowCount == 0) {
      return const _BasicChartLayout(
        rowCount: 0,
        columns: [],
        columnIds: [],
        cells: [],
      );
    }

    if (document.columns.isEmpty) {
      return _BasicChartLayout(
        rowCount: rowCount,
        columns: const [[]],
        columnIds: const ['A'],
        cells: const [],
      );
    }

    final sortedColumns = [...document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));
    final columns = <List<_BasicChartCell>>[];
    final columnIds = <String>[];
    final allCells = <_BasicChartCell>[];

    for (
      var columnIndex = 0;
      columnIndex < sortedColumns.length;
      columnIndex++
    ) {
      final column = sortedColumns[columnIndex];
      columnIds.add(column.id);
      final orderedCells = [...column.cells]
        ..sort((left, right) => left.startRow.compareTo(right.startRow));
      final mappedCells = <_BasicChartCell>[];

      for (final cell in orderedCells) {
        final endRow = cell.endRow;
        final endColumnIndex = columnIndex + cell.columnSpan - 1;
        if (cell.startRow < 1 ||
            cell.rowSpan < 1 ||
            cell.columnSpan < 1 ||
            cell.startRow > rowCount ||
            endRow > rowCount ||
            endColumnIndex >= sortedColumns.length) {
          return null;
        }

        final chartCell = _BasicChartCell(
          columnIndex: columnIndex,
          columnId: column.id,
          startRow: cell.startRow,
          rowSpan: cell.rowSpan,
          columnSpan: cell.columnSpan,
          text: cell.text,
        );
        mappedCells.add(chartCell);
        allCells.add(chartCell);
      }

      columns.add(mappedCells);
    }

    for (var leftIndex = 0; leftIndex < columns.length; leftIndex++) {
      for (final leftCell in columns[leftIndex]) {
        final leftEndColumn = leftIndex + leftCell.columnSpan - 1;
        for (var rightIndex = leftIndex; rightIndex <= leftEndColumn; rightIndex++) {
          for (final rightCell in columns[rightIndex]) {
            if (identical(leftCell, rightCell)) {
              continue;
            }
            final columnsOverlap = rightIndex >= leftIndex && rightIndex <= leftEndColumn;
            final rowsOverlap = leftCell.startRow <= rightCell.endRow &&
                leftCell.endRow >= rightCell.startRow;
            if (columnsOverlap && rowsOverlap) {
              return null;
            }
          }
        }
      }
    }

    return _BasicChartLayout(
      rowCount: rowCount,
      columns: columns,
      columnIds: columnIds,
      cells: allCells,
    );
  }
}

class _BasicChartCell {
  const _BasicChartCell({
    required this.columnIndex,
    required this.columnId,
    required this.startRow,
    required this.rowSpan,
    required this.columnSpan,
    required this.text,
  });

  final int columnIndex;
  final String columnId;
  final int startRow;
  final int rowSpan;
  final int columnSpan;
  final String text;

  int get endRow => startRow + rowSpan - 1;
}

class _EmptyWorkflowCell extends StatelessWidget {
  const _EmptyWorkflowCell({
    required this.isMarked,
    required this.isSelected,
    required this.showLeftBorder,
    required this.showTopBorder,
    this.onTap,
  });

  final bool isMarked;
  final bool isSelected;
  final bool showLeftBorder;
  final bool showTopBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : isMarked
              ? const Color(0xFFFFF2C8)
              : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: RecipeChartView._cellMinHeight,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: showLeftBorder
                  ? BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : RecipeChartView._borderColor,
                      width: isSelected ? 2 : 1,
                    )
                  : BorderSide.none,
              top: showTopBorder
                  ? BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : RecipeChartView._borderColor,
                      width: isSelected ? 2 : 1,
                    )
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
