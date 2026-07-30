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
    _dslController = TextEditingController(
      text: _buildInitialDsl(widget.initialRecipe.document),
    )..addListener(_handleDslChanged);
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
    setState(() {});
  }

  _ParsedDocumentState get _parsedDocumentState {
    final title = _titleController.text.trim();
    final yieldText = _yieldController.text.trim();

    try {
      final document = RecipeDslCodec.parse(
        title: title.isEmpty ? widget.initialRecipe.title : title,
        yieldText: yieldText.isEmpty ? 'Yield TBD' : yieldText,
        source: _dslController.text,
      );
      return _ParsedDocumentState(document: document);
    } on FormatException catch (error) {
      return _ParsedDocumentState(error: error.message);
    }
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedDocumentState = _parsedDocumentState;
    if (parsedDocumentState.document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parsedDocumentState.error!)),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final yieldText = _yieldController.text.trim();
    final title = _titleController.text.trim();
    final document = parsedDocumentState.document!;

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
    final parsedDocumentState = _parsedDocumentState;

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
                          ? 'Edit the recipe DSL and preview the chart live.'
                          : 'Start with the DSL and shape the chart live.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Prep rows and workflow columns are edited as text. Single rows use "1. text" and merged ranges use "1-3: text".',
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
              _FieldLabel(
                label: 'Chart DSL',
                child: TextFormField(
                  controller: _dslController,
                  minLines: 12,
                  maxLines: 20,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  decoration: const InputDecoration(
                    hintText:
                        'prep:\n- Warm a small pan\n\nA:\n1. 1 egg\n\nB:\n1. crack\n\nC:\n1. whisk',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (parsedDocumentState.error != null)
                _EditorErrorBanner(message: parsedDocumentState.error!),
              if (parsedDocumentState.error != null) const SizedBox(height: 20),
              Text(
                'Chart Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (parsedDocumentState.document != null)
                RecipeChartView(document: parsedDocumentState.document!)
              else
                _InvalidChartPreview(message: parsedDocumentState.error!),
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

class _ParsedDocumentState {
  const _ParsedDocumentState({this.document, this.error});

  final RecipeDocument? document;
  final String? error;
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
