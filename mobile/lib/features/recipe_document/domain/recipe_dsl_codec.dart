import 'recipe_document.dart';

class RecipeDslCodec {
  const RecipeDslCodec._();

  static RecipeDocument parse({
    required String title,
    required String yieldText,
    required String source,
  }) {
    final normalizedLines = source.replaceAll('\r\n', '\n').split('\n');
    final prepRows = <PrepRow>[];
    final columnsById = <String, List<WorkflowCell>>{};
    String? currentSection;
    String? currentColumnId;
    var highestRow = 0;

    for (var index = 0; index < normalizedLines.length; index++) {
      final rawLine = normalizedLines[index];
      final lineNumber = index + 1;
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        continue;
      }

      if (_prepHeaderPattern.hasMatch(trimmed)) {
        currentSection = 'prep';
        currentColumnId = null;
        continue;
      }

      final columnMatch = _columnHeaderPattern.firstMatch(trimmed);
      if (columnMatch != null) {
        final columnId = columnMatch.group(1)!;
        if (columnsById.containsKey(columnId)) {
          throw FormatException(
            'Line $lineNumber: duplicate column "$columnId".',
          );
        }
        columnsById[columnId] = <WorkflowCell>[];
        currentSection = columnId;
        currentColumnId = columnId;
        continue;
      }

      if (currentSection == null) {
        throw FormatException(
          'Line $lineNumber: expected "prep:" or a column header like "A:".',
        );
      }

      if (currentSection == 'prep') {
        final prepMatch = _prepItemPattern.firstMatch(trimmed);
        if (prepMatch == null) {
          throw FormatException(
            'Line $lineNumber: prep rows must start with "- ".',
          );
        }

        final text = prepMatch.group(1)!.trim();
        if (text.isEmpty) {
          throw FormatException('Line $lineNumber: prep row cannot be empty.');
        }

        prepRows.add(PrepRow(text: text));
        continue;
      }

      final cellMatch = _cellPattern.firstMatch(trimmed);
      if (cellMatch == null) {
        if (currentColumnId != null) {
          final existingCells = columnsById[currentColumnId]!;
          if (existingCells.isNotEmpty) {
            final previousCell = existingCells.removeLast();
            existingCells.add(
              WorkflowCell(
                startRow: previousCell.startRow,
                rowSpan: previousCell.rowSpan,
                text: '${previousCell.text}\n$trimmed',
              ),
            );
            continue;
          }
        }

        throw FormatException(
          'Line $lineNumber: expected a row entry like "1. text" or "1-3: text".',
        );
      }

      final startRow = int.parse(cellMatch.group(1)!);
      final endRow = int.parse(cellMatch.group(2) ?? cellMatch.group(1)!);
      final text = cellMatch.group(3)!.trim();

      if (startRow < 1) {
        throw FormatException('Line $lineNumber: row numbers must be 1 or higher.');
      }
      if (endRow < startRow) {
        throw FormatException(
          'Line $lineNumber: row ranges must go from low to high.',
        );
      }
      if (text.isEmpty) {
        throw FormatException('Line $lineNumber: cell text cannot be empty.');
      }

      final cells = columnsById[currentSection]!;
      for (final existing in cells) {
        final existingEnd = existing.startRow + existing.rowSpan - 1;
        final overlaps = startRow <= existingEnd && endRow >= existing.startRow;
        if (overlaps) {
          throw FormatException(
            'Line $lineNumber: rows $startRow-$endRow overlap in column $currentSection.',
          );
        }
      }

      cells.add(
        WorkflowCell(
          startRow: startRow,
          rowSpan: endRow - startRow + 1,
          text: text,
        ),
      );
      if (endRow > highestRow) {
        highestRow = endRow;
      }
    }

    final sortedColumnIds = columnsById.keys.toList()..sort();
    final columns = [
      for (final columnId in sortedColumnIds)
        WorkflowColumn(
          id: columnId,
          cells: (columnsById[columnId]!..sort(
            (left, right) => left.startRow.compareTo(right.startRow),
          )),
        ),
    ];

    return RecipeDocument(
      title: title,
      yieldText: yieldText,
      prepRows: prepRows,
      columns: columns,
      rowCount: highestRow,
    );
  }

  static String encode(RecipeDocument document) {
    final buffer = StringBuffer();

    if (document.prepRows.isNotEmpty) {
      buffer.writeln('prep:');
      for (final prepRow in document.prepRows) {
        buffer.writeln('- ${prepRow.text}');
      }
    }

    final sortedColumns = [...document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));

    for (final column in sortedColumns) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }

      buffer.writeln('${column.id}:');
      final sortedCells = [...column.cells]
        ..sort((left, right) => left.startRow.compareTo(right.startRow));
      for (final cell in sortedCells) {
        final endRow = cell.startRow + cell.rowSpan - 1;
        if (cell.rowSpan == 1) {
          buffer.writeln('${cell.startRow}. ${cell.text}');
        } else {
          buffer.writeln('${cell.startRow}-$endRow: ${cell.text}');
        }
      }
    }

    return buffer.toString().trimRight();
  }
}

final _prepHeaderPattern = RegExp(r'^prep:$', caseSensitive: false);
final _columnHeaderPattern = RegExp(r'^([A-Z]):$');
final _prepItemPattern = RegExp(r'^-\s+(.+)$');
final _cellPattern = RegExp(r'^(\d+)(?:-(\d+))?[.:]\s*(.+)$');
