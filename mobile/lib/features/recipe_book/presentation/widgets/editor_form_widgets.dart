import 'package:flutter/material.dart';

class EditorErrorBanner extends StatelessWidget {
  const EditorErrorBanner({super.key, required this.message});

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

class ColumnEditorCard extends StatelessWidget {
  const ColumnEditorCard({
    super.key,
    required this.columnId,
    required this.columnLabel,
    required this.addCellLabel,
    required this.deleteColumnLabel,
    required this.child,
    required this.onAddCell,
    required this.onDeleteColumn,
  });

  final String columnId;
  final String columnLabel;
  final String addCellLabel;
  final String deleteColumnLabel;
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
                  '$columnLabel $columnId',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddCell,
                icon: const Icon(Icons.add_box_outlined),
                tooltip: addCellLabel,
              ),
              IconButton(
                onPressed: onDeleteColumn,
                icon: const Icon(Icons.delete_outline),
                tooltip: deleteColumnLabel,
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

class EditorListRow extends StatelessWidget {
  const EditorListRow({
    super.key,
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
        trailing:
            actionMenu ??
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

class EditorPlaceholder extends StatelessWidget {
  const EditorPlaceholder({super.key, required this.text});

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

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, required this.child});

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
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
