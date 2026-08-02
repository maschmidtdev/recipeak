import 'package:flutter/material.dart';

class EditorBottomActions extends StatelessWidget {
  const EditorBottomActions({
    super.key,
    required this.chartActions,
    required this.onDiscard,
    required this.onSave,
    required this.discardLabel,
    required this.saveLabel,
  });

  final Widget chartActions;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final String discardLabel;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            child: chartActions,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onDiscard,
                    icon: const Icon(Icons.close),
                    label: Text(discardLabel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check),
                    label: Text(saveLabel),
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
    );
  }
}
