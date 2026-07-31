import 'recipe_document.dart';

class RecipeDslData {
  const RecipeDslData({
    required this.title,
    required this.description,
    required this.duration,
    required this.yieldText,
    required this.tags,
    required this.isFavorite,
    required this.document,
  });

  final String title;
  final String description;
  final String duration;
  final String yieldText;
  final List<String> tags;
  final bool isFavorite;
  final RecipeDocument document;
}

class RecipeDslCodec {
  const RecipeDslCodec._();

  static RecipeDslData parseRecipe({required String source}) {
    final normalizedLines = source.replaceAll('\r\n', '\n').split('\n');
    final prepRows = <PrepRow>[];
    final columnsById = <String, List<WorkflowCell>>{};
    final widthsById = <String, ColumnWidthSpec>{};
    String? currentSection;
    String? currentColumnId;
    var title = '';
    var description = '';
    var duration = '';
    var yieldText = '';
    var isFavorite = false;
    var favoriteSpecified = false;
    final tags = <String>[];

    for (var index = 0; index < normalizedLines.length; index++) {
      final rawLine = normalizedLines[index];
      final lineNumber = index + 1;
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
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

      final metadataMatch = _metadataPattern.firstMatch(trimmed);
      if (metadataMatch != null) {
        final key = metadataMatch.group(1)!.toLowerCase();
        final value = (metadataMatch.group(2) ?? '').trim();
        currentColumnId = null;

        switch (key) {
          case 'title':
            title = value;
            currentSection = null;
            continue;
          case 'description':
            description = value;
            currentSection = null;
            continue;
          case 'duration':
            duration = value;
            currentSection = null;
            continue;
          case 'yield':
            yieldText = value;
            currentSection = null;
            continue;
          case 'tags':
            tags
              ..clear()
              ..addAll(_parseTags(value));
            currentSection = null;
            continue;
          case 'favorite':
            isFavorite = _parseFavoriteValue(value, lineNumber);
            favoriteSpecified = true;
            currentSection = null;
            continue;
          case 'prep':
            currentSection = 'prep';
            continue;
          case 'widths':
            currentSection = 'widths';
            continue;
        }
      }

      if (currentSection == null) {
        throw FormatException(
          'Line $lineNumber: expected recipe metadata, "prep:", "widths:", or a column header like "A:".',
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

      if (currentSection == 'widths') {
        final widthMatch = _widthPattern.firstMatch(trimmed);
        if (widthMatch == null) {
          throw FormatException(
            'Line $lineNumber: expected a width entry like "A: fit" or "B: 180".',
          );
        }

        final columnId = widthMatch.group(1)!;
        if (widthsById.containsKey(columnId)) {
          throw FormatException(
            'Line $lineNumber: duplicate width entry for column $columnId.',
          );
        }

        final rawWidth = widthMatch.group(2)!.trim().toLowerCase();
        if (rawWidth == 'fit') {
          widthsById[columnId] = const ColumnWidthSpec.fit();
          continue;
        }

        final logicalPixels = double.tryParse(rawWidth);
        if (logicalPixels == null || logicalPixels <= 0) {
          throw FormatException(
            'Line $lineNumber: width for column $columnId must be "fit" or a positive number.',
          );
        }
        widthsById[columnId] = ColumnWidthSpec.fixed(logicalPixels);
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
        throw FormatException(
          'Line $lineNumber: row numbers must be 1 or higher.',
        );
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
    }

    for (final widthColumnId in widthsById.keys) {
      if (!columnsById.containsKey(widthColumnId)) {
        throw FormatException(
          'WIDTHS entry for column $widthColumnId is invalid because column $widthColumnId is not declared.',
        );
      }
    }

    final sortedColumnIds = columnsById.keys.toList()..sort();
    final columns = [
      for (final columnId in sortedColumnIds)
        WorkflowColumn(
          id: columnId,
          widthSpec: widthsById[columnId],
          cells: (columnsById[columnId]!..sort(
            (left, right) => left.startRow.compareTo(right.startRow),
          )),
        ),
    ];

    return RecipeDslData(
      title: title,
      description: description,
      duration: duration,
      yieldText: yieldText,
      tags: tags,
      isFavorite: favoriteSpecified ? isFavorite : false,
      document: RecipeDocument(
        prepRows: prepRows,
        columns: columns,
      ),
    );
  }

  static String encodeRecipe(RecipeDslData recipe) {
    final buffer = StringBuffer();

    void writeMetadata(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        buffer.writeln('$key: $trimmed');
      }
    }

    writeMetadata('title', recipe.title);
    writeMetadata('description', recipe.description);
    writeMetadata('duration', recipe.duration);
    writeMetadata('yield', recipe.yieldText);

    if (recipe.tags.isNotEmpty) {
      buffer.writeln('tags: ${recipe.tags.join(', ')}');
    }

    if (recipe.isFavorite) {
      buffer.writeln('favorite: true');
    }

    if (buffer.isNotEmpty) {
      buffer.writeln();
    }

    if (recipe.document.prepRows.isNotEmpty) {
      buffer.writeln('prep:');
      for (final prepRow in recipe.document.prepRows) {
        buffer.writeln('- ${prepRow.text}');
      }
      buffer.writeln();
    }

    final sortedColumns = [...recipe.document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));
    final widthColumns = [
      for (final column in sortedColumns)
        if (column.widthSpec != null) column,
    ];

    if (widthColumns.isNotEmpty) {
      buffer.writeln('widths:');
      for (final column in widthColumns) {
        final widthSpec = column.widthSpec!;
        final value = switch (widthSpec.kind) {
          ColumnWidthKind.fit => 'fit',
          ColumnWidthKind.fixed => _formatLogicalPixels(widthSpec.logicalPixels!),
        };
        buffer.writeln('${column.id}: $value');
      }
      buffer.writeln();
    }

    for (var index = 0; index < sortedColumns.length; index++) {
      final column = sortedColumns[index];
      buffer.writeln('${column.id}:');
      final sortedCells = [...column.cells]
        ..sort((left, right) => left.startRow.compareTo(right.startRow));
      for (final cell in sortedCells) {
        final endRow = cell.startRow + cell.rowSpan - 1;
        final lines = cell.text.split('\n');
        if (cell.rowSpan == 1) {
          buffer.writeln('${cell.startRow}. ${lines.first}');
        } else {
          buffer.writeln('${cell.startRow}-$endRow: ${lines.first}');
        }
        for (final continuation in lines.skip(1)) {
          buffer.writeln(continuation);
        }
      }
      if (index != sortedColumns.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }
}

List<String> _parseTags(String source) {
  final seen = <String>{};
  final tags = <String>[];
  for (final rawTag in source.split(',')) {
    final tag = rawTag.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (tag.isEmpty || !seen.add(tag.toLowerCase())) {
      continue;
    }
    tags.add(tag);
  }
  return tags;
}

bool _parseFavoriteValue(String value, int lineNumber) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'true':
    case 'yes':
    case '1':
    case 'on':
      return true;
    case 'false':
    case 'no':
    case '0':
    case 'off':
    case '':
      return false;
    default:
      throw FormatException(
        'Line $lineNumber: favorite must be true or false.',
      );
  }
}

String _formatLogicalPixels(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

final _metadataPattern = RegExp(
  r'^(title|description|duration|yield|tags|favorite|prep|widths):(?:\s*(.*))?$',
  caseSensitive: false,
);
final _columnHeaderPattern = RegExp(r'^([A-Z]):$');
final _prepItemPattern = RegExp(r'^-\s+(.+)$');
final _widthPattern = RegExp(r'^([A-Z]):\s*(fit|\d+(?:\.\d+)?)$', caseSensitive: false);
final _cellPattern = RegExp(r'^(\d+)(?:-(\d+))?[.:]\s*(.+)$');
