import 'package:flutter/material.dart';

import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import '../../recipe_document/domain/recipe_document.dart';
import '../../recipe_document/domain/recipe_dsl_codec.dart';
import '../../recipe_document/presentation/recipe_chart_view.dart';

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({
    super.key,
    required this.initialRecipe,
    this.allowDelete = false,
  });

  final RecipeSummary initialRecipe;
  final bool allowDelete;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _yieldController;
  late final TextEditingController _notesController;
  late final TextEditingController _dslController;
  RecipeDocument? _document;
  bool _isDslEditorExpanded = false;
  String? _dslError;
  bool _isSyncingDslText = false;
  RecipeChartSelection? _selectedCell;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialRecipe.title);
    _yieldController = TextEditingController(text: widget.initialRecipe.yieldText);
    _notesController = TextEditingController(
      text: _isDefaultDraftDescription(widget.initialRecipe.description)
          ? ''
          : widget.initialRecipe.description,
    );
    _document = _normalizedDocument(widget.initialRecipe.document);
    _dslController = TextEditingController()
      ..addListener(_handleDslChanged);
    _syncDslFromDocument();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yieldController.dispose();
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

    final title = _titleController.text.trim();
    final yieldText = _yieldController.text.trim();

    try {
      final document = RecipeDslCodec.parse(
        title: title.isEmpty ? widget.initialRecipe.title : title,
        yieldText: yieldText.isEmpty ? 'Yield TBD' : yieldText,
        source: _dslController.text,
      );
      setState(() {
        _document = _normalizedDocument(document);
        _dslError = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _dslError = error.message;
      });
    }
  }

  void _setDocument(RecipeDocument document) {
    setState(() {
      _document = _normalizedDocument(document);
      _dslError = null;
      _selectedCell = _resolvedSelection(_selectedCell, _normalizedDocument(document));
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
    final nextDsl = _buildInitialDsl(_currentDocument);
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
    var highestRow = document.rowCount;

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

    for (final column in normalizedColumns) {
      for (final cell in column.cells) {
        final endRow = cell.startRow + cell.rowSpan - 1;
        if (endRow > highestRow) {
          highestRow = endRow;
        }
      }
    }

    return document.copyWith(
      prepRows: [...document.prepRows],
      columns: normalizedColumns,
      rowCount: highestRow < 0 ? 0 : highestRow,
    );
  }

  RecipeDocument get _currentDocument {
    return _document ??= _normalizedDocument(widget.initialRecipe.document);
  }

  Future<void> _editPrepRow({int? index}) async {
    final controller = TextEditingController(
      text: index == null ? '' : _currentDocument.prepRows[index].text,
    );
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Add Prep Row' : 'Edit Prep Row'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Preheat oven'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
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
    final nextRow = _currentDocument.rowCount + 1;
    if (_currentDocument.columns.every((column) => column.cells.isEmpty)) {
      final targetColumnId = _currentDocument.columns.isEmpty
          ? 'A'
          : _currentDocument.columns.first.id;
      final document = _currentDocument.copyWith(
        rowCount: nextRow,
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

    _setDocument(_currentDocument.copyWith(rowCount: nextRow));
  }

  void _removeWorkflowRow() {
    if (_currentDocument.rowCount <= 0) {
      return;
    }

    final newRowCount = _currentDocument.rowCount - 1;
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

    _setDocument(
      _currentDocument.copyWith(columns: columns, rowCount: newRowCount),
    );
  }

  int _clampedRowSpan(WorkflowCell cell, int maxRow) {
    final endRow = cell.startRow + cell.rowSpan - 1;
    if (endRow <= maxRow) {
      return cell.rowSpan;
    }
    return maxRow - cell.startRow + 1;
  }

  void _addColumn() {
    final nextId = _nextColumnId(_currentDocument.columns);
    if (nextId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more column letters available.')),
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
          title: Text(existingCell == null ? 'Add Cell' : 'Edit Cell'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Cell text'),
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
                      decoration: const InputDecoration(labelText: 'Start row'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'End row'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Save'),
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
        draft.endRow > _currentDocument.rowCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rows must stay between 1 and ${_currentDocument.rowCount}, and end row must be after start row.',
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
            'That row range overlaps another cell in column $columnId.',
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
    if (newEndRow > _currentDocument.rowCount) {
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
                        'Prep Rows',
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
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentDocument.prepRows.isEmpty)
                  const _EditorPlaceholder(
                    text: 'No prep rows yet. Add one to create the top instructions.',
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
                            subtitle: 'Prep row ${index + 1}',
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
                        'Workflow Cells',
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
                      label: const Text('Add Column'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentDocument.columns.isEmpty)
                  const _EditorPlaceholder(
                    text: 'No workflow columns yet. Add a column to start placing cells.',
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
                                  const _EditorPlaceholder(
                                    text: 'No cells in this column yet.',
                                  )
                                else
                                  for (final cell in column.cells)
                                    _EditorListRow(
                                      title: cell.text,
                                      subtitle: cell.rowSpan == 1
                                          ? 'Row ${cell.startRow}'
                                          : 'Rows ${cell.startRow}-${cell.startRow + cell.rowSpan - 1}',
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
                                          const PopupMenuItem(
                                            value: _CellAction.edit,
                                            child: Text('Edit'),
                                          ),
                                          if (_canMergeUp(column.id, cell))
                                            const PopupMenuItem(
                                              value: _CellAction.mergeUp,
                                              child: Text('Merge With Above'),
                                            ),
                                          if (_canMergeDown(column.id, cell))
                                            const PopupMenuItem(
                                              value: _CellAction.mergeDown,
                                              child: Text('Merge With Below'),
                                            ),
                                          if (cell.rowSpan > 1)
                                            const PopupMenuItem(
                                              value: _CellAction.unmerge,
                                              child: Text('Unmerge'),
                                            ),
                                          const PopupMenuItem(
                                            value: _CellAction.delete,
                                            child: Text('Delete'),
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
    if (endRow >= _currentDocument.rowCount) {
      return false;
    }
    return true;
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
    final title = _titleController.text.trim();
    final document = _currentDocument;

    Navigator.of(context).pop(
      RecipeEditorResult.saved(
        widget.initialRecipe.copyWith(
          title: title,
          description: notes.isEmpty ? _defaultDraftDescription : notes,
          yieldText: yieldText.isEmpty ? 'Yield TBD' : yieldText,
          document: document.copyWith(
            title: title,
            yieldText: yieldText.isEmpty ? 'Yield TBD' : yieldText,
          ),
          duration: widget.initialRecipe.isDraft ? 'Draft' : widget.initialRecipe.duration,
          isDraft: true,
        ),
      ),
    );
  }

  void _deleteRecipe() {
    Navigator.of(context).pop(const RecipeEditorResult.deleted());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.allowDelete ? 'Edit Recipe' : 'New Recipe'),
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
                      widget.allowDelete
                          ? 'Edit the recipe visually and keep DSL as an advanced option.'
                          : 'Start visually and use DSL only when you want it.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use buttons to build prep rows, workflow rows, columns, and merged chart cells. The DSL stays available as a fallback.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5E675F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(
                label: 'Recipe title',
                child: TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Banana Nut Bread'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a recipe title.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Yield',
                child: TextFormField(
                  controller: _yieldController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: '10 servings'),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Draft notes',
                child: TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Optional notes about the recipe before you build the workflow chart.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD7CCBE)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _isDslEditorExpanded = !_isDslEditorExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chart DSL',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Optional advanced editing and paste/import flow.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF5E675F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isDslEditorExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isDslEditorExpanded) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _dslController,
                          minLines: 12,
                          maxLines: 20,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'prep:\n- Warm a small pan\n\nA:\n1. 1 egg\n\nB:\n1. crack\n\nC:\n1. whisk',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_dslError != null) _EditorErrorBanner(message: _dslError!),
              if (_dslError != null) const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD7CCBE)),
                ),
                child: Text(
                  'Prep rows: ${_currentDocument.prepRows.length}  |  Workflow rows: ${_currentDocument.rowCount}  |  Columns: ${_currentDocument.columns.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E675F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chart Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              RecipeChartView(
                document: _currentDocument,
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCell != null && _currentCell == null) ...[
                    FilledButton(
                      onPressed: () => _editCell(
                        columnId: _selectedCell!.columnId,
                        initialStartRow: _selectedCell!.startRow,
                        initialEndRow: _selectedCell!.startRow,
                      ),
                      child: const Text('Create Cell'),
                    ),
                    FilledButton.tonal(
                      onPressed: _clearSelection,
                      child: const Text('Cancel'),
                    ),
                  ] else if (_currentCell != null) ...[
                    FilledButton(
                      onPressed: () => _editCell(
                        columnId: _selectedCell!.columnId,
                        existingCell: _currentCell,
                      ),
                      child: const Text('Edit Cell'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          _deleteCell(_selectedCell!.columnId, _currentCell!),
                      child: const Text('Delete Cell'),
                    ),
                    if (_canMergeUp(_selectedCell!.columnId, _currentCell!))
                      FilledButton.tonal(
                        onPressed: () =>
                            _mergeCellUp(_selectedCell!.columnId, _currentCell!),
                        child: const Text('Merge Up'),
                      ),
                    if (_canMergeDown(_selectedCell!.columnId, _currentCell!))
                      FilledButton.tonal(
                        onPressed: () => _mergeCellDown(
                          _selectedCell!.columnId,
                          _currentCell!,
                        ),
                        child: const Text('Merge Down'),
                      ),
                    if (_currentCell!.rowSpan > 1)
                      FilledButton.tonal(
                        onPressed: () =>
                            _unmergeCell(_selectedCell!.columnId, _currentCell!),
                        child: const Text('Unmerge'),
                      ),
                    FilledButton.tonal(
                      onPressed: _clearSelection,
                      child: const Text('Done'),
                    ),
                  ] else ...[
                  FilledButton.tonalIcon(
                    onPressed: _openPrepManager,
                    icon: const Icon(Icons.format_list_bulleted),
                    label: const Text('Prep'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _removeWorkflowRow,
                    icon: const Icon(Icons.remove),
                    label: const Text('Row'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addWorkflowRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Row'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addColumn,
                    icon: const Icon(Icons.view_column),
                    label: const Text('Column'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _openCellManager,
                    icon: const Icon(Icons.dashboard_customize),
                    label: const Text('Cells'),
                  ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (widget.allowDelete) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _deleteRecipe,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB33A2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveRecipe,
                      icon: const Icon(Icons.check),
                      label: Text(widget.allowDelete ? 'Save' : 'Create Draft'),
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

class _InvalidChartPreview extends StatelessWidget {
  const _InvalidChartPreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3B1A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart preview unavailable',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8A2E24),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSectionCard extends StatelessWidget {
  const _EditorSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7CCBE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5E675F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
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

const _defaultDraftDescription =
    'New draft recipe ready for ingredients, prep rows, and chart steps.';

bool _isDefaultDraftDescription(String description) {
  return description == _defaultDraftDescription;
}

String _buildInitialDsl(RecipeDocument document) {
  final encoded = RecipeDslCodec.encode(document);
  if (encoded.trim().isNotEmpty) {
    return encoded;
  }

  return 'prep:\n- Warm a small pan\n\nA:\n1. 1 egg\n\nB:\n1. crack\n\nC:\n1. whisk';
}
