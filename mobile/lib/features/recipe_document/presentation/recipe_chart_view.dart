import 'package:flutter/material.dart';

import '../domain/recipe_document.dart';

class RecipeChartView extends StatelessWidget {
  const RecipeChartView({super.key, required this.document});

  final RecipeDocument document;

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
              'The current implementation only supports the first single-row recipe example. More complex charts will come next.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E675F),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7CCBE)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final prepRow in document.prepRows)
              _PrepRow(text: prepRow.text),
            Row(
              children: [
                for (final cell in layout.cells)
                  Expanded(
                    child: _WorkflowCell(
                      text: cell.text,
                      showLeftBorder: cell.index > 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
        border: Border(bottom: BorderSide(color: Color(0xFFD7CCBE))),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WorkflowCell extends StatelessWidget {
  const _WorkflowCell({required this.text, required this.showLeftBorder});

  final String text;
  final bool showLeftBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          left: showLeftBorder
              ? const BorderSide(color: Color(0xFFD7CCBE))
              : BorderSide.none,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _BasicChartLayout {
  const _BasicChartLayout({required this.cells});

  final List<_BasicChartCell> cells;

  static _BasicChartLayout? tryFrom(RecipeDocument document) {
    if (document.rowCount != 1 || document.columns.isEmpty) {
      return null;
    }

    final sortedColumns = [...document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));

    final cells = <_BasicChartCell>[];
    for (var index = 0; index < sortedColumns.length; index++) {
      final column = sortedColumns[index];
      if (column.cells.length != 1) {
        return null;
      }

      final cell = column.cells.single;
      if (cell.startRow != 1 || cell.rowSpan != 1) {
        return null;
      }

      cells.add(_BasicChartCell(index: index, text: cell.text));
    }

    return _BasicChartLayout(cells: cells);
  }
}

class _BasicChartCell {
  const _BasicChartCell({required this.index, required this.text});

  final int index;
  final String text;
}
