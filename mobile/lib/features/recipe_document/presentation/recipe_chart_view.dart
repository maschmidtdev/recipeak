import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/recipe_document.dart';

class RecipeChartView extends StatelessWidget {
  const RecipeChartView({
    super.key,
    required this.document,
  });

  final RecipeDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (document.columns.isEmpty || document.rowCount == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          'Chart grid is still empty. Add prep rows and workflow cells next.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5E675F),
          ),
        ),
      );
    }

    final metrics = _ChartMetrics.forDocument(document);
    final chartWidth = metrics.columnOffsets.last + metrics.columnWidths.last;
    final chartHeight =
        (document.prepRows.length * metrics.prepRowHeight) +
        (document.rowCount * metrics.gridRowHeight);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: chartHeight,
            child: Stack(
              children: [
                for (var index = 0; index < document.prepRows.length; index++)
                  _PrepRowTile(
                    text: document.prepRows[index].text,
                    top: index * metrics.prepRowHeight,
                    width: chartWidth,
                    height: metrics.prepRowHeight,
                  ),
                for (var columnIndex = 0;
                    columnIndex < document.columns.length;
                    columnIndex++)
                  ..._buildColumnCells(
                    document.columns[columnIndex],
                    columnIndex,
                    metrics,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColumnCells(
    WorkflowColumn column,
    int columnIndex,
    _ChartMetrics metrics,
  ) {
    final left = metrics.columnOffsets[columnIndex];
    final width = metrics.columnWidths[columnIndex];
    final topBase = metrics.prepRowHeight * metrics.prepRowCount;

    return [
      Positioned(
        left: left,
        top: topBase,
        width: width,
        height: metrics.gridRowHeight * metrics.rowCount,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: metrics.gridLineColor),
            ),
          ),
        ),
      ),
      for (final cell in column.cells)
        Positioned(
          left: left,
          top: topBase + ((cell.startRow - 1) * metrics.gridRowHeight),
          width: width,
          height: cell.rowSpan * metrics.gridRowHeight,
          child: _ChartCell(
            text: cell.text,
            showTopBorder: cell.startRow == 1,
          ),
        ),
    ];
  }
}

class _PrepRowTile extends StatelessWidget {
  const _PrepRowTile({
    required this.text,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final double top;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFD7CCBE)),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCell extends StatelessWidget {
  const _ChartCell({
    required this.text,
    required this.showTopBorder,
  });

  final String text;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Color(0xFFD7CCBE)),
          right: const BorderSide(color: Color(0xFFD7CCBE)),
          bottom: const BorderSide(color: Color(0xFFD7CCBE)),
          top: showTopBorder
              ? const BorderSide(color: Color(0xFFD7CCBE))
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartMetrics {
  const _ChartMetrics({
    required this.prepRowCount,
    required this.rowCount,
    required this.columnWidths,
    required this.columnOffsets,
    required this.prepRowHeight,
    required this.gridRowHeight,
    required this.gridLineColor,
  });

  final int prepRowCount;
  final int rowCount;
  final List<double> columnWidths;
  final List<double> columnOffsets;
  final double prepRowHeight;
  final double gridRowHeight;
  final Color gridLineColor;

  static _ChartMetrics forDocument(RecipeDocument document) {
    const prepRowHeight = 44.0;
    const gridRowHeight = 58.0;
    const defaultWidth = 132.0;
    const fitWidth = 124.0;

    final widths = document.columns.map<double>((column) {
      final widthSpec = column.widthSpec;
      if (widthSpec == null) {
        return defaultWidth;
      }

      switch (widthSpec.kind) {
        case ColumnWidthKind.fixed:
          return math.max(120.0, widthSpec.logicalPixels ?? defaultWidth);
        case ColumnWidthKind.fit:
          return fitWidth;
      }
    }).toList();

    final offsets = <double>[];
    var running = 0.0;
    for (final width in widths) {
      offsets.add(running);
      running += width;
    }

    return _ChartMetrics(
      prepRowCount: document.prepRows.length,
      rowCount: document.rowCount,
      columnWidths: widths,
      columnOffsets: offsets,
      prepRowHeight: prepRowHeight,
      gridRowHeight: gridRowHeight,
      gridLineColor: const Color(0xFFD7CCBE),
    );
  }
}
