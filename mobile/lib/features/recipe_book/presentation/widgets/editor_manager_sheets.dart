import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../recipe_document/domain/recipe_document.dart';
import 'editor_form_widgets.dart';

class PrepManagerSheet extends StatelessWidget {
  const PrepManagerSheet({
    super.key,
    required this.prepRows,
    required this.onAddPrepRow,
    required this.onEditPrepRow,
    required this.onDeletePrepRow,
  });

  final List<PrepRow> prepRows;
  final VoidCallback onAddPrepRow;
  final ValueChanged<int> onEditPrepRow;
  final ValueChanged<int> onDeletePrepRow;

  @override
  Widget build(BuildContext context) {
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
                    onAddPrepRow();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(localizations.addLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (prepRows.isEmpty)
              EditorPlaceholder(
                text:
                    '${localizations.noPrepRowsPlaceholder} ${localizations.createTopInstructionsHint}',
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var index = 0; index < prepRows.length; index++)
                      EditorListRow(
                        title: prepRows[index].text,
                        subtitle: localizations.prepRowNumberLabel(index + 1),
                        onEdit: () {
                          Navigator.of(context).pop();
                          onEditPrepRow(index);
                        },
                        onDelete: () {
                          Navigator.of(context).pop();
                          onDeletePrepRow(index);
                        },
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

class CellManagerSheet extends StatelessWidget {
  const CellManagerSheet({
    super.key,
    required this.columns,
    required this.onAddColumn,
    required this.onAddCell,
    required this.onDeleteColumn,
    required this.onEditCell,
    required this.onDeleteCell,
    required this.onMoveCellUp,
    required this.onMoveCellDown,
    required this.onMergeCellUp,
    required this.onMergeCellDown,
    required this.onUnmergeCell,
    required this.canMoveCellUp,
    required this.canMoveCellDown,
    required this.canMergeCellUp,
    required this.canMergeCellDown,
  });

  final List<WorkflowColumn> columns;
  final VoidCallback onAddColumn;
  final ValueChanged<String> onAddCell;
  final ValueChanged<String> onDeleteColumn;
  final void Function(String columnId, WorkflowCell cell) onEditCell;
  final void Function(String columnId, WorkflowCell cell) onDeleteCell;
  final void Function(String columnId, WorkflowCell cell) onMoveCellUp;
  final void Function(String columnId, WorkflowCell cell) onMoveCellDown;
  final void Function(String columnId, WorkflowCell cell) onMergeCellUp;
  final void Function(String columnId, WorkflowCell cell) onMergeCellDown;
  final void Function(String columnId, WorkflowCell cell) onUnmergeCell;
  final bool Function(String columnId, WorkflowCell cell) canMoveCellUp;
  final bool Function(String columnId, WorkflowCell cell) canMoveCellDown;
  final bool Function(String columnId, WorkflowCell cell) canMergeCellUp;
  final bool Function(String columnId, WorkflowCell cell) canMergeCellDown;

  @override
  Widget build(BuildContext context) {
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
                    onAddColumn();
                  },
                  icon: const Icon(Icons.view_column),
                  label: Text(localizations.addColumnLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (columns.isEmpty)
              EditorPlaceholder(text: localizations.noWorkflowColumnsPlaceholder)
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final column in columns) ...[
                      ColumnEditorCard(
                        columnId: column.id,
                        onAddCell: () {
                          Navigator.of(context).pop();
                          onAddCell(column.id);
                        },
                        onDeleteColumn: () {
                          Navigator.of(context).pop();
                          onDeleteColumn(column.id);
                        },
                        child: Column(
                          children: [
                            if (column.cells.isEmpty)
                              EditorPlaceholder(
                                text: localizations.noCellsInColumnPlaceholder,
                              )
                            else
                              for (final cell in column.cells)
                                EditorListRow(
                                  title: cell.text,
                                  subtitle: cell.rowSpan == 1
                                      ? localizations.singleRowLabel(
                                          cell.startRow,
                                        )
                                      : localizations.rowRangeLabel(
                                          cell.startRow,
                                          cell.startRow + cell.rowSpan - 1,
                                        ),
                                  actionMenu: _CellActionMenu(
                                    columnId: column.id,
                                    cell: cell,
                                    onEditCell: onEditCell,
                                    onDeleteCell: onDeleteCell,
                                    onMoveCellUp: onMoveCellUp,
                                    onMoveCellDown: onMoveCellDown,
                                    onMergeCellUp: onMergeCellUp,
                                    onMergeCellDown: onMergeCellDown,
                                    onUnmergeCell: onUnmergeCell,
                                    canMoveCellUp: canMoveCellUp,
                                    canMoveCellDown: canMoveCellDown,
                                    canMergeCellUp: canMergeCellUp,
                                    canMergeCellDown: canMergeCellDown,
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
  }
}

enum _CellManagerAction {
  edit,
  delete,
  moveUp,
  moveDown,
  mergeUp,
  mergeDown,
  unmerge,
}

class _CellActionMenu extends StatelessWidget {
  const _CellActionMenu({
    required this.columnId,
    required this.cell,
    required this.onEditCell,
    required this.onDeleteCell,
    required this.onMoveCellUp,
    required this.onMoveCellDown,
    required this.onMergeCellUp,
    required this.onMergeCellDown,
    required this.onUnmergeCell,
    required this.canMoveCellUp,
    required this.canMoveCellDown,
    required this.canMergeCellUp,
    required this.canMergeCellDown,
  });

  final String columnId;
  final WorkflowCell cell;
  final void Function(String columnId, WorkflowCell cell) onEditCell;
  final void Function(String columnId, WorkflowCell cell) onDeleteCell;
  final void Function(String columnId, WorkflowCell cell) onMoveCellUp;
  final void Function(String columnId, WorkflowCell cell) onMoveCellDown;
  final void Function(String columnId, WorkflowCell cell) onMergeCellUp;
  final void Function(String columnId, WorkflowCell cell) onMergeCellDown;
  final void Function(String columnId, WorkflowCell cell) onUnmergeCell;
  final bool Function(String columnId, WorkflowCell cell) canMoveCellUp;
  final bool Function(String columnId, WorkflowCell cell) canMoveCellDown;
  final bool Function(String columnId, WorkflowCell cell) canMergeCellUp;
  final bool Function(String columnId, WorkflowCell cell) canMergeCellDown;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopupMenuButton<_CellManagerAction>(
      onSelected: (action) {
        Navigator.of(context).pop();
        switch (action) {
          case _CellManagerAction.edit:
            onEditCell(columnId, cell);
            break;
          case _CellManagerAction.delete:
            onDeleteCell(columnId, cell);
            break;
          case _CellManagerAction.moveUp:
            onMoveCellUp(columnId, cell);
            break;
          case _CellManagerAction.moveDown:
            onMoveCellDown(columnId, cell);
            break;
          case _CellManagerAction.mergeUp:
            onMergeCellUp(columnId, cell);
            break;
          case _CellManagerAction.mergeDown:
            onMergeCellDown(columnId, cell);
            break;
          case _CellManagerAction.unmerge:
            onUnmergeCell(columnId, cell);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CellManagerAction.edit,
          child: Text(localizations.edit),
        ),
        if (canMoveCellUp(columnId, cell))
          PopupMenuItem(
            value: _CellManagerAction.moveUp,
            child: Text(localizations.moveUp),
          ),
        if (canMoveCellDown(columnId, cell))
          PopupMenuItem(
            value: _CellManagerAction.moveDown,
            child: Text(localizations.moveDown),
          ),
        if (canMergeCellUp(columnId, cell))
          PopupMenuItem(
            value: _CellManagerAction.mergeUp,
            child: Text(localizations.mergeWithAbove),
          ),
        if (canMergeCellDown(columnId, cell))
          PopupMenuItem(
            value: _CellManagerAction.mergeDown,
            child: Text(localizations.mergeWithBelow),
          ),
        if (cell.rowSpan > 1 || cell.columnSpan > 1)
          PopupMenuItem(
            value: _CellManagerAction.unmerge,
            child: Text(localizations.unmerge),
          ),
        PopupMenuItem(
          value: _CellManagerAction.delete,
          child: Text(localizations.delete),
        ),
      ],
    );
  }
}
