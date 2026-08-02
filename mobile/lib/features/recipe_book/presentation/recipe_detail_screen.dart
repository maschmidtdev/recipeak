import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/recipe_summary.dart';
import 'recipe_editor_result.dart';
import 'recipe_editor_screen.dart';
import '../../recipe_document/presentation/recipe_chart_view.dart';
import '../../../l10n/app_localizations.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.availableTags,
  });

  final RecipeSummary recipe;
  final List<String> availableTags;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late RecipeSummary _recipe;
  late List<String> _availableTags;
  bool _hasUnsyncedChanges = false;
  final _exportChartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _availableTags = List.of(widget.availableTags);
  }

  Future<void> _openEditor(BuildContext context) async {
    final result = await Navigator.of(context).push<RecipeEditorResult>(
      MaterialPageRoute(
        builder: (context) => RecipeEditorScreen(
          initialRecipe: _recipe,
          availableTags: _availableTags,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    switch (result.action) {
      case RecipeEditorAction.save:
        if (result.recipe != null) {
          setState(() {
            _recipe = result.recipe!;
            _availableTags = List.of(result.availableTags ?? _availableTags);
            _hasUnsyncedChanges = true;
          });
        }
        break;
      case RecipeEditorAction.delete:
        Navigator.of(context).pop(result);
        break;
    }
  }

  void _deleteRecipe(BuildContext context) {
    Navigator.of(context).pop(const RecipeEditorResult.deleted());
  }

  Future<Uint8List?> _captureChartImage() async {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(2.0, 3.0).toDouble();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          top: 0,
          child: IgnorePointer(
            child: Transform.translate(
              offset: const Offset(-10000, 0),
              child: Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    brightness: Brightness.light,
                    surface: const Color(0xFFF3EFE6),
                    onSurface: const Color(0xFF1F241F),
                  ),
                  textTheme: theme.textTheme.apply(
                    bodyColor: const Color(0xFF1F241F),
                    displayColor: const Color(0xFF1F241F),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: RepaintBoundary(
                    key: _exportChartKey,
                    child: ColoredBox(
                      color: const Color(0xFFF3EFE6),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipe.title,
                              style: const TextStyle(
                                color: Color(0xFF1F241F),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RecipeChartView(
                              document: _recipe.document,
                              allowHorizontalScroll: false,
                              expandToAvailableWidth: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final boundary = _exportChartKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  Future<void> _saveChartImage() async {
    final localizations = AppLocalizations.of(context);
    final fileName = _imageFileName(_recipe.title);

    try {
      final imageBytes = await _captureChartImage();
      if (imageBytes == null) {
        return;
      }

      await Gal.putImageBytes(
        imageBytes,
        name: fileName,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.chartImageSaved)),
      );
    } on GalException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.chartImageSaveFailed)),
      );
    }
  }

  Future<void> _shareChartImage() async {
    final fileName = _imageFileName(_recipe.title);
    final imageBytes = await _captureChartImage();
    if (imageBytes == null) {
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          imageBytes,
          mimeType: 'image/png',
          name: fileName,
        ),
      ],
      subject: _recipe.title,
    );
  }

  String _imageFileName(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final baseName = normalized.isEmpty ? 'recipe-chart' : normalized;
    return '$baseName-chart.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = _recipe;
    final localizations = AppLocalizations.of(context);
    final durationText = recipe.duration.trim();
    final yieldText = recipe.yieldText.trim();
    final hasDuration = durationText.isNotEmpty;
    final hasYield = yieldText.isNotEmpty;

    return PopScope(
      canPop: !_hasUnsyncedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_hasUnsyncedChanges) {
          return;
        }
        Navigator.of(
          context,
        ).pop(RecipeEditorResult.saved(_recipe, availableTags: _availableTags));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(recipe.title),
        ),
        body: SafeArea(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (recipe.isFavorite)
                          const Icon(Icons.favorite, color: Color(0xFFC96A3D)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5E675F),
                      ),
                    ),
                    if (recipe.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in recipe.tags)
                            Chip(
                              label: Text(_tagLabel(context, tag)),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                    if (hasDuration || hasYield) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (hasDuration)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule, size: 18),
                                const SizedBox(width: 6),
                                Text(durationText),
                              ],
                            ),
                          if (hasYield)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.restaurant_menu, size: 18),
                                const SizedBox(width: 6),
                                Text(yieldText),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.chartPreview,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _shareChartImage,
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: localizations.shareChartImage,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    onPressed: _saveChartImage,
                    icon: const Icon(Icons.download_outlined),
                    tooltip: localizations.exportChartImage,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecipeChartView(document: recipe.document),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _deleteRecipe(context),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(localizations.delete),
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
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(localizations.edit),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tagLabel(BuildContext context, String tag) {
  return tag;
}
