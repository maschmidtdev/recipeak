import 'package:flutter/material.dart';

import '../../../app/dev_flags.dart';
import '../domain/recipe_collection_filters.dart';
import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import 'widgets/editor_action_grid.dart';
import '../../recipe_document/domain/chart_document_editor.dart';
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
  _CellActionPanel _cellActionPanel = _CellActionPanel.main;
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
        final mediaQuery = MediaQuery.of(context);
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.82,
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
                    Flexible(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _dslController,
                          minLines: 12,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations.chartDslHint,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
      if (_selectedCell == null) {
        _cellActionPanel = _CellActionPanel.main;
      }
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
        tags: sortedTags(_selectedTags),
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

  ChartDocumentEditor get _chartEditor => ChartDocumentEditor(
    document: _currentDocument,
    workflowRowCount: _currentWorkflowRowCount,
  );

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
                  columnSpan: cell.columnSpan,
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
    final nextId = _chartEditor.nextColumnId();
    if (nextId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.noMoreColumnLetters)),
      );
      return;
    }

    _setDocument(_chartEditor.addColumn(nextId));
  }

  void _deleteColumn(String columnId) {
    _setDocument(_chartEditor.deleteColumn(columnId));
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
        return AlertDialog(
          scrollable: true,
          title: Text(localizations.editCell),
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

    if (!_chartEditor.canPlaceCell(
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

    _setDocument(
      _chartEditor.upsertCell(
        columnId: columnId,
        existingCell: existingCell,
        newCell: WorkflowCell(
          startRow: draft.startRow,
          rowSpan: draft.endRow - draft.startRow + 1,
          columnSpan: existingCell?.columnSpan ?? 1,
          text: draft.text,
        ),
      ),
    );
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: columnId,
        startRow: draft.startRow,
      );
    });
  }

  void _deleteCell(String columnId, WorkflowCell targetCell) {
    _setDocument(
      _chartEditor.deleteCell(columnId: columnId, targetCell: targetCell),
    );
  }

  void _moveCellUp(String columnId, WorkflowCell cell) {
    if (!_canMoveUp(columnId, cell)) {
      return;
    }
    if (!_selectedCellIsStored) {
      setState(() {
        _selectedCell = RecipeChartSelection(
          columnId: columnId,
          startRow: cell.startRow - 1,
        );
      });
      return;
    }
    _moveCellByDelta(columnId: columnId, cell: cell, rowDelta: -1, columnDelta: 0);
  }

  void _moveCellDown(String columnId, WorkflowCell cell) {
    if (!_canMoveDown(columnId, cell)) {
      return;
    }
    if (!_selectedCellIsStored) {
      setState(() {
        _selectedCell = RecipeChartSelection(
          columnId: columnId,
          startRow: cell.startRow + 1,
        );
      });
      return;
    }
    _moveCellByDelta(columnId: columnId, cell: cell, rowDelta: 1, columnDelta: 0);
  }

  void _moveCellLeft(String columnId, WorkflowCell cell) {
    if (!_canMoveLeft(columnId, cell)) {
      return;
    }
    if (!_selectedCellIsStored) {
      final nextColumnId = _chartEditor.columnIdByOffset(columnId, -1);
      if (nextColumnId == null) {
        return;
      }
      setState(() {
        _selectedCell = RecipeChartSelection(
          columnId: nextColumnId,
          startRow: cell.startRow,
        );
      });
      return;
    }
    _moveCellByDelta(columnId: columnId, cell: cell, rowDelta: 0, columnDelta: -1);
  }

  void _moveCellRight(String columnId, WorkflowCell cell) {
    if (!_canMoveRight(columnId, cell)) {
      return;
    }
    if (!_selectedCellIsStored) {
      final nextColumnId = _chartEditor.columnIdByOffset(columnId, 1);
      if (nextColumnId == null) {
        return;
      }
      setState(() {
        _selectedCell = RecipeChartSelection(
          columnId: nextColumnId,
          startRow: cell.startRow,
        );
      });
      return;
    }
    _moveCellByDelta(columnId: columnId, cell: cell, rowDelta: 0, columnDelta: 1);
  }

  void _mergeCellUp(String columnId, WorkflowCell cell) {
    final result = _chartEditor.mergeCellUp(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.merge);
  }

  void _mergeCellDown(String columnId, WorkflowCell cell) {
    final result = _chartEditor.mergeCellDown(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.merge);
  }

  void _mergeCellLeft(String columnId, WorkflowCell cell) {
    final result = _chartEditor.mergeCellLeft(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.merge);
  }

  void _mergeCellRight(String columnId, WorkflowCell cell) {
    final result = _chartEditor.mergeCellRight(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.merge);
  }

  void _unmergeCell(String columnId, WorkflowCell cell) {
    final result = _chartEditor.unmergeCell(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result);
  }

  void _unmergeCellUp(String columnId, WorkflowCell cell) {
    final result = _chartEditor.unmergeCellUp(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.unmerge);
  }

  void _unmergeCellDown(String columnId, WorkflowCell cell) {
    final result = _chartEditor.unmergeCellDown(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.unmerge);
  }

  void _unmergeCellLeft(String columnId, WorkflowCell cell) {
    final result = _chartEditor.unmergeCellLeft(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.unmerge);
  }

  void _unmergeCellRight(String columnId, WorkflowCell cell) {
    final result = _chartEditor.unmergeCellRight(columnId, cell);
    if (result == null) {
      return;
    }
    _applyChartEditResult(result, panel: _CellActionPanel.unmerge);
  }

  void _moveCellByDelta({
    required String columnId,
    required WorkflowCell cell,
    required int rowDelta,
    required int columnDelta,
  }) {
    final result = _chartEditor.moveCellByDelta(
      columnId: columnId,
      cell: cell,
      rowDelta: rowDelta,
      columnDelta: columnDelta,
    );
    if (result == null) {
      return;
    }

    _applyChartEditResult(result);
  }

  void _applyChartEditResult(
    ChartDocumentEditResult result, {
    _CellActionPanel? panel,
  }) {
    _setDocument(result.document);
    setState(() {
      _selectedCell = RecipeChartSelection(
        columnId: result.selectedColumnId,
        startRow: result.selectedStartRow,
      );
      if (panel != null) {
        _cellActionPanel = panel;
      }
    });
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
                                          if (cell.rowSpan > 1 || cell.columnSpan > 1)
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
    return _chartEditor.canMergeUp(columnId, cell);
  }

  bool _canMergeDown(String columnId, WorkflowCell cell) {
    return _chartEditor.canMergeDown(columnId, cell);
  }

  bool _canMergeLeft(String columnId, WorkflowCell cell) {
    return _chartEditor.canMergeLeft(columnId, cell);
  }

  bool _canMergeRight(String columnId, WorkflowCell cell) {
    return _chartEditor.canMergeRight(columnId, cell);
  }

  bool _canMoveUp(String columnId, WorkflowCell cell) {
    if (!_selectedCellIsStored) {
      return cell.startRow > 1;
    }
    return _chartEditor.canMove(
      columnId: columnId,
      cell: cell,
      rowDelta: -1,
      columnDelta: 0,
    );
  }

  bool _canMoveDown(String columnId, WorkflowCell cell) {
    if (!_selectedCellIsStored) {
      return cell.startRow < _currentWorkflowRowCount;
    }
    return _chartEditor.canMove(
      columnId: columnId,
      cell: cell,
      rowDelta: 1,
      columnDelta: 0,
    );
  }

  bool _canMoveLeft(String columnId, WorkflowCell cell) {
    if (!_selectedCellIsStored) {
      return _chartEditor.columnIdByOffset(columnId, -1) != null;
    }
    return _chartEditor.canMove(
      columnId: columnId,
      cell: cell,
      rowDelta: 0,
      columnDelta: -1,
    );
  }

  bool _canMoveRight(String columnId, WorkflowCell cell) {
    if (!_selectedCellIsStored) {
      return _chartEditor.columnIdByOffset(columnId, 1) != null;
    }
    return _chartEditor.canMove(
      columnId: columnId,
      cell: cell,
      rowDelta: 0,
      columnDelta: 1,
    );
  }

  bool _canUnmergeUp(WorkflowCell cell) {
    return _selectedCellIsStored && _chartEditor.canUnmergeUp(cell);
  }

  bool _canUnmergeDown(WorkflowCell cell) {
    return _selectedCellIsStored && _chartEditor.canUnmergeDown(cell);
  }

  bool _canUnmergeLeft(WorkflowCell cell) {
    return _selectedCellIsStored && _chartEditor.canUnmergeLeft(cell);
  }

  bool _canUnmergeRight(String columnId, WorkflowCell cell) {
    return _selectedCellIsStored && _chartEditor.canUnmergeRight(columnId, cell);
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

  WorkflowCell? get _selectedCellForActions {
    final selection = _selectedCell;
    if (selection == null) {
      return null;
    }
    return _currentCell ??
        WorkflowCell(
          startRow: selection.startRow,
          rowSpan: 1,
          text: '',
        );
  }

  bool get _selectedCellIsStored => _currentCell != null;

  bool get _hasAvailableMergeAction {
    final selection = _selectedCell;
    final cell = _selectedCellForActions;
    if (selection == null || cell == null) {
      return false;
    }
    return _canMergeUp(selection.columnId, cell) ||
        _canMergeDown(selection.columnId, cell) ||
        _canMergeLeft(selection.columnId, cell) ||
        _canMergeRight(selection.columnId, cell);
  }

  void _clearSelection() {
    setState(() {
      _selectedCell = null;
      _cellActionPanel = _CellActionPanel.main;
    });
  }

  void _returnToMainCellActions() {
    setState(() {
      _cellActionPanel = _CellActionPanel.main;
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

    final normalizedTag = normalizeTag(tag);
    if (normalizedTag.isEmpty) {
      return;
    }

    setState(() {
      _availableTags.add(normalizedTag);
      _selectedTags.add(normalizedTag);
    });
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
                        for (final tag in sortedTags(_availableTags))
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
                    _cellActionPanel = _CellActionPanel.main;
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
              child: _selectedCellForActions != null && _selectedCell != null
                  ? _cellActionPanelContent(localizations)
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

  Widget _cellActionPanelContent(AppLocalizations localizations) {
    switch (_cellActionPanel) {
      case _CellActionPanel.main:
        return MainCellActionGrid(
          merge: ActionIconButton(
            onPressed: _hasAvailableMergeAction
                ? () => setState(() {
                      _cellActionPanel = _CellActionPanel.merge;
                    })
                : null,
            icon: Icons.merge_type,
            tooltip: localizations.merge,
          ),
          moveUp: ActionIconButton(
            onPressed: _canMoveUp(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _moveCellUp(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.arrow_upward,
            tooltip: localizations.moveUp,
          ),
          unmerge: ActionIconButton(
            onPressed: _selectedCellIsStored &&
                    (_selectedCellForActions!.rowSpan > 1 ||
                        _selectedCellForActions!.columnSpan > 1)
                ? () => setState(() {
                      _cellActionPanel = _CellActionPanel.unmerge;
                    })
                : null,
            icon: Icons.call_split,
            tooltip: localizations.unmerge,
          ),
          moveLeft: ActionIconButton(
            onPressed: _canMoveLeft(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _moveCellLeft(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.arrow_back,
            tooltip: localizations.moveLeft,
          ),
          moveDown: ActionIconButton(
            onPressed: _canMoveDown(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _moveCellDown(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.arrow_downward,
            tooltip: localizations.moveDown,
          ),
          moveRight: ActionIconButton(
            onPressed: _canMoveRight(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _moveCellRight(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.arrow_forward,
            tooltip: localizations.moveRight,
          ),
          edit: ActionIconButton(
            onPressed: () => _editCell(
              columnId: _selectedCell!.columnId,
              existingCell: _currentCell,
              initialStartRow: _selectedCell!.startRow,
              initialEndRow: _selectedCell!.startRow,
            ),
            icon: Icons.edit_outlined,
            tooltip: localizations.editCell,
          ),
          done: ActionIconButton(
            onPressed: _clearSelection,
            icon: Icons.check,
            tooltip: localizations.done,
            isConfirm: true,
          ),
          delete: ActionIconButton(
            onPressed: _selectedCellIsStored
                ? () => _deleteCell(_selectedCell!.columnId, _currentCell!)
                : null,
            icon: Icons.delete_outline,
            tooltip: localizations.deleteCell,
          ),
        );
      case _CellActionPanel.merge:
        return DirectionalActionGrid(
          up: ActionIconButton(
            onPressed: _canMergeUp(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _mergeCellUp(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.vertical_align_top,
            tooltip: localizations.mergeUp,
          ),
          left: ActionIconButton(
            onPressed: _canMergeLeft(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _mergeCellLeft(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.align_horizontal_left,
            tooltip: localizations.mergeLeft,
          ),
          right: ActionIconButton(
            onPressed: _canMergeRight(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _mergeCellRight(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.align_horizontal_right,
            tooltip: localizations.mergeRight,
          ),
          down: ActionIconButton(
            onPressed: _canMergeDown(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _mergeCellDown(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.vertical_align_bottom,
            tooltip: localizations.mergeDown,
          ),
          done: ActionIconButton(
            onPressed: _returnToMainCellActions,
            icon: Icons.check,
            tooltip: localizations.done,
            isConfirm: true,
          ),
        );
      case _CellActionPanel.unmerge:
        return DirectionalActionGrid(
          up: ActionIconButton(
            onPressed: _canUnmergeUp(_selectedCellForActions!)
                ? () => _unmergeCellUp(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.vertical_align_top,
            tooltip: localizations.unmergeUp,
          ),
          left: ActionIconButton(
            onPressed: _canUnmergeLeft(_selectedCellForActions!)
                ? () => _unmergeCellLeft(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.align_horizontal_left,
            tooltip: localizations.unmergeLeft,
          ),
          right: ActionIconButton(
            onPressed: _canUnmergeRight(_selectedCell!.columnId, _selectedCellForActions!)
                ? () => _unmergeCellRight(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.align_horizontal_right,
            tooltip: localizations.unmergeRight,
          ),
          down: ActionIconButton(
            onPressed: _canUnmergeDown(_selectedCellForActions!)
                ? () => _unmergeCellDown(_selectedCell!.columnId, _selectedCellForActions!)
                : null,
            icon: Icons.vertical_align_bottom,
            tooltip: localizations.unmergeDown,
          ),
          done: ActionIconButton(
            onPressed: _returnToMainCellActions,
            icon: Icons.check,
            tooltip: localizations.done,
            isConfirm: true,
          ),
        );
    }
  }
}

enum _CellActionPanel {
  main,
  merge,
  unmerge,
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

String _tagLabel(BuildContext context, String tag) {
  return tag;
}
