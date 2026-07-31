import 'package:flutter/material.dart';

import '../../../app/dev_flags.dart';
import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import '../../recipe_document/domain/recipe_document.dart';
import '../../recipe_document/domain/recipe_dsl_codec.dart';
import '../../recipe_document/presentation/recipe_chart_view.dart';
import '../../../l10n/app_localizations.dart';

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({
    super.key,
    required this.initialRecipe,
    required this.availableTags,
  });

  final RecipeSummary initialRecipe;
  final List<String> availableTags;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _yieldController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  late final TextEditingController _dslController;
  RecipeDocument? _document;
  late int _workflowRowCount;
  String? _dslError;
  bool _isSyncingDslText = false;
  RecipeChartSelection? _selectedCell;
  late bool _isFavorite;
  late final Set<String> _selectedTags;
  late final Set<String> _availableTags;

  @override
  void initState() {
    super.initState();
    final localizedTimeTbd = widget.initialRecipe.duration.trim();
    _titleController = TextEditingController(text: widget.initialRecipe.title);
    _yieldController = TextEditingController(text: widget.initialRecipe.yieldText);
    _durationController = TextEditingController(
      text: localizedTimeTbd.toLowerCase() == 'time tbd' ||
              localizedTimeTbd.toLowerCase() == 'zeit offen'
          ? ''
          : widget.initialRecipe.duration,
    );
    _notesController = TextEditingController(text: widget.initialRecipe.description);
    _isFavorite = widget.initialRecipe.isFavorite;
    _selectedTags = {...widget.initialRecipe.tags};
    _availableTags = {...widget.availableTags, ...widget.initialRecipe.tags};
    _document = _normalizedDocument(widget.initialRecipe.document);
    _workflowRowCount = _document!.rowCount;
    _dslController = TextEditingController()
      ..addListener(_handleDslChanged);
    _syncDslFromDocument();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yieldController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _dslController
      ..removeListener(_handleDslChanged)
      ..dispose();
    super.dispose();
  }

  void _handleDslChanged() {
    if (_isSyncingDslText) {
      return;
    }

    try {
      final parsed = RecipeDslCodec.parseRecipe(source: _dslController.text);
      setState(() {
        _titleController.text = parsed.title;
        _notesController.text = parsed.description;
        _durationController.text = parsed.duration;
        _yieldController.text = parsed.yieldText;
        _isFavorite = parsed.isFavorite;
        _availableTags.addAll(parsed.tags);
        _selectedTags
          ..clear()
          ..addAll(parsed.tags);
        _document = _normalizedDocument(parsed.document);
        _workflowRowCount = _document!.rowCount;
        _dslError = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _dslError = error.message;
      });
    }
  }

  Future<void> _openDslEditor() async {
    _syncDslFromDocument();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final localizations = AppLocalizations.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.edit} ${localizations.chartDslLabel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.chartDslDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5E675F),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dslController,
                minLines: 12,
                maxLines: 20,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                decoration: InputDecoration(
                  hintText: localizations.chartDslHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDslInfo() async {
    final localizations = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.chartDslLabel),
          content: Text(localizations.chartDslInfoBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.done),
            ),
          ],
        );
      },
    );
  }

  void _setDocument(RecipeDocument document) {
    final normalized = _normalizedDocument(document);
    setState(() {
      _document = normalized;
      _workflowRowCount = _workflowRowCount > normalized.rowCount
          ? _workflowRowCount
          : normalized.rowCount;
      _dslError = null;
      _selectedCell = _resolvedSelection(_selectedCell, normalized);
    });
    _syncDslFromDocument();
  }

  RecipeChartSelection? _resolvedSelection(
    RecipeChartSelection? selection,
    RecipeDocument document,
  ) {
    if (selection == null) {
      return null;
    }
    for (final column in document.columns) {
      if (column.id != selection.columnId) {
        continue;
      }
      for (final cell in column.cells) {
        if (cell.startRow == selection.startRow) {
          return selection;
        }
      }
    }
    return null;
  }

  void _syncDslFromDocument() {
    final nextDsl = RecipeDslCodec.encodeRecipe(
      RecipeDslData(
        title: _titleController.text.trim(),
        description: _notesController.text.trim(),
        duration: _durationController.text.trim(),
        yieldText: _yieldController.text.trim(),
        tags: _sortedTags(_selectedTags),
        isFavorite: _isFavorite,
        document: _currentDocument,
      ),
    );
    _isSyncingDslText = true;
    _dslController.value = TextEditingValue(
      text: nextDsl,
      selection: TextSelection.collapsed(offset: nextDsl.length),
    );
    _isSyncingDslText = false;
  }

  RecipeDocument _normalizedDocument(RecipeDocument document) {
    final sortedColumns = [...document.columns]
      ..sort((left, right) => left.id.compareTo(right.id));

    final normalizedColumns = [
      for (final column in sortedColumns)
        WorkflowColumn(
          id: column.id,
          widthSpec: column.widthSpec,
          cells: [
            for (final cell in [...column.cells]
              ..sort((left, right) => left.startRow.compareTo(right.startRow)))
              cell,
          ],
        ),
    ];

    return document.copyWith(
      prepRows: [...document.prepRows],
      columns: normalizedColumns,
    );
  }

  RecipeDocument get _currentDocument {
    return _document ??= _normalizedDocument(widget.initialRecipe.document);
  }

  int get _currentWorkflowRowCount {
    return _workflowRowCount > _currentDocument.rowCount
        ? _workflowRowCount
        : _currentDocument.rowCount;
  }

  Future<void> _editPrepRow({int? index}) async {
    final localizations = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: index == null ? '' : _currentDocument.prepRows[index].text,
    );
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            index == null
                ? localizations.addPrepRowTitle
                : localizations.editPrepRowTitle,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: localizations.prepRowHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );

    if (!mounted || text == null || text.isEmpty) {
      return;
    }

    final prepRows = [..._currentDocument.prepRows];
    if (index == null) {
      prepRows.add(PrepRow(text: text));
    } else {
      prepRows[index] = PrepRow(text: text);
    }
    _setDocument(_currentDocument.copyWith(prepRows: prepRows));
  }

  void _deletePrepRow(int index) {
    final prepRows = [..._currentDocument.prepRows]..removeAt(index);
    _setDocument(_currentDocument.copyWith(prepRows: prepRows));
  }

  void _addWorkflowRow() {
    final nextRow = _currentWorkflowRowCount + 1;
    if (_currentDocument.columns.every((column) => column.cells.isEmpty)) {
      final targetColumnId = _currentDocument.columns.isEmpty
          ? 'A'
          : _currentDocument.columns.first.id;
      final document = _currentDocument.copyWith(
        columns: [
          WorkflowColumn(
            id: targetColumnId,
            cells: [
              WorkflowCell(
                startRow: nextRow,
                rowSpan: 1,
                text: 'New cell',
              ),
            ],
          ),
        ],
      );
      final selection = RecipeChartSelection(
        columnId: targetColumnId,
        startRow: nextRow,
      );
      setState(() {
        _document = _normalizedDocument(document);
        _workflowRowCount = nextRow;
        _selectedCell = selection;
        _dslError = null;
      });
      _syncDslFromDocument();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _editCell(
          columnId: selection.columnId,
          existingCell: _currentCell,
          initialStartRow: selection.startRow,
          initialEndRow: selection.startRow,
        );
      });
      return;
    }

    setState(() {
      _workflowRowCount = nextRow;
    });
    _syncDslFromDocument();
  }

  void _removeWorkflowRow() {
    if (_currentWorkflowRowCount <= 0) {
      return;
    }

    final newRowCount = _currentWorkflowRowCount - 1;
    final columns = [
      for (final column in _currentDocument.columns)
        WorkflowColumn(
          id: column.id,
          widthSpec: column.widthSpec,
          cells: [
            for (final cell in column.cells)
              if (cell.startRow <= newRowCount)
                WorkflowCell(
                  startRow: cell.startRow,
                  rowSpan: _clampedRowSpan(cell, newRowCount),
                  text: cell.text,
                ),
          ],
        ),
    ];

    final normalized = _normalizedDocument(
      _currentDocument.copyWith(columns: columns),
    );
    setState(() {
      _document = normalized;
      _workflowRowCount = newRowCount;
      _selectedCell = _resolvedSelection(_selectedCell, normalized);
      _dslError = null;
    });
    _syncDslFromDocument();
  }

  int _clampedRowSpan(WorkflowCell cell, int maxRow) {
    final endRow = cell.startRow + cell.rowSpan - 1;
    if (endRow <= maxRow) {
      return cell.rowSpan;
    }
    return maxRow - cell.startRow + 1;
  }

  void _addColumn() {
    final localizations = AppLocalizations.of(context);
    final nextId = _nextColumnId(_currentDocument.columns);
    if (nextId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.noMoreColumnLetters)),
      );
      return;
    }

    final columns = [..._currentDocument.columns, WorkflowColumn(id: nextId, cells: const [])];
    _setDocument(_currentDocument.copyWith(columns: columns));
  }

  String? _nextColumnId(List<WorkflowColumn> columns) {
    for (var code = 65; code <= 90; code++) {
      final id = String.fromCharCode(code);
      if (!columns.any((column) => column.id == id)) {
        return id;
      }
    }
    return null;
  }

  void _deleteColumn(String columnId) {
    final columns = [
      for (final column in _currentDocument.columns)
        if (column.id != columnId) column,
    ];
    _setDocument(_currentDocument.copyWith(columns: columns));
  }

  Future<void> _editCell({
    required String columnId,
    WorkflowCell? existingCell,
    int? initialStartRow,
    int? initialEndRow,
  }) async {
    final localizations = AppLocalizations.of(context);
    final textController = TextEditingController(text: existingCell?.text ?? '');
    final startController = TextEditingController(
      text: (existingCell?.startRow ?? initialStartRow ?? 1).toString(),
    );
    final endController = TextEditingController(
      text: (existingCell != null
              ? existingCell.startRow + existingCell.rowSpan - 1
              : initialEndRow ?? initialStartRow ?? 1)
          .toString(),
    );

    final draft = await showDialog<_CellDraft>(
      context: context,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: AlertDialog(
            scrollable: true,
            title: Text(
              existingCell == null
                  ? localizations.addCellTitle
                  : localizations.editCell,
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: localizations.cellTextHint,
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: localizations.startRowLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: localizations.endRowLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final startRow = int.tryParse(startController.text.trim());
                  final endRow = int.tryParse(endController.text.trim());
                  final text = textController.text.trim();
                  if (startRow == null || endRow == null || text.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(
                    _CellDraft(startRow: startRow, endRow: endRow, text: text),
                  );
                },
                child: Text(localizations.save),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || draft == null) {
      return;
    }

    if (draft.startRow < 1 ||
        draft.endRow < draft.startRow ||
        draft.endRow > _currentWorkflowRowCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.invalidRowRangeMessage(_currentWorkflowRowCount),
          ),
        ),
      );
      return;
    }

    if (!_canPlaceCell(
      columnId: columnId,
      startRow: draft.startRow,
      endRow: draft.endRow,
      excluding: existingCell,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.overlappingRowRangeMessage(columnId),
          ),
        ),
      );
      return;
    }

    final columns = [
      for (final column in _currentDocument.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: _updatedCells(
              column.cells,
              existingCell,
              WorkflowCell(
                startRow: draft.startRow,
                rowSpan: draft.endRow - draft.startRow + 1,
                text: draft.text,
              ),
            ),
          )
        else
          column,
    ];

    _setDocument(_currentDocument.copyWith(columns: columns));
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: columnId,
        startRow: draft.startRow,
      );
    });
  }

  List<WorkflowCell> _updatedCells(
    List<WorkflowCell> cells,
    WorkflowCell? existingCell,
    WorkflowCell replacement,
  ) {
    final nextCells = [
      for (final cell in cells)
        if (!_sameCell(cell, existingCell)) cell,
      replacement,
    ]..sort((left, right) => left.startRow.compareTo(right.startRow));
    return nextCells;
  }

  bool _sameCell(WorkflowCell cell, WorkflowCell? other) {
    if (other == null) {
      return false;
    }
    return cell.startRow == other.startRow &&
        cell.rowSpan == other.rowSpan &&
        cell.text == other.text;
  }

  bool _canPlaceCell({
    required String columnId,
    required int startRow,
    required int endRow,
    WorkflowCell? excluding,
  }) {
    final column = _currentDocument.columns.firstWhere((item) => item.id == columnId);
    for (final cell in column.cells) {
      if (_sameCell(cell, excluding)) {
        continue;
      }
      final cellEnd = cell.startRow + cell.rowSpan - 1;
      final overlaps = startRow <= cellEnd && endRow >= cell.startRow;
      if (overlaps) {
        return false;
      }
    }
    return true;
  }

  void _deleteCell(String columnId, WorkflowCell targetCell) {
    final columns = [
      for (final column in _currentDocument.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: [
              for (final cell in column.cells)
                if (!_sameCell(cell, targetCell)) cell,
            ],
          )
        else
          column,
    ];
    _setDocument(_currentDocument.copyWith(columns: columns));
  }

  void _moveCellUp(String columnId, WorkflowCell cell) {
    if (!_canMoveUp(columnId, cell)) {
      return;
    }
    _moveCellByOffset(columnId: columnId, cell: cell, offset: -1);
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: columnId,
        startRow: cell.startRow - 1,
      );
    });
  }

  void _moveCellDown(String columnId, WorkflowCell cell) {
    if (!_canMoveDown(columnId, cell)) {
      return;
    }
    _moveCellByOffset(columnId: columnId, cell: cell, offset: 1);
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: columnId,
        startRow: cell.startRow + 1,
      );
    });
  }

  void _mergeCellUp(String columnId, WorkflowCell cell) {
    if (cell.startRow <= 1) {
      return;
    }
    final aboveCell = _cellCoveringRow(columnId, cell.startRow - 1, excluding: cell);
    final newStartRow = aboveCell?.startRow ?? (cell.startRow - 1);
    final newEndRow = cell.startRow + cell.rowSpan - 1;
    _mergeIntoRange(
      columnId: columnId,
      baseCell: cell,
      startRow: newStartRow,
      endRow: newEndRow,
    );
  }

  void _mergeCellDown(String columnId, WorkflowCell cell) {
    final currentEndRow = cell.startRow + cell.rowSpan - 1;
    final belowCell = _cellCoveringRow(columnId, currentEndRow + 1, excluding: cell);
    final newEndRow =
        belowCell?.startRow != null ? belowCell!.startRow + belowCell.rowSpan - 1 : currentEndRow + 1;
    if (newEndRow > _currentWorkflowRowCount) {
      return;
    }
    _mergeIntoRange(
      columnId: columnId,
      baseCell: cell,
      startRow: cell.startRow,
      endRow: newEndRow,
    );
  }

  void _unmergeCell(String columnId, WorkflowCell cell) {
    if (cell.rowSpan == 1) {
      return;
    }
    _replaceCell(
      columnId: columnId,
      oldCell: cell,
      newCell: WorkflowCell(
        startRow: cell.startRow,
        rowSpan: 1,
        text: cell.text,
      ),
    );
  }

  void _replaceCell({
    required String columnId,
    required WorkflowCell oldCell,
    required WorkflowCell newCell,
  }) {
    final columns = [
      for (final column in _currentDocument.columns)
        if (column.id == columnId)
          WorkflowColumn(
            id: column.id,
            widthSpec: column.widthSpec,
            cells: _updatedCells(column.cells, oldCell, newCell),
          )
        else
          column,
    ];
    _setDocument(_currentDocument.copyWith(columns: columns));
  }

  void _moveCellByOffset({
    required String columnId,
    required WorkflowCell cell,
    required int offset,
  }) {
    if (cell.rowSpan > 1) {
      final boundaryRow = offset < 0
          ? cell.startRow - 1
          : cell.startRow + cell.rowSpan;
      final targetCell = _cellCoveringRow(
        columnId,
        boundaryRow,
        excluding: cell,
      );

      if (targetCell == null) {
        _replaceCell(
          columnId: columnId,
          oldCell: cell,
          newCell: WorkflowCell(
            startRow: cell.startRow + offset,
            rowSpan: cell.rowSpan,
            text: cell.text,
          ),
        );
        return;
      }

      final column = _currentDocument.columns.firstWhere(
        (item) => item.id == columnId,
      );
      final displacedRow = offset < 0
          ? cell.startRow + cell.rowSpan - 1
          : cell.startRow;
      final nextCells = <WorkflowCell>[
        for (final existing in column.cells)
          if (!_sameCell(existing, cell) && !_sameCell(existing, targetCell))
            existing,
        WorkflowCell(
          startRow: cell.startRow + offset,
          rowSpan: cell.rowSpan,
          text: cell.text,
        ),
        WorkflowCell(
          startRow: displacedRow,
          rowSpan: targetCell.rowSpan,
          text: targetCell.text,
        ),
      ]..sort((left, right) => left.startRow.compareTo(right.startRow));

      final columns = [
        for (final existingColumn in _currentDocument.columns)
          if (existingColumn.id == columnId)
            WorkflowColumn(
              id: existingColumn.id,
              widthSpec: existingColumn.widthSpec,
              cells: nextCells,
            )
          else
            existingColumn,
      ];
      _setDocument(_currentDocument.copyWith(columns: columns));
      return;
    }

    final targetRow = cell.startRow + offset;
    final targetCell = _cellCoveringRow(columnId, targetRow, excluding: cell);
    final column = _currentDocument.columns.firstWhere((item) => item.id == columnId);
    final nextCells = <WorkflowCell>[
      for (final existing in column.cells)
        if (!_sameCell(existing, cell) &&
            (targetCell == null || !_sameCell(existing, targetCell)))
          existing,
      WorkflowCell(
        startRow: targetRow,
        rowSpan: cell.rowSpan,
        text: cell.text,
      ),
      if (targetCell != null)
        WorkflowCell(
          startRow: cell.startRow,
          rowSpan: targetCell.rowSpan,
          text: targetCell.text,
        ),
    ]..sort((left, right) => left.startRow.compareTo(right.startRow));

    final columns = [
      for (final existingColumn in _currentDocument.columns)
        if (existingColumn.id == columnId)
          WorkflowColumn(
            id: existingColumn.id,
            widthSpec: existingColumn.widthSpec,
            cells: nextCells,
          )
        else
          existingColumn,
    ];
    _setDocument(_currentDocument.copyWith(columns: columns));
  }

  WorkflowCell? _cellCoveringRow(
    String columnId,
    int row, {
    WorkflowCell? excluding,
  }) {
    final column = _currentDocument.columns.firstWhere((item) => item.id == columnId);
    for (final cell in column.cells) {
      if (_sameCell(cell, excluding)) {
        continue;
      }
      final endRow = cell.startRow + cell.rowSpan - 1;
      if (row >= cell.startRow && row <= endRow) {
        return cell;
      }
    }
    return null;
  }

  void _mergeIntoRange({
    required String columnId,
    required WorkflowCell baseCell,
    required int startRow,
    required int endRow,
  }) {
    final column = _currentDocument.columns.firstWhere((item) => item.id == columnId);
    final absorbedCells = <WorkflowCell>[
      for (final cell in column.cells)
        if (_rangesOverlap(
          startRow,
          endRow,
          cell.startRow,
          cell.startRow + cell.rowSpan - 1,
        ))
          cell,
    ]..sort((left, right) => left.startRow.compareTo(right.startRow));

    final mergedText = absorbedCells
        .map((cell) => cell.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');

    final replacement = WorkflowCell(
      startRow: startRow,
      rowSpan: endRow - startRow + 1,
      text: mergedText.isEmpty ? baseCell.text : mergedText,
    );

    final columns = [
      for (final item in _currentDocument.columns)
        if (item.id == columnId)
          WorkflowColumn(
            id: item.id,
            widthSpec: item.widthSpec,
            cells: [
              for (final cell in item.cells)
                if (!absorbedCells.any((absorbed) => _sameCell(cell, absorbed))) cell,
              replacement,
            ]..sort((left, right) => left.startRow.compareTo(right.startRow)),
          )
        else
          item,
    ];

    _setDocument(_currentDocument.copyWith(columns: columns));
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: columnId,
        startRow: startRow,
      );
    });
  }

  bool _rangesOverlap(
    int startA,
    int endA,
    int startB,
    int endB,
  ) {
    return startA <= endB && endA >= startB;
  }

  Future<void> _openPrepManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.prepRowsTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editPrepRow();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(localizations.addLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentDocument.prepRows.isEmpty)
                  _EditorPlaceholder(
                    text:
                        '${localizations.noPrepRowsPlaceholder} ${localizations.createTopInstructionsHint}',
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (var index = 0;
                            index < _currentDocument.prepRows.length;
                            index++)
                          _EditorListRow(
                            title: _currentDocument.prepRows[index].text,
                            subtitle: localizations.prepRowNumberLabel(index + 1),
                            onEdit: () {
                              Navigator.of(context).pop();
                              _editPrepRow(index: index);
                            },
                            onDelete: () {
                              Navigator.of(context).pop();
                              _deletePrepRow(index);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCellManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.workflowCellsTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _addColumn();
                      },
                      icon: const Icon(Icons.view_column),
                      label: Text(localizations.addColumnLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentDocument.columns.isEmpty)
                  _EditorPlaceholder(
                    text: localizations.noWorkflowColumnsPlaceholder,
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final column in _currentDocument.columns) ...[
                          _ColumnEditorCard(
                            columnId: column.id,
                            onAddCell: () {
                              Navigator.of(context).pop();
                              _editCell(columnId: column.id);
                            },
                            onDeleteColumn: () {
                              Navigator.of(context).pop();
                              _deleteColumn(column.id);
                            },
                            child: Column(
                              children: [
                                if (column.cells.isEmpty)
                                  _EditorPlaceholder(
                                    text: localizations.noCellsInColumnPlaceholder,
                                  )
                                else
                                  for (final cell in column.cells)
                                    _EditorListRow(
                                      title: cell.text,
                                      subtitle: cell.rowSpan == 1
                                          ? localizations.singleRowLabel(cell.startRow)
                                          : localizations.rowRangeLabel(
                                              cell.startRow,
                                              cell.startRow + cell.rowSpan - 1,
                                            ),
                                      actionMenu: PopupMenuButton<_CellAction>(
                                        onSelected: (action) {
                                          Navigator.of(context).pop();
                                          switch (action) {
                                            case _CellAction.edit:
                                              _editCell(
                                                columnId: column.id,
                                                existingCell: cell,
                                              );
                                              break;
                                            case _CellAction.delete:
                                              _deleteCell(column.id, cell);
                                              break;
                                            case _CellAction.moveUp:
                                              _moveCellUp(column.id, cell);
                                              break;
                                            case _CellAction.moveDown:
                                              _moveCellDown(column.id, cell);
                                              break;
                                            case _CellAction.mergeUp:
                                              _mergeCellUp(column.id, cell);
                                              break;
                                            case _CellAction.mergeDown:
                                              _mergeCellDown(column.id, cell);
                                              break;
                                            case _CellAction.unmerge:
                                              _unmergeCell(column.id, cell);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: _CellAction.edit,
                                            child: Text(localizations.edit),
                                          ),
                                          if (_canMoveUp(column.id, cell))
                                            PopupMenuItem(
                                              value: _CellAction.moveUp,
                                              child: Text(localizations.moveUp),
                                            ),
                                          if (_canMoveDown(column.id, cell))
                                            PopupMenuItem(
                                              value: _CellAction.moveDown,
                                              child: Text(localizations.moveDown),
                                            ),
                                          if (_canMergeUp(column.id, cell))
                                            PopupMenuItem(
                                              value: _CellAction.mergeUp,
                                              child: Text(localizations.mergeWithAbove),
                                            ),
                                          if (_canMergeDown(column.id, cell))
                                            PopupMenuItem(
                                              value: _CellAction.mergeDown,
                                              child: Text(localizations.mergeWithBelow),
                                            ),
                                          if (cell.rowSpan > 1)
                                            PopupMenuItem(
                                              value: _CellAction.unmerge,
                                              child: Text(localizations.unmerge),
                                            ),
                                          PopupMenuItem(
                                            value: _CellAction.delete,
                                            child: Text(localizations.delete),
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canMergeUp(String columnId, WorkflowCell cell) {
    if (cell.startRow <= 1) {
      return false;
    }
    return true;
  }

  bool _canMergeDown(String columnId, WorkflowCell cell) {
    final endRow = cell.startRow + cell.rowSpan - 1;
    if (endRow >= _currentWorkflowRowCount) {
      return false;
    }
    return true;
  }

  bool _canMoveUp(String columnId, WorkflowCell cell) {
    if (cell.startRow <= 1) {
      return false;
    }
    if (cell.rowSpan > 1) {
      final targetCell = _cellCoveringRow(
        columnId,
        cell.startRow - 1,
        excluding: cell,
      );
      return targetCell == null || targetCell.rowSpan == 1;
    }
    final targetCell = _cellCoveringRow(columnId, cell.startRow - 1, excluding: cell);
    return targetCell == null || targetCell.rowSpan == 1;
  }

  bool _canMoveDown(String columnId, WorkflowCell cell) {
    final endRow = cell.startRow + cell.rowSpan - 1;
    if (endRow >= _currentWorkflowRowCount) {
      return false;
    }
    if (cell.rowSpan > 1) {
      final targetCell = _cellCoveringRow(columnId, endRow + 1, excluding: cell);
      return targetCell == null || targetCell.rowSpan == 1;
    }
    final targetCell = _cellCoveringRow(columnId, cell.startRow + 1, excluding: cell);
    return targetCell == null || targetCell.rowSpan == 1;
  }

  WorkflowCell? get _currentCell {
    final selection = _selectedCell;
    if (selection == null) {
      return null;
    }
    for (final column in _currentDocument.columns) {
      if (column.id != selection.columnId) {
        continue;
      }
      for (final cell in column.cells) {
        if (cell.startRow == selection.startRow) {
          return cell;
        }
      }
    }
    return null;
  }

  void _clearSelection() {
    setState(() {
      _selectedCell = null;
    });
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dslError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dslError!)),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final yieldText = _yieldController.text.trim();
    final durationText = _durationController.text.trim();
    final title = _titleController.text.trim();
    final document = _currentDocument;

    Navigator.of(context).pop(
      RecipeEditorResult.saved(
        widget.initialRecipe.copyWith(
          title: title,
          description: notes,
          yieldText: yieldText,
          document: document,
          tags: _selectedTags.toList()..sort(),
          isFavorite: _isFavorite,
          duration: durationText,
          isDraft: false,
        ),
        availableTags: _availableTags.toList()..sort(),
      ),
    );
  }

  Future<void> _addTag() async {
    final localizations = AppLocalizations.of(context);
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.addTagTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: localizations.tagNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(localizations.addDialogConfirm),
            ),
          ],
        );
      },
    );

    if (!mounted || tag == null || tag.isEmpty) {
      return;
    }

    final normalizedTag = _normalizeTag(tag);
    if (normalizedTag.isEmpty) {
      return;
    }

    setState(() {
      _availableTags.add(normalizedTag);
      _selectedTags.add(normalizedTag);
    });
  }

  String _normalizeTag(String input) {
    final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) {
      return '';
    }
    return collapsed;
  }

  void _discardChanges() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRecipe.title.trim().isEmpty
              ? localizations.newRecipe
              : localizations.editRecipe,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialRecipe.title.trim().isEmpty
                          ? localizations.newRecipeEditorHeadline
                          : localizations.editRecipeEditorHeadline,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.editorIntroBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5E675F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(
                label: localizations.recipeTitleLabel,
                child: TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.recipeTitleHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.recipeTitleRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: localizations.yieldLabel,
                child: TextFormField(
                  controller: _yieldController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(hintText: localizations.yieldHint),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: localizations.durationLabel,
                child: TextFormField(
                  controller: _durationController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.durationHint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: localizations.notesLabel,
                child: TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: localizations.notesHint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: localizations.tagsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(localizations.favoriteLabel),
                      value: _isFavorite,
                      onChanged: (value) {
                        setState(() {
                          _isFavorite = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _sortedTags(_availableTags))
                          FilterChip(
                            label: Text(_tagLabel(context, tag)),
                            selected: _selectedTags.contains(tag),
                            showCheckmark: false,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(localizations.addTagLabel),
                          onPressed: _addTag,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _openDslEditor,
                    child: Text(
                      '${localizations.edit} ${localizations.chartDslLabel}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _showDslInfo,
                    icon: const Icon(Icons.help_outline, size: 22),
                    tooltip: localizations.chartDslLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_dslError != null) _EditorErrorBanner(message: _dslError!),
              if (_dslError != null) const SizedBox(height: 20),
              if (kIsDevelopmentMode) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD7CCBE)),
                  ),
                  child: Text(
                    localizations.chartStructureSummary(
                      _currentDocument.prepRows.length,
                      _currentWorkflowRowCount,
                      _currentDocument.columns.length,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5E675F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                localizations.chartPreview,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              RecipeChartView(
                document: _currentDocument,
                rowCountOverride: _currentWorkflowRowCount,
                selectedCell: _selectedCell,
                onCellTap: (selection) {
                  setState(() {
                    _selectedCell = _selectedCell?.columnId == selection.columnId &&
                            _selectedCell?.startRow == selection.startRow
                        ? null
                        : selection;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7CCBE)),
              ),
              child: _currentCell != null || _selectedCell != null
                  ? _ActionGrid(
                      children: [
                        if (_selectedCell != null && _currentCell == null) ...[
                          _ActionIconButton(
                            onPressed: () => _editCell(
                              columnId: _selectedCell!.columnId,
                              initialStartRow: _selectedCell!.startRow,
                              initialEndRow: _selectedCell!.startRow,
                            ),
                            icon: Icons.add_box_outlined,
                            tooltip: localizations.createCell,
                            isPrimary: true,
                          ),
                          _ActionIconButton(
                            onPressed: _clearSelection,
                            icon: Icons.close,
                            tooltip: localizations.cancel,
                          ),
                        ] else if (_currentCell != null) ...[
                          _ActionIconButton(
                            onPressed: () => _editCell(
                              columnId: _selectedCell!.columnId,
                              existingCell: _currentCell,
                            ),
                            icon: Icons.edit_outlined,
                            tooltip: localizations.editCell,
                            isPrimary: true,
                          ),
                          if (_canMoveUp(_selectedCell!.columnId, _currentCell!))
                            _ActionIconButton(
                              onPressed: () => _moveCellUp(
                                _selectedCell!.columnId,
                                _currentCell!,
                              ),
                              icon: Icons.arrow_upward,
                              tooltip: localizations.moveUp,
                            ),
                          if (_canMergeUp(_selectedCell!.columnId, _currentCell!))
                            _ActionIconButton(
                              onPressed: () => _mergeCellUp(
                                _selectedCell!.columnId,
                                _currentCell!,
                              ),
                              icon: Icons.vertical_align_top,
                              tooltip: localizations.mergeUp,
                            ),
                          _ActionIconButton(
                            onPressed: () => _deleteCell(
                              _selectedCell!.columnId,
                              _currentCell!,
                            ),
                            icon: Icons.delete_outline,
                            tooltip: localizations.deleteCell,
                          ),
                          if (_canMoveDown(_selectedCell!.columnId, _currentCell!))
                            _ActionIconButton(
                              onPressed: () => _moveCellDown(
                                _selectedCell!.columnId,
                                _currentCell!,
                              ),
                              icon: Icons.arrow_downward,
                              tooltip: localizations.moveDown,
                            ),
                          if (_canMergeDown(
                            _selectedCell!.columnId,
                            _currentCell!,
                          ))
                            _ActionIconButton(
                              onPressed: () => _mergeCellDown(
                                _selectedCell!.columnId,
                                _currentCell!,
                              ),
                              icon: Icons.vertical_align_bottom,
                              tooltip: localizations.mergeDown,
                            ),
                          if (_currentCell!.rowSpan > 1)
                            _ActionIconButton(
                              onPressed: () => _unmergeCell(
                                _selectedCell!.columnId,
                                _currentCell!,
                              ),
                              icon: Icons.call_split,
                              tooltip: localizations.unmerge,
                            ),
                          _ActionIconButton(
                            onPressed: _clearSelection,
                            icon: Icons.check,
                            tooltip: localizations.done,
                          ),
                        ],
                      ],
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _openPrepManager,
                          icon: const Icon(Icons.format_list_bulleted),
                          label: Text(localizations.prepLabel),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _removeWorkflowRow,
                          icon: const Icon(Icons.remove),
                          label: Text(localizations.rowLabel),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _addWorkflowRow,
                          icon: const Icon(Icons.add),
                          label: Text(localizations.rowLabel),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _addColumn,
                          icon: const Icon(Icons.view_column),
                          label: Text(localizations.columnLabel),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _openCellManager,
                          icon: const Icon(Icons.dashboard_customize),
                          label: Text(localizations.cellsLabel),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                  child: FilledButton.tonalIcon(
                      onPressed: _discardChanges,
                      icon: const Icon(Icons.close),
                      label: Text(localizations.discard),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                  child: FilledButton.icon(
                      onPressed: _saveRecipe,
                      icon: const Icon(Icons.check),
                      label: Text(localizations.save),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CellDraft {
  const _CellDraft({
    required this.startRow,
    required this.endRow,
    required this.text,
  });

  final int startRow;
  final int endRow;
  final String text;
}

enum _CellAction {
  edit,
  delete,
  moveUp,
  moveDown,
  mergeUp,
  mergeDown,
  unmerge,
}

class _EditorErrorBanner extends StatelessWidget {
  const _EditorErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9E6E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3B1A9)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF8A2E24),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final child in children)
          SizedBox(
            width: 96,
            child: child,
          ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isPrimary = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final button = isPrimary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Icon(icon),
          )
        : FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Icon(icon),
          );

    return Tooltip(
      message: tooltip,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}

class _ColumnEditorCard extends StatelessWidget {
  const _ColumnEditorCard({
    required this.columnId,
    required this.child,
    required this.onAddCell,
    required this.onDeleteColumn,
  });

  final String columnId;
  final Widget child;
  final VoidCallback onAddCell;
  final VoidCallback onDeleteColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7CCBE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Column $columnId',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddCell,
                icon: const Icon(Icons.add_box_outlined),
                tooltip: 'Add cell',
              ),
              IconButton(
                onPressed: onDeleteColumn,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete column',
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EditorListRow extends StatelessWidget {
  const _EditorListRow({
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
    this.actionMenu,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? actionMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3DACD)),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF5E675F),
          ),
        ),
        trailing: actionMenu ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
      ),
    );
  }
}

class _EditorPlaceholder extends StatelessWidget {
  const _EditorPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5E675F),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

List<String> _sortedTags(Iterable<String> tags) {
  final values = [...tags];
  values.sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
  return values;
}

String _tagLabel(BuildContext context, String tag) {
  return tag;
}
