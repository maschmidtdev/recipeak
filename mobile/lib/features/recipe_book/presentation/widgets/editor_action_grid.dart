import 'package:flutter/material.dart';

class DirectionalActionGrid extends StatelessWidget {
  const DirectionalActionGrid({
    super.key,
    required this.up,
    required this.left,
    required this.right,
    required this.down,
    required this.done,
  });

  final Widget up;
  final Widget left;
  final Widget right;
  final Widget down;
  final Widget done;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: up),
            const SizedBox(width: 8),
            Expanded(child: left),
            const SizedBox(width: 8),
            Expanded(child: right),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: down),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: done),
          ],
        ),
      ],
    );
  }
}

class MainCellActionGrid extends StatelessWidget {
  const MainCellActionGrid({
    super.key,
    required this.merge,
    required this.moveUp,
    required this.unmerge,
    required this.moveLeft,
    required this.moveDown,
    required this.moveRight,
    required this.edit,
    required this.done,
    required this.delete,
  });

  final Widget merge;
  final Widget moveUp;
  final Widget unmerge;
  final Widget moveLeft;
  final Widget moveDown;
  final Widget moveRight;
  final Widget edit;
  final Widget done;
  final Widget delete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionGridRow(children: [merge, moveUp, unmerge]),
        const SizedBox(height: 8),
        _ActionGridRow(children: [moveLeft, moveDown, moveRight]),
        const SizedBox(height: 8),
        _ActionGridRow(children: [edit, done, delete]),
      ],
    );
  }
}

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isConfirm = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool isConfirm;

  @override
  Widget build(BuildContext context) {
    final button = isConfirm
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

class _ActionGridRow extends StatelessWidget {
  const _ActionGridRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
