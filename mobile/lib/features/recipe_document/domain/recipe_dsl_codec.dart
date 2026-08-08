import '../../ingredients/domain/ingredient_cell_text.dart';
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
    _ColumnSection? currentColumnSection;
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
        if (_isBlankCellContinuation(
          lines: normalizedLines,
          currentIndex: index,
          currentColumnId: currentColumnSection?.startColumnId,
          columnsById: columnsById,
        )) {
          final existingCells = columnsById[currentColumnSection!.startColumnId]!;
          final previousCell = existingCells.removeLast();
          existingCells.add(
            previousCell.copyWith(
              text: '${previousCell.text}\n',
            ),
          );
        }
        continue;
      }

      final columnMatch = _columnHeaderPattern.firstMatch(trimmed);
      if (columnMatch != null) {
        final startColumnId = columnMatch.group(1)!;
        final endColumnId = columnMatch.group(2) ?? startColumnId;
        final section = _ColumnSection.fromIds(
          startColumnId: startColumnId,
          endColumnId: endColumnId,
          lineNumber: lineNumber,
        );
        for (var code = section.startCode; code <= section.endCode; code++) {
          final columnId = String.fromCharCode(code);
          columnsById.putIfAbsent(columnId, () => <WorkflowCell>[]);
        }
        currentSection = section.startColumnId;
        currentColumnSection = section;
        continue;
      }

      final metadataMatch = _metadataPattern.firstMatch(trimmed);
      if (metadataMatch != null) {
        final key = metadataMatch.group(1)!.toLowerCase();
        final value = (metadataMatch.group(2) ?? '').trim();
        currentColumnSection = null;

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

      final cellMetadataMatch = _cellMetadataPattern.firstMatch(trimmed);
      if (cellMetadataMatch != null) {
        final section = currentColumnSection;
        if (section == null ||
            columnsById[section.startColumnId] == null ||
            columnsById[section.startColumnId]!.isEmpty) {
          throw FormatException(
            'Line $lineNumber: cell metadata must follow a cell entry.',
          );
        }

        final key = cellMetadataMatch.group(1)!.toLowerCase();
        final value = cellMetadataMatch.group(2)!.trim();
        final cells = columnsById[section.startColumnId]!;
        final previousCell = cells.removeLast();
        cells.add(
          switch (key) {
            'ingredient' => previousCell.copyWith(ingredientProductId: value),
            'amount' => previousCell.copyWith(
                ingredientAmount: normalizedIngredientAmount(value),
              ),
            _ => previousCell,
          },
        );
        continue;
      }

      if (trimmed.startsWith('@')) {
        throw FormatException(
          'Line $lineNumber: expected cell metadata like "@ingredient id" or "@amount 200".',
        );
      }

      final cellMatch = _cellPattern.firstMatch(trimmed);
      if (cellMatch == null) {
        if (currentColumnSection != null) {
          final existingCells = columnsById[currentColumnSection.startColumnId]!;
          if (existingCells.isNotEmpty) {
            final previousCell = existingCells.removeLast();
            existingCells.add(
              previousCell.copyWith(
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
      final text = (cellMatch.group(3) ?? '').trim();

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
      final section = currentColumnSection;
      if (section == null) {
        throw FormatException(
          'Line $lineNumber: expected a column section before row entries.',
        );
      }

      for (var code = section.startCode; code <= section.endCode; code++) {
        final columnId = String.fromCharCode(code);
        final cells = columnsById[columnId]!;
        for (final existing in cells) {
          final existingEnd = existing.startRow + existing.rowSpan - 1;
          final overlaps = startRow <= existingEnd && endRow >= existing.startRow;
          if (overlaps) {
            throw FormatException(
              'Line $lineNumber: rows $startRow-$endRow overlap in column $columnId.',
            );
          }
        }
      }

      columnsById[section.startColumnId]!.add(
        WorkflowCell(
          startRow: startRow,
          rowSpan: endRow - startRow + 1,
          columnSpan: section.columnSpan,
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
    _validateRectangularCells(columns);

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
        if (column.widthSpec?.kind == ColumnWidthKind.fixed) column,
    ];

    if (widthColumns.isNotEmpty) {
      buffer.writeln('widths:');
      for (final column in widthColumns) {
        final widthSpec = column.widthSpec!;
        final value = _formatLogicalPixels(widthSpec.logicalPixels!);
        buffer.writeln('${column.id}: $value');
      }
      buffer.writeln();
    }

    final exportColumns = [
      for (final column in sortedColumns)
        if (column.cells.isNotEmpty || !_isCoveredOnlyColumn(column, sortedColumns))
          column,
    ];

    for (var index = 0; index < exportColumns.length; index++) {
      final column = exportColumns[index];
      final sortedCells = [...column.cells]
        ..sort((left, right) => left.startRow.compareTo(right.startRow));
      final hasHorizontalSpans = sortedCells.any((cell) => cell.columnSpan > 1);
      if (!hasHorizontalSpans) {
        buffer.writeln('${column.id}:');
        for (final cell in sortedCells) {
          _writeCell(buffer, cell);
        }
      } else if (sortedCells.isEmpty) {
        buffer.writeln('${column.id}:');
      } else {
        for (final cell in sortedCells) {
          final columnEndId = String.fromCharCode(
            column.id.codeUnitAt(0) + cell.columnSpan - 1,
          );
          final sectionHeader = cell.columnSpan == 1
              ? '${column.id}:'
              : '${column.id}-$columnEndId:';
          buffer.writeln(sectionHeader);
          _writeCell(buffer, cell);
        }
      }
      if (index != exportColumns.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }
}

void _writeCell(StringBuffer buffer, WorkflowCell cell) {
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
  if (cell.ingredientProductId != null) {
    buffer.writeln('   @ingredient ${cell.ingredientProductId}');
  }
  if (cell.ingredientAmount.isNotEmpty) {
    buffer.writeln('   @amount ${cell.ingredientAmount}');
  }
}

bool _isCoveredOnlyColumn(
  WorkflowColumn targetColumn,
  List<WorkflowColumn> sortedColumns,
) {
  if (targetColumn.cells.isNotEmpty) {
    return false;
  }

  final targetColumnCode = targetColumn.id.codeUnitAt(0);
  for (final column in sortedColumns) {
    final columnCode = column.id.codeUnitAt(0);
    if (columnCode >= targetColumnCode) {
      continue;
    }

    for (final cell in column.cells) {
      final endColumnCode = columnCode + cell.columnSpan - 1;
      if (endColumnCode >= targetColumnCode) {
        return true;
      }
    }
  }

  return false;
}

void _validateRectangularCells(List<WorkflowColumn> columns) {
  final cells = <_RectCell>[];
  for (final column in columns) {
    final startColumn = column.id.codeUnitAt(0);
    for (final cell in column.cells) {
      cells.add(
        _RectCell(
          startColumn: startColumn,
          endColumn: startColumn + cell.columnSpan - 1,
          startRow: cell.startRow,
          endRow: cell.endRow,
        ),
      );
    }
  }

  for (var leftIndex = 0; leftIndex < cells.length; leftIndex++) {
    final left = cells[leftIndex];
    for (var rightIndex = leftIndex + 1; rightIndex < cells.length; rightIndex++) {
      final right = cells[rightIndex];
      final columnsOverlap =
          left.startColumn <= right.endColumn && left.endColumn >= right.startColumn;
      final rowsOverlap = left.startRow <= right.endRow && left.endRow >= right.startRow;
      if (columnsOverlap && rowsOverlap) {
        throw const FormatException('Cell ranges overlap.');
      }
    }
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

bool _isBlankCellContinuation({
  required List<String> lines,
  required int currentIndex,
  required String? currentColumnId,
  required Map<String, List<WorkflowCell>> columnsById,
}) {
  if (currentColumnId == null || columnsById[currentColumnId]!.isEmpty) {
    return false;
  }

  for (var index = currentIndex + 1; index < lines.length; index++) {
    final trimmed = lines[index].trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final startsNewDslEntry = _columnHeaderPattern.hasMatch(trimmed) ||
        _metadataPattern.hasMatch(trimmed) ||
        _cellMetadataPattern.hasMatch(trimmed) ||
        trimmed.startsWith('@') ||
        _cellPattern.hasMatch(trimmed) ||
        _prepItemPattern.hasMatch(trimmed) ||
        _widthPattern.hasMatch(trimmed);
    return !startsNewDslEntry;
  }

  return false;
}

class _RectCell {
  const _RectCell({
    required this.startColumn,
    required this.endColumn,
    required this.startRow,
    required this.endRow,
  });

  final int startColumn;
  final int endColumn;
  final int startRow;
  final int endRow;
}

final _metadataPattern = RegExp(
  r'^(title|description|duration|yield|tags|favorite|prep|widths):(?:\s*(.*))?$',
  caseSensitive: false,
);
final _columnHeaderPattern = RegExp(r'^([A-Z])(?:-([A-Z]))?:$');
final _prepItemPattern = RegExp(r'^-\s+(.+)$');
final _widthPattern = RegExp(r'^([A-Z]):\s*(fit|\d+(?:\.\d+)?)$', caseSensitive: false);
final _cellPattern = RegExp(r'^(\d+)(?:-(\d+))?[.:](?:\s*(.*))?$');
final _cellMetadataPattern = RegExp(r'^@(ingredient|amount)\s+(.+)$');

class _ColumnSection {
  const _ColumnSection({
    required this.startColumnId,
    required this.startCode,
    required this.endCode,
  });

  factory _ColumnSection.fromIds({
    required String startColumnId,
    required String endColumnId,
    required int lineNumber,
  }) {
    final startCode = startColumnId.codeUnitAt(0);
    final endCode = endColumnId.codeUnitAt(0);
    if (endCode < startCode) {
      throw FormatException(
        'Line $lineNumber: column ranges must go from low to high.',
      );
    }
    return _ColumnSection(
      startColumnId: startColumnId,
      startCode: startCode,
      endCode: endCode,
    );
  }

  final String startColumnId;
  final int startCode;
  final int endCode;

  int get columnSpan => endCode - startCode + 1;
}
