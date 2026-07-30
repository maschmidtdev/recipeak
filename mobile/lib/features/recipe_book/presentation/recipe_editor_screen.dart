import 'package:flutter/material.dart';

import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yieldController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notes = _notesController.text.trim();
    final yieldText = _yieldController.text.trim();

    Navigator.of(context).pop(
      RecipeEditorResult.saved(
        widget.initialRecipe.copyWith(
          title: _titleController.text.trim(),
          description: notes.isEmpty ? _defaultDraftDescription : notes,
          yieldText: yieldText.isEmpty ? 'Yield TBD' : yieldText,
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
                          ? 'Adjust the draft before building the chart.'
                          : 'Start with a draft, then shape the chart.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This editor currently covers title, yield, and notes. Chart editing comes next.',
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
