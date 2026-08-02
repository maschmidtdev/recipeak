import 'package:flutter/material.dart';

class DslEditorSheet extends StatelessWidget {
  const DslEditorSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.description,
    required this.hintText,
  });

  final TextEditingController controller;
  final String title;
  final String description;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E675F),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: controller,
                      minLines: 12,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      decoration: InputDecoration(
                        hintText: hintText,
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
  }
}

class DslInfoDialog extends StatelessWidget {
  const DslInfoDialog({
    super.key,
    required this.title,
    required this.body,
    required this.doneLabel,
  });

  final String title;
  final String body;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(doneLabel),
        ),
      ],
    );
  }
}
